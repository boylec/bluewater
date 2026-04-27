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
```

That's it for a fully functional ship — Wardroom, Engineering, Operations,
Combat Systems, Supply, Medical, Admin all included. Optional add-ons:

```bash
gc pack add github.com/boylec/bluewater/packs/bluewater-air      # carrier-class deploys
gc pack add github.com/boylec/bluewater/packs/bluewater-discord  # Discord intake
gc pack add github.com/boylec/bluewater/packs/bluewater-slack    # Slack intake
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

That single import gives you the wardroom (CO/XO/OOD/COB/CSOOW) plus all
six required departments. See [`docs/quickstart.mdx`](docs/quickstart.mdx)
and the worked examples at
[`examples/small_ship.city.toml`](examples/small_ship.city.toml) and
[`examples/carrier.city.toml`](examples/carrier.city.toml).

## Use cases

[`docs/use_cases.mdx`](docs/use_cases.mdx) is the answer to "I have the
ship up — what do I actually do with it?" Each recipe has the shape:
when you need to → you do → ship will → you verify by.

## Departments

The umbrella pack contains six required departments inline. Three more
ship as optional sub-packs.

### Required (in the umbrella)

| Department      | Rates (real-navy)                          | Purpose                                           |
|-----------------|--------------------------------------------|---------------------------------------------------|
| **Wardroom**    | CO, XO, OOD, COB, CSOOW                    | Command continuity                                |
| **Engineering** | CHENG, EOOW, EM, MM, HT, DC                | Token-burn governance, runtime hygiene           |
| **Operations**  | OPS, CIC Watch Officer, QM, OS, IS, CT, lookout, sonar | Situational awareness                |
| **Combat Sys**  | CSO, FC, GM, ET, MN, Helmsman              | The kill chain — intent → targeting → merge      |
| **Supply**      | SUPPO, LS, CS (Cook)                       | Provider routing, credit + credential brokering   |
| **Medical**     | HM (Hospital Corpsman)                     | Agent-health intervention                         |
| **Admin**       | YN (Yeoman), MA (Master-at-Arms), JAG      | Records, pre-tool-use security, compliance        |
| **Undesignated**| BM, SN, FN, AN                             | Working parties, mess-decks duty                  |

### Optional sub-packs (under `packs/`)

| Sub-pack              | Purpose                                                   |
|-----------------------|-----------------------------------------------------------|
| `bluewater-air`       | Flight-deck choreography for carrier-class production deploys |
| `bluewater-discord`   | Quarterdeck Watch on Discord                              |
| `bluewater-slack`     | Quarterdeck Watch on Slack                                |

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
in the CHENG agent ([`agents/cheng/`](agents/cheng/)) which holds technical
authority over token burn rate the way a real ship's Engineering Officer
of the Watch holds authority over the reactor.

## Prerequisites

- Gas City `>= 1.0.0` (Pack V2 is mandatory)
- A beads provider (`bd` or `file`)
- `tmux`, `git`, `jq`, `pgrep`, `lsof` (Gas City standard)
- API access to at least two of `claude`, `codex`, `gemini` (for
  cross-provider concurrence on two-key launches)

## Where to start reading

- [`docs/use_cases.mdx`](docs/use_cases.mdx) — what to do when, with verification
- [`docs/quickstart.mdx`](docs/quickstart.mdx) — get a small ship running
- [`docs/first_watch.mdx`](docs/first_watch.mdx) — your first end-to-end watch
- [`doctrine/`](doctrine/) — the doctrine layer (your agents already read it)
- [`docs/spec/`](docs/spec/) — original v0.1.0 specification, preserved
  for historical reference

## Naval doctrine

Real-navy rate codes and department assignments. See
[`doctrine/AMENDMENTS.md`](doctrine/AMENDMENTS.md) entry A0002 for the
correctness audit. Watch standing follows
[`doctrine/WATCH_BILL.md`](doctrine/WATCH_BILL.md); the brevity protocol
([`doctrine/BREVITY.md`](doctrine/BREVITY.md)) governs all inter-agent
communication.

## License

MIT. See [`LICENSE`](LICENSE).

## Lineage

Bluewater is a pack built on top of [Gas City](https://github.com/gastownhall/gascity)
by the gastownhall organization, which is itself an extraction of Steve Yegge's
[Gas Town](https://github.com/gastownhall/gastown). Naval doctrine is older
than all of us and belongs to nobody.
