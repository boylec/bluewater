# Build Instructions for the Implementing Agent

You are a Claude agent tasked with building the Bluewater pack from this
specification. Read this document fully before doing anything else.

## What you are building

A Gas City pack repository that implements naval-doctrine multi-agent
orchestration. The repository contains an umbrella pack (`bluewater`) and
eight sub-packs (`bluewater-{ops,cs,eng,supply,air,medical,admin,discord}`),
plus shared doctrine documents and a formula catalog.

The output is a published GitHub repository under the `gastownhall`
organization (or a fork of it) named `bluewater`, structured to
be installable via `gc pack add` per Gas City Pack v2 conventions.

## RFC 2119 keywords

This specification uses **SHALL**, **SHOULD**, **MAY**, **MUST NOT**, and
**SHOULD NOT** with their standard RFC 2119 meanings. SHALL and MUST NOT are
binding. SHOULD and SHOULD NOT are strong defaults — deviate only with a
written justification recorded in the commit message. MAY is genuinely
optional.

## Order of operations

You SHALL execute the following steps in order:

### 1. Ground yourself in current Gas City reality

The exact pack.toml schema, formula schema, and order schema may have
evolved since this specification was written. Before generating any TOML or
running any `gc` command, you SHALL consult these sources of truth, in order:

1. The current `gastownhall/gascity` repository on GitHub
   - In particular: `internal/config/` (city.toml schema and pack composition)
   - In particular: `internal/runtime/` (runtime providers)
   - In particular: `internal/beads/` (work tracking)
2. The default pack at `examples/gastown/packs/gastown` in that repo —
   this is your reference implementation for how a Pack v2 pack is laid out
3. The `gastownhall/gascity-packs` repository, for examples of non-default
   packs and the Discord adapter pattern
4. The latest release notes (Gas City `>= 0.13.4`), specifically
   "Pack v2 review formulas," "Graph v2 runtime support," "explicit session
   naming," and "rig-aware mail provenance"
5. The docs site at `docs.gascityhall.com` (or wherever it lives at build time)

If any of those sources contradicts this specification on a matter of
**Gas City schema or syntax**, the source of truth wins. If any of them
contradicts this specification on a matter of **naval doctrine or pack
design**, this specification wins.

### 2. Read the specification top-down

Read in this order before writing anything:

1. [`README.md`](./README.md) — context
2. [`ARCHITECTURE.md`](./ARCHITECTURE.md) — the design as a whole
3. [`doctrine/GLOSSARY.md`](./doctrine/GLOSSARY.md) — terminology
4. [`doctrine/DOCTRINE.md`](./doctrine/DOCTRINE.md) — the doctrine layer
5. [`doctrine/BATTLE_BILL.md`](./doctrine/BATTLE_BILL.md) — incident → role routing
6. [`doctrine/WATCH_BILL.md`](./doctrine/WATCH_BILL.md) — watch rotation
7. [`doctrine/BREVITY.md`](./doctrine/BREVITY.md) — agent-to-agent comms
8. [`doctrine/RATING_PROGRESSION.md`](./doctrine/RATING_PROGRESSION.md) — striker → board → rated
9. [`packs/bluewater/REQUIREMENTS.md`](./packs/bluewater/REQUIREMENTS.md) — umbrella
10. Each `packs/bluewater-*/REQUIREMENTS.md` in any order
11. [`formulas/CATALOG.md`](./formulas/CATALOG.md) — every evolution
12. [`tests/ACCEPTANCE.md`](./tests/ACCEPTANCE.md) — how to know you're done

### 3. Bootstrap the repository

You SHALL:

- Create a fresh git repository for the pack output (do not modify the
  specification repository).
- Commit a `pack.toml` at the root for the umbrella pack `bluewater`,
  conformant to whatever Pack v2 schema is current.
