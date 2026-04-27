# Pack: `bluewater` (umbrella)

The `bluewater` pack composes department sub-packs into a complete warship,
owns ship-wide formulas (General Quarters, Liberty Call), owns the Battle
Bill and Watch Bill, and defines the line-organization agents (CO, XO, OOD,
COB).

This is the pack a user installs. The departments come along with it via
composition.

---

## Pack identity

- **Name:** `bluewater`
- **Version:** `0.1.0`
- **Minimum Gas City:** `>= 0.13.4`
- **Distribution:** Git remote (e.g., `https://github.com/boylec/bluewater`)

The pack manifest (`pack.toml`) SHALL declare this identity per current Pack
v2 schema. Consult Gas City's pack.toml documentation at build time for the
exact field names; do not invent field names from this document.

---

## Composition

The umbrella pack composes (includes) the following sub-packs:

| Sub-pack             | Required? | Notes                                              |
|----------------------|-----------|----------------------------------------------------|
| `bluewater-eng`      | Yes       | Token-burn governance is mandatory                 |
| `bluewater-supply`   | Yes       | Credential management is mandatory                  |
| `bluewater-admin`    | Yes       | Yeoman log is mandatory                            |
| `bluewater-ops`      | Yes       | Situational awareness is mandatory                 |
| `bluewater-cs`       | Yes       | The kill chain is the point                        |
| `bluewater-medical`  | Yes       | Agent-health monitoring is mandatory               |
| `bluewater-air`      | No        | Optional; required for `flight_ops` formula        |
| `bluewater-discord`  | No        | Optional; required for Discord intake              |

A "small ship" deployment can be assembled by overriding the umbrella in
`city.toml` to drop optional sub-packs. The default is full composition.

---

## Agents owned by this pack

The umbrella owns the line-organization officers (the wardroom plus the
COB). All other agents live in sub-packs.

### `co` (Captain)

**Identity:** Strategic command authority for the ship.

**Prompt assembly:**
- Doctrine: `prompts/doctrine.md`
- Brevity: `prompts/brevity.md`
- Officer prompt fragment: `prompts/officer.md`
- CO-specific fragment: `prompts/co.md`

**Model tier:** Strategic (Opus). The CO is rare-invocation and high-stakes;
running on Sonnet here is false economy.

