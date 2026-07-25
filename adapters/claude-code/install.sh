#!/usr/bin/env bash
# adapters/claude-code/install.sh — installs the Claude Code usage-limit automation adapter.
#
# What it does (user-level, applies to all your Claude Code projects):
#   1. Copies usage-limit-guard.sh and statusline-usage-bridge.sh to ~/.claude/hooks/
#   2. Merges the guard hooks (SessionStart/PreToolUse/Stop/StopFailure), the status-line
#      bridge, and default env vars into ~/.claude/settings.json — with a timestamped backup,
#      never overwriting an existing statusLine or duplicating entries (safe to re-run)
#
# Run directly, via the repo's root install.sh, or let the skill offer it on activation.

set -euo pipefail

RAW="https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main/adapters/claude-code"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
GUARD="$HOOKS_DIR/usage-limit-guard.sh"
BRIDGE="$HOOKS_DIR/statusline-usage-bridge.sh"

say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq is required (https://jqlang.org). Install it and re-run."

# --- 1. install the scripts (prefer local copies next to this script; else download) ---
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/usage-limit-guard.sh" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

mkdir -p "$HOOKS_DIR"
if [ -n "$SRC_DIR" ]; then
  cp "$SRC_DIR/usage-limit-guard.sh" "$GUARD"
  cp "$SRC_DIR/statusline-usage-bridge.sh" "$BRIDGE"
else
  curl -fsSL "$RAW/usage-limit-guard.sh" -o "$GUARD" || die "download failed: usage-limit-guard.sh"
  curl -fsSL "$RAW/statusline-usage-bridge.sh" -o "$BRIDGE" || die "download failed: statusline-usage-bridge.sh"
fi
chmod +x "$GUARD" "$BRIDGE"
say "✓ Hook scripts installed in $HOOKS_DIR"

# --- 2. merge settings.json ---
mkdir -p "$HOME/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq empty "$SETTINGS" 2>/dev/null || die "$SETTINGS is not valid JSON — fix it and re-run."

BACKUP="$SETTINGS.backup.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$BACKUP"

GUARD_CMD="bash ~/.claude/hooks/usage-limit-guard.sh"
BRIDGE_CMD="bash ~/.claude/hooks/statusline-usage-bridge.sh"

STATUSLINE_NOTE=""
HAS_STATUSLINE=$(jq -r 'if .statusLine then "yes" else "no" end' "$SETTINGS")
HAS_BRIDGE=$(jq -r 'if ((.statusLine.command // "") | contains("statusline-usage-bridge")) then "yes" else "no" end' "$SETTINGS")
if [ "$HAS_STATUSLINE" = "yes" ] && [ "$HAS_BRIDGE" = "no" ]; then
  STATUSLINE_NOTE="kept-existing"
fi

TMP=$(mktemp)
jq --arg guard "$GUARD_CMD" --arg bridge "$BRIDGE_CMD" '
  .env = ({"CLAUDE_5H_THRESHOLD":"90","CLAUDE_5H_AUTORESUME":"1"} + (.env // {}))
  | (if .statusLine then . else .statusLine = {type:"command", command:$bridge} end)
  | if (.hooks // {} | tostring | contains("usage-limit-guard.sh")) then . else
      .hooks = (.hooks // {})
      | .hooks.SessionStart = ((.hooks.SessionStart // []) + [{hooks:[{type:"command", command:($guard + " report")}]}])
      | .hooks.PreToolUse   = ((.hooks.PreToolUse   // []) + [{matcher:"*", hooks:[{type:"command", command:($guard + " guard")}]}])
      | .hooks.Stop         = ((.hooks.Stop         // []) + [{hooks:[{type:"command", command:($guard + " schedule-resume")}]}])
      | .hooks.StopFailure  = ((.hooks.StopFailure  // []) + [{matcher:"rate_limit", hooks:[{type:"command", command:($guard + " resume-on-failure")}]}])
    end
' "$SETTINGS" > "$TMP"
jq empty "$TMP" 2>/dev/null || { rm -f "$TMP"; die "settings merge produced invalid JSON — $SETTINGS unchanged (backup at $BACKUP)"; }
mv "$TMP" "$SETTINGS"
say "✓ ~/.claude/settings.json updated (backup: $BACKUP)"

if [ "$STATUSLINE_NOTE" = "kept-existing" ]; then
  say ""
  say "! You already have a custom statusLine — it was NOT touched."
  say "  To feed the guard REAL rate-limit data, add the bridge block from"
  say "  ~/.claude/hooks/statusline-usage-bridge.sh (the ~8 lines under '--- bridge ---')"
  say "  to the top of your own status-line script. Until then the guard uses the"
  say "  estimate fallback (see HOOKS.md for calibration)."
fi

say ""
say "Claude Code usage-limit automation installed:"
say "  • pauses cleanly at ~90% of the 5-hour limit (checkpoint files stay writable)"
say "  • auto-resumes with 'claude --continue' when the limit resets"
say "  • StopFailure safety net if the hard limit is hit mid-task"
say "  • tells you what happened in the terminal, chat, desktop, and ~/.claude/usage-guard/notifications.log"
say "Restart any open Claude Code sessions to pick up the new hooks."
