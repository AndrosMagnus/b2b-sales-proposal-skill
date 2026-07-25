# B2B Sales Proposal

> A complete B2B sales proposal workflow skill for AI coding agents — from deal intake to signed contract.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/AndrosMagnus/b2b-sales-proposal-skill/releases)
[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-compatible-green.svg)](https://agentskills.dev)

---

## What it does

`/b2b-sales-proposal` runs a structured 5-phase workflow that turns a raw deal idea into a signed contract:

| Phase | What happens |
|---|---|
| **0 — Intake** | Scan deal documents, confirm pricing model, stress-test strategy with grill-me-codex |
| **1 — Intelligence** | Research the client and map the competitive landscape |
| **2 — Persuasion Strategy** | Apply influence principles and pre-neutralize objections |
| **2.5 — Initial Outreach** | *(only if no prior relationship)* Get the meeting before sending the proposal |
| **3 — Creation** | Write and generate the proposal Word doc + delivery email |
| **4 — Close** | Build a competitive battlecard, negotiation playbook, and close script |

Each phase saves its output to a dedicated file. State is fully preserved across sessions — you can stop, start a fresh session, and pick up exactly where you left off.

**v2.0 adds a full task-management layer:**
- **Context budgeting** — every task is chunked to fit ~50% of a context window, with a checkpoint at every chunk boundary
- **Task + results files** — each phase gets a task file (chunk plan, Definition of Done, verification method, work log) and a separate results file with the clean deliverables
- **Verification loop** — every task defines how its output will be tested *before* work starts, runs the test after, and on failure retries with lessons recorded in `LESSONS.md`
- **Usage-limit automation** — pauses work at ~90% of the usage limit, tells you why and when it restarts, and auto-resumes at reset. Automated in Claude Code via the [`adapters/claude-code/`](adapters/claude-code/HOOKS.md) adapter; behavioral rule in every other agent

The core workflow is **agent-generic**: everything lives in `AGENTS.md` + plain markdown files that Codex, Cursor, Copilot, Windsurf, Aider, and 30+ other agents read natively. Agent-specific automation ships as optional adapters in `adapters/` (currently: Claude Code).

---

## Install

**One-paste (recommended)** — installs the skill for every agent detected on your machine, and adds the Claude Code automation adapter automatically if Claude Code is present:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/AndrosMagnus/b2b-sales-proposal-skill/main/install.sh)"
```

**Skill only** (any agent; the skill offers the Claude Code adapter later on activation):

```bash
npx skills add https://github.com/AndrosMagnus/b2b-sales-proposal-skill --skill b2b-sales-proposal
```

---

## Usage

Open your agent in the deal's project folder and run:

```
/b2b-sales-proposal
```

On first run, a setup wizard collects your seller profile (name, company, business model, margin, transfer tax, output language). This is saved globally so you don't repeat it for every deal.

---

## Required skills

This workflow calls specialized sub-skills. They are checked automatically on activation — missing ones are flagged with install commands.

| Skill | Phase | Install |
|---|---|---|
| `grill-me-codex` | 0 | `npx skills add https://github.com/chaseai-yt/grill-me-codex --skill grill-me-codex` |
| `account-research` | 1 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill account-research` |
| `competitive-intelligence-analyst` | 1 | `npx skills add https://github.com/shipshitdev/library --skill competitive-intelligence-analyst` |
| `influence-psychology` | 2 | `npx skills add https://github.com/wondelai/skills --skill influence-psychology` |
| `conversion-psychology` | 2 | `npx skills add https://github.com/mike-coulbourn/claude-vibes --skill conversion-psychology` |
| `draft-outreach` | 2.5 + 3 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill draft-outreach` |
| `proposal-writer` | 3 | `npx skills add https://github.com/ncklrs/startup-os-skills --skill proposal-writer` |
| `competitive-intelligence` | 4 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill competitive-intelligence` |
| `negotiation` | 4 | `npx skills add https://github.com/wondelai/skills --skill negotiation` |
| `closing-deals` | 4 | `npx skills add https://skills.volces.com/skills/clawhub/jk-0001` |

> **No Codex?** `grill-me-codex` requires the Codex CLI. If you don't use Codex, the workflow falls back to `grill-me` (Act 1 only — the strategic interview, without the Codex review pass). Install: `npx skills add mattpocock/skills/grill-me`

---

## How state is preserved across sessions

The workflow creates two context files at the start of every deal:

**`AGENTS.md`** — the project cockpit. Read natively by 30+ agents (Codex, Cursor, GitHub Copilot, Windsurf, Aider, and others). Contains current phase, session protocol, key decisions, and the full file index.

**`CLAUDE.md`** — one line: `@AGENTS.md`. Claude Code auto-loads this at session start, importing the cockpit automatically.

**`PLAN_[client].md`** — the single operational source for the deal. After Phase 0, it contains every task and subtask with checkboxes and verification status, the full approved strategy, key decisions, risks, out-of-scope boundaries, pricing, and session history. This is the file to read first when resuming after any context reset.

**`phaseN_name.md` / `phaseN_results.md`** — per-task files: the task file holds the chunk plan, Definition of Done, verification method and evidence; the results file holds the clean deliverables and is never auto-loaded.

**`LESSONS.md`** — append-only lessons from failed verifications, read at every task start so quality compounds.

