# Bluewater

A [Gas City](https://github.com/gastownhall/gascity) pack that runs your
multi-agent factory like a warship: clean chain of command, watch standing
with formal turnover, pre-composed casualty response, explicit token-cost
discipline, and cross-provider two-key launches for risky operations.

It is an opinionated alternative to the default `gastown` pack for users who
want stricter command structure, durable evolutions instead of improvised
reactions, and explicit token-cost authority at every tier.

## Install

```bash
gc pack add github.com/boylec/bluewater
gc pack add github.com/boylec/bluewater/packs/bluewater-eng
gc pack add github.com/boylec/bluewater/packs/bluewater-cs
# ...add the departments your ship needs
```

See [`docs/install.mdx`](docs/install.mdx) for the full walkthrough.

## Quickstart

A small ship runs with three sub-packs:

```toml
# city.toml
[workspace]
name = "my-ship"
provider = "claude"

[imports.bluewater]
source = "github.com/boylec/bluewater"

[imports.bluewater_eng]
source = "github.com/boylec/bluewater/packs/bluewater-eng"

[imports.bluewater_ops]
source = "github.com/boylec/bluewater/packs/bluewater-ops"

[imports.bluewater_cs]
source = "github.com/boylec/bluewater/packs/bluewater-cs"
```

See [`docs/quickstart.mdx`](docs/quickstart.mdx) and the worked example at
[`examples/small_ship.city.toml`](examples/small_ship.city.toml).

For a carrier-class deployment with all departments, see
[`examples/carrier.city.toml`](examples/carrier.city.toml).

## Departments

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

Minimum running ship: `bluewater` + `bluewater-eng` + `bluewater-ops` +
`bluewater-cs`. Carrier-class adds `bluewater-air`. Long-running production
packs add `bluewater-supply` and `bluewater-medical`.

## Why this pack instead of `gastown`

1. **No single-Mayor failure mode.** The CO/XO/OOD chain keeps a competent,
   awake, decisive node in command at all times, with ritualized handoff.
2. **Pre-composed evolutions.** Incidents trigger pre-rehearsed formulas
   (General Quarters, Man Overboard, Board of Inquiry) rather than ad-hoc
   Mayor reasoning.
3. **Doctrine / Tactics / Orders separation.** Three-layer prompt hierarchy
   that maps onto prompt-cache boundaries and reduces per-invocation token
   cost substantially.

See [`docs/spec/ARCHITECTURE.md`](docs/spec/ARCHITECTURE.md) for the full case.

## Costs

Bluewater is designed to run *cheaper* than `gastown` at equivalent throughput,
not more expensively, despite having more roles. The mechanism is in
[`doctrine/DOCTRINE.md`](doctrine/DOCTRINE.md) under "Token Discipline" and
in [`packs/bluewater-eng/`](packs/bluewater-eng/) (CHENG agent, refusal
authority over token burn rate).

## Prerequisites

- Gas City `>= 1.0.0` (Pack V2 is mandatory)
- A beads provider (`bd` or `file`)
- `tmux`, `git`, `jq`, `pgrep`, `lsof` (Gas City standard)
- API access to at least two of `claude`, `codex`, `gemini` (for
  cross-provider concurrence on two-key launches)

## Where to start reading

- [`docs/quickstart.mdx`](docs/quickstart.mdx) — get a small ship running
- [`docs/first_watch.mdx`](docs/first_watch.mdx) — your first end-to-end watch
- [`doctrine/`](doctrine/) — the doctrine layer (read this *if* you're
  modifying agent prompts; otherwise the agents read it for you)
- [`docs/spec/`](docs/spec/) — original v0.1.0 specification, preserved as
  historical reference

## License

MIT. See [`LICENSE`](LICENSE).

## Lineage

Bluewater is a pack built on top of [Gas City](https://github.com/gastownhall/gascity)
by the gastownhall organization, which is itself an extraction of Steve Yegge's
[Gas Town](https://github.com/gastownhall/gastown). Naval doctrine is older
than all of us and belongs to nobody.