- Create the directory tree per [`ARCHITECTURE.md`](./ARCHITECTURE.md).
- Add an MIT `LICENSE` and a user-facing `README.md` (separate from this
  specification's README).

### 4. Build doctrine first

The doctrine layer SHALL be built before any agent or formula. Doctrine is
the long-lived, prompt-cache-friendly base. Specifically:

- The contents of `doctrine/DOCTRINE.md` SHALL be turned into a file (e.g.
  `prompts/doctrine.md`) that every agent's prompt template includes by
  reference.
- The Battle Bill SHALL be turned into a structured data file (TOML or JSON)
  that formulas read at dispatch time. Formulas SHALL NOT hard-code role
  assignments that are already in the Battle Bill.
- The Brevity Protocol vocabulary SHALL be its own short prompt include
  applied to every agent that participates in agent-to-agent communication.

### 5. Build sub-packs in dependency order

Recommended build order, lowest dependency first:

1. `bluewater-eng` — needed for runtime/budget governance everywhere else
2. `bluewater-supply` — needed for provider routing
3. `bluewater-admin` — needed for Yeoman log, security gates
4. `bluewater-medical` — needed for agent health
5. `bluewater-ops` — situational awareness foundation
6. `bluewater-cs` — depends on ops (for targeting)
7. `bluewater-air` — depends on cs (lands what cs builds)
8. `bluewater-discord` — adapter, depends on the rest being functional
9. `bluewater` (umbrella) — composition only, last

### 6. Build formulas

Formulas SHALL be implemented after the agents they invoke exist.
[`formulas/CATALOG.md`](./formulas/CATALOG.md) gives the full set; treat
each as a discrete TOML file under `formulas/` in the appropriate sub-pack.

Mandatory formulas (every ship needs these):

- `watch_turnover` (in `bluewater-ops`)
- `plan_of_the_day` (in `bluewater-ops`)
- `general_quarters` (in `bluewater`, umbrella)
- `man_overboard` (in `bluewater-medical`)
- `sea_and_anchor_detail` (in `bluewater-air` if present, else `bluewater-cs`)
- `board_of_inquiry` (in `bluewater-admin`)
- `captains_mast` (in `bluewater-admin`)
- `liberty_call` (in `bluewater`, umbrella)
- `rating_board` (in `bluewater-admin`)

Optional formulas (carrier-class or specialty):

- `field_day` (in `bluewater-eng`)
- `unrep` (in `bluewater-supply`)
- `flight_ops` (in `bluewater-air`)
- `sigint_collection` (in `bluewater-ops`, CT division)

### 7. Wire orders

Orders are the event-triggered bridge between external events and formulas.
You SHALL implement at least:

- `pre_tool_use` order routing to MAA for security review
- `pr_opened` order routing to the code review formula
- `ci_failed_on_main` order triggering General Quarters
- `prod_alert` order triggering General Quarters at higher severity
- `convoy_landed` order triggering Yeoman log update + Captain's Mast
  consideration
- `agent_stalled` order triggering Man Overboard

### 8. Acceptance test before tagging

You SHALL run [`tests/ACCEPTANCE.md`](./tests/ACCEPTANCE.md) end to end on a
test rig before tagging a release. Specifically: a clean `gc init`, install
the pack, run the smoke-test convoy described there, verify all acceptance
criteria pass, and only then tag `v0.1.0`.

### 9. Publish

Push to `boylec/bluewater` (or a fork) on GitHub. Add a
release announcement to the pack README. File a PR against
`gastownhall/gascity-packs` referencing the new pack.

## Hard constraints

You SHALL NOT:

- Hard-code naval role names into Gas City's Go codebase. Bluewater is a pack;
  it adds no SDK primitives. (Gas City's "zero hardcoded roles" stance is
  exactly what makes this pack possible.)
- Use a single model provider for the full ship. The two-key launch
  requirement assumes at least two distinct providers are configured.
- Implement lookouts, sonar, or any other "watch" agent as a 24/7 polling
  LLM session. See [`doctrine/DOCTRINE.md`](./doctrine/DOCTRINE.md), section
  "LLMs sleep until alarm condition."
- Skip prompt caching. The doctrine layer exists in part to make caching
  effective; an implementation that re-ships the doctrine in every request
  forfeits the design's primary cost advantage.
- Skip the brevity protocol. Verbose agent-to-agent acknowledgments are a
  silent token leak.
- Allow any agent to send work to itself except via the documented
  handoff and seance mechanisms.

You SHOULD NOT:

- Add roles not specified here without a Board of Inquiry-equivalent design
  review (a recorded discussion in `doctrine/AMENDMENTS.md`).
- Run all agents on the highest model tier. See per-role tiering in each
  sub-pack's REQUIREMENTS.md. The default tier is **Sonnet**, not Opus.

## When you get stuck

If a requirement is ambiguous or contradicts something you find in current
Gas City: **prefer Gas City's reality over this spec's letter, but record
the deviation in the commit message and in `doctrine/AMENDMENTS.md`**.

If a requirement is missing entirely (e.g., this spec doesn't say what model
the Sailing Master should use): **make the choice that preserves the design's
intent**. Sailing Master is a senior specialist consulted rarely; default to
the same tier as Department Heads (Sonnet), bumping to Opus for genuinely
hard waters.

If you cannot complete the build in one session: **commit work-in-progress
with the unfinished sub-packs marked `status = "draft"` in their pack.toml**,
hand off via `gt handoff`, and let the next session's predecessor seance
discover where you left off.

## Output expectations

A successful build produces:

- A working Gas City pack repository, public on GitHub
- An `examples/` directory in that repo with a sample `city.toml` showing
  how to compose the umbrella pack
- A `docs/` directory in that repo (Mintlify-compatible per Gas City
  convention) with at minimum: install, quickstart, and a single
  end-to-end tutorial ("Your first watch")
- All acceptance tests in [`tests/ACCEPTANCE.md`](./tests/ACCEPTANCE.md)
  passing
- A `v0.1.0` tag

Anything beyond that is gold-plating. Don't.
