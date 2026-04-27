# Pack: `bluewater-ops` (Operations Department)

The Operations Department owns situational awareness, planning, and the
intelligence pipeline. It feeds the rest of the ship the picture they
need to act.

The single most important architectural commitment in this sub-pack:
**lookouts and sonar are deterministic, not LLM**. Implementations that
poll with LLM sessions are wrong.

---

## Pack identity

- **Name:** `bluewater-ops`
- **Department:** Operations
- **Department Head:** OPS
- **Required by umbrella?** Yes

---

## Agents

### `ops` (Department Head, Operations)

**Identity:** Owns situational awareness across the ship. Reports to XO.

**Prompt:** doctrine + brevity + officer + ops-dept-head fragment

**Model tier:** Tactical (Sonnet)

**Watchstanding:** None. OPS is on duty during waking hours, not standing
watches. CIC Watch is the watchstander.

**Duties:**
- Owns the daily ops picture: what's happening, who's doing what, what's
  next
- Coordinates the Plan of the Day production with QM
- Roll up watch reports for `eight_o_clock_reports`
- Surface anomalies from sonar/CT to XO

### `cic_watch` (CIC Watch Officer)

**Identity:** The fusion point for all sensor inputs. The OOD's primary
information source.

**Prompt:** doctrine + brevity + officer + cic-watch fragment

**Model tier:** Operational (Sonnet)

**Watchstanding:** Continuous. Rotates on context-pressure per Watch Bill.

**Duties:**
- Receives lookout alarms and sonar contacts via the event bus
- Fuses overlapping inputs into a single tactical picture
- Reports to OOD using brevity-coded summaries
- Maintains a "track table" of active concerns (current contacts) that
  updates as alarms come and go

**Tool permissions:**
- Read: all lookout output, sonar output, dashboard state
- Write: track table updates, OOD reports
- Restricted: cannot directly invoke evolutions; routes via OOD

**Implementer note:** The track table is a small structured artifact
(JSON or TOML) the CIC Watch maintains between alarms. It is the agent's
externalized memory; this is what allows CIC Watch to be useful without
re-reading every lookout report on every wake.

### `qm` (Quartermaster / Navigator)

**Identity:** Ship's planner. Owns the Plan of the Day.

**Prompt:** doctrine + brevity + chief + qm fragment

**Model tier:** Tactical (Sonnet)

**When awakened:**
- Nightly at a configurable hour (default 0200 ship time) to compose
  next-day Plan of the Day
- On request from OPS or XO for revised planning during the day
- During Sea and Anchor Detail (the QM is part of that watch)

**Duties:**
- Compose the Plan of the Day from: open beads in priority order,
  dependencies, available rated personnel, configured budget for the
  day
- Estimate convoy completion via dead reckoning (extrapolate current
  burn rate against remaining bead complexity)
- Maintain the master schedule

**Output:** A structured Plan of the Day document committed to the
Yeoman's log nightly, briefed by XO at `morning_quarters`.

### Lookouts (deterministic — NOT LLM)

Lookouts are processes, not sessions. Each lookout watches one arc.
Standard arcs:

| Lookout name        | Arc                                                       |
|---------------------|-----------------------------------------------------------|
| `lookout_ci`        | CI/build status on all monitored branches                 |
| `lookout_prod`      | Production metrics (latency, error rate, saturation)      |
| `lookout_security`  | Security advisories for project dependencies              |
| `lookout_deps`      | Dependency-update events (new releases, deprecations)     |
| `lookout_quartrdck` | Discord and GitHub intake (pre-Quarterdeck-Watch routing) |

Each lookout SHALL be implemented as:
- A scheduled or event-driven script (cron, webhook, file-watch)
- Comparing current state against a baseline
- Firing an order on any deviation matching configured patterns
- Logging its observations to a structured rolling buffer (last N events)
  that CIC Watch and CT can query on demand

Implementers SHALL NOT implement lookouts as 24/7 LLM sessions. The
default Gas City runtime supports event-driven order firing; use it.

### Sonar (deterministic — NOT LLM, except on alarm)

Sonar is **passive listening for patterns** in ambient signal. Distinct
from lookouts: lookouts watch designated arcs for known threats. Sonar
listens for *anomalies* in baseline patterns.

| Sonar channel       | Listens for                                                |
|---------------------|-----------------------------------------------------------|
| `sonar_logs`        | Statistical anomalies in log volume, error patterns       |
| `sonar_chat`        | Discord chatter patterns (frustration, recurring topics)  |
| `sonar_costs`       | Token-burn anomalies (per-rate, per-formula)              |
| `sonar_seance`      | Patterns in predecessor-session queries                   |

Sonar contacts are softer signals than lookout alarms. They route to CIC
Watch first for assessment, not directly to evolution invocation.

### CT division (Cryptologic Technicians)

CT agents are LLM sessions, but spawned only when needed for analysis.
The CT division has four flavors:

#### `ctn` (CT Networks)

**Specialty:** Cyber/security analysis, intrusion detection.

**Spawned:** When MAA flags a security event needing deeper analysis,
when `lookout_security` fires, or on suspicious-pattern reports from
`sonar_logs`.

**Prompt:** doctrine + brevity + ct-base + ctn fragment

**Model tier:** Operational (Sonnet) for routine; Strategic (Opus) for
critical-severity reports.

