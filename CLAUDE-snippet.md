# CLAUDE-snippet v2.0 — B2B Sales Proposal

Reference templates for the files this workflow creates automatically.

The skill creates these files for you when you run `/b2b-sales-proposal`. Use this file if you need to set up a project manually or understand the structure.

**What's new in v2.0:**
- **Context budgeting** — every task is split into chunks sized to finish within ~50% of a context window, with a checkpoint after each chunk
- **Task files** — each task gets its own `.md` with chunk plan, Definition of Done, and verification method, referenced from the PLAN
- **Results files** — deliverables live in separate `phaseN_results.md` files, never auto-loaded
- **Verification loop** — every task defines how it will be tested BEFORE work starts, runs the test after, and retries with lessons learned on failure
- **`LESSONS.md`** — append-only lessons from failed verifications, read at every task start
- **Usage-limit automation** — pauses work at ~90% of the limit, notifies you, and auto-resumes when it resets. Automated in Claude Code via `adapters/claude-code/`; behavioral rule in all other agents

Replace everything in [ ] with actual values.

---

## BLOCK 1a — AGENTS.md (project cockpit — primary file)

Used by: Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity, and 25+ other agents natively.

The cockpit is deliberately small: it tells the agent where you are, what to do next, and the rules of the game. Everything heavy lives in other files, loaded on demand.

