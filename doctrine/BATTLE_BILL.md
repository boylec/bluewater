# Battle Bill

The Battle Bill is the routing table that maps each named casualty type and
each named evolution to the watchstations required, who is OIC (Officer In
Charge), and who supports.

This document is the **specification** of the Battle Bill. The implementing
agent SHALL produce a structured TOML version at `bluewater/battle_bill.toml`
that formulas read at dispatch time. **Formulas SHALL NOT hard-code role
assignments that are present here.**

The Battle Bill is committed and version-controlled. It is amended via the
`board_of_inquiry` formula or the `doctrine_amendment` formula. Live edits
are forbidden.

---

## Schema

Each row identifies an evolution or casualty by name, lists the
watchstations involved, marks one as OIC, and references the formula that
implements the evolution.

Conceptual structure (translate to current Pack v2 formula schema at build
time):

```toml
[[evolution]]
id = "general_quarters"
trigger = "alarm"           # alarm | scheduled | command | order
oic = "co"                  # which watchstation has command of this evolution
watchstations = [
  "co", "xo", "ood", "csoow", "cic_watch", "cheng",
  "dc_team_alpha", "dc_team_bravo", "fc_team", "gunner_team", "yeoman"
]
formula = "general_quarters.toml"
severity_min = "high"        # for casualty-class evolutions
description = "Full-crew alarm response for ship-threatening casualty."
```

For watchstations that are filled by a specific rating rather than a named
position, use the rating identifier:

```toml
oic = { rating = "dc1", count = 1 }
watchstations = [
  { rating = "dc2", count = 2 },
  { rating = "et2", count = 1, optional = true },
]
```

---

## Evolutions

These are the named evolutions every Bluewater ship SHALL implement.

### Routine evolutions

| ID                  | OIC  | Trigger      | Description                                          |
|---------------------|------|--------------|------------------------------------------------------|
| `morning_quarters`  | XO   | scheduled    | Daily ops brief; XO presents Plan of the Day         |
| `watch_turnover`    | OOD  | scheduled    | Formal handoff between OOD watches                   |
| `plan_of_the_day`   | QM   | scheduled    | Overnight plan generation                            |
| `eight_o_clock_reports` | XO | scheduled  | Department status roll-up to XO                      |
| `liberty_call`      | CO   | scheduled    | Designated rest period; risky evolutions paused      |
| `field_day`         | COB  | scheduled    | Tech-debt / cleanup convoy                           |

### Operational evolutions

| ID                       | OIC   | Trigger | Description                                       |
|--------------------------|-------|---------|---------------------------------------------------|
| `sea_and_anchor_detail`  | XO    | command | Choreographed deploy; specific roles activate     |
| `flight_ops`             | AirBoss | command | Flight-deck deploy choreography (carrier-class) |
| `unrep`                  | SUPPO | command | Refresh external context without stopping work   |
| `replenish_credits`      | SUPPO | alarm   | Provider-credit exhaustion recovery               |
| `pr_review`              | CSO   | order   | Multi-provider code review (Pack v2 formula)      |

### Casualty evolutions

| ID                       | OIC    | Severity | Description                                       |
|--------------------------|--------|----------|---------------------------------------------------|
| `general_quarters`       | CO     | high     | Ship-threatening casualty; full-crew response     |
| `man_overboard`          | OOD    | medium   | Stalled or hung agent recovery                    |
| `fire_in_compartment`    | DC OIC | high     | Localized failure; compartmentalize and isolate   |
| `loss_of_propulsion`     | CHENG  | high     | Provider-wide outage; failover routing            |
| `flooding`               | DC OIC | high     | Runaway resource consumption                      |
| `collision_at_sea`       | OOD    | high     | Two agents have produced conflicting changes      |
| `grounding`              | CO     | critical | Agent has executed a forbidden action             |
| `radiation_leak`         | MAA    | critical | Secret or sensitive data exposure detected        |

### Administrative evolutions

| ID                       | OIC    | Trigger      | Description                                       |
|--------------------------|--------|--------------|---------------------------------------------------|
| `captains_mast`          | CO     | order        | Review of an agent that misbehaved                |
| `board_of_inquiry`       | XO     | order        | Post-incident formal review with adversarial agent|
| `rating_board`           | COB    | order        | Striker → rated promotion review                  |
| `doctrine_amendment`     | COB    | order        | Proposed change to doctrine documents             |
| `change_of_command`      | COB    | scheduled    | Periodic CO/XO model rotation                     |

