# CLAUDE-snippet — B2B Sales Proposal

Reference templates for the files this workflow creates automatically.

The skill creates these files for you when you run `/b2b-sales-proposal`. Use this file if you need to set up a project manually or understand the structure.

Replace everything in [ ] with actual values.

---

## BLOCK 1a — AGENTS.md (project cockpit — primary file)

Used by: Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity, and 25+ other agents natively.

```markdown
# [Provider] → [Client]

## Current Status
**Active phase:** Phase 0 — Intake
**Last completed:** —
**Next action:** Run /b2b-sales-proposal to start Phase 0

---

## Session Protocol

**On session start:**
Read AGENTS.md → read only the active phase file → confirm state before acting.

**On phase start:**
Create phaseN_name.md immediately with status 🔄 In Progress. Do not wait for the phase to complete.

**On completing a subtask within a phase:**
Update phaseN_name.md with results and current status (what was done, what remains).
Update "Current Status" in AGENTS.md.

**When approaching the context limit (~50% used):**
Stop. Save phaseN_name.md with everything generated so far, status 🔄 In Progress.
Update "Current Status" with full detail: what completed, which file has the results, exactly what to do next.
Update PLAN_[client].md only if a phase fully completed in this session.
Say: "We're approaching the context limit. Files are updated — start a fresh session and we'll continue without losing anything."

**On completing a full phase (gate passed):**
Finalize phaseN_name.md → change status to ✅ Complete.
Update PLAN_[client].md → mark ✅ and record file name.
Update "Current Status" in AGENTS.md → next phase and next action.

**Phase gate (always before advancing):**
Ask: "Is this phase's output sufficient to continue, or is there anything to adjust?"
Do not advance until confirmed.

**Do not auto-load previous phase files.**
Only the active phase file. Prior phases: load on demand when needed.

---

## Key Decisions
- [record seller decisions here — pricing, format, constraints, tone rules]
- [these are not changed without explicit approval]

---

## File Index
| File | Content | Status |
|---|---|---|
| `PLAN_[client].md` | Single operational source: phases, strategy, decisions, risks, pricing, history | always available |
| `PLAN.md` | Raw grill artifact (reference only) | ⬜ |
| `PLAN-REVIEW-LOG.md` | Codex review rounds log (reference only) | ⬜ |
| `phase0_intake.md` | Documents read, deal context, pricing calculated | ⬜ |
| `phase1_intelligence.md` | Client profile, competitors, exclusive advantage | ⬜ |
| `phase2_strategy.md` | Influence principles, objection map | ⬜ |
| `phase2.5_outreach.md` | Prospecting email + follow-up sequence | ⬜ / N/A |
| `phase3_proposal.md` | Proposal draft, Word versions, delivery email | ⬜ |
| `phase4_close.md` | Competitive battlecard, negotiation playbook, close | ⬜ |
| `DESIGN.md` | Provider visual system (if applicable) | ⬜ / N/A |
```

---

## BLOCK 1b — CLAUDE.md (Claude Code bridge — one line only)

Claude Code auto-loads `CLAUDE.md` at session start. This single line imports `AGENTS.md` so Claude Code uses the same cockpit as every other agent.

```markdown
@AGENTS.md
```

If `CLAUDE.md` already exists with other content, add `@AGENTS.md` at the top.

---

## BLOCK 2 — PLAN_[client].md (master project index)

