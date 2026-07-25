#!/usr/bin/env bash
# install.sh — one-paste installer for the B2B Sales Proposal skill.
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main/install.sh)"
#
# What it does:
#   1. Installs the skill for EVERY agent the skills.sh CLI detects on this machine
#      (Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity, ...)
#      — the generic AGENTS.md workflow (chunking, PLAN, task files, verification,
#      lessons learned) works in all of them.
#   2. If Claude Code is present, additionally installs its automation adapter:
#      usage-limit auto-pause at ~90%, notifications, and auto-resume at reset.
#      Other agents follow the same Usage-Limit Rule manually (no hook system to automate).

set -uo pipefail

REPO="https://github.com/AndrosMagnus/b2b-sales-proposal-skill"
RAW="https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main"

say() { printf '%s\n' "$*"; }

say "── B2B Sales Proposal — installer ──"
say ""

# --- 1. skill, for every detected agent ---
if command -v npx >/dev/null 2>&1; then
  say "→ Installing the skill for your agents (skills.sh)..."
  npx --yes skills add "$REPO" --skill b2b-sales-proposal \
    || say "!  skills CLI reported a problem — you can retry manually: npx skills add $REPO --skill b2b-sales-proposal"
else
  say "!  npx not found (Node.js required for the skills.sh CLI)."
  say "   Install Node.js, then run: npx skills add $REPO --skill b2b-sales-proposal"
fi
say ""

# --- 2. Claude Code automation adapter ---
if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
  say "→ Claude Code detected — installing the usage-limit automation adapter..."
  SELF_DIR=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/adapters/claude-code/install.sh" ]; then
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  if [ -n "$SELF_DIR" ]; then
    bash "$SELF_DIR/adapters/claude-code/install.sh" || say "!  Adapter install failed — see adapters/claude-code/HOOKS.md for manual setup."
  else
    TMP_INSTALLER=$(mktemp)
    if curl -fsSL "$RAW/adapters/claude-code/install.sh" -o "$TMP_INSTALLER"; then
      bash "$TMP_INSTALLER" || say "!  Adapter install failed — see $RAW/adapters/claude-code/HOOKS.md for manual setup."
    else
      say "!  Could not download the adapter installer — see $RAW/adapters/claude-code/HOOKS.md"
    fi
    rm -f "$TMP_INSTALLER"
  fi
else
  say "→ Claude Code not detected — skipping its automation adapter."
  say "  (The skill itself still works in Codex, Cursor, and any AGENTS.md-reading agent.)"
fi

say ""
say "Done. Open your agent in a deal folder and run: /b2b-sales-proposal"