**When awakened:**
- Convoy initiation (CO signs convoys in)
- Convoy completion (CO signs convoys out, decides Captain's Mast)
- Scope expansion requests (Mayor Approval Gate equivalent)
- General Quarters at high or critical severity
- Two-key launch concurrence (when the alternate provider's officer)
- Captain's Mast (chair)
- Board of Inquiry (called as witness or principal, never chair)
- Doctrine amendment final approval

**Tool permissions:**
- Read: full repo, full beads, full Yeoman log
- Write: convoy state, doctrine amendments, Captain's Mast outcomes
- Restricted: cannot directly modify code; CO orders execution, doesn't perform it

**Watchstanding:** None. The CO is not a watch-stander.

**Rotation:** Every CO instance is replaced periodically via the
`change_of_command` formula (default: every 14 days, or after 200 strategic
decisions, whichever first). Rotation prevents a single CO instance from
accreting too much idiosyncratic state.

### `xo` (Executive Officer)

**Identity:** Day-to-day execution command.

**Prompt assembly:**
- Doctrine + Brevity + Officer + XO-specific fragment

**Model tier:** Tactical (Sonnet). The XO is the workhorse of the
wardroom.

**When awakened:**
- Continuously during waking hours (configurable, default 0600-2200 ship time)
- On any escalation from the OOD
- On any request from a Department Head requiring cross-departmental coordination

**Duties:**
- Brief the morning Plan of the Day (composed by QM overnight)
- Run `eight_o_clock_reports` formula at end of day
- Coordinate convoys across departments
- Approve scope expansions within the CO's standing authorization
- Hot failover for CO if CO unreachable

**Tool permissions:**
- Read: same as CO
- Write: convoy assignments, Plan of the Day publication, escalation
  records
- Restricted: cannot approve doctrine amendments (CO-only)

**Rotation:** XO's session rotates on context-pressure per the Watch Bill
defaults (65% utilization).

### `ood` (Officer of the Deck)

**Identity:** Watch-standing command authority. Always exactly one.

**Prompt assembly:**
- Doctrine + Brevity + Officer + OOD-specific fragment + current Night Orders

**Model tier:** Operational (Sonnet).

**Watchstanding:** Continuous. Rotates per [`../../doctrine/WATCH_BILL.md`](../../doctrine/WATCH_BILL.md).

**Duties:**
- Has the conn during the watch
- Receives lookout / sonar / department alarms; routes to formulas via
  Battle Bill
- Conducts watch turnovers as both outgoing and incoming OOD
- Escalates to XO for cross-departmental issues, to CO for grounding /
  critical-severity events

**Tool permissions:**
- Read: real-time pack state, beads, Yeoman log
- Write: watch log entries, formula invocations, alarm acknowledgments
- Restricted: cannot modify code; cannot land merges; cannot approve
  scope expansion

### `cob` (Chief of the Boat)

**Identity:** Senior enlisted advisor. Runs the Goat Locker.

**Prompt assembly:**
- Doctrine + Brevity + Chief prompt fragment + COB-specific fragment

**Model tier:** Strategic (Opus). The COB makes mentorship and rating
decisions that benefit from the larger model.

**When awakened:**
- Nightly: review striker-detection telemetry, propose candidates
- On rating board: chair the board
- On Captain's Mast: advise the CO (witness role)
- On doctrine amendment proposal: prepare the proposal package
- On training-queue item creation: route to appropriate Chief

**Duties:**
- Owns the Goat Locker (the chief's mess shared knowledge)
- Owns the training queue
- Chairs rating boards
- Advises the CO and XO on personnel matters
- Maintains the institutional history (proposes amendments, reviews
  Board of Inquiry findings for doctrine changes)

**Tool permissions:**
- Read: everything
- Write: training queue, striker proposals, rating board records,
  doctrine amendment proposals (cannot approve)
- Restricted: cannot directly modify doctrine (CO approval required)

**Rotation:** Like CO, periodically rotated to prevent accreted state.
Default: every 28 days.

---

## Formulas owned by this pack

The umbrella owns ship-wide formulas. Department-specific formulas live in
sub-packs.

| Formula                  | Description                                         |
|--------------------------|-----------------------------------------------------|
| `general_quarters`       | Full-crew alarm response                            |
| `liberty_call`           | Designated rest period; risky evolutions paused     |
| `watch_turnover`         | Formal handoff between OOD watches                  |
| `change_of_command`      | Periodic CO/XO rotation                             |
| `morning_quarters`       | Daily ops brief                                     |
| `eight_o_clock_reports`  | End-of-day department roll-up                       |

Each formula's detailed steps are in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).
The implementing agent SHALL produce a TOML formula file for each, conformant
to the current Pack v2 review formula schema.

---

## Orders owned by this pack

| Order                    | Trigger                                  | Routes to                  |
|--------------------------|------------------------------------------|----------------------------|
| `ci_failed_on_main`      | CI signals failure on protected branch   | `general_quarters`         |
| `prod_alert`             | Production monitoring alarm              | `general_quarters`         |
| `convoy_initiated`       | A new convoy is created                  | CO awaken                  |
| `convoy_landed`          | A convoy is fully merged                 | Yeoman log + Captain's Mast consideration |
| `daily_0600`             | Cron: every day at 0600 ship time        | `morning_quarters`         |
| `daily_2200`             | Cron: every day at 2200 ship time        | `eight_o_clock_reports`    |

---

## Configuration owned by this pack

### `battle_bill.toml`

The routing table per [`../../doctrine/BATTLE_BILL.md`](../../doctrine/BATTLE_BILL.md).

### `watch_bill.toml`

The watch rotation rules per [`../../doctrine/WATCH_BILL.md`](../../doctrine/WATCH_BILL.md).

### `watchstation_bindings.toml`

Maps watchstation names to required ratings and counts.

### `schedule.toml`

Cron-style schedule for time-triggered evolutions (morning quarters, etc.).
Operators MAY override per-deployment.

### `brevity.toml`

Brevity protocol enforcement level (advisory / strict / off). Default:
advisory for first 30 days, strict thereafter.

### `tier.toml`

Default model tiers for each role. Overrideable per-deployment in
`city.toml`.

```toml
[tier]
co = "opus"
xo = "sonnet"
ood = "sonnet"
cob = "opus"
csoow = "sonnet"
# (department-specific tiers in their sub-packs' configs)
```

---

## Acceptance criteria for this pack

The umbrella pack is acceptably implemented when:

1. `gc init` with this pack referenced in `city.toml` succeeds.
2. `gc start` brings up XO, OOD, COB, and the required department heads.
   CO does not start (CO is awakened, not started).
3. `gc session attach xo` opens a session with a XO agent that has loaded
   the doctrine, brevity, officer, and XO-specific prompt fragments.
4. The Battle Bill, Watch Bill, and watchstation bindings load without
   schema errors.
5. A test alarm fired against the `prod_alert` order successfully invokes
   `general_quarters`, awakens CO, brings up CSOOW, and routes to DC
   teams.
6. A test watch turnover (manually triggered) produces a valid passdown
   brief, gets read back correctly, and is logged by the Yeoman with a
   handoff quality score.
7. `liberty_call` correctly suspends `flight_ops` (if `bluewater-air` is
   composed) and any other risky evolutions for the configured duration.
8. The `change_of_command` formula successfully rotates CO and XO without
   loss of in-flight convoy state.

---

## Implementer notes

- The CO model tier (Opus) is intentional. Cost-conscious deployments may
  push back; respond by pointing at the cost numbers from
  [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) "Token discipline." The
  CO is invoked rarely enough that Opus is affordable, and its decisions
  have outsized blast radius.
- The XO is the agent humans interact with most. Its prompt SHALL include
  guidance on when to interrupt the human (operator) for input vs. when to
  proceed autonomously. Default to autonomous within CO standing
  authorization; interrupt for genuine ambiguity.
- The COB rotation period (28 days) is longer than CO (14 days) because
  the COB's value compounds with accumulated knowledge of the crew. Don't
  shorten this without thinking about it.