After any session reset (or `/clear`), the agent reads `AGENTS.md` → the PLAN status header → only the active task file, and has everything needed to continue without questions — context is spent on work, not on re-reading history.

---

## Multi-agent compatibility

This skill installs and runs in any Agent Skills-compatible agent without modification:

- **Claude Code** — uses `CLAUDE.md` → `@AGENTS.md`
- **Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity** — read `AGENTS.md` natively
- **Skills installation** — `npx skills add` handles the correct path (`~/.claude/skills/` or `~/.agents/skills/`) automatically per agent

---

## Supported business models

**Agency / Rep** — client pays the provider; provider pays you a commission. Transfer tax stays with the client.

**Reseller** — client pays you; you pay the provider. You absorb the transfer tax on the outbound wire. Auto-calculation:
```
final_price = (provider_cost × (1 + transfer_tax_%)) / (1 − margin_%)
```

Both models can coexist in your seller profile if you use different models per deal.

---

## Project files created per deal

| File | Content |
|---|---|
| `AGENTS.md` | Project cockpit — current status, session/verification/usage-limit protocols, file index |
| `CLAUDE.md` | Claude Code bridge — one line: `@AGENTS.md` |
| `PLAN_[client].md` | Single operational source: tasks + subtasks + verification status, strategy, decisions, risks, pricing, history |
| `LESSONS.md` | Append-only lessons learned from failed verifications |
| `PLAN.md` | Raw grill artifact (reference) |
| `PLAN-REVIEW-LOG.md` | Codex adversarial review log (reference) |
| `phase0_intake.md` + `phase0_results.md` | Documents read, deal summary, pricing table |
| `phase1_intelligence.md` + `phase1_results.md` | Client profile, competitive landscape, exclusive advantage |
| `phase2_strategy.md` + `phase2_results.md` | Influence principles applied, objection map |
| `phase2.5_outreach.md` + `phase2.5_results.md` | Prospecting email + 14-day follow-up sequence |
| `phase3_proposal.md` + `phase3_results.md` | Proposal draft, Word versions, delivery email |
| `phase4_close.md` + `phase4_results.md` | Battlecard, negotiation playbook, close techniques |
| `DESIGN.md` | Provider visual system, if used for Word generation |

Task files (`phaseN_name.md`) hold the process — chunk plan, Definition of Done, verification record. Results files (`phaseN_results.md`) hold the clean deliverables.

---

## Usage-limit automation (adapters)

The cockpit's Usage-Limit Rule is generic: at ~90% of the usage limit, checkpoint everything, announce the pause in chat, stop, and resume after reset. How much of that is *automated* depends on the agent:

**Claude Code — fully automated** via [`adapters/claude-code/`](adapters/claude-code/HOOKS.md), installed automatically by `install.sh` (or offered by the skill on activation). Uses **real usage data** (Claude Code ≥ v2.1.80 exposes `rate_limits` to status lines; a bridge script relays it to the hooks — no calibration needed):

- At ~90% the agent checkpoints all state files and stops cleanly (finishing the current chunk only if it fits); a background process resumes the session with `claude --continue` the moment the limit resets
- If the hard limit is ever hit mid-task anyway, a `StopFailure` hook schedules the same auto-resume — nothing has to be re-run manually
- You're told what happened and when it restarts — in the terminal, the chat, a desktop notification, and `~/.claude/usage-guard/notifications.log`

**Codex, Cursor, and other agents — behavioral**: they read the same rule in `AGENTS.md` and follow it (checkpoint + stop + announce), but they expose no hook system for automatic pause detection or resume — you say "continue" after the reset. Additional adapters can be added under `adapters/` as agents grow the needed surfaces.

---

## Credits

This workflow orchestrates the following skills — all credit goes to their creators:

| Skill | Author | Repository |
|---|---|---|
| `grill-me-codex` | chaseai-yt | [github.com/chaseai-yt/grill-me-codex](https://github.com/chaseai-yt/grill-me-codex) |
| `grill-me` *(fallback for grill-me-codex)* | Matt Pocock | [github.com/mattpocock/skills](https://github.com/mattpocock/skills) |
| `account-research` | Anthropic | [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| `competitive-intelligence-analyst` | shipshitdev | [github.com/shipshitdev/library](https://github.com/shipshitdev/library) |
| `influence-psychology` | wondelai | [github.com/wondelai/skills](https://github.com/wondelai/skills) |
| `conversion-psychology` | mike-coulbourn | [github.com/mike-coulbourn/claude-vibes](https://github.com/mike-coulbourn/claude-vibes) |
| `draft-outreach` | Anthropic | [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| `proposal-writer` | ncklrs | [github.com/ncklrs/startup-os-skills](https://github.com/ncklrs/startup-os-skills) |
| `competitive-intelligence` | Anthropic | [github.com/anthropics/knowledge-work-plugins](https://github.com/anthropics/knowledge-work-plugins) |
| `negotiation` | wondelai | [github.com/wondelai/skills](https://github.com/wondelai/skills) |
| `closing-deals` | clawhub | [skills.volces.com/skills/clawhub/jk-0001](https://skills.volces.com/skills/clawhub/jk-0001) |

---

## License

MIT — see [LICENSE](LICENSE) for details.
