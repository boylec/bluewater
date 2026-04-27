# Bluewater

A [Gas City](https://github.com/gastownhall/gascity) pack that runs your
multi-agent factory like a warship: clean chain of command, watch
standing with formal turnover, pre-composed casualty response, explicit
token-cost discipline, and cross-provider two-key launches for risky
operations.

> **New here?** If terms like *wardroom*, *battle bill*, or
> *carrier-class* sound mystical, jump to
> [`docs/concepts.mdx`](docs/concepts.mdx) (the plain-English
> walkthrough) or [`docs/glossary.mdx`](docs/glossary.mdx) (the lookup
> table). The naval theming stays — it's the design's native vocabulary
> — but every term has a software-engineering gloss alongside it.

Bluewater stands on `gastown`'s shoulders. Steve Yegge's Gas Town
(extracted into the Gas City SDK by the gastownhall organization)
proved multi-agent orchestration as a workable shape; Bluewater takes
that foundation and adds a stricter command structure for crews that
want pre-composed evolutions, formal handoffs, and explicit token-cost
authority at every tier. It's a different opinion within the same
family, not a competitor.

## Install

```bash
# The umbrella pack — wardroom (CO/XO/OOD command layer) plus six
# required departments (Engineering, Combat Systems, Operations,
# Supply, Medical, Admin) all bundled. One import, full ship.
gc pack add github.com/boylec/bluewater
```

That's it for a fully functional ship. Optional add-ons:

```bash
# Production-deploy choreography: pre-flight checks, two-key authorization,
# smoke-test verification, automatic rollback on failure.
gc pack add github.com/boylec/bluewater/packs/bluewater-air

# Inbound chat from Discord — slash commands, mentions, message routing
# to the appropriate watch-stander.
gc pack add github.com/boylec/bluewater/packs/bluewater-discord

# Same as the Discord adapter, but for Slack.
gc pack add github.com/boylec/bluewater/packs/bluewater-slack
```

See [`docs/install.mdx`](docs/install.mdx) for the full walkthrough.

## Quickstart

```toml
# city.toml
[workspace]
name = "my-ship"
provider = "claude"
formula_v2 = true

[imports.bluewater]
source = "github.com/boylec/bluewater"
```

That single import gives you the command-layer agents (CO/XO/OOD/COB/CSOOW)
plus all six required departments. See
[`docs/quickstart.mdx`](docs/quickstart.mdx) and the worked examples at
[`examples/small_ship.city.toml`](examples/small_ship.city.toml) and
[`examples/carrier.city.toml`](examples/carrier.city.toml).

## What do I do with it?

[`docs/use_cases.mdx`](docs/use_cases.mdx) is the answer to "I have the
ship up — now what?" Each recipe has the shape: when you need to → you
do → ship will → you verify by. Eight common scenarios covered:

- File a feature for the ship to build
- Ship a hotfix to production (with two-key gate)
- Production alarm fires (you do nothing; ship handles it)
- Run a casualty drill (training the rating pool)
- Promote a striker to a rated specialist
- Scope expansion (when CO needs to sign off)
- Just see what's happening
- Daily watch turnover (also automatic; you're not involved)

## Departments

The umbrella pack contains six required departments inline. Three more
ship as optional sub-packs.

### Required (in the umbrella)

| Department      | Naval rates                                                | In SE terms                                                    |
|-----------------|------------------------------------------------------------|----------------------------------------------------------------|
| **Wardroom**    | CO, XO, OOD, COB, CSOOW                                    | Command layer (incident commander, day-driver, on-call, training, casualty co-driver) |
| **Engineering** | CHENG, EOOW, EM, MM, HT, DC                                | Runtime infra and cost control (cost authority, watch surrogate, signal/event-bus, daemon supervision, data-layer hygiene, casualty response) |
| **Operations**  | OPS, CIC Watch Officer, QM, OS, IS, CT, lookout, sonar     | Observability, planning, threat intel; lookouts and sonar are deterministic (no LLM) |
| **Combat Sys**  | CSO, FC, GM, ET, MN, Helmsman                              | The merge pipeline — intent → targeting (FC) → implementation (GM) → merge (Helmsman); ET handles combat electronics; MN does vuln scans |
| **Supply**      | SUPPO, LS, CS (Cook)                                       | Provider routing and credential brokering; Cook is deterministic (agent-health early warning) |
| **Medical**     | HM (Hospital Corpsman)                                     | Agent intervention — investigates stalls, hangs, looping |
| **Admin**       | YN (Yeoman), MA (Master-at-Arms), JAG                      | Durable logging, pre-tool-use security gate, license/compliance |
| **Undesignated**| BM, SN, FN, AN                                             | Working parties on smallest beads; entry rates for new agent identities |

### Optional sub-packs (under `packs/`)

| Sub-pack              | What it adds                                                   |
|-----------------------|----------------------------------------------------------------|
| `bluewater-air`       | Production-deploy choreography for carrier-class ships         |
| `bluewater-discord`   | Discord chat intake (Quarterdeck Watch on Discord)            |
| `bluewater-slack`     | Slack chat intake (Quarterdeck Watch on Slack)                |

## When Bluewater fits

`gastown` is the right starting point for most ships. Bluewater layers
on a stricter command structure, which trades simplicity for three
specific properties you may want:

1. **No single-Mayor failure mode.** The CO/XO/OOD chain keeps a
   competent, awake, decisive node in command at all times. If CO is
   unreachable, XO has command. If XO is unreachable, the senior OOD
   has command. Every transfer is logged. This matters when ships
   run unattended for hours.
2. **Pre-composed evolutions.** Common incidents trigger
   pre-rehearsed runbooks (General Quarters for sev1, Man Overboard
   for stalled agents, Board of Inquiry for post-incident review)
   instead of ad-hoc Mayor reasoning. Faster response, more
   consistent outcomes, auditable trail.
3. **Doctrine / Tactics / Orders separation.** Three-layer prompt
   hierarchy that maps onto prompt-cache boundaries. The doctrine
   layer is identical across all 47 ratings; once cached, it's
   near-free on subsequent agent spawns. This is what lets Bluewater
   carry a richer role set without paying more per landed work item.

If your ship is small, single-purpose, single-developer, or short-lived,
`gastown`'s simpler shape is probably better. If you're running a
long-lived production fleet that lands convoys daily and would benefit
from formal incident response, give Bluewater a look.

See [`docs/spec/ARCHITECTURE.md`](docs/spec/ARCHITECTURE.md) for the
full design rationale.

## Costs

Bluewater is designed to land convoys at a similar cost to `gastown`
despite carrying more roles. Two mechanisms make this work:

- **CHENG burn-rate authority.** The Chief Engineer agent has technical
  authority over token-burn rate the way a real ship's Engineering
  Officer of the Watch holds authority over the reactor. CHENG can
  refuse a Mayor (XO) order to spawn more workers if it would breach
  the configured envelope — only the CO can override, and the override
  is logged.
- **Doctrine prompt caching.** The doctrine layer (the agent's
  behavioral contract) is identical across all roles and stable across
  all sessions. Front-loaded in every prompt, it amortizes to near-zero
  through the prompt cache. The default `gastown` prompt structure
  doesn't naturally exploit this; Bluewater's three-layer hierarchy is
  built around it.

The CHENG agent definition is at
[`agents/cheng/`](agents/cheng/); the doctrine layer is at
[`doctrine/DOCTRINE.md`](doctrine/DOCTRINE.md).

## Prerequisites

- Gas City `>= 1.0.0` (Pack V2 layout is mandatory)
- A beads provider (`bd` or `file`)
- `tmux`, `git`, `jq`, `pgrep`, `lsof` (Gas City standard)
- API access to at least two of `claude`, `codex`, `gemini` for
  cross-provider concurrence on two-key launches; ships with one
  provider work but degrade those features

## Where to start reading

For someone new to the pack:

- [`docs/concepts.mdx`](docs/concepts.mdx) — plain-English walkthrough
  of the metaphor (start here if naval terms are new to you)
- [`docs/glossary.mdx`](docs/glossary.mdx) — every naval term in one
  lookup table
- [`docs/quickstart.mdx`](docs/quickstart.mdx) — six steps to a running
  ship
- [`docs/use_cases.mdx`](docs/use_cases.mdx) — what to do when, with
  verification
- [`docs/first_watch.mdx`](docs/first_watch.mdx) — narrative walkthrough
  of one OOD watch end-to-end

For someone modifying the pack:

- [`doctrine/`](doctrine/) — the doctrine layer your agents already
  read; modify carefully and via `doctrine/AMENDMENTS.md`
- [`docs/spec/`](docs/spec/) — original v0.1.0 specification, preserved
  as historical reference

## Naval doctrine alignment

Real-navy rate codes and department assignments. See
[`doctrine/AMENDMENTS.md`](doctrine/AMENDMENTS.md) entry A0002 for the
correctness audit (e.g., why ET is in Combat Systems and DC is in
Engineering, not the other way around). Watch standing follows
[`doctrine/WATCH_BILL.md`](doctrine/WATCH_BILL.md); the brevity protocol
([`doctrine/BREVITY.md`](doctrine/BREVITY.md)) governs all inter-agent
communication.

## License

MIT. See [`LICENSE`](LICENSE).

## Lineage and acknowledgment

Bluewater is a pack built on top of [Gas City](https://github.com/gastownhall/gascity)
by the gastownhall organization, which is itself an extraction of Steve
Yegge's [Gas Town](https://github.com/gastownhall/gastown). Gas Town is
the existence proof that multi-agent orchestration works at all; Gas
City is the SDK that lets new shapes be built on top. Bluewater is one
of those shapes — a stricter, naval-flavored sibling to the default
`gastown` pack, sharing its lineage and benefitting from the same
underlying machinery. Naval doctrine itself is older than all of us
and belongs to nobody.
