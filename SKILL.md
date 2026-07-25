---
name: b2b-sales-proposal
description: Complete B2B sales proposal workflow — 5 phases from deal intake to close. Use when starting a new B2B deal, preparing a client proposal, or managing a sales cycle. Covers document scanning, pricing calculation (agency or reseller models), intelligence research, persuasion strategy, proposal creation (Word doc + delivery email), and negotiation close. Invoke at the start of any new deal with /b2b-sales-proposal.
license: MIT
metadata:
  author: AndrosMagnus
  version: "2.0.0"
---

# B2B Sales Proposal

Complete B2B sales proposal workflow. Invoke with `/b2b-sales-proposal` at the start of any new deal.

---

## On activation

Run these checks in order before starting Phase 0:

1. **Seller profile** → load if exists, run setup wizard if missing
2. **Dependencies** → verify required skills are installed; install or guide if any are missing
3. **Project CLAUDE.md** → create or update cockpit structure if missing
4. **Usage-limit automation (Claude Code only, optional)** → if running in Claude Code and `~/.claude/hooks/usage-limit-guard.sh` is not present, offer once: "Optional: this workflow ships automation that pauses at ~90% of the 5-hour usage limit, notifies you, and auto-resumes at reset. Install it now? (yes/skip)" If yes, run `bash <skill folder>/adapters/claude-code/install.sh` (the installer is included in the installed skill folder; it backs up settings and is safe to re-run). In other agents, skip silently — the Usage-Limit Rule in AGENTS.md covers them behaviorally. Do not block on this step.
5. Begin Phase 0

---

## SETUP WIZARD (first run only)

Run when `~/.claude/seller-profile.md` does not exist AND no seller profile block is found in the current project's CLAUDE.md.

Say: "Welcome to the B2B Sales Proposal workflow. I'll ask a few quick questions to configure your seller profile — takes about 2 minutes."

Ask all of the following in a single message:

**About you:**
1. Your full name and title
2. Your company name
3. What do you sell? (product or service — one line)
4. Who do you typically sell to? (industry, company size, buyer role)

**Business model:**
5. How do deals typically work for you?
   - **(A) Agency / Rep model** — client pays the provider directly; provider pays you a commission. What is your typical commission %?
   - **(B) Reseller model** — client pays you; you pay the provider. Is there an international wire transfer tax in your country? If yes, what %? What is your default target margin? (suggested: 35% of final price)
   - **(C) Both, depending on the deal** — model will be confirmed per deal in Phase 0

**Preferences:**
6. Preferred language for output documents (proposals, emails, battlecards)
7. Any standing rules to always apply? Examples: "never show per-unit pricing", "always include a tax disclaimer", "proposals must not exceed 8 pages". (Leave blank if none.)

**Profile storage:**
8. Where should I save this profile?
   - **(Global)** → `~/.claude/seller-profile.md` — available in all future Claude Code projects (recommended)
   - **(This project only)** → stored only in this project's CLAUDE.md

After collecting answers, show a summary table and ask: "Does this look right? (yes to save / tell me what to change)"

Once confirmed, save the profile with this structure:

```markdown
# Seller Profile

**Name:** [name]
**Title:** [title]
**Company:** [company]
**Product/Service:** [one-line description]
**Target Market:** [industry, size, buyer role]
**Business Model:** [Agency / Reseller / Both]
**Commission %:** [% or N/A]
**Transfer Tax %:** [% or 0%]
**Default Margin %:** [% or N/A]
**Output Language:** [language]
**Standing Rules:**
- [rule 1 — or "None"]
```

If global → write to `~/.claude/seller-profile.md`.
If project only → append a `## Seller Profile` section to the current project's CLAUDE.md.

---

## RETURNING USER CHECK

