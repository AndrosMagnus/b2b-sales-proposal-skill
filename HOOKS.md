# HOOKS.md — 5-hour usage-limit guard

Claude Code hooks that enforce the cockpit's **Usage-Limit Rule**: at ~90% of the 5-hour usage limit the agent stops starting new work, checkpoints everything (task file, PLAN, `AGENTS.md` Current Status), and an automatic resume fires the moment the limit resets. If the hard limit is ever hit mid-task anyway, a safety-net hook schedules the resume too — you never have to re-run anything manually.

**Claude Code only.** Other agents (Codex, Cursor, …) don't run these hooks — for them the Usage-Limit Rule in `AGENTS.md` is a behavioral instruction, and resume is manual.

---

## How it gets the usage number

Claude Code **v2.1.80+** passes real rate-limit data (`rate_limits.five_hour.used_percentage`, `resets_at`) to **status line** scripts — but not to hooks. So this setup uses the status line as a bridge:

1. **`statusline-usage-bridge.sh`** (status line, user-level) — saves the real numbers to `~/.claude/usage-guard/rate_limits.json` on every status-line refresh, and prints a normal status line (model · dir · 5h % · weekly %). If you already have a custom status line, copy just the "bridge" block into your own script.
2. **`usage-limit-guard.sh`** (hooks, per project) — reads that file for the real percentage and reset time. **No calibration needed.**

On older Claude Code versions (or if the bridge isn't installed), the guard falls back to an **estimate** (ccusage active block, else a sliding 5-hour window over local transcripts) — that path requires calibrating `CLAUDE_5H_TOKEN_LIMIT` (see below). With neither source available, the guard fails open (never blocks your session).

---

## What each hook does

| Hook event | Mode | Behavior |
|---|---|---|
| `SessionStart` | `report` | If usage is within 20 points of the threshold, injects "you are at ~X% of the 5-hour limit" into context so the agent sizes chunks accordingly |
| `PreToolUse` | `guard` | At ≥ threshold (default 90%), denies work tools with a message telling the agent to checkpoint and stop. `Write`/`Edit`/`Read`/`TodoWrite` stay allowed so the checkpoint files can still be saved |
| `Stop` | `schedule-resume` | At ≥ threshold, spawns a detached background process that waits until the block resets (+2 min margin), then runs `claude --continue -p "…continue from Current Status…"` in the project directory. One pending resume at a time, guaranteed by a lockfile |
| `StopFailure` (matcher `rate_limit`) | `resume-on-failure` | **Safety net:** fires when a run actually dies from hitting the limit mid-task. Schedules the same auto-resume — using the real reset time if known, otherwise retrying every 15 minutes (up to 6h) until a resume attempt gets through |

The result: normally the agent pauses *cleanly before the wall* — finishing the chunk if it fits, saving all state files — and continues by itself after the reset, headless, picking up from `AGENTS.md`. And even if the wall is hit abruptly, the `StopFailure` net still brings the session back automatically.

---

## You get told what happened

Whenever the guard pauses or resumes, it sends you a simple message — a desktop notification on macOS (`osascript`) or Linux (`notify-send`), and always a line in `~/.claude/usage-guard/notifications.log`:

```
Paused: 5-hour usage limit at ~93% (threshold 90%). Work is being checkpointed. Auto-resume at 16:36 CET.
Stopped: hit the 5-hour usage limit mid-task. Progress up to the last checkpoint is saved. Auto-resume at 18:06 CET.
Usage limit reset — Claude resumed automatically.
```

One notification per pause (guard, Stop, and StopFailure events are deduplicated per block). Times are shown in your local timezone. On systems without a desktop notifier (e.g. WSL without `notify-send`), you still get the log file. Test it with:

```bash
bash .claude/hooks/usage-limit-guard.sh notify "test"
```

---

## Install

**1. Status-line bridge (user-level — rate limits are account-wide):**

```bash
mkdir -p ~/.claude/hooks
cp hooks/statusline-usage-bridge.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/statusline-usage-bridge.sh
```

Add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/hooks/statusline-usage-bridge.sh" }
```

Already have a status line you like? Keep it — just add the bridge block (the ~8 lines under `--- bridge ---` in the script) to the top of your own script.

**2. Guard hooks (per deal project):**

```bash
mkdir -p .claude/hooks
cp hooks/usage-limit-guard.sh .claude/hooks/
chmod +x .claude/hooks/usage-limit-guard.sh
```

Merge the `hooks` and `env` blocks of `hooks/settings.json.example` into the project's `.claude/settings.json` (create it if missing; if you already have hooks, merge the arrays — don't overwrite).

**3. Requirements:** `bash`, `jq`. That's it on Claude Code ≥ 2.1.80. On older versions also calibrate the fallback (below); Node/npx recommended there so the script can use [`ccusage`](https://github.com/ryoppippi/ccusage).

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

State, the resume lockfile, and the resume log live in `~/.claude/usage-guard/` (`resume.log` shows what the auto-resumed run did).

---

## Honest caveats

- **The percentage is real** on Claude Code ≥ 2.1.80 with the bridge installed (same numbers as `/usage`). The bridge only refreshes while a Claude Code session is open, so the guard uses data up to 30 minutes old; the estimate fallback is approximate by nature.
- **Unofficial surfaces.** The `rate_limits` statusline field, hook schemas, and `ccusage` output can all change with Claude Code updates.
- **Auto-resume runs headless.** The resumed session executes with your default permission settings, without you watching. The cockpit protocol keeps it disciplined (checkpoints, verification, task gates that wait for your answer), but set `CLAUDE_5H_AUTORESUME=0` if you'd rather resume manually.
- **Auto-resume needs the machine awake.** The scheduled process is a background wait; a laptop that sleeps or reboots cancels it. Resume manually in that case (`claude --continue`).
- **Fails open by design.** Any measurement error disables the guard rather than blocking your session.
