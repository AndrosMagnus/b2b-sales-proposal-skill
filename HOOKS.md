# HOOKS.md — 5-hour usage-limit guard

Claude Code hooks that enforce the cockpit's **Usage-Limit Rule**: at ~90% of the 5-hour usage limit the agent stops starting new work, checkpoints everything (task file, PLAN, `AGENTS.md` Current Status), and an automatic resume is scheduled for the moment the limit resets.

**Claude Code only.** Other agents (Codex, Cursor, …) don't run these hooks — for them the Usage-Limit Rule in `AGENTS.md` is a behavioral instruction, and resume is manual.

---

## What each hook does

| Hook event | Mode | Behavior |
|---|---|---|
| `SessionStart` | `report` | If usage is within 20 points of the threshold, injects "you are at ~X% of the 5-hour limit" into context so the agent sizes chunks accordingly |
| `PreToolUse` | `guard` | At ≥ threshold (default 90%), denies work tools with a message telling the agent to checkpoint and stop. `Write`/`Edit`/`Read`/`TodoWrite` stay allowed so the checkpoint files can still be saved |
| `Stop` | `schedule-resume` | At ≥ threshold, spawns a detached background process that waits until the 5-hour block resets (+2 min margin), then runs `claude --continue -p "…continue from Current Status…"` in the project directory. One resume per block, guaranteed by a lockfile |

The result: mid-task the agent finishes only what fits, saves state, and stops; between tasks it doesn't start the next one — and work continues by itself after the reset, headless, picking up from `AGENTS.md`.

---

## Install

1. Copy the hook into the deal project (or any project using the v2.0 cockpit):

   ```bash
   mkdir -p .claude/hooks
   cp hooks/usage-limit-guard.sh .claude/hooks/
   chmod +x .claude/hooks/usage-limit-guard.sh
   ```

2. Merge `hooks/settings.json.example` into the project's `.claude/settings.json` (create it if missing). If you already have hooks configured, merge the arrays — don't overwrite.

3. Set your token limit (see calibration below) in `.claude/settings.json`:

   ```json
   "env": { "CLAUDE_5H_TOKEN_LIMIT": "9000000" }
   ```

4. Requirements: `bash`, `jq`. Optional but recommended: Node/npx so the script can use [`ccusage`](https://github.com/ryoppippi/ccusage) for a more accurate active-block measurement.

---

## Calibrating `CLAUDE_5H_TOKEN_LIMIT` (required)

**The guard is a no-op until you set this.** Anthropic does not publish per-plan token numbers for the 5-hour limit, and it is not exposed to hooks — so the script compares an *estimated* token count against a limit *you* provide.

The reliable way to calibrate:

1. Work normally until Claude Code tells you you're approaching or hitting the 5-hour limit (or check `/usage` when it shows a high percentage).
2. At that moment run: `npx ccusage@latest blocks --active`
3. Note the active block's total tokens. If `/usage` said 80%, your limit ≈ `tokens / 0.80`. If you actually hit the limit, that token count *is* your limit.
4. Set `CLAUDE_5H_TOKEN_LIMIT` to that number, rounded down ~10% for safety.

Re-calibrate if you change plans or Anthropic adjusts limits.

---

## Configuration reference

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_5H_TOKEN_LIMIT` | `0` (disabled) | Estimated tokens per 5-hour block for your plan |
| `CLAUDE_5H_THRESHOLD` | `90` | Percentage at which to pause |
| `CLAUDE_5H_AUTORESUME` | `1` | `1` = schedule automatic `claude --continue` at reset; `0` = pause only, resume manually |

State, lockfiles, and the resume log live in `~/.claude/usage-guard/` (`resume.log` shows what the auto-resumed run did).

---

## Honest caveats

- **It's an estimate.** Neither hooks nor the CLI expose real 5-hour-limit consumption. `ccusage` reconstructs blocks from local transcript files; the fallback path sums a sliding 5-hour window. Both can drift from Anthropic's real accounting (cache reads are weighted differently, other devices/sessions on the same account aren't visible locally). The threshold + calibration margin absorb most of this, but treat 90% as approximate.
- **May break with Claude Code updates.** Transcript format, hook schema, and `ccusage` output are all unofficial surfaces.
- **Auto-resume runs headless.** The resumed session executes with your default permission settings, without you watching. The cockpit protocol keeps it safe (it checkpoints files and respects task gates — gates require your answer, so it will do work and then wait), but if that makes you uncomfortable set `CLAUDE_5H_AUTORESUME=0` and resume manually.
- **Auto-resume needs the machine awake.** The scheduled process is a `sleep`-then-run in the background; a laptop that sleeps or reboots cancels it. Resume manually in that case (`claude --continue`).
- **Fails open by design.** Any measurement error disables the guard rather than blocking your session.
