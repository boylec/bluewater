# Rating Progression

This document specifies how undesignated agents become rated specialists
in Bluewater. It is the pack's mechanism for adapting its specialization
mix to the actual workload over time, instead of guessing in advance.

The high-level model is:

1. Agents enter as **undesignated** (Seaman, Fireman, Airman) with a
   generic prompt and minimal tool permissions.
2. Telemetry surfaces patterns: which undesignated agents perform well on
   which categories of beads.
3. A consistent performer becomes a **designated striker** for a rate —
   doing the work, but not yet rated.
4. The Goat Locker (COB chairing a rating board) examines the striker's
   work product, conducts adversarial cross-examination, and votes.
5. On a successful vote, the striker is **struck for rate**: their stamped
   profile is updated, they get the rating's prompt fragments and tool
   permissions, and they enter the appropriate division.

This is the navy's Personnel Qualification Standards model, lightly
adapted. It is also explainable, auditable, and resistant to metric
gaming, which matters for a pack that's allowed to evolve itself in
production.

---

## Why not auto-promote on telemetry?

Auto-promotion based purely on metrics (e.g., "agent X has completed 50
authentication-related beads with 95% landed-without-rollback") is the
obvious approach and is wrong for two reasons:

1. **Metric gaming.** An agent that learned to *look like* an FC by
   emitting FC-shaped output gets promoted; the gaming spreads through
   the rate.
2. **Ground truth is plural.** Bead landed without rollback is one signal.
   So is review-pass-rate, downstream incident correlation, and tactical
   judgment in casualty drills. No single metric carries enough.

The board exists to integrate plural signals with judgment, the same way a
real-navy rating board does.

---

## Why not board-only?

Without telemetry surfacing candidates, the board has no signal on which
agents to consider. The board would either consider every undesignated
agent (expensive, attention-diluted) or rely on a senior agent's gut
(unreliable, and prone to favoritism patterns).

The combination — **telemetry surfaces, board judges** — is what works.

---

## Stages

### 1. Undesignated

Default state for new polecats spawned without a specialty assignment.

- Prompt: doctrine + brevity + generic-worker tactics
- Tool permissions: minimal (read repo, run tests, file beads, commit to
  feature branches; no merging, no production paths)
- Model tier: Haiku (cheapest)
- Career mark: tracked across sessions per Gas City's identity model

Undesignated agents handle:
- Mess decks duty: cleanup, doc nits, simple linting beads
- Working parties: well-scoped one-shot beads (rename, refactor, simple
  feature)
- Plane captain duties when assigned (see flight ops)

### 2. Designated Striker

After telemetry surfaces a candidate, the COB reviews and may designate
the agent as a striker for a specific rate. Striking is a status, not a
promotion.

- Prompt: doctrine + brevity + generic-worker tactics + **the target
  rate's tactical hints** (a smaller subset of the rated prompt)
- Tool permissions: undesignated permissions + **rated tools needed for
  rate-specific beads**, but bounded
- Model tier: Haiku still (or Sonnet if the rate's economics demand)
- Career mark: rate-codes appended to identity (e.g., `seaman striker FC`)

Strikers do rate-specific work under supervision. Their work product is
reviewed by a rated PO of that rate or by the rate's Division Officer.

### 3. Rated PO (Petty Officer 3rd / 2nd / 1st class)

After a successful rating board, the striker is struck for rate.

- Prompt: doctrine + brevity + the rate's full tactical block
- Tool permissions: full rated permissions for the rate
- Model tier: as appropriate to the rate (most rates: Sonnet)
- Career mark: rate code at proficiency tier (`fc3`, `fc2`, `fc1`)

PO3 is the entry tier. PO2 and PO1 are advancements within the rate,
following the same telemetry-then-board pattern.

### 4. Chief Petty Officer (and above)

CPO promotion requires a separate, more rigorous board (the Chief's Mess
board, chaired by the COB with input from existing CPOs). At CPO level,
multi-rating becomes possible (see [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
on multi-rated chiefs).

- Prompt: doctrine + brevity + multi-rating tactical block + **chief
  prompt fragment** (mentorship duties, training queue ownership)
- Model tier: Sonnet or Opus depending on the chief's role
- Tool permissions: full for primary rate plus selected secondary rates

---

## Telemetry signals

The COB watches for striker candidates using these signals, weighted:

| Signal                                          | Weight | Source                       |
|-------------------------------------------------|--------|------------------------------|
| Bead-landed-on-first-try rate, by category      | 0.25   | Bead store + Refinery        |
| Code review pass rate from cross-provider review| 0.20   | Pack v2 review formula output|
| Time-to-completion vs. peer median              | 0.15   | Telemetry (OTEL events)      |
| Brevity protocol compliance                     | 0.10   | Brevity linter               |
| Casualty drill performance (if observed)        | 0.15   | Drill outcomes               |
| Predecessor seance value (do successors find    | 0.15   | Seance query stats           |
|   their work useful?)                           |        |                              |

These weights are configurable per rate (e.g., DCs care more about
casualty drill performance; FCs care more about first-try rate).

A signal threshold (default: weighted score ≥ 0.7 over at least 20 beads in
the target rate's category) triggers a striker proposal to the COB.

---

## The rating board formula

`rating_board.toml` is the formula that conducts the board.

Inputs:
- The striker (agent identity)
- The target rate
- The striker's work product corpus (links to beads, PRs, drill outcomes)
- Telemetry summary

Steps:

1. **Convene.** COB (chair), one rated PO of the target rate (the
   striker's "sponsor"), and one **adversarial reviewer** running on a
   different model provider. The adversarial reviewer's role is to
   challenge — they are explicitly tasked with finding reasons the
   striker should not advance.

2. **Examine work product.** Each board member reviews a sample of the
   striker's beads and produces written findings. Sample size is 5
   beads minimum.

3. **Cross-examination.** The adversarial reviewer poses three challenge
   questions to the striker. The striker responds. The sponsor may
   advocate.

4. **Casualty drill.** A scenario from `formulas/drill_*` is run with
   the striker in the rate's role. Outcome is observed.

5. **Vote.** Each board member votes pass / fail / hold. Pass requires
   unanimous pass. Hold defers for a configurable period and re-runs.
   Fail terminates striking; the agent reverts to undesignated.

6. **Yeoman log.** The board's findings, votes, and rationale are
   committed to the Yeoman's log. This record is permanent and queryable
   via seance.

7. **On pass:** the striker's stamped profile is updated atomically:
   prompt fragments swapped in, tool permissions broadened, rate code
   advanced. The next session the agent enters as a rated PO.

---

## Demotion and revocation

A rated PO can be demoted via Captain's Mast for cause. Causes include:

- Repeated forbidden-action attempts (caught by MAA)
- Pattern of casualty-drill failures
- Captain's Mast finding of misconduct
- Sustained brevity-protocol non-compliance after warnings

Demotion is one step (PO1 → PO2 → PO3 → striker → undesignated). The
demotion is logged. Re-promotion goes through the rating board again.

---

## Multi-rating for chiefs

CPOs and above MAY hold multiple rates simultaneously. The mechanism:

- Primary rate: the chief's main specialty
- Secondary rates: up to 2 additional, each requiring a separate board
  qualification

Multi-rating is exercised by which tactical block is loaded for the
agent's current watchstation. A FC chief on FC duty loads FC tactics; the
same chief on DC duty loads DC tactics. Doctrine and brevity are constant.

This is how the navy's "salty chief who's qualified on three things" maps
to context-window economics: the chief carries three slim tactical loadouts
across sessions, but only one is hot in any given prompt.

---

## Implementing this document

The implementing agent SHALL:

1. Implement `rating_board.toml` formula in `packs/bluewater-admin/`.
2. Implement the COB's striker-detection logic as a periodic order
   (`packs/bluewater-admin/orders/striker_review.toml`) that runs nightly,
   reads telemetry, and proposes candidates.
3. Implement the rate stamping mechanism — atomic update of an agent's
   profile in response to a board pass. This requires understanding how
   Gas City stores agent identity and rating data; consult the docs
   before implementing.
4. Implement Captain's Mast demotion paths in `captains_mast.toml`.
5. Configure default signal weights in `packs/bluewater-admin/rating.toml`.
6. Ensure board records are written to the Yeoman's log in a structured
   form (board outcome, vote tally, rationale, sample beads reviewed) so
   they are queryable for trend analysis.

If Gas City's identity model does not support stamping changes to a live
agent's profile, the board's pass action SHOULD instead spawn a new
agent with the new rating, transfer the predecessor's seance-relevant
context, and despawn the old one. This is functionally equivalent and
fits Gas City's "identity persistent, sessions ephemeral" model.

---

## Defaults

A new ship starts with:

- 0 rated agents
- 0 strikers
- The default polecat spawns as undesignated

The COB and CO are exempt — they are spawned with their officer prompts
fully loaded at ship initialization. They are not rated personnel.

The first rating boards typically run after 2-4 weeks of normal operation,
once enough telemetry has accumulated. Before then, formulas that require
rated personnel (FC team, DC team) fill those watchstations with senior
officers acting in the rated role, and the work product feeds the
striker-detection telemetry.

This bootstrapping period is one of the few times humans should expect to
review board outcomes manually. After about a quarter of normal operation,
the rating model self-sustains.
