#!/usr/bin/env bash
# usage-limit-guard.sh — Claude Code hook: pause near the 5-hour usage limit, auto-resume at reset.
#
# Modes (first argument):
#   report          SessionStart hook — injects current usage % into context so the agent can plan chunks
#   guard           PreToolUse hook  — at >= threshold, denies new work tools (checkpoint writes stay allowed)
#   schedule-resume Stop hook        — at >= threshold, schedules `claude --continue` for when the block resets
#
# Configuration (environment variables, e.g. in .claude/settings.json "env" or your shell profile):
#   CLAUDE_5H_TOKEN_LIMIT   tokens per 5-hour block (REQUIRED — guard is a no-op when unset/0; see HOOKS.md
#                           for how to calibrate this for your plan)
#   CLAUDE_5H_THRESHOLD     percentage at which to pause (default: 90)
#   CLAUDE_5H_AUTORESUME    1 = schedule automatic resume at reset (default: 1; set 0 to resume manually)
#
# Anthropic does not expose 5-hour-limit usage to hooks, so this script ESTIMATES it:
#   1st choice: ccusage (https://github.com/ryoppippi/ccusage) active-block token count, if available
#   fallback:   sums token usage from local transcripts (~/.claude/projects/**/*.jsonl) over a sliding 5h window
# Estimates are approximate — calibrate CLAUDE_5H_TOKEN_LIMIT as described in HOOKS.md. The script fails
# open (exit 0, no blocking) on any measurement problem so it can never brick a session.

set -uo pipefail

MODE="${1:-guard}"
LIMIT="${CLAUDE_5H_TOKEN_LIMIT:-0}"
THRESHOLD="${CLAUDE_5H_THRESHOLD:-90}"
AUTORESUME="${CLAUDE_5H_AUTORESUME:-1}"
STATE_DIR="${HOME}/.claude/usage-guard"
CACHE_TTL=60  # seconds between fresh measurements (PreToolUse fires often; keep it cheap)

INPUT="$(cat 2>/dev/null || true)"