**Restricted:** CT operates in a separate audit boundary. CT outputs SHALL
be logged to a CT-specific log channel (think SCIF) with restricted read
access. The CT report is delivered to MAA, JAG, and CO; not to the
general fleet.

#### `ctr` (CT Collection)

**Specialty:** Aggregation and correlation of log/event streams during
incident response.

**Spawned:** When Board of Inquiry needs evidence aggregation; when an
ongoing incident requires multi-source correlation.

**Prompt:** doctrine + brevity + ct-base + ctr fragment

**Model tier:** Operational (Sonnet)

**Restricted:** Same audit boundary as CTN.

#### `cti` (CT Linguist)

**Specialty:** Parsing weird-format inbound — vendor changelogs,
third-party API quirks, escaped log lines, undocumented protocols.

**Spawned:** When a parser fails or an unknown format is encountered.

**Prompt:** doctrine + brevity + ct-base + cti fragment

**Model tier:** Operational (Sonnet)

#### `ctt` (CT Technical)

**Specialty:** Reverse-engineering signals from external systems.

**Spawned:** When integration with an external system shows unexpected
behavior and ET cannot diagnose.

**Prompt:** doctrine + brevity + ct-base + ctt fragment

**Model tier:** Tactical (Sonnet)

---

## Watchstation bindings owned by this pack

```toml
[watchstation.cic_watch]
rating = "ot1"                    # OS1 = senior CIC operator
fallback_rating = "ot2"
count = 1
required = true

[watchstation.qm_watch]
rating = "qm"
count = 1
required = false                  # QM is on call, not always on watch
```

---

## Formulas owned by this pack

| Formula                  | Description                                         |
|--------------------------|-----------------------------------------------------|
| `plan_of_the_day`        | Nightly QM composition of next-day plan             |
| `track_table_update`     | CIC Watch fuses lookout/sonar contacts              |
| `sigint_collection`      | CT-led incident evidence collection                 |
| `intel_brief`            | OPS daily intel summary for XO                      |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                       | Trigger                                  | Routes to                  |
|-----------------------------|------------------------------------------|----------------------------|
| `lookout_ci_alarm`          | `lookout_ci` script alarms                | CIC Watch fusion + maybe `general_quarters` |
| `lookout_prod_alarm`        | `lookout_prod` script alarms              | CIC Watch fusion + `prod_alert` if severe |
| `lookout_security_alarm`    | `lookout_security` script alarms          | MAA + CTN spawn            |
| `lookout_deps_alarm`        | `lookout_deps` script alarms              | OPS for triage             |
| `sonar_anomaly`             | Any sonar channel alarms                  | CIC Watch                  |
| `unknown_format_encountered`| Parser failure on inbound data            | CTI spawn                  |
| `external_misbehavior`      | Integration anomaly                       | CTT spawn                  |
| `nightly_plan_kickoff`      | Cron at 0200                              | `plan_of_the_day`          |

---

## Configuration owned by this pack

### `lookout.toml`

Configures each lookout's input source, baseline, alarm threshold, and
order to fire. Example:

```toml
[lookout.ci]
source = "github_actions"
repos = ["${rig_list}"]
baseline = "last 24h success rate"
alarm_when = "main branch fail OR success rate drops > 30% in last 4h"
fires_order = "lookout_ci_alarm"
poll_interval_seconds = 60          # for non-webhook sources
```

### `sonar.toml`

Configures each sonar channel's input stream, anomaly definition, and
contact threshold.

### `ct.toml`

Configures CT division: which flavor spawns on which trigger, audit
boundary configuration, retention rules.

### `qm.toml`

QM configuration: when to run, complexity heuristics for dead reckoning,
budget input source.

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. `lookout_ci` fires on a deliberately-broken CI run, the order routes
   to CIC Watch, and CIC Watch produces a brevity-formatted report to OOD
   without spawning more than one LLM call.
3. `plan_of_the_day` runs on schedule, produces a structured plan, and
   the plan is correctly briefed by XO at the next `morning_quarters`.
4. CIC Watch's track table persists across the agent's session rotations
   (it lives in the Yeoman log or a dedicated artifact, not in agent
   context).
5. CT division agents spawn only on the right triggers and write to the
   restricted audit boundary, not the general log.
6. A simulated CI failure → CIC Watch report → OOD acknowledgment cycle
   completes in ≤ 4 LLM calls total.

---

## Implementer notes

- **CIC Watch's track table is the trick.** Without it, CIC Watch needs
  to re-read all lookout history on every wake, which is expensive and
  slow. With it, CIC Watch wakes, reads the diff against last state, and
  emits a delta. Build this artifact early.
- **Lookout baselines are non-trivial.** "What is normal CI behavior on
  this repo?" requires history. Bootstrap by snapshotting current state
  on first run; refine via Board of Inquiry findings.
- **CT audit boundary.** Treat the CT log channel as if it were sensitive.
  Use a separate beads tag or a separate Yeoman log file. Read access
  restricted to MAA, JAG, CO, and CT itself. CTN's findings are the kind
  of thing you don't want every Haiku polecat seeing in its prompt.
- **Don't conflate sonar with lookouts.** Lookouts watch known arcs for
  known threats. Sonar listens for anomalies. They have different signal
  characteristics (lookouts produce true/false alarms, sonar produces
  weak signal that needs assessment) and different routing.