```markdown
# Plan: [Provider] → [Client]

**Objective:** [one line — expand with the full Goal from the grill after Phase 0 Block C]
**Status:** Phase 0 ⬜ | Phase 1 ⬜ | Phase 2 ⬜ | Phase 2.5 ⬜/N/A | Phase 3 ⬜ | Phase 4 ⬜
**Next step:** Phase 0 — Intake

---

## Phases

### Phase 0 — Intake ⬜
> Result: `phase0_intake.md`

- [ ] Document location confirmed
- [ ] Document scan complete
- [ ] Block A: deal context
- [ ] Block B: business model and pricing calculated
- [ ] Block C: plan hardening (grill-me-codex / grill-me) + integration into this file
- [ ] Gate: pricing confirmed ✅

### Phase 1 — Intelligence ⬜
> Result: `phase1_intelligence.md`

- [ ] account-research (or sales:account-research) — client profile
- [ ] competitive-intelligence-analyst — competitive landscape and exclusive advantage
- [ ] Gate: client researched + main competitive angle identified ✅

### Phase 2 — Persuasion Strategy ⬜
> Result: `phase2_strategy.md`

- [ ] influence-psychology — 7 principles applied to this client
- [ ] conversion-psychology — objections mapped and neutralized
- [ ] Gate: clear strategy + anticipated objections ✅

### Phase 2.5 — Initial Outreach ⬜ / N/A
> Result: `phase2.5_outreach.md`
> Run only if no prior relationship with the client

- [ ] draft-outreach (or sales:draft-outreach) — personalized prospecting email
- [ ] 14-day follow-up sequence
- [ ] Gate: email sent, waiting for response ✅

### Phase 3 — Creation ⬜
> Result: `phase3_proposal.md`

- [ ] proposal-writer — structure and draft
- [ ] Word document generated
- [ ] Seller review — manual edits recorded
- [ ] draft-outreach (or sales:draft-outreach), warm variant — delivery email
- [ ] Gate: seller approved the proposal ✅

### Phase 4 — Close ⬜
> Result: `phase4_close.md`
> Run when client feedback is received or meeting is scheduled

- [ ] competitive-intelligence (or sales:competitive-intelligence) — interactive HTML battlecard
- [ ] negotiation — full negotiation playbook
- [ ] closing-deals — post-meeting close techniques
- [ ] Gate: meeting done + feedback captured ✅

---

## Approved Strategy
[Populated in Phase 0 Block C — Approach from grill-me-codex / grill-me]

---

## Key Decisions (locked)
[Populated in Phase 0 Block C — Key decisions & tradeoffs from grill-me-codex / grill-me]
[Add any seller decisions made during the process here]

---

## Risks and Open Questions
[Populated in Phase 0 Block C — Risks / open questions from grill-me-codex / grill-me]

---

## Out of Scope
[Populated in Phase 0 Block C — Out of scope from grill-me-codex / grill-me]

---

## Pricing
| Item | Value |
|---|---|
| Model | [Agency / Reseller] |
| Provider cost | [currency + amount] |
| Transfer tax ([%]) | [amount / N/A] |
| Other costs | [amount / 0] |
| Total cost | [amount] |
| Target margin | [%] |
| **Final price** | **[amount]** |

[If multiple packages, one section per package]

---

## Reference Documents
[Key documents available: provider proposals, meeting transcripts, pricing sheets, etc.]

---

## Session History
| Date | What was done | Files updated |
|---|---|---|
| [date] | Phase 0 complete | phase0_intake.md ✅ |
```

---

## BLOCK 3 — phaseN_name.md structure

Each phase file is created at the **start** of the phase, not when it finishes.

```markdown
# Phase N — [Name]
**Status:** 🔄 In Progress — completed: [subtask] | pending: [subtask]
**Last updated:** [date]

---

[results of completed subtasks so far]
```

When the phase is complete and the gate passes, the header changes to:

```markdown
# Phase N — [Name]
**Status:** ✅ Complete
**Last updated:** [date]

---

[full results]
```

---

## Update rules — summary

| Moment | phaseN_name.md | PLAN_[client].md | CLAUDE.md |
|---|---|---|---|
| Phase starts | Create with 🔄 | — | Update active phase |
| Subtask completes | Update results + 🔄 | — | Update last completed |
| ~50% context | Save with 🔄 | Only if a phase completed | Always |
| Phase complete + gate | Change to ✅ | Mark ✅ + record file | Update next phase |

---

## Why this structure works

**AGENTS.md** is the cockpit — minimal, auto-loaded natively by 30+ agents at session start. Its only job is to tell the agent where you are and what to do next. Claude Code uses it via the `@AGENTS.md` import in `CLAUDE.md`.

**PLAN_[client].md** is the full log — phase detail, history, pricing. Loaded on demand when needed. Also the fallback for any agent that doesn't auto-load a context file: "Read PLAN_[client].md to see the current state of this deal."

**phaseN_name.md** exists from the first moment work on that phase begins. It always reflects the real state: in progress or complete. After starting any new session, the agent loads it and knows exactly what was done and what comes next — no questions needed.
