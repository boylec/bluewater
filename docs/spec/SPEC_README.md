# Bluewater

A [Gas City](https://github.com/gastownhall/gascity) pack that runs your agent
factory like a warship: CO/XO command continuity, watch standing with clean
rotation, pre-composed casualty response, and Chief Engineer authority over
token burn. Built on hundreds of years of naval doctrine because the problems
are the same — keep a complex system alive, far from help, for a long time.

It is an opinionated alternative to the default `gastown` pack for users who
want stricter command structure, durable evolutions instead of improvised
reactions, and explicit token-cost discipline at every tier.

## Status

Specification stage. This repository contains the requirements documents for
the pack and its sub-packs. Implementation is intended to be carried out by
a Claude agent (or a swarm of them, ironically enough) reading these documents.

If you are that agent, start at [`BUILD_INSTRUCTIONS.md`](./BUILD_INSTRUCTIONS.md).

If you are a human, start at [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## What you get

A composable warship-class pack made up of department sub-packs:

| Sub-pack              | Department      | Purpose                                                 |
|-----------------------|-----------------|---------------------------------------------------------|
| `bluewater`           | Umbrella        | Composes departments into a complete ship               |
| `bluewater-ops`       | Operations      | Situational awareness, planning, lookouts, sonar, CT    |
| `bluewater-cs`        | Combat Systems  | The kill chain: FC → polecats → helmsman → refinery     |
| `bluewater-eng`       | Engineering     | Runtime infrastructure, token-burn governance           |
| `bluewater-supply`    | Supply          | Credit/credential brokering across providers            |
| `bluewater-air`       | Air             | Flight-deck choreography for production deploys         |
| `bluewater-medical`   | Medical         | Agent health monitoring and intervention                |
| `bluewater-admin`     | Admin           | Yeoman, MAA, JAG — records, security, compliance        |
| `bluewater-discord`   | Adapter         | Discord intake, modeled on `gascity-packs/discord`      |

A small ship can run with just `bluewater-ops` + `bluewater-cs` + `bluewater-eng`.
Carrier-class deployments add `bluewater-air`. Long-running production packs add
`bluewater-supply` and `bluewater-medical`.

## Why this pack instead of `gastown`

Three structural advantages over the default pack:

1. **No single-Mayor failure mode.** The CO/XO/OOD chain keeps a competent,
   awake, decisive node in command at all times, with ritualized handoff.
2. **Pre-composed evolutions.** Incidents trigger pre-rehearsed formulas
   (General Quarters, Man Overboard, Board of Inquiry) rather than ad-hoc
   Mayor reasoning.
3. **Doctrine / Tactics / Orders separation.** Three-layer prompt hierarchy
   that maps onto prompt-cache boundaries and reduces per-invocation token
   cost substantially.

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) for the full case.

## Costs

Bluewater is designed to run *cheaper* than `gastown` at equivalent throughput,
not more expensively, despite having more roles. The mechanism is in
[`doctrine/DOCTRINE.md`](./doctrine/DOCTRINE.md) under "Token Discipline" and
in [`packs/bluewater-eng/REQUIREMENTS.md`](./packs/bluewater-eng/REQUIREMENTS.md)
(CHENG agent, technical-authority budget enforcement).

## Prerequisites

- Gas City `>= 0.13.4` (Pack v2 review formulas required)
- A beads provider (`bd` or `file`)
- `tmux`, `git`, `jq`, `pgrep`, `lsof` (Gas City standard)
- API access to at least two of `claude`, `codex`, `gemini` (for cross-provider
  concurrence on two-key launches)

## License

MIT. See [`LICENSE`](./LICENSE).

## Lineage

Bluewater is built on top of and depends on [Gas City](https://github.com/gastownhall/gascity)
by the gastownhall organization, which is itself an extraction of Steve Yegge's
[Gas Town](https://github.com/gastownhall/gastown). Naval doctrine is older than
all of us and belongs to nobody.
