# Bluewater Architecture

This document describes the design as a single coherent system. Implementers
should read this before diving into individual pack requirements; everything
that follows is consistent with the picture established here.

## Design goals, in priority order

1. **No single point of agent insanity.** The pack SHALL be able to lose any
   one agent — including the Captain — without losing the ship.
2. **Pre-composed, not improvised, response to incidents.** Anything that
   happens often enough to matter SHALL have a formula.
3. **Cheaper than `gastown` at equivalent throughput.** Despite a richer role
   set, total token spend per landed convoy SHALL NOT exceed the default
   pack's measured baseline. (See "Token Discipline" below.)
4. **Auditable.** Every command, decision, and rating change SHALL leave a
   trail readable by humans, by the Yeoman, and by Boards of Inquiry.
5. **Composable.** Departments SHALL be runnable standalone for small ships,
   and combinable for warships and carriers.

## Core architectural decisions

### Two orthogonal hierarchies

Every active agent simultaneously occupies a position in two structures:

- **Line organization** — chain of command. CO → XO → Department Head →
  Division Officer → CPO → PO → Seaman. This is who the agent takes orders
  from and reports to.
- **Rating** — durable specialty. FC, ET, DC, GM, STG, CT, SK, undesignated.
  This is what the agent is qualified to do.

Gas City currently fuses these (a "polecat" is both a position and a
specialty). Bluewater splits them. This split is the single most important
architectural move in the pack.

In practice:

- A **rating** is a stamped agent profile: prompt fragments, tool permissions,
  default model tier, skill priors. Stored in `ratings/<rate>.toml` per
  sub-pack.
- A **watchstation** is a slot in a formula or watch bill that requires an
  agent of a given rating to fill it. Formulas reference watchstations by
  name; the dispatcher binds an actual agent to the slot.
- An **agent instance** is a live session: identity + rating + current
  watchstation. Identity persists across sessions (per Gas City convention).
  Rating persists across sessions. Watchstation does not.

### Doctrine / Tactics / Orders — three-layer prompt hierarchy

Every active agent's prompt is assembled at session start from three layers:

| Layer    | Lifetime    | Source                              | Cache           |
|----------|-------------|-------------------------------------|------------------|
| Doctrine | Pack-level  | `doctrine/DOCTRINE.md` and shared   | Cached          |
| Tactics  | Formula-level | The current formula's tactical block | Cached per formula |
| Orders   | Per-invocation | The CO's intent + bead context     | Not cached       |

This separation is **load-bearing for cost**, not just for clarity. If the
doctrine layer is identical across thousands of agent invocations and is
front-loaded in every prompt, prompt caching amortizes its cost to near zero.
The default `gastown` pack does not exploit this, and pays for it on every
spawn.

Implementers SHALL ensure prompt assembly puts doctrine first, tactics second,
orders last, with explicit cache breakpoints if the runtime supports them.

### Command continuity (CO / XO / OOD)

At any moment, command authority belongs to exactly one agent. The chain is:

- **Captain (CO)** — strategic Mayor. Approves scope expansion, signs convoys
  in/out, sets intent. Does not execute. Runs on a slower/larger model
  (Opus-tier). Awakens for: scope change requests, convoy initiation,
  Captain's Mast, Board of Inquiry, two-key launches.
- **Executive Officer (XO)** — execution Mayor. Runs the Plan of the Day.
  Hot failover for CO. Faster/cheaper model (Sonnet-tier). The agent humans
  talk to most days.
- **Officer of the Deck (OOD)** — watch standing. Always exactly one OOD has
  the conn. Watches rotate (see [`doctrine/WATCH_BILL.md`](./doctrine/WATCH_BILL.md)).
  Formal watch turnover with passdown briefs is itself a formula.

If CO is unreachable or context-saturated, XO assumes command. If XO is
unreachable, the senior OOD assumes command. The transfer is logged by the
Yeoman in all cases.