case "$LIMIT" in ''|*[!0-9]*) exit 0;; esac
[ "$LIMIT" -gt 0 ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

NOW=$(date -u +%s)

# ISO-8601 UTC timestamp ("2026-07-10T07:00:00.000Z") -> epoch seconds. GNU date first, BSD fallback.
to_epoch() {
  local ts="${1%%.*}"; ts="${ts%Z}"
  date -u -d "$ts" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null
}

measure() {  # sets USED (tokens in current block) and BLOCK_END (epoch when the block resets)
  USED=0; BLOCK_END=0
  local blocks_json end_ts
  if blocks_json=$(npx --yes ccusage@latest blocks --json --active 2>/dev/null) && [ -n "$blocks_json" ]; then
    USED=$(printf '%s' "$blocks_json" | jq -r '[.blocks[]? | select(.isActive == true)][0].totalTokens // 0' 2>/dev/null) || USED=0
    end_ts=$(printf '%s' "$blocks_json" | jq -r '[.blocks[]? | select(.isActive == true)][0].endTime // empty' 2>/dev/null)
    [ -n "$end_ts" ] && BLOCK_END=$(to_epoch "$end_ts") || BLOCK_END=0
  fi
  case "$USED" in ''|*[!0-9]*) USED=0;; esac
  if [ "$USED" -eq 0 ]; then
    # Fallback: sliding 5-hour window over local transcripts (input + output + cache-creation tokens)
    local cutoff=$((NOW - 18000)) oldest=$NOW ts tok e
    while IFS=$'\t' read -r ts tok; do
      [ -n "$ts" ] || continue
      e=$(to_epoch "$ts") || continue
      case "$tok" in ''|*[!0-9]*) continue;; esac
      if [ "$e" -ge "$cutoff" ]; then
        USED=$((USED + tok))
        [ "$e" -lt "$oldest" ] && oldest=$e
      fi
    done < <(find "$HOME/.claude/projects" -name '*.jsonl' -mmin -330 2>/dev/null -exec cat {} + 2>/dev/null \
      | jq -r 'select(.message.usage? and .timestamp?) |
          [.timestamp,
           ((.message.usage.input_tokens // 0) + (.message.usage.output_tokens // 0) + (.message.usage.cache_creation_input_tokens // 0))
          ] | @tsv' 2>/dev/null)
    [ "$BLOCK_END" -eq 0 ] && [ "$USED" -gt 0 ] && BLOCK_END=$((oldest + 18000))
  fi
  [ "$BLOCK_END" -gt 0 ] || BLOCK_END=$((NOW + 18000))
}

# Cached measurement so PreToolUse stays fast between refreshes
CACHE="$STATE_DIR/measure.cache"
USED=0; BLOCK_END=0
if [ -f "$CACHE" ]; then
  read -r C_TS C_USED C_END < "$CACHE" 2>/dev/null || true
  case "${C_TS:-x}${C_USED:-x}${C_END:-x}" in *[!0-9]*) C_TS=0;; esac
  if [ "${C_TS:-0}" -gt 0 ] && [ $((NOW - C_TS)) -lt "$CACHE_TTL" ]; then
    USED=$C_USED; BLOCK_END=$C_END
  fi
fi
if [ "$USED" -eq 0 ] && [ "$BLOCK_END" -eq 0 ]; then
  measure
  printf '%s %s %s\n' "$NOW" "$USED" "$BLOCK_END" > "$CACHE" 2>/dev/null || true
fi

PCT=$((USED * 100 / LIMIT))
RESET_HUMAN=$(date -u -d "@$BLOCK_END" '+%H:%M UTC' 2>/dev/null || date -u -r "$BLOCK_END" '+%H:%M UTC' 2>/dev/null || echo "the next 5-hour reset")

case "$MODE" in
  report)
    if [ "$PCT" -ge $((THRESHOLD - 20)) ]; then
      echo "Usage-limit guard: ~${PCT}% of the 5-hour usage limit consumed (est. ${USED}/${LIMIT} tokens, block resets ~${RESET_HUMAN}). Per AGENTS.md, plan chunks so you can checkpoint before ${THRESHOLD}%."
    fi
    ;;

  guard)
    [ "$PCT" -ge "$THRESHOLD" ] || exit 0
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
    case "$TOOL" in
      Write|Edit|MultiEdit|NotebookEdit|TodoWrite|Read) exit 0 ;;  # keep checkpointing possible
    esac
    jq -n --arg reason "Usage-limit guard: ~${PCT}% of the 5-hour usage limit is used (threshold ${THRESHOLD}%). Do not start new work. Checkpoint now per AGENTS.md: update the active task file, PLAN, and Current Status (set Blocked by: 5-hour usage limit — resumes automatically at ${RESET_HUMAN}), then stop. Auto-resume is scheduled for ~${RESET_HUMAN}." \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
    ;;

  schedule-resume)
    [ "$PCT" -ge "$THRESHOLD" ] || exit 0
    [ "$AUTORESUME" = "1" ] || exit 0
    CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    [ -n "$CWD" ] && [ -d "$CWD" ] || CWD="$PWD"
    LOCK="$STATE_DIR/resume-${BLOCK_END}.lock"   # one resume per block, even across many Stop events
    [ -e "$LOCK" ] && exit 0
    : > "$LOCK" 2>/dev/null || exit 0
    DELAY=$((BLOCK_END - NOW + 120))             # +2 min safety margin past the reset
    [ "$DELAY" -lt 60 ] && DELAY=60
    nohup bash -c "sleep $DELAY && cd '$CWD' && claude --continue -p 'The 5-hour usage limit has reset. Read AGENTS.md, follow the Session Protocol, and continue from Current Status / Next action. Clear the Blocked by field and checkpoint files as you go.'" \
      >> "$STATE_DIR/resume.log" 2>&1 &
    disown 2>/dev/null || true
    echo "Usage-limit guard: auto-resume scheduled in ${DELAY}s (~${RESET_HUMAN}). Log: $STATE_DIR/resume.log" >&2
    ;;
esac

exit 0