---

## Triggers

Trigger types and their wiring:

- **alarm** — produced by an order (event handler). Examples: `ci_failed_on_main`,
  `prod_alert`, `agent_stalled`, `secret_leaked`. Each alarm-class evolution
  SHALL have an order that fires it.
- **scheduled** — produced by Gas City's scheduler (or cron). Configured in
  `bluewater/schedule.toml` per the deployment.
- **command** — invoked manually by the CO, XO, or via Discord slash command.
- **order** — invoked as a step within another formula.

---

## Watchstations and rating mapping

Watchstations name positions in an evolution. They are filled by agent
instances of a given rating. The mapping from watchstation to rating lives
in `bluewater/watchstation_bindings.toml`. Examples:

```toml
[watchstation.cic_watch]
rating = "ot1"          # Operations Specialist 1st class
count = 1
required = true

[watchstation.dc_team_alpha]
rating = "dc"           # any rated DC
count = { min = 1, max = 3 }
required = true

[watchstation.gunner_team]
rating = "gm"
count = { min = 1, max = 8 }
required = false        # GQ can run without if no implementation needed

[watchstation.fc_team]
rating = "fc"
count = 1
required = true
```

When a formula dispatches, the dispatcher reads the Battle Bill, looks up
each watchstation's binding, and spawns or assigns agents accordingly. If a
required watchstation cannot be filled (rating not available, budget
exhausted, all candidates context-saturated), the dispatcher SHALL escalate
to the OIC of the evolution before proceeding.

---

## Severity ladder

Casualty evolutions reference a severity ladder. Severity drives:

- Whether two-key launch is required
- Whether the CO must be awakened
- Whether a Board of Inquiry is mandatory after resolution
- The token budget the CHENG agent will authorize

Levels:

- **low** — XO can handle without involving CO. No mandatory Board of Inquiry.
- **medium** — XO leads, CO informed but not awakened. Board of Inquiry
  optional, COB's call.
- **high** — CO is awakened. CSO and CHENG involved. Board of Inquiry
  mandatory.
- **critical** — CO is awakened. Two-key launch required for any remediation
  action. Board of Inquiry mandatory and chaired by an external (different
  city) reviewer if the Wasteland is configured.

---

## Implementing this document

The implementing agent SHALL:

1. Translate the tables above into `bluewater/battle_bill.toml` using the
   actual Pack v2 schema in current Gas City. The conceptual schema shown
   here is illustrative only.

2. For each evolution listed, ensure a corresponding formula file exists at
   the path indicated by the formula column. The full formula catalog is
   in [`../formulas/CATALOG.md`](../formulas/CATALOG.md); use that for
   detailed step content.

3. Wire each alarm-class evolution to an order in some sub-pack's
   `orders/` directory. The mapping is:

   | Alarm                 | Order file                                                       |
   |-----------------------|------------------------------------------------------------------|
   | `general_quarters`    | `packs/bluewater/orders/ci_failed_on_main.toml` and `prod_alert.toml` |
   | `man_overboard`       | `packs/bluewater-medical/orders/agent_stalled.toml`              |
   | `loss_of_propulsion`  | `packs/bluewater-supply/orders/provider_outage.toml`             |
   | `flooding`            | `packs/bluewater-eng/orders/burn_rate_exceeded.toml`             |
   | `radiation_leak`      | `packs/bluewater-admin/orders/secret_leaked.toml`                |
   | `collision_at_sea`    | `packs/bluewater-cs/orders/merge_conflict_persistent.toml`       |
   | `grounding`           | `packs/bluewater-admin/orders/forbidden_action_executed.toml`    |

4. Validate that for every formula, every named watchstation has a binding
   in `watchstation_bindings.toml`. The `acceptance` test suite includes a
   linter for this; it SHALL pass before tagging a release.

---

## Amendments

Changes to the Battle Bill SHALL be made via the `doctrine_amendment`
formula. Amendments SHALL include:

- The proposed change as a unified diff
- A rationale (why the existing routing failed, with reference to the
  Board of Inquiry that surfaced the gap, if applicable)
- A simulation result (run against the test rig with the change applied)
- COB sign-off

A separate `AMENDMENTS.md` log in the doctrine directory records every
historical amendment for auditability.
