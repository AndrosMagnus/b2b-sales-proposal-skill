# HOOKS.md — Claude Code adapter: usage-limit automation

Claude Code hooks that pause Claude at ~90% of the 5-hour usage limit, checkpoint its work, and automatically resume the moment the limit resets. If the hard limit is ever hit mid-task anyway, a safety-net hook schedules the resume too — you never have to re-run anything manually.

**Works standalone, in any project — the b2b-sales-proposal skill is not required.** This started as that skill's automation adapter (`adapters/claude-code/`), enforcing its cockpit's Usage-Limit Rule. But the hooks themselves have no dependency on the skill: they're general-purpose Claude Code automation you can install on their own and use for any repo or workflow, including plain software development. If the current project happens to have an `AGENTS.md` cockpit (e.g. a b2b-sales-proposal deal folder), the checkpoint/resume instructions reference it automatically; in any other project they use generic "save your work" wording instead — see [Standalone install](#standalone-install-no-skill-required) below.

Codex, Cursor, and other agents follow the same idea as a behavioral instruction (in projects using this skill's `AGENTS.md`) but don't expose a hook system that could automate it — this adapter is Claude Code only.

---

## How it gets the usage number

Claude Code **v2.1.80+** passes real rate-limit data (`rate_limits.five_hour.used_percentage`, `resets_at`) to **status line** scripts — but not to hooks. So this setup uses the status line as a bridge:

1. **`statusline-usage-bridge.sh`** (status line, user-level) — saves the real numbers to `~/.claude/usage-guard/rate_limits.json` on every status-line refresh, and prints a normal status line (model · dir · 5h % · weekly %). If you already have a custom status line, copy just the "bridge" block into your own script.
2. **`usage-limit-guard.sh`** (hooks) — reads that file for the real percentage and reset time. **No calibration needed.**

On older Claude Code versions (or if the bridge isn't installed), the guard falls back to an **estimate** (ccusage active block, else a sliding 5-hour window over local transcripts) — that path requires calibrating `CLAUDE_5H_TOKEN_LIMIT` (see below). With neither source available, the guard fails open (never blocks your session).

---

## What each hook does

| Hook event | Mode | Behavior |
|---|---|---|
| `SessionStart` | `report` | If usage is within 20 points of the threshold, injects "you are at ~X% of the 5-hour limit" into context so the agent sizes chunks accordingly |
| `PreToolUse` | `guard` | At ≥ threshold (default 90%), denies work tools with a message telling the agent to checkpoint and stop. `Write`/`Edit`/`Read`/`TodoWrite` stay allowed so the checkpoint files can still be saved |
| `Stop` | `schedule-resume` | At ≥ threshold, spawns a detached background process that waits until the block resets (+2 min margin), then runs `claude --continue -p "…"` in the project directory. One pending resume at a time, guaranteed by a lockfile |
| `StopFailure` (matcher `rate_limit`) | `resume-on-failure` | **Safety net:** fires when a run actually dies from hitting the limit mid-task. Schedules the same auto-resume — using the real reset time if known, otherwise retrying every 15 minutes (up to 6h) until a resume attempt gets through |

The result: normally the agent pauses *cleanly before the wall* — finishing the current unit of work if it fits, saving state — and continues by itself after the reset, headless, picking up where it left off (via `AGENTS.md` if the project has one, otherwise by checking recent file changes / commits / notes). And even if the wall is hit abruptly, the `StopFailure` net still brings the session back automatically.

---

## You get told what happened — in the terminal, the chat, and on the desktop

Whenever the guard pauses or resumes, the same simple message reaches you through three channels:

1. **Terminal** — the hooks emit a `systemMessage`, which the Claude Code UI renders directly in the session:
   `⏸ Paused: 5-hour usage limit at ~93% (threshold 90%). Work is being checkpointed. Auto-resume at 16:36 CET.`
2. **Chat** — the deny reason instructs the agent's last reply before stopping to end with one line stating it's stopping, why, and the resume time, and the auto-resumed session to open by confirming the resume before continuing (in b2b-sales-proposal projects this maps onto the cockpit's own Usage-Limit Rule wording; elsewhere it's just a plain status line)
3. **Desktop + log** — a notification via `osascript` (macOS) or `notify-send` (Linux), and always a line in `~/.claude/usage-guard/notifications.log`:

```
Paused: 5-hour usage limit at ~93% (threshold 90%). Work is being checkpointed. Auto-resume at 16:36 CET.
Stopped: hit the 5-hour usage limit mid-task. Progress up to the last checkpoint is saved. Auto-resume at 18:06 CET.
Usage limit reset — Claude resumed automatically.
```

One message per pause per channel (guard, Stop, and StopFailure firings are deduplicated per rate-limit block; the Stop hook additionally confirms once when the resume is actually scheduled). Times are shown in your local timezone. On systems without a desktop notifier (e.g. WSL without `notify-send`), the terminal, chat, and log channels still work. Test the desktop/log channel with:

```bash
bash ~/.claude/hooks/usage-limit-guard.sh notify "test"
```

---

## Install

### As part of the b2b-sales-proposal skill

The repo's one-paste installer detects Claude Code and runs this adapter's installer for you:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main/install.sh)"
```

The skill also offers to run it on activation if it detects the adapter is missing.

### Standalone (no skill required)

Want just the pause/notify/auto-resume behavior for general Claude Code use — any dev repo, not this skill? Run the adapter installer directly, no skill install needed:

```bash
curl -fsSL https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main/adapters/claude-code/install.sh | bash
```

Or clone/download just this folder and run `bash install.sh` from inside it. That's the entire footprint — two scripts in `~/.claude/hooks/` plus a settings merge. Nothing else from the repo is touched or required, and it applies user-wide (every project you open in Claude Code gets the guard), not just b2b-sales-proposal deal folders. Projects without an `AGENTS.md` automatically get generic "save your work" checkpoint/resume wording instead of the cockpit-specific instructions — see [Configuration reference](#configuration-reference) to override that wording explicitly (e.g. for your own project conventions) if you don't like the default.

### What either installer does

Copies both scripts to `~/.claude/hooks/` and merges the hooks, status line, and env defaults into `~/.claude/settings.json` — with a timestamped backup, never overwriting an existing custom statusLine, and never duplicating entries (safe to re-run). User-level install is the default because rate limits are account-wide.

**Manual** — copy `usage-limit-guard.sh` and `statusline-usage-bridge.sh` to `~/.claude/hooks/`, `chmod +x` them, and merge `settings.json.example` into `~/.claude/settings.json`. Already have a status line you like? Keep it — just add the bridge block (the ~8 lines under `--- bridge ---` in the script) to the top of your own script. To scope the guard to one project instead of user-level, put the `hooks` block in that project's `.claude/settings.json` with adjusted paths.

**Requirements:** `bash`, `jq`. That's it on Claude Code ≥ 2.1.80. On older versions also calibrate the fallback (below); Node/npx recommended there so the script can use [`ccusage`](https://github.com/ryoppippi/ccusage).

---

## Fallback calibration (only for Claude Code < 2.1.80 / no bridge)

Anthropic's real numbers aren't available to the estimate path, so it compares estimated tokens against a limit you provide:

1. Work until Claude Code shows a high 5-hour percentage in `/usage`.
2. Run `npx ccusage@latest blocks --active` and note the active block's total tokens.
3. If `/usage` said 80%, your limit ≈ `tokens / 0.80`. Set `CLAUDE_5H_TOKEN_LIMIT` to that, rounded down ~10% for safety.

---

## Configuration reference

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_5H_THRESHOLD` | `90` | Percentage at which to pause |
| `CLAUDE_5H_AUTORESUME` | `1` | `1` = schedule automatic `claude --continue` at reset; `0` = pause only, resume manually |
| `CLAUDE_5H_TOKEN_LIMIT` | `0` (off) | Estimated tokens per 5-hour block — only used by the fallback path |
| `CLAUDE_5H_CHECKPOINT_HINT` | auto | Overrides the "how to save state before stopping" instruction. Default: uses the AGENTS.md Session Protocol wording if the project has one, otherwise generic "save your work" wording |
| `CLAUDE_5H_RESUME_HINT` | auto | Overrides the "how to pick back up" instruction given on auto-resume. Same auto-detection default as above |

Set these in `~/.claude/settings.json`'s `env` block (applies everywhere) or a project's own `.claude/settings.json` (applies to that project only) — e.g. to point the hint at your own task-tracking convention instead of AGENTS.md.

State, the resume lockfile, and the resume log live in `~/.claude/usage-guard/` (`resume.log` shows what the auto-resumed run did).

---

## Honest caveats

- **The percentage is real** on Claude Code ≥ 2.1.80 with the bridge installed (same numbers as `/usage`). The bridge only refreshes while a Claude Code session is open, so the guard uses data up to 30 minutes old; the estimate fallback is approximate by nature.
- **Unofficial surfaces.** The `rate_limits` statusline field, hook schemas, and `ccusage` output can all change with Claude Code updates.
- **Auto-resume runs headless.** The resumed session executes with your default permission settings, without you watching. The cockpit protocol keeps it disciplined (checkpoints, verification, task gates that wait for your answer), but set `CLAUDE_5H_AUTORESUME=0` if you'd rather resume manually.
- **Auto-resume needs the machine awake.** The scheduled process is a background wait; a laptop that sleeps or reboots cancels it. Resume manually in that case (`claude --continue`).
- **Fails open by design.** Any measurement error disables the guard rather than blocking your session.