```markdown
# [Provider] → [Client]

## Current Status
**Active task:** Phase 0 — Intake
**Active chunk:** — (set when the task is chunked)
**Last completed:** —
**Next action:** Run /b2b-sales-proposal to start Phase 0
**Blocked by:** — (none / waiting on seller / 5-hour usage limit — resumes at [time])

---

## Session Protocol

**On session start:**
Read AGENTS.md → read the status header of PLAN_[client].md → read ONLY the active task file (phaseN_name.md). Confirm state in one line before acting. Never auto-load prior task or results files — load them on demand only when a specific fact is needed.

**On task start — chunk before you work:**
1. Split the task into chunks sized so each chunk, including its file updates, completes within about 50% of a fresh context window. When unsure, cut smaller.
2. Create phaseN_name.md immediately (status 🔄 In Progress) containing: the chunk list as checkboxes, the Definition of Done, and the verification method (see Verification Protocol) — all BEFORE starting chunk 1.
3. Reference the task file and its subtasks in PLAN_[client].md.
4. Read LESSONS.md (it is short) and apply anything relevant to this task.

**On chunk / subtask complete:**
Tick the chunk in phaseN_name.md, append what was produced and where it lives, tick the matching subtask in PLAN_[client].md, refresh "Current Status" above.

**At ~50% of the context window used (checkpoint):**
Stop. Save phaseN_name.md with everything generated so far, status 🔄 In Progress.
Update "Current Status" with full detail: what completed, which file has the results, the literal next action.
Update PLAN_[client].md only if a task fully completed in this session.
Say: "Checkpoint saved — run /clear (or start a fresh session) and we continue with zero loss."

**On task complete:**
Run the Verification Protocol below. Only a PASS closes the task:
Deliverables saved in phaseN_results.md → phaseN_name.md set to ✅ Complete with verification evidence → PLAN_[client].md marked ✅ with both file names → "Current Status" moved to the next task.

**Task gate (always before advancing):**
Ask: "Verification passed — [one-line evidence]. Is this output sufficient to continue, or is there anything to adjust?"
Do not advance until confirmed.

---

## Verification Protocol

Every task is verified for QUALITY, not just completion.

1. **Before work:** write into the task file (a) the Definition of Done — specific, checkable criteria — and (b) the verification method — how the output will actually be tested.
2. **Unknown how to test?** Research it first (web search, docs, comparable examples), record the chosen method in the task file, then start work.
3. **After work:** RUN the verification — actually execute the checks against the output. Never self-declare success without running them.
4. **FAIL →** append the cause and the corrective rule to LESSONS.md, then redo the task applying those lessons. After 2 failed retries, stop and present the seller the failure analysis and options.
5. **PASS →** record the evidence (what was checked, the outcome) in the task file's Verification record, then close the task per the Session Protocol.

---

## Usage-Limit Rule

When you learn that ≥ ~90% of the usage limit is consumed — from the automation adapter's warning (Claude Code), your agent's own limit indicator, or the seller telling you:
- **Mid-task:** finish the current chunk only if it clearly fits; otherwise checkpoint immediately (same steps as the ~50% context checkpoint) and stop.
- **Between tasks:** do NOT start the next task. Checkpoint and stop.
- Set "Blocked by" in Current Status to: "5-hour usage limit — resumes automatically at [time]".
- **Always tell the seller in chat.** Your final reply before stopping must end with:
  "⏸️ Stopping — 5-hour usage limit at ~[X]%. Everything is checkpointed in [files]. Auto-resume at [time]."
- **On automatic resume**, your first reply must start with:
  "▶️ Resumed — 5-hour usage limit reset. Continuing [task] from [next action]."

If the agent's automation adapter is installed (Claude Code: `adapters/claude-code/` in the skill repo), detection, notifications, and the resume are automatic. In any other agent — or without the adapter — follow this rule manually and resume after the reset by opening the project and saying "continue".

---

## Key Decisions
- [record seller decisions here — pricing, format, constraints, tone rules]
- [these are not changed without explicit approval]

---

## File Index
| File | Content | When to load |
|---|---|---|
| `PLAN_[client].md` | Master plan: tasks, subtasks, verification status, strategy, pricing, history | Status header every session; full file on demand |
| `phaseN_name.md` | Per-task file: chunk plan, Definition of Done, verification method + evidence, work log | Active task only |
| `phaseN_results.md` | Per-task deliverables (emails, drafts, battlecards, pricing tables) | On demand |
| `LESSONS.md` | One-line lessons from failed verifications | At every task start |
| `PLAN.md` | Raw grill artifact (reference only) | On demand |
| `PLAN-REVIEW-LOG.md` | Codex review rounds log (reference only) | On demand |
| `DESIGN.md` | Provider visual system (if applicable) | Phase 3 only |
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

## Tasks

### Phase 0 — Intake ⬜
> Task file: `phase0_intake.md` · Results: `phase0_results.md`

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] Document location confirmed
- [ ] Document scan complete
- [ ] Block A: deal context
- [ ] Block B: business model and pricing calculated
- [ ] Block C: plan hardening (grill-me-codex / grill-me) + integration into this file
- [ ] Verification run — PASS recorded
- [ ] Gate: pricing confirmed by seller ✅

### Phase 1 — Intelligence ⬜
> Task file: `phase1_intelligence.md` · Results: `phase1_results.md`

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] account-research (or sales:account-research) — client profile
- [ ] competitive-intelligence-analyst — competitive landscape and exclusive advantage
- [ ] Verification run — PASS recorded
- [ ] Gate: client researched + main competitive angle identified ✅

### Phase 2 — Persuasion Strategy ⬜
> Task file: `phase2_strategy.md` · Results: `phase2_results.md`

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] influence-psychology — 7 principles applied to this client
- [ ] conversion-psychology — objections mapped and neutralized
- [ ] Verification run — PASS recorded
- [ ] Gate: clear strategy + anticipated objections ✅

### Phase 2.5 — Initial Outreach ⬜ / N/A
> Task file: `phase2.5_outreach.md` · Results: `phase2.5_results.md`
> Run only if no prior relationship with the client

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] draft-outreach (or sales:draft-outreach) — personalized prospecting email
- [ ] 14-day follow-up sequence
- [ ] Verification run — PASS recorded
- [ ] Gate: email sent, waiting for response ✅

### Phase 3 — Creation ⬜
> Task file: `phase3_proposal.md` · Results: `phase3_results.md`

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] proposal-writer — structure and draft
- [ ] Word document generated
- [ ] Seller review — manual edits recorded
- [ ] draft-outreach (or sales:draft-outreach), warm variant — delivery email
- [ ] Verification run — PASS recorded
- [ ] Gate: seller approved the proposal ✅

### Phase 4 — Close ⬜
> Task file: `phase4_close.md` · Results: `phase4_results.md`
> Run when client feedback is received or meeting is scheduled

- [ ] Chunk plan + Definition of Done + verification method written
- [ ] competitive-intelligence (or sales:competitive-intelligence) — interactive HTML battlecard
- [ ] negotiation — full negotiation playbook
- [ ] closing-deals — post-meeting close techniques
- [ ] Verification run — PASS recorded
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
| Date | What was done | Files updated | Verification |
|---|---|---|---|
| [date] | Phase 0 complete | phase0_intake.md ✅ phase0_results.md | PASS |
```

---

## BLOCK 3 — phaseN_name.md (task file)

Each task file is created at the **start** of the task, not when it finishes — with the chunk plan, Definition of Done, and verification method written BEFORE any work happens.