When a seller profile is found (either at `~/.claude/seller-profile.md` or in the current project's CLAUDE.md), load it and confirm in one line:

"Still at [Company] selling [Product/Service]? (yes / no to update)"

If no → re-run setup wizard.

---

## DEPENDENCY CHECK

Check which skills are installed. Run both commands — skills may be in either location:
```
ls ~/.claude/skills/
ls ~/.agents/skills/
```

For each skill missing from the list, run the install command shown below. Offer to run installs automatically: "Skill X is missing. Install now? (yes/skip)"

### All required skills with install commands

| Skill | Used in | Install command |
|---|---|---|
| `grill-me-codex` | Phase 0 — plan hardening | *See special flow below* |
| `competitive-intelligence-analyst` | Phase 1 | `npx skills add https://github.com/shipshitdev/library --skill competitive-intelligence-analyst` |
| `influence-psychology` | Phase 2 | `npx skills add https://github.com/wondelai/skills --skill influence-psychology` |
| `conversion-psychology` | Phase 2 | `npx skills add https://github.com/mike-coulbourn/claude-vibes --skill conversion-psychology` |
| `proposal-writer` | Phase 3 | `npx skills add https://github.com/ncklrs/startup-os-skills --skill proposal-writer` |
| `negotiation` | Phase 4 | `npx skills add https://github.com/wondelai/skills --skill negotiation` |
| `closing-deals` | Phase 4 | `npx skills add https://skills.volces.com/skills/clawhub/jk-0001` |
| `account-research` | Phase 1 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill account-research` |
| `draft-outreach` | Phase 2.5 + 3 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill draft-outreach` |
| `competitive-intelligence` | Phase 4 | `npx skills add https://github.com/anthropics/knowledge-work-plugins --skill competitive-intelligence` |

> **Note on knowledge-work-plugins naming:** `account-research`, `draft-outreach`, and `competitive-intelligence` may appear as `sales:account-research`, `sales:draft-outreach`, and `sales:competitive-intelligence` in environments with the Anthropic Cowork plugin active. Both names refer to the same skills — use whichever form your agent recognizes.

### `grill-me-codex` special flow

`grill-me-codex` is a two-act skill: Act 1 is a relentless strategic interview (Claude ↔ you), Act 2 sends the locked plan to Codex for adversarial review. It requires the Codex CLI.

If `grill-me-codex` is not installed:
1. Ask: "Do you use Codex (OpenAI's coding agent) alongside Claude Code?"
2. **If yes:**
   - Run `codex --version` to check if the Codex CLI is installed
   - If not installed: "Install the Codex CLI first (`npm install -g @openai/codex` or check the OpenAI Codex docs), then re-run this check."
   - If installed, run:
     ```
     npx skills add https://github.com/chaseai-yt/grill-me-codex --skill grill-me-codex
     ```
3. **If no (or Codex CLI unavailable):** install `grill-me` as fallback:
   ```
   npx skills add mattpocock/skills/grill-me
   ```
   `grill-me` runs Act 1 only (the strategic interview) without the Codex review pass. It is sufficient for most deals.

### Proceed when

All skills are installed or confirmed available. Then continue to project setup.

---

## PROJECT SETUP

Check if the current project directory has an `AGENTS.md` containing the proposal cockpit structure (look for a `## Current Status` section and `## Session Protocol` section from this workflow).

If the cockpit is missing, create these files:

**1. `AGENTS.md`** — the primary project cockpit. Readable by 30+ agents natively (Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity, and others). Replace [Provider] and [Client] with actual values once known from Phase 0 Block A, or leave as placeholders:

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
| `DESIGN.md` | Provider visual system (if applicable) | Phase 3 only |
```

**Also create `LESSONS.md`** (append-only lessons file, read at every task start):

```markdown
# Lessons Learned
<!-- Append-only. One line per lesson. Read at every task start. -->

| Date | Task | What failed | Rule going forward |
|---|---|---|---|
```

See `CLAUDE-snippet.md` in the skill repo for the full templates of the task file (`phaseN_name.md`) and results file (`phaseN_results.md`).

**2. `CLAUDE.md`** — one-liner for Claude Code users. Claude Code auto-loads this file at session start, which imports AGENTS.md:

```markdown
@AGENTS.md
```

If `CLAUDE.md` already exists in the project with other content, append `@AGENTS.md` at the top rather than replacing it.

---

## MULTI-AGENT COMPATIBILITY

The Agent Skills format is multi-agent by design. This skill installs and runs in any compatible agent — Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, Aider, Antigravity, and others — without modification.

**Context file strategy:**
- `AGENTS.md` is the project cockpit and is read natively by 30+ agents (Codex, Cursor, Copilot, Windsurf, Aider, Antigravity, etc.)
- `CLAUDE.md` contains `@AGENTS.md` so Claude Code auto-imports the same cockpit
- Single source of truth, zero duplication

**Skills installation path:**
- Claude Code installs skills in `~/.claude/skills/`
- Many other agents use `~/.agents/skills/`
- Install commands (`npx skills add`) handle the right path automatically for each agent

**Invoking sub-skills:** Throughout these instructions, "invoke `/skill-name`" uses slash-command syntax, which is common across most agents. In agents that use a different invocation syntax (e.g., `@skill-name` or a tool menu), use whatever that agent's equivalent is. The skill logic and output are identical regardless.

**Starting a new session:** When these instructions say "start a fresh session", that means whatever your agent uses to clear context and begin again — `/clear` in Claude Code, a new conversation window, or equivalent. The phase files and AGENTS.md always preserve full state, so nothing is lost.

---

## PHASE 0 — Intake, Documents & Pricing

Say: "Starting Phase 0 — Intake."

Create `phase0_intake.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant.

### Document location check

Before scanning anything, ask:

"Do you have existing documents for this deal — quotes, emails, meeting notes, conversation transcripts, provider pricing sheets, previous proposals? 

If yes, choose one:
- **Open this session in that folder** — close this and reopen Claude Code in the deal's folder, then re-run `/b2b-sales-proposal`
- **Copy the files here** — paste or drop the files into the current folder, then say 'ready'
- **Tell me the path** — share the full path and I'll read from there

If no documents yet, say 'no documents' and we'll start from questions."

Wait for the response before proceeding to Step 0.1.

---

### Step 0.1 — Document scan

Once documents are located:

1. List all available files (provider proposals, meeting transcripts, briefings, exported emails, previous versions, etc.)
2. Sort by modification date — if multiple versions of the same document exist, read the most recent
3. Read all relevant documents and extract: deal context, client, provider, pricing mentioned, pain points, prior commitments
4. Ask: "Are there documents in other locations I should read? (technical specs, use cases, provider docs elsewhere) — share the path or paste the content."
5. Read any additional documents provided

With that context, ask only the questions in Blocks A and B that the documents did not already answer. If a document already covers something, confirm it rather than asking from scratch.

---

### Block A — Deal context

Ask only what could not be extracted from documents:

1. Who is the provider / principal?
2. Who is the client? What do you already know — sector, size, key contacts?
3. Are there documents not yet available? (provider pricing sheets, previous proposals, meeting transcripts, briefings)
4. Is there a specific deadline or meeting driving the timeline?
5. What pain points do you already know about? Are there competitors in play?
6. **Relationship status with this client?**
   - **(a)** Prior meeting or conversation — established relationship
   - **(b)** Contact exists but haven't discussed this product or deal yet
   - **(c)** Cold prospect — no prior contact

The answer to #6 determines whether Phase 2.5 (initial outreach) runs or we go straight to Phase 3.

Once provider and client names are confirmed, update the `AGENTS.md` title from `[Provider] → [Client]` to the actual values.

---

### Block B — Business model & pricing

Confirm which model applies to this deal. If the seller profile says "Both", ask now.

---

**AGENCY MODEL**
Client pays the provider directly. Provider pays the seller a commission.
The seller does not absorb the transfer tax — the client pays it when remitting to the provider abroad.

Ask:
- What is the commission structure with this provider? (% of sale, flat fee, or other)
- Are the client-facing prices set by the provider, or does the seller have flexibility?

---

**RESELLER MODEL**
Client pays the seller. Seller pays the provider abroad.
Seller absorbs the transfer tax when remitting to the provider.

Ask:
- What does the provider charge you? (request document or numbers)
- Any additional costs beyond the provider? (local implementation, own overhead, etc.)
- What is your target margin for this deal? (default from seller profile: [default_margin_%] — confirm or adjust)

**Auto-calculation (reseller model):**
```
provider_cost  = what the provider charges
transfer_tax   = provider_cost × [transfer_tax_%]
other_costs    = (ask — may be 0)
total_cost     = provider_cost + transfer_tax + other_costs
target_margin  = margin % (default from seller profile)
final_price    = total_cost / (1 - target_margin)
seller_margin  = final_price - total_cost
```

Show a breakdown table before continuing. Confirm with seller.

If there are multiple packages or service tiers, calculate each separately.
Always present pricing as closed packages in the commercial document — never per-unit, per-hectare, per-user, or similar formulas.

---

### Block C — Plan hardening

Once context and pricing are confirmed, invoke `/grill-me-codex` (or `/grill-me` if that's what was installed) to stress-test the deal strategy before research begins.

Focus of the interrogation:
- Why is this client going to buy — what is the real pain being solved?
- What is the biggest risk of a "no"?
- What does the client need to believe for the price to feel reasonable?
- Are there internal alternatives or competitors that could block the deal?
- What is the strongest argument and the weakest in this proposal?
- Does the timing make sense — why now and not later?
- Who makes the final decision, and what does that specific person care about?

Once grill-me-codex (or grill-me) approves the plan, integrate the full content of `PLAN.md` into `PLAN_[client].md` — nothing omitted:

| Section in `PLAN.md` | Where it goes in `PLAN_[client].md` |
|---|---|
| Goal | Expands the **Objective** field |
| Approach | New section **"## Approved Strategy"** |
| Key decisions & tradeoffs | Populates **"## Key Decisions (locked)"** |
| Risks / open questions | New section **"## Risks and Open Questions"** |
| Out of scope | New section **"## Out of Scope"** |

`PLAN.md` remains as the raw grill artifact (reference). `PLAN_[client].md` is the single operational source from this point forward.

---

### Phase 0 output

Create these files:

**`PLAN_[client].md`** — master project index:

```markdown
# Plan: [Provider] → [Client]

**Objective:** [one line — what this proposal needs to achieve]
**Status:** Phase 0 ✅ | Phase 1 ⬜ | Phase 2 ⬜ | [Phase 2.5 ⬜] | Phase 3 ⬜ | Phase 4 ⬜
**Next step:** Phase 1 — Intelligence

## Tasks
| Task | Task file | Results file | Verification | Status |
|---|---|---|---|---|
| Phase 0 — Intake | phase0_intake.md | phase0_results.md | PASS | ✅ |
| Phase 1 — Intelligence | — | — | — | ⬜ |
| Phase 2 — Strategy | — | — | — | ⬜ |
| Phase 2.5 — Initial Outreach | — | — | — | ⬜ / N/A |
| Phase 3 — Creation | — | — | — | ⬜ |
| Phase 4 — Close | — | — | — | ⬜ |

(Expand each task with its subtask checkboxes as it starts — see the full PLAN template in CLAUDE-snippet.md. Tick subtasks the moment they complete.)

## Key Decisions (locked)
[seller decisions + grill-me-codex / grill-me output]

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

## Session history
| Date | What was done |
|---|---|
| [today] | Phase 0 complete |
```

**`phase0_intake.md`** — the task file: chunk plan, Definition of Done, verification method + record, work log.

**`phase0_results.md`** — the deliverables: documents found and read, deal summary, business model, calculated pricing table, known pain points, client relationship status.

**Run the Phase 0 verification** before closing. Suggested checks:
- Recompute the pricing independently from the raw inputs — result must match the presented table exactly
- Every Block A and Block B question is answered or explicitly marked N/A
- The grill output is fully integrated into PLAN_[client].md (Approved Strategy, Key Decisions, Risks, Out of Scope populated — no placeholders left)

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → mark `phase0_intake.md` ✅ Complete with evidence, update PLAN and AGENTS.md: Phase 0 ✅, active task Phase 1.

**Phase 0 gate:** "Verification passed — [evidence]. Is the deal context clear and the pricing confirmed? Ready to move to Phase 1?"

---

## PHASE 1 — Intelligence

Say: "Starting Phase 1 — Intelligence."

Create `phase1_intelligence.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant.

Invoke in sequence:

1. Invoke `/account-research` (or `/sales:account-research` if using the Cowork plugin) — research the client: who they are, estimated revenue, org structure, current initiatives, digital footprint, recent projects, decision-making patterns. Update `phase1_intelligence.md` when complete.

2. Invoke `/competitive-intelligence-analyst` — map the provider's competitive landscape in this market: who else could offer the client the same thing, what is the exclusive advantage that no one else can replicate. This analysis feeds directly into the proposal's central argument. Update `phase1_intelligence.md` when complete.

**Run the Phase 1 verification** before closing. Suggested checks:
- Every factual claim about the client has a source (URL or document) recorded next to it
- The "exclusive advantage" is genuinely exclusive: name each competitor from the landscape and state why they cannot replicate it
- No generic filler — every finding is specific to this client and this deal

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → save deliverables to `phase1_results.md`, mark `phase1_intelligence.md` ✅ Complete with evidence, update AGENTS.md and PLAN: Phase 1 ✅ + file names.

**Phase 1 gate:** "Verification passed — [evidence]. Is the client profile solid and the main competitive angle clear? Ready for Phase 2?"

---

## PHASE 2 — Persuasion Strategy

Say: "Starting Phase 2 — Persuasion Strategy."

Create `phase2_strategy.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant.

Invoke in sequence:

1. Invoke `/influence-psychology` — apply the 7 principles of influence to the client profile from Phase 1. What framing maximizes the probability of yes? Which principles are most relevant given this client? Update `phase2_strategy.md` when complete.

2. Invoke `/conversion-psychology` — map the likely objections (price, timing, ROI, internal alternatives, status quo) and design how to neutralize each in the document before they surface. Update `phase2_strategy.md` when complete.

**Run the Phase 2 verification** before closing. Suggested checks:
- Each influence principle cites a concrete Phase 1 fact it leverages — no generic psychology advice
- Every likely objection (price, timing, ROI, internal alternatives, status quo) has a specific neutralization AND a note on where it will land in the proposal
- The strategy is consistent with the locked Key Decisions in PLAN_[client].md

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → save deliverables to `phase2_results.md`, mark `phase2_strategy.md` ✅ Complete with evidence, update AGENTS.md and PLAN: Phase 2 ✅.

**Phase 2 gate:** "Verification passed — [evidence]. Is the persuasion strategy clear and objections mapped? Ready to continue?"

---

## PHASE 2.5 — Initial Outreach *(only if no prior relationship)*

**Run only if Phase 0 Block A identified relationship status (b) or (c).**
If relationship is established (status a) → skip directly to Phase 3.

Say: "Starting Phase 2.5 — Initial Outreach."

Create `phase2.5_outreach.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant.

Invoke `/draft-outreach` (or `/sales:draft-outreach` if using the Cowork plugin) with Phase 1 and Phase 2 context:
- Phase 1 intelligence provides the personalized hook (recent news, market trigger, competitor move, specific initiative)
- Phase 2 strategy informs the framing and angle of the message
- The email must be short, with a low-commitment CTA ("15 minutes to explore if this is relevant?")
- Include a follow-up sequence for the next 14 days if no response is received

Output: prospecting email + follow-up sequence. Save in `phase2.5_results.md`, log the process in `phase2.5_outreach.md`.

**Run the Phase 2.5 verification** before closing. Suggested checks:
- Email is short (aim under ~150 words), plain text, one low-commitment CTA
- The hook references a verifiable, client-specific fact from Phase 1 — not a generic opener
- Follow-up sequence covers 14 days with coherent spacing and escalating angles, no repeated message

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → mark `phase2.5_outreach.md` ✅ Complete with evidence, update AGENTS.md and PLAN: Phase 2.5 ✅.

**After securing the meeting:** collect feedback and any new information from the call before continuing to Phase 3.

**Phase 2.5 gate:** "Verification passed — [evidence]. Was the meeting secured? Any new information from the call to factor into the proposal?"

---

## PHASE 3 — Creation

Say: "Starting Phase 3 — Creation."

Create `phase3_proposal.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant. (Phase 3 is usually the largest task — chunk it so drafting, Word generation, and the delivery email each fit comfortably within ~50% of a context window.)

**Step 3.1 — Draft the proposal:**

Invoke `/proposal-writer` using as input:
- Prioritized pain points from Phase 0 (open from the client's pain, not from the product)
- Intelligence from Phase 1 (real client and market data)
- Persuasion strategy from Phase 2 (framing, anticipated objections already neutralized)
- Pricing from Phase 0 (presented as closed packages)
- If `DESIGN.md` exists in the project, use it as the visual system reference
- Output language: [output_language from seller profile]
- All standing rules from seller profile

Update `phase3_proposal.md` when complete.

**Step 3.2 — Generate Word document:**

Generate the Word document using the `docx` skill if installed (`/docx`), or python-docx as fallback. If no visual system is defined in DESIGN.md, ask the seller if they want one before generating.

**Step 3.3 — Delivery email:**

Invoke `/draft-outreach` (or `/sales:draft-outreach` if using the Cowork plugin), warm outreach variant — the email that accompanies the proposal when sending it to the client:
- Use the "Have Met / Mutual Connection" template
- Reference the prior conversation or how the relationship started
- Highlight two or three points from the proposal most relevant to this specific client
- Clear CTA to review the document together
- Plain text only — no markdown, no HTML, no bullet points

Save the proposal draft, delivery email, and Word version history in `phase3_results.md`; record process and seller's manual edits in `phase3_proposal.md`.

> **Optional:** Invoke `/create-an-asset` (or `/sales:create-an-asset`) if the deal requires an additional visual asset (personalized landing page, HTML one-pager, workflow demo). Not part of the standard flow — only if the seller decides it adds value for this specific deal.

**Run the Phase 3 verification** before closing. Suggested checks:
- Open the generated Word document and confirm it renders without errors (if you don't know how to inspect a .docx programmatically, research it first — e.g. python-docx — and record the method)
- Pricing in the document matches the PLAN_[client].md pricing table exactly — closed packages only, no per-unit formulas anywhere
- Document language is [output_language] throughout; every standing rule from the seller profile passes; no template placeholders remain
- Each mapped objection from Phase 2 is actually neutralized somewhere in the document

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → mark `phase3_proposal.md` ✅ Complete with evidence, update AGENTS.md and PLAN: Phase 3 ✅.

**Phase 3 gate:** "Verification passed — [evidence]. Is the proposal approved and ready to send?"

---

## PHASE 4 — Close

Run only when client feedback is received or a meeting is scheduled.

Say: "Starting Phase 4 — Close."

Create `phase4_close.md` immediately with status 🔄 In Progress and its Spec — chunk plan, Definition of Done, verification method — per the Session Protocol. Read LESSONS.md and apply anything relevant.

Invoke in sequence:

1. Invoke `/competitive-intelligence` (or `/sales:competitive-intelligence` if using the Cowork plugin) — generates an interactive HTML battlecard per competitor: talk tracks, landmine questions to expose their weaknesses, specific objection handling. The tactical artifact to use before and during the meeting. Update `phase4_close.md` when complete.

2. Invoke `/negotiation` — build the negotiation playbook using the battlecard as input: accusation audit, calibrated questions, black swans, "That's right" script, Ackerman pricing ladder. Calibrated questions are adjusted to the specific competitors in play. Update `phase4_close.md` when complete.

3. Invoke `/closing-deals` — post-meeting close techniques based on the feedback received from this specific client. Update `phase4_close.md` when complete.

**Run the Phase 4 verification** before closing. Suggested checks:
- Open the HTML battlecard in a browser (or render-check it) — it loads, and covers every competitor identified in Phase 1
- Negotiation playbook numbers (Ackerman ladder, anchors) are derived from the actual final price in PLAN_[client].md
- Close techniques reference the actual feedback captured from this client, not generic scripts

FAIL → record the lesson in LESSONS.md and redo per the Verification Protocol. PASS → save deliverables to `phase4_results.md`, mark `phase4_close.md` ✅ Complete with evidence, update AGENTS.md and PLAN: Phase 4 ✅.

**Phase 4 gate:** "Verification passed — [evidence]. Meeting done. Anything else to close the deal?"

---

## Context rules (all phases)

- **Chunk first:** at every task start, split the work into chunks that each finish within ~50% of a fresh context window. Checkpoint (save all state files) at each chunk boundary and whenever context passes ~50% — then invite the seller to `/clear` and continue.
- **Verify always:** no task closes without running its verification method and recording PASS evidence. FAIL → LESSONS.md → redo with lessons applied (max 2 retries, then escalate to the seller).
- End each phase → save phaseN_name.md + phaseN_results.md → update PLAN → update AGENTS.md → then continue. Never skip the save.
- On resuming after starting a new session: read `AGENTS.md`, the status header of `PLAN_[client].md`, then ONLY the active task file. Do not auto-load all files.
- If context from a prior phase is needed, load it on demand — not preemptively.
- **Usage limit:** at ~90% (adapter warning, agent indicator, or seller notice), don't start new tasks; finish the current chunk only if it clearly fits, checkpoint, set "Blocked by" in AGENTS.md, announce the pause in chat, and stop. Auto-resume is handled by the Claude Code adapter (adapters/claude-code/) where installed; elsewhere resume manually after reset.
- Pricing in the commercial document: always closed packages. Never per-unit, per-hectare, per-user, or similar formulas.
- Document language and tone: use [output_language from seller profile].
- Apply [standing_rules from seller profile] to all output documents.
- The seller's decisions are final. Record in "Key Decisions" in PLAN. Not revisited without explicit approval.

---

## Standard file naming

| File | Content |
|---|---|
| `PLAN_[client].md` | Single operational source: phases, approved strategy, key decisions, risks, out of scope, pricing, session history |
| `PLAN.md` | Raw grill artifact — Goal, Approach, Key decisions, Risks, Out of scope (reference only) |
| `PLAN-REVIEW-LOG.md` | Codex adversarial review rounds log (reference only) |
| `LESSONS.md` | Append-only lessons from failed verifications — read at every task start |
| `phaseN_name.md` | Task files: chunk plan, Definition of Done, verification method + record, work log |
| `phaseN_results.md` | Results files: the actual deliverables per task |
| `phase0_intake.md` / `phase0_results.md` | Documents read, deal context, business model, pricing table |
| `phase1_intelligence.md` / `phase1_results.md` | Client profile, competitors, exclusive advantage |
| `phase2_strategy.md` / `phase2_results.md` | Influence principles, objection map |
| `phase2.5_outreach.md` / `phase2.5_results.md` | Prospecting email + follow-up sequence (if applicable) |
| `phase3_proposal.md` / `phase3_results.md` | Proposal draft, Word version history, delivery email |
| `phase4_close.md` / `phase4_results.md` | Competitive battlecard, negotiation playbook, close techniques |
| `DESIGN.md` | Provider visual system (if applicable) |
