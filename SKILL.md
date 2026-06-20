---
name: b2b-sales-proposal
description: Complete B2B sales proposal workflow — 5 phases from deal intake to close. Use when starting a new B2B deal, preparing a client proposal, or managing a sales cycle. Covers document scanning, pricing calculation (agency or reseller models), intelligence research, persuasion strategy, proposal creation (Word doc + delivery email), and negotiation close. Invoke at the start of any new deal with /b2b-sales-proposal.
license: MIT
metadata:
  author: AndrosMagnus
  version: "1.0.0"
---

# B2B Sales Proposal

Complete B2B sales proposal workflow. Invoke with `/b2b-sales-proposal` at the start of any new deal.

---

## On activation

Run these checks in order before starting Phase 0:

1. **Seller profile** → load if exists, run setup wizard if missing
2. **Dependencies** → verify required skills are installed; install or guide if any are missing
3. **Project CLAUDE.md** → create or update cockpit structure if missing
4. Begin Phase 0

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

Check which skills are installed:
```
ls ~/.claude/skills/
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

Check if the current project directory has a CLAUDE.md containing the proposal cockpit structure (look for a `## Current Status` section and `## Session Protocol` section from this workflow).

If the cockpit is missing → create CLAUDE.md (or append to existing one) using this template. Replace [Provider] and [Client] with actual values once known from Phase 0 Block A, or leave as placeholders:

```markdown
# [Provider] → [Client]

## Current Status
**Active phase:** Phase 0 — Intake
**Last completed:** —
**Next action:** Run /b2b-sales-proposal to start Phase 0

---

## Session Protocol

**On session start:**
Read this CLAUDE.md → read only the active phase file → confirm state before acting.

**On phase start:**
Create phaseN_name.md immediately with status 🔄 In Progress. Do not wait for the phase to complete.

**On completing a subtask within a phase:**
Update phaseN_name.md with results and current status (what was done, what remains).
Update "Current Status" in this CLAUDE.md.

**At ~50% context:**
Stop. Save phaseN_name.md with everything generated so far, status 🔄 In Progress.
Update "Current Status" with full detail: what completed, which file has the results, exactly what to do next.
Update PLAN_[client].md only if a phase fully completed in this session.
Say: "We're at ~50% context. Files are updated. You can /clear and we'll continue without losing anything."

**On completing a full phase (gate passed):**
Finalize phaseN_name.md → change status to ✅ Complete.
Update PLAN_[client].md → mark ✅ and record file name.
Update "Current Status" in this CLAUDE.md → next phase and next action.

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
| `PLAN_[client].md` | Phase detail, session history, pricing | always available |
| `phase0_intake.md` | Documents read, deal context, pricing calculated | ⬜ |
| `phase1_intelligence.md` | Client profile, competitors, exclusive advantage | ⬜ |
| `phase2_strategy.md` | Influence principles, objection map | ⬜ |
| `phase2.5_outreach.md` | Prospecting email + follow-up sequence | ⬜ / N/A |
| `phase3_proposal.md` | Proposal draft, Word versions, delivery email | ⬜ |
| `phase4_close.md` | Competitive battlecard, negotiation playbook, close | ⬜ |
| `DESIGN.md` | Provider visual system (if applicable) | ⬜ / N/A |
```

---

## MULTI-AGENT COMPATIBILITY

The Agent Skills format is multi-agent by design. This skill installs and runs identically in Claude Code, Codex, Cursor, GitHub Copilot, Gemini CLI, Antigravity, and any other agent that supports the SKILL.md format — no special configuration needed.

**The only Claude Code-specific behavior** is CLAUDE.md auto-loading. Claude Code reads CLAUDE.md automatically at the start of every session, so it always knows the current deal state without being told.

**For all other agents:** start each session by telling your agent: "Read `PLAN_[client].md` to see the current state of this deal." The PLAN file is the agent-neutral source of truth. Everything else — the phase files, the workflow, the file conventions — works identically across all agents.

