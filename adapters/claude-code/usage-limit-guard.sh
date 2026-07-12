#!/usr/bin/env bash
# usage-limit-guard.sh — Claude Code hooks: pause near the 5-hour usage limit, auto-resume at reset.
#
# Modes (first argument):
#   report            SessionStart hook — injects current usage % into context so the agent plans chunks
#   guard             PreToolUse hook   — at >= threshold, denies new work tools (checkpoint writes allowed)
#   schedule-resume   Stop hook         — at >= threshold, schedules `claude --continue` for the reset
#   resume-on-failure StopFailure hook (matcher: rate_limit) — the hard limit was hit mid-task:
#                     schedules the auto-resume anyway, so nothing has to be re-run by hand
#   notify <msg>      internal — sends a user notification (also usable manually for testing)
#
# User notifications: whenever the guard pauses work or schedules/executes a resume, it tells you with
# a simple message in THREE places:
#   1. the terminal — hook "systemMessage" rendered by the Claude Code UI
#   2. the chat — the agent is required (deny reason + AGENTS.md rule) to post the pause/resume message
#   3. desktop + log — osascript (macOS) / notify-send (Linux), always ~/.claude/usage-guard/notifications.log
#   "Paused: 5-hour usage limit at ~92%. Work checkpointed. Auto-resume at 14:37 CET."
#   "Usage limit reset — Claude resumed automatically."
#
# Usage data sources, in order of preference:
#   1. REAL — ~/.claude/usage-guard/rate_limits.json, written by statusline-usage-bridge.sh.
#      Claude Code >= v2.1.80 passes rate_limits (used_percentage, resets_at) to the status line,
#      but NOT to hooks — the bridge closes that gap. No calibration needed.
#   2. ESTIMATE — ccusage active block, else a sliding 5h window over local transcripts. Requires
#      CLAUDE_5H_TOKEN_LIMIT to be calibrated (see HOOKS.md). Fallback for older Claude Code.
#   With neither source, report/guard/schedule-resume are no-ops (fail open); resume-on-failure
#   still works by polling `claude --continue` until the limit has reset.
#
# Configuration (environment variables):
#   CLAUDE_5H_THRESHOLD     percentage at which to pause (default: 90)
#   CLAUDE_5H_AUTORESUME    1 = schedule automatic resume (default: 1; 0 = pause only)
#   CLAUDE_5H_TOKEN_LIMIT   tokens per 5h block — only needed for the ESTIMATE fallback (default: 0)

set -uo pipefail

MODE="${1:-guard}"
THRESHOLD="${CLAUDE_5H_THRESHOLD:-90}"
AUTORESUME="${CLAUDE_5H_AUTORESUME:-1}"
LIMIT="${CLAUDE_5H_TOKEN_LIMIT:-0}"
STATE_DIR="${HOME}/.claude/usage-guard"
BRIDGE_TTL=1800  # accept bridge data up to 30 min old
CACHE_TTL=60     # seconds between fresh estimate measurements