```markdown
# Phase N — [Name]
**Status:** 🔄 In Progress — completed: [chunk] | pending: [chunk]
**Last updated:** [date]
**Results file:** phaseN_results.md

---

## Spec

**Definition of Done:**
- [specific, checkable criterion 1]
- [specific, checkable criterion 2]

**Verification method:**
[How the output will actually be tested — commands to run, checklist to apply, review criteria.
If you don't know how to test this kind of output, research it first and record the chosen method here before starting work.]

**Lessons applied from LESSONS.md:**
- [relevant lesson, or "none apply"]

---

## Chunk plan (each chunk ≈ fits in ≤50% of a context window)
- [ ] Chunk 1 — [scope]
- [ ] Chunk 2 — [scope]

---

## Work log
| Date | Chunk | What was produced | Where it lives |
|---|---|---|---|
| [date] | 1 | [output summary] | phaseN_results.md § [section] |

---

## Verification record
**Run:** [date] — **Result:** PASS / FAIL
**Evidence:** [what was checked, how, and the outcome — never blank on a ✅ task]
**Retries:** [0 / 1 / 2] — lessons recorded in LESSONS.md: [yes / n/a]
```

When the task is complete, verification PASSED, and the gate confirmed, the header changes to:

```markdown
# Phase N — [Name]
**Status:** ✅ Complete — verification PASS ([date])
**Last updated:** [date]
**Results file:** phaseN_results.md
```

---

## BLOCK 4 — phaseN_results.md (results file)

The deliverables live here — separated from process so they stay clean, copy-ready, and are never auto-loaded.

```markdown
# Phase N — [Name] — Results
**Produced by:** phaseN_name.md
**Verification:** PASS ([date])

---

[the actual deliverables: emails, proposal drafts, battlecards, pricing tables, research summaries]
```

---

## BLOCK 5 — LESSONS.md (lessons learned)

Append-only. One line per lesson. Read at every task start — it must stay short enough to always be cheap to load.

```markdown
# Lessons Learned
<!-- Append-only. One line per lesson. Read at every task start. -->

| Date | Task | What failed | Rule going forward |
|---|---|---|---|
| [date] | Phase 3 | Proposal exceeded 8-page standing rule | Check standing rules against DoD before drafting |
```

---

## Update rules — summary

| Moment | phaseN_name.md | phaseN_results.md | PLAN_[client].md | AGENTS.md | LESSONS.md |
|---|---|---|---|---|---|
| Task starts | Create with 🔄 + spec + chunks | — | Reference task file | Update active task | Read |
| Chunk completes | Tick chunk + log | Append output | Tick subtask | Update last completed | — |
| ~50% context | Save with 🔄 | Save | Only if a task completed | Always | — |
| Verification FAIL | Record FAIL + retry | — | — | — | Append lesson |
| Task complete + PASS + gate | Change to ✅ + evidence | Finalize | Mark ✅ + record files | Update next task | — |
| ~90% of 5-hour limit | Save with 🔄 | Save | Only if a task completed | Always + "Blocked by" | — |

---

## Usage-limit automation (adapters)

The workflow's core (everything above) is generic — it runs in any AGENTS.md-reading agent. The pause-at-90% / auto-resume-at-reset *automation* is per-agent; the Claude Code adapter ships in `adapters/claude-code/`:

- `install.sh` — one-command installer (also run automatically by the repo's root `install.sh` and offered by the skill on activation)
- `statusline-usage-bridge.sh` — status-line script that saves the REAL rate-limit data Claude Code (≥ v2.1.80) passes to status lines, where the guard hooks can read it
- `usage-limit-guard.sh` — blocks new tool calls at the threshold (allowing checkpoint writes), notifies you in the terminal/chat/desktop, schedules the automatic resume at reset, and — via a `StopFailure` hook — schedules it even when the hard limit is hit mid-task
- `settings.json.example` + `HOOKS.md` — reference configuration, full setup, and honest caveats

Agents without an adapter (Codex, Cursor, …) follow the Usage-Limit Rule behaviorally and resume manually.

---

## Why this structure works

**AGENTS.md** is the cockpit — minimal, auto-loaded natively by 30+ agents at session start. Its only job is to tell the agent where you are, what to do next, and the rules (chunking, verification, limits). Claude Code uses it via the `@AGENTS.md` import in `CLAUDE.md`.

**PLAN_[client].md** is the master index — every task and subtask with its checkbox, verification status, strategy, pricing, history. The status header is read every session; the full file only on demand.

**phaseN_name.md** (task file) exists from the first moment work begins, with the chunk plan and the test written before the work. After any `/clear`, the agent loads only this file and knows exactly what was done, what comes next, and how the output will be judged.

**phaseN_results.md** keeps deliverables clean and out of the context window until actually needed.

**LESSONS.md** turns failed verifications into permanent rules, so quality compounds across tasks and across deals.

The net effect: context is spent on work, not on re-reading history — and nothing is lost at `/clear`, at the ~50% checkpoint, or at the 5-hour usage limit.
