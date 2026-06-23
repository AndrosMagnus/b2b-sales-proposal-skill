# B2B Sales Proposal

> A complete B2B sales proposal workflow skill for AI coding agents — from deal intake to signed contract.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/AndrosMagnus/b2b-sales-proposal-skill/releases)
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

---

## Install

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

**`PLAN_[client].md`** — the single operational source for the deal. After Phase 0, it contains the full approved strategy, key decisions, risks, out-of-scope boundaries, pricing, and session history. This is the file to read first when resuming after any context reset.

After any session reset, the agent reads `AGENTS.md` → `PLAN_[client].md` and has everything needed to continue without questions.

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
| `AGENTS.md` | Project cockpit — active phase, session protocol, file index |
| `CLAUDE.md` | Claude Code bridge — one line: `@AGENTS.md` |
| `PLAN_[client].md` | Single operational source: strategy, decisions, risks, pricing, history |
| `PLAN.md` | Raw grill artifact (reference) |
| `PLAN-REVIEW-LOG.md` | Codex adversarial review log (reference) |
| `phase0_intake.md` | Documents read, deal summary, pricing table |
| `phase1_intelligence.md` | Client profile, competitive landscape, exclusive advantage |
| `phase2_strategy.md` | Influence principles applied, objection map |
| `phase2.5_outreach.md` | Prospecting email + 14-day follow-up sequence |
| `phase3_proposal.md` | Proposal draft, Word versions, delivery email |
| `phase4_close.md` | Battlecard, negotiation playbook, close techniques |
| `DESIGN.md` | Provider visual system, if used for Word generation |

---

## License

MIT — see [LICENSE](LICENSE) for details.

Built on top of [grill-me](https://github.com/mattpocock/skills) by Matt Pocock (MIT).
