#!/usr/bin/env bash
# statusline-usage-bridge.sh — Claude Code statusLine command.
#
# Claude Code (>= v2.1.80) passes REAL rate-limit data (rate_limits.five_hour.used_percentage,
# resets_at) to the status line — but not to hooks. This script bridges the gap: it saves that
# data to ~/.claude/usage-guard/rate_limits.json where usage-limit-guard.sh reads it, then prints
# a normal status line.
#
# Install user-level (rate limits are account-wide), in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/hooks/statusline-usage-bridge.sh" }
#
# Already have a custom status line? Just add the "bridge" block below to your own script —
# only the file write matters to the guard; the printed line is yours to design.

set -uo pipefail
INPUT="$(cat)"
command -v jq >/dev/null 2>&1 || { echo "Claude"; exit 0; }

# --- bridge: persist real rate-limit data for the usage-limit-guard hooks ---
STATE_DIR="${HOME}/.claude/usage-guard"
mkdir -p "$STATE_DIR" 2>/dev/null || true
RL=$(printf '%s' "$INPUT" | jq -c '.rate_limits // empty' 2>/dev/null)
if [ -n "$RL" ]; then
  printf '%s' "$RL" | jq -c --argjson now "$(date +%s)" '. + {written_at: $now}' \
    > "$STATE_DIR/rate_limits.json.tmp" 2>/dev/null \
    && mv -f "$STATE_DIR/rate_limits.json.tmp" "$STATE_DIR/rate_limits.json" 2>/dev/null
fi

# --- display: model · dir · 5h/weekly usage (customize freely) ---
printf '%s' "$INPUT" | jq -r '
  def pct(x): if x == null then "–" else ((x | floor | tostring) + "%") end;
  [ (.model.display_name // "Claude"),
    ((.workspace.current_dir // .cwd // "") | split("/") | last // ""),
    "5h " + pct(.rate_limits.five_hour.used_percentage),
    "wk " + pct(.rate_limits.seven_day.used_percentage)
  ] | map(select(. != "")) | join("  ·  ")' 2>/dev/null || echo "Claude"