**Invoking sub-skills from other agents:** When these instructions say "invoke `/skill-name`", that is Claude Code slash-command syntax. In other agents, the equivalent is: "Use the [skill-name] skill" or "Follow the instructions in [skill-name]." The behavior is the same.

---

## PHASE 0 — Intake, Documents & Pricing

Say: "Starting Phase 0 — Intake."

Create `phase0_intake.md` immediately with status 🔄 In Progress.

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

The locked decisions from this step are added directly to `PLAN_[client].md` under "Key Decisions".

---

### Phase 0 output

Create two files:

**`PLAN_[client].md`** — master project index:

```markdown
# Plan: [Provider] → [Client]

**Objective:** [one line — what this proposal needs to achieve]
**Status:** Phase 0 ✅ | Phase 1 ⬜ | Phase 2 ⬜ | [Phase 2.5 ⬜] | Phase 3 ⬜ | Phase 4 ⬜
**Next step:** Phase 1 — Intelligence

## Phases and result files
| Phase | File | Status |
|---|---|---|
| Phase 0 — Intake | phase0_intake.md | ✅ |
| Phase 1 — Intelligence | — | ⬜ |
| Phase 2 — Strategy | — | ⬜ |
| Phase 2.5 — Initial Outreach | — | ⬜ / N/A |
| Phase 3 — Creation | — | ⬜ |
| Phase 4 — Close | — | ⬜ |

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

**`phase0_intake.md`** — include: documents found and read, deal summary, business model, calculated pricing table, known pain points, client relationship status.

Update CLAUDE.md: mark Phase 0 ✅, set active phase to Phase 1.
Mark `phase0_intake.md` as ✅ Complete and update PLAN before continuing.

**Phase 0 gate:** "Is the deal context clear and the pricing confirmed? Ready to move to Phase 1?"

---

## PHASE 1 — Intelligence

Say: "Starting Phase 1 — Intelligence."

Create `phase1_intelligence.md` immediately with status 🔄 In Progress.

Invoke in sequence:

1. Invoke `/account-research` (or `/sales:account-research` if using the Cowork plugin) — research the client: who they are, estimated revenue, org structure, current initiatives, digital footprint, recent projects, decision-making patterns. Update `phase1_intelligence.md` when complete.

2. Invoke `/competitive-intelligence-analyst` — map the provider's competitive landscape in this market: who else could offer the client the same thing, what is the exclusive advantage that no one else can replicate. This analysis feeds directly into the proposal's central argument. Update `phase1_intelligence.md` when complete.

Finalize `phase1_intelligence.md` as ✅ Complete.
Update CLAUDE.md and PLAN: Phase 1 ✅ + file name.

**Phase 1 gate:** "Is the client profile solid and the main competitive angle clear? Ready for Phase 2?"

---

## PHASE 2 — Persuasion Strategy

Say: "Starting Phase 2 — Persuasion Strategy."

Create `phase2_strategy.md` immediately with status 🔄 In Progress.

Invoke in sequence:

1. Invoke `/influence-psychology` — apply the 7 principles of influence to the client profile from Phase 1. What framing maximizes the probability of yes? Which principles are most relevant given this client? Update `phase2_strategy.md` when complete.

2. Invoke `/conversion-psychology` — map the likely objections (price, timing, ROI, internal alternatives, status quo) and design how to neutralize each in the document before they surface. Update `phase2_strategy.md` when complete.

Finalize `phase2_strategy.md` as ✅ Complete.
Update CLAUDE.md and PLAN: Phase 2 ✅.

**Phase 2 gate:** "Is the persuasion strategy clear and objections mapped? Ready to continue?"

---

## PHASE 2.5 — Initial Outreach *(only if no prior relationship)*

**Run only if Phase 0 Block A identified relationship status (b) or (c).**
If relationship is established (status a) → skip directly to Phase 3.

Say: "Starting Phase 2.5 — Initial Outreach."

Create `phase2.5_outreach.md` immediately with status 🔄 In Progress.

Invoke `/draft-outreach` (or `/sales:draft-outreach` if using the Cowork plugin) with Phase 1 and Phase 2 context:
- Phase 1 intelligence provides the personalized hook (recent news, market trigger, competitor move, specific initiative)
- Phase 2 strategy informs the framing and angle of the message
- The email must be short, with a low-commitment CTA ("15 minutes to explore if this is relevant?")
- Include a follow-up sequence for the next 14 days if no response is received

Output: prospecting email + follow-up sequence. Save in `phase2.5_outreach.md`.

**After securing the meeting:** collect feedback and any new information from the call before continuing to Phase 3.

Finalize `phase2.5_outreach.md` as ✅ Complete.
Update CLAUDE.md and PLAN: Phase 2.5 ✅.

**Phase 2.5 gate:** "Was the meeting secured? Any new information from the call to factor into the proposal?"

---

## PHASE 3 — Creation

Say: "Starting Phase 3 — Creation."

Create `phase3_proposal.md` immediately with status 🔄 In Progress.

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

Record all Word versions generated and any manual edits made by the seller in `phase3_proposal.md`.

> **Optional:** Invoke `/create-an-asset` (or `/sales:create-an-asset`) if the deal requires an additional visual asset (personalized landing page, HTML one-pager, workflow demo). Not part of the standard flow — only if the seller decides it adds value for this specific deal.

Finalize `phase3_proposal.md` as ✅ Complete.
Update CLAUDE.md and PLAN: Phase 3 ✅.

**Phase 3 gate:** "Is the proposal approved and ready to send?"

---

## PHASE 4 — Close

Run only when client feedback is received or a meeting is scheduled.

Say: "Starting Phase 4 — Close."

Create `phase4_close.md` immediately with status 🔄 In Progress.

Invoke in sequence:

1. Invoke `/competitive-intelligence` (or `/sales:competitive-intelligence` if using the Cowork plugin) — generates an interactive HTML battlecard per competitor: talk tracks, landmine questions to expose their weaknesses, specific objection handling. The tactical artifact to use before and during the meeting. Update `phase4_close.md` when complete.

2. Invoke `/negotiation` — build the negotiation playbook using the battlecard as input: accusation audit, calibrated questions, black swans, "That's right" script, Ackerman pricing ladder. Calibrated questions are adjusted to the specific competitors in play. Update `phase4_close.md` when complete.

3. Invoke `/closing-deals` — post-meeting close techniques based on the feedback received from this specific client. Update `phase4_close.md` when complete.

Finalize `phase4_close.md` as ✅ Complete.
Update CLAUDE.md and PLAN: Phase 4 ✅.

**Phase 4 gate:** "Meeting done. Anything else to close the deal?"

---

## Context rules (all phases)

- End each phase → save phaseN_name.md → update PLAN → update CLAUDE.md → then continue. Never skip the save.
- On resuming after `/clear`: read `PLAN_[client].md` first. Then read ONLY the active phase file. Do not auto-load all files.
- If context from a prior phase is needed, load it on demand — not preemptively.
- Pricing in the commercial document: always closed packages. Never per-unit, per-hectare, per-user, or similar formulas.
- Document language and tone: use [output_language from seller profile].
- Apply [standing_rules from seller profile] to all output documents.
- The seller's decisions are final. Record in "Key Decisions" in PLAN. Not revisited without explicit approval.

---

## Standard file naming

| File | Content |
|---|---|
| `PLAN_[client].md` | Master index, phase status, key decisions, session history, pricing |
| `phase0_intake.md` | Documents read, deal context, business model, pricing table |
| `phase1_intelligence.md` | Client profile, competitors, exclusive advantage |
| `phase2_strategy.md` | Influence principles, objection map |
| `phase2.5_outreach.md` | Prospecting email + follow-up sequence (if applicable) |
| `phase3_proposal.md` | Proposal draft, Word version history, delivery email |
| `phase4_close.md` | Competitive battlecard, negotiation playbook, close techniques |
| `DESIGN.md` | Provider visual system (if applicable) |