### LLMs sleep until alarm condition

Watch standing in the navy is mostly nothing-happening. The pack mirrors this:
**lookouts, sonar, and most monitoring agents are deterministic processes
(cron + jq + grep + diff against baseline)**, not 24/7 LLM sessions. They
escalate to an LLM only on alarm.

This is the single biggest cost-control measure. Implementers who wire
lookouts as polling LLM sessions have failed the design.

The exceptions are:

- The OOD on the conn — must be a live session, but is throttled and
  context-disciplined.
- The XO during waking hours — live but mostly idle.
- Active polecats and gunner's mates working on assigned beads.

Everything else materializes on demand.

### Two-key launch with cross-provider concurrence

Any bead whose execution would touch production, modify configuration in
shared infrastructure, or expend more than a configured token threshold
SHALL require concurrence from two officers running on **different model
providers**. This is Mayor Approval Gates extended with a cross-provider
constraint.

Defense rationale: same-provider concurrence does not protect against
provider-wide blind spots (training-data biases, prompt-injection patterns
the provider's safety training has not covered). Cross-provider concurrence
does.

### The Battle Bill is a committed artifact

For every named casualty type and every named evolution, there is a row in
the Battle Bill specifying which watchstation is OIC and which support.
The Battle Bill is a TOML file in the umbrella pack at
`bluewater/battle_bill.toml`, version-controlled, never edited live.

Formulas SHALL read the Battle Bill at dispatch time and SHALL NOT hard-code
role assignments.

## Department layout

Departments are sub-packs. Each sub-pack contains:

- A `pack.toml` declaring its agents, formulas, and orders
- A `prompts/` directory with rating-specific prompt fragments
- A `ratings/` directory with rating definitions
- A `formulas/` directory with department-owned evolutions
- A `orders/` directory with department-owned event handlers
- A `REQUIREMENTS.md` describing what's in it

The umbrella `bluewater` pack composes departments, owns ship-wide formulas
(General Quarters, Liberty Call), owns the Battle Bill, and owns the line
organization (CO/XO/OOD agents).

```
bluewater/
├── pack.toml                           # umbrella pack manifest
├── battle_bill.toml                    # routing table
├── watch_bill.toml                     # watch rotation rules
├── prompts/
│   ├── doctrine.md                     # the cross-cutting doctrine layer
│   ├── brevity.md                      # the brevity protocol vocabulary
│   └── …
├── ratings/                            # umbrella-level ratings (officers)
│   ├── co.toml
│   ├── xo.toml
│   ├── ood.toml
│   └── cob.toml
├── formulas/
│   ├── general_quarters.toml
│   ├── liberty_call.toml
│   └── watch_turnover.toml
├── orders/
│   └── ci_failed_on_main.toml
├── packs/
│   ├── bluewater-ops/
│   ├── bluewater-cs/
│   ├── bluewater-eng/
│   ├── bluewater-supply/
│   ├── bluewater-air/
│   ├── bluewater-medical/
│   ├── bluewater-admin/
│   └── bluewater-discord/
├── examples/
│   └── small_ship.city.toml
└── docs/
    └── …
```

## Token discipline (the hard part)

Naive implementation of this pack would torch a Pro Max plan in seconds. The
cost story is the design's most fragile property. Six mechanisms together
make it cheaper than `gastown`, not more expensive.

### 1. Most rates are stamped definitions, not live sessions

Steady state running agents:

- 1 OOD on watch
- 1 XO awake during waking hours
- N polecats and gunner's mates currently working assigned beads
- Whatever specialists are mid-evolution

Total awake-and-billing live sessions in steady state SHOULD be ≤ 6 + N where
N is active polecats. CO, COB, dept heads, and most rates exist as profiles
that are spawned on demand and despawned on completion.

### 2. Deterministic monitoring under LLM escalation

Per "LLMs sleep until alarm" above. Lookouts, sonar, and most of the Admin
department are bash/jq/grep with LLM escalation on alarm conditions.

### 3. Aggressive model tiering

| Tier   | Roles                                                | Model      |
|--------|------------------------------------------------------|------------|
| Strategic | CO, COB, two-key reviewer of last resort            | Opus       |
| Tactical  | XO, Department Heads (CSO, CHENG, OPS), JAG         | Sonnet     |
| Operational | OOD, FC, ET, DC, MAA, rated POs                   | Sonnet     |
| Worker  | Gunner's mates, undesignated polecats, helmsman       | Haiku      |
| None    | Lookouts, sonar, deterministic checks                  | (no LLM)   |

Defaults SHALL be encoded in each sub-pack's REQUIREMENTS.md and overrideable
in `city.toml`.

### 4. Prompt caching via the Doctrine/Tactics/Orders split

Doctrine is large and stable. Cache it. Tactics is medium and stable per
formula. Cache it. Orders is small and per-invocation. Don't.

### 5. Brevity protocol

See [`doctrine/BREVITY.md`](./doctrine/BREVITY.md). Defined vocabulary
(`ROGER`, `WILCO`, `NEGAT`, `SAY AGAIN`, `BREAK BREAK`, `INTERROGATIVE`)
collapses agent-to-agent acknowledgments from paragraphs to tokens.

### 6. Async event escalation, not sync polling

OOD does not ask each lookout "anything?" every interval. Lookouts call OOD
on contact via the event bus. Gas City's order primitive is the event bus.

### Budget enforcement

The CHENG agent (in `bluewater-eng`) holds **technical authority** over
token burn rate the same way a real ship's Engineering Officer of the Watch
holds authority over the reactor. CHENG MAY refuse a Mayor order to spawn
more workers if the requested operation would breach the configured burn
rate, and only the CO can override (and the override is logged).

The SUPPO agent (in `bluewater-supply`) tracks per-provider credit
consumption and routes work to whichever provider has budget headroom.

## Anti-patterns this pack actively defends against

- **Council Anti-Pattern.** Every decision becomes a meeting, every agent
  weighs in. Defense: clear chain of command, single decision-maker per
  evolution, structured briefs only when called.
- **Mom Anti-Pattern.** An agent re-summarizes everything for everyone
  "just in case." Defense: the bead store is the summary; the Yeoman's log
  is the canonical narrative; nobody else re-summarizes.
- **Reading-Comprehension Anti-Pattern.** Every new watch reads the entire
  convoy history. Defense: watch turnover is a passdown brief written by the
  predecessor, not a transcript dump. Use seance for predecessor questions,
  not preemptive reading.
- **Yes-Man Anti-Pattern.** Verbose acknowledgments leak tokens. Defense:
  brevity protocol; silent ack is the default.

If you find yourself implementing one of these, stop, re-read this section,
and find the formula or doctrine page that prevents it.

## Telemetry

The pack SHALL emit (via Gas City's existing OTEL data model):

- Per-agent token cost, broken down by tier
- Per-formula run count, success rate, and token cost
- Per-rating utilization (how much wall time and how many tokens by rate)
- Watch turnover events with handoff quality scores (see WATCH_BILL.md)
- Two-key launch events with concurrence outcomes

These feed both the SUPPO agent's budget decisions and the COB's
striker-promotion decisions.

## Where this pack ends and Gas City begins

Bluewater is a pack. It contributes:

- Agent definitions
- Prompt templates
- Formulas (orchestrations)
- Orders (event triggers)
- A Battle Bill, Watch Bill, brevity protocol
- Doctrine documents

Bluewater does **not** contribute:

- Changes to Gas City's Go code
- New runtime providers
- New beads providers
- New CLI commands

If a feature in this spec appears to require a Gas City SDK change, the
implementing agent SHALL stop, file an issue against `gastownhall/gascity`,
and continue with the rest of the build, leaving that feature in
`status = "blocked"`.