SELF="${BASH_SOURCE[0]}"
case "$SELF" in /*) ;; *) SELF="$(cd "$(dirname "$SELF")" 2>/dev/null && pwd)/$(basename "$SELF")";; esac

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
case "$LIMIT" in ''|*[!0-9]*) LIMIT=0;; esac

# --- user notification: desktop popup when possible, always logged ---
notify() {
  local msg="$1" title="Claude Code — 5h usage limit"
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$msg\" with title \"$title\"" >/dev/null 2>&1
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$msg" >/dev/null 2>&1
  fi
  printf '%s  %s\n' "$(date '+%F %H:%M:%S')" "$msg" >> "$STATE_DIR/notifications.log" 2>/dev/null || true
}

if [ "$MODE" = "notify" ]; then
  shift || true
  notify "${*:-Claude Code usage-limit guard test notification.}"
  exit 0
fi

INPUT="$(cat 2>/dev/null || true)"
command -v jq >/dev/null 2>&1 || exit 0

NOW=$(date -u +%s)
PCT=0; BLOCK_END=0; USED=0; SOURCE=""

# ISO-8601 UTC timestamp ("2026-07-10T07:00:00.000Z") -> epoch seconds. GNU date first, BSD fallback.
to_epoch() {
  local ts="${1%%.*}"; ts="${ts%Z}"
  date -u -d "$ts" +%s 2>/dev/null || date -u -j -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null
}

# Source 1: real rate-limit data saved by the status-line bridge
read_bridge() {
  local f="$STATE_DIR/rate_limits.json" wa reset
  [ -f "$f" ] || return 1
  wa=$(jq -r '.written_at // 0' "$f" 2>/dev/null)
  case "$wa" in ''|*[!0-9]*) return 1;; esac
  [ $((NOW - wa)) -le "$BRIDGE_TTL" ] || return 1
  PCT=$(jq -r '.five_hour.used_percentage // empty | floor' "$f" 2>/dev/null)
  case "$PCT" in ''|*[!0-9]*) PCT=0; return 1;; esac
  reset=$(jq -r '.five_hour.resets_at // 0 | floor' "$f" 2>/dev/null)
  case "$reset" in ''|*[!0-9]*) reset=0;; esac
  BLOCK_END=$reset
  SOURCE="real"
  return 0
}

# Source 2: estimate — ccusage active block, else transcript sliding window
measure_estimate() {
  USED=0; BLOCK_END=0
  local blocks_json end_ts
  if blocks_json=$(npx --yes ccusage@latest blocks --json --active 2>/dev/null) && [ -n "$blocks_json" ]; then
    USED=$(printf '%s' "$blocks_json" | jq -r '[.blocks[]? | select(.isActive == true)][0].totalTokens // 0' 2>/dev/null) || USED=0
    end_ts=$(printf '%s' "$blocks_json" | jq -r '[.blocks[]? | select(.isActive == true)][0].endTime // empty' 2>/dev/null)
    [ -n "$end_ts" ] && BLOCK_END=$(to_epoch "$end_ts") || BLOCK_END=0
  fi
  case "$USED" in ''|*[!0-9]*) USED=0;; esac
  if [ "$USED" -eq 0 ]; then
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

read_estimate_cached() {
  [ "$LIMIT" -gt 0 ] || return 1
  local cache="$STATE_DIR/measure.cache" c_ts c_used c_end
  if [ -f "$cache" ]; then
    read -r c_ts c_used c_end < "$cache" 2>/dev/null || true
    case "${c_ts:-x}" in *[!0-9]*|'') c_ts=0;; esac
    case "${c_used:-x}" in *[!0-9]*|'') c_used=-1;; esac
    case "${c_end:-x}" in *[!0-9]*|'') c_end=0;; esac
    if [ "$c_ts" -gt 0 ] && [ $((NOW - c_ts)) -lt "$CACHE_TTL" ] && [ "$c_used" -ge 0 ]; then
      USED=$c_used; BLOCK_END=$c_end
      PCT=$((USED * 100 / LIMIT)); SOURCE="estimated"
      return 0
    fi
  fi
  measure_estimate
  printf '%s %s %s\n' "$NOW" "$USED" "$BLOCK_END" > "$cache" 2>/dev/null || true
  PCT=$((USED * 100 / LIMIT)); SOURCE="estimated"
  return 0
}

read_bridge || read_estimate_cached || true

if [ "$BLOCK_END" -gt "$NOW" ]; then
  RESET_HUMAN=$(date -d "@$BLOCK_END" '+%H:%M %Z' 2>/dev/null || date -r "$BLOCK_END" '+%H:%M %Z' 2>/dev/null || echo "the next reset")
else
  RESET_HUMAN="when the limit resets (time unknown)"
fi

RESUME_PROMPT="The 5-hour usage limit has reset. Start your reply with one line confirming the automatic resume, e.g.: Resumed — 5-hour usage limit reset, continuing [task]. Then read AGENTS.md, follow the Session Protocol, and continue from Current Status / Next action. Clear the Blocked by field and checkpoint files as you go."

# Tell the user once per pause (guard, Stop, and StopFailure may all fire — the marker dedupes them).
# Sets NOTIFIED=1 when this call was the one that notified.
NOTIFIED=0
maybe_notify_pause() {
  local msg="$1" marker="$STATE_DIR/pause-notified" prev=0 diff
  [ -f "$marker" ] && prev=$(cat "$marker" 2>/dev/null || echo 0)
  case "$prev" in ''|*[!0-9]*) prev=0;; esac
  diff=$((BLOCK_END - prev)); [ "$diff" -lt 0 ] && diff=$((-diff))
  [ "$diff" -lt 600 ] && return 0   # already notified for this block
  echo "$BLOCK_END" > "$marker" 2>/dev/null || true
  NOTIFIED=1
  notify "$msg"
}

# Sets SCHEDULED=1 when a resume was actually scheduled by this call (lockfile dedupes repeats)
SCHEDULED=0
schedule_resume() {  # $1 = block-end epoch (0 = unknown -> poll until the limit has reset)
  [ "$AUTORESUME" = "1" ] || return 0
  local end="$1" lock="$STATE_DIR/resume.lock" pending cwd
  if [ -f "$lock" ]; then
    pending=$(cat "$lock" 2>/dev/null || echo 0)
    case "$pending" in ''|*[!0-9]*) pending=0;; esac
    [ "$pending" -gt "$NOW" ] && return 0   # a resume is already scheduled
  fi
  cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
  [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$PWD"
  if [ "$end" -gt "$NOW" ]; then
    local delay=$((end - NOW + 120))   # +2 min safety margin past the reset
    echo $((NOW + delay)) > "$lock" 2>/dev/null || return 0
    nohup bash -c "sleep $delay; bash '$SELF' notify 'Usage limit reset — Claude resumed automatically.' </dev/null; cd '$cwd' && claude --continue -p '$RESUME_PROMPT'; rm -f '$lock'" \
      >> "$STATE_DIR/resume.log" 2>&1 &
    echo "Usage-limit guard: auto-resume scheduled in ${delay}s (~${RESET_HUMAN}). Log: $STATE_DIR/resume.log" >&2
  else
    # Reset time unknown: retry every 15 min (max 6h) until a resume attempt gets through
    echo $((NOW + 21600)) > "$lock" 2>/dev/null || return 0
    nohup bash -c "cd '$cwd' || exit 1; for i in \$(seq 1 24); do sleep 900; if claude --continue -p '$RESUME_PROMPT'; then bash '$SELF' notify 'Usage limit reset — Claude resumed automatically.' </dev/null; break; fi; done; rm -f '$lock'" \
      >> "$STATE_DIR/resume.log" 2>&1 &
    echo "Usage-limit guard: reset time unknown — auto-resume will retry every 15 min. Log: $STATE_DIR/resume.log" >&2
  fi
  SCHEDULED=1
  disown 2>/dev/null || true
}

case "$MODE" in
  report)
    [ -n "$SOURCE" ] || exit 0
    if [ "$PCT" -ge $((THRESHOLD - 20)) ]; then
      echo "Usage-limit guard: ~${PCT}% of the 5-hour usage limit consumed (${SOURCE}; resets ~${RESET_HUMAN}). Per AGENTS.md, plan chunks so you can checkpoint before ${THRESHOLD}%."
    fi
    ;;

  guard)
    [ -n "$SOURCE" ] || exit 0
    [ "$PCT" -ge "$THRESHOLD" ] || exit 0
    PAUSE_MSG="Paused: 5-hour usage limit at ~${PCT}% (threshold ${THRESHOLD}%). Work is being checkpointed. Auto-resume at ${RESET_HUMAN}."
    maybe_notify_pause "$PAUSE_MSG"
    TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
    case "$TOOL" in
      Write|Edit|MultiEdit|NotebookEdit|TodoWrite|Read)   # keep checkpointing possible
        [ "$NOTIFIED" = "1" ] && jq -n --arg m "⏸ $PAUSE_MSG" '{systemMessage:$m}'
        exit 0 ;;
    esac
    REASON="Usage-limit guard: ~${PCT}% of the 5-hour usage limit is used (${SOURCE}; threshold ${THRESHOLD}%). Do not start new work. Checkpoint now per AGENTS.md: update the active task file, PLAN, and Current Status (set Blocked by: 5-hour usage limit — resumes automatically at ${RESET_HUMAN}). Then end your reply with the pause message from the Usage-Limit Rule (stopping, why, and the resume time) and stop. Auto-resume is scheduled for ${RESET_HUMAN}."
    if [ "$NOTIFIED" = "1" ]; then
      jq -n --arg m "⏸ $PAUSE_MSG" --arg reason "$REASON" \
        '{systemMessage:$m, hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
    else
      jq -n --arg reason "$REASON" \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
    fi
    ;;

  schedule-resume)
    [ -n "$SOURCE" ] || exit 0
    [ "$PCT" -ge "$THRESHOLD" ] || exit 0
    maybe_notify_pause "Paused: 5-hour usage limit at ~${PCT}% (threshold ${THRESHOLD}%). Work is checkpointed. Auto-resume at ${RESET_HUMAN}."
    schedule_resume "$BLOCK_END"
    [ "$SCHEDULED" = "1" ] && jq -n --arg m "⏸ Claude paused — 5-hour usage limit at ~${PCT}%. Auto-resume scheduled for ${RESET_HUMAN}." '{systemMessage:$m}'
    ;;

  resume-on-failure)
    # StopFailure(rate_limit): the hard wall was hit mid-task. Notify + schedule the resume even
    # with no usage source — poll mode handles an unknown reset time.
    maybe_notify_pause "Stopped: hit the 5-hour usage limit mid-task. Progress up to the last checkpoint is saved. Auto-resume at ${RESET_HUMAN}."
    schedule_resume "$BLOCK_END"
    [ "$SCHEDULED" = "1" ] && jq -n --arg m "⏸ Claude stopped — hit the 5-hour usage limit mid-task. Progress up to the last checkpoint is saved. Auto-resume at ${RESET_HUMAN}." '{systemMessage:$m}'
    ;;
esac

exit 0
