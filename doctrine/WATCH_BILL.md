# Watch Bill

The Watch Bill defines how watch standing works in Bluewater: who stands
watch, when watches rotate, and what happens at turnover.

The most important architectural decision in this document: **watches rotate
on context-pressure, not on a clock**. This is a deviation from real-navy
practice and is justified below.

---

## Why watches rotate at all

A long-running LLM session degrades. Context fills, attention gets diluted
across competing concerns, and decisions made later in a session are
empirically worse than decisions made early. Naval practice solved this
4 centuries ago: a watch lasts 4 hours, then a fresh person takes the conn.

Bluewater applies the same logic to its OOD and other watch-standing
agents. A fresh agent on watch is more reliable than a tired agent on watch.

---

## Why context-pressure rather than time

A real-navy watch is 4 hours because that's how long a human can stand a
watch alertly. An LLM session's degradation is not driven by wall-clock
time — it's driven by **context utilization**. A session that has been
awake for 6 hours but received few queries is fresh; a session awake for
20 minutes that has handled 50 queries is saturated.

The Watch Bill therefore rotates on a context-utilization threshold, not a
clock. The default threshold is **65% of the model's context window**.
Optional secondary thresholds (e.g., 4 wall-clock hours, 100 dispatched
beads) MAY be configured but are not the primary trigger.

---

## Watch positions

The following watchstations are continuously manned:

| Position    | Continuous? | Notes                                                |
|-------------|-------------|------------------------------------------------------|
| OOD         | Yes         | Always exactly one OOD has the conn                  |
| CIC Watch   | Yes (steady steaming) | Single CIC watch officer fuses lookout reports |
| EOOW        | Yes         | Engineering Officer of the Watch (token burn rate)   |
| BMOW        | Conditional | Bosun's Mate of the Watch — when polecats are awake  |
| CSOOW       | Only at GQ  | Combat Systems Officer of the Watch — split from OOD only at General Quarters or higher |
| Helmsman    | Conditional | Only when an active merge is in progress             |
| Lookouts    | Continuous, deterministic | Cron + grep, not LLM, until alarm        |
| Sonar       | Continuous, deterministic | Pattern-matching on event streams, not LLM until alarm |

The CO and XO are **not** watch-standers. They are command authorities who
are awakened on demand or on schedule.

---

## Watch rotation rules

### OOD rotation

The OOD agent SHALL be relieved when **any** of the following are true:

1. Its context utilization crosses the configured threshold (default 65%)
2. It has been on watch longer than the configured maximum (default 4 hours
   wall clock)
3. It has dispatched more than the configured maximum number of beads
   (default 100)
4. It has explicitly requested relief (`INTERROGATIVE: request_relief`)
5. Its insanity check has triggered (peer agent has reported it as
   incoherent)

When relief is needed, the dispatcher SHALL spawn a new OOD agent with
fresh context, conduct a watch turnover (see below), then mark the previous
OOD as relieved and begin its despawn sequence.

### Other watch positions

EOOW, CIC Watch, and BMOW rotate on the same rules as OOD with the same
default thresholds.

### Department heads

Department Heads (CSO, CHENG, OPS, SUPPO) are not watch-standers. They are
spawned at the start of a duty day, informed by the Yeoman of overnight
events, and despawned at the end of the day. They are re-spawned on demand
during their duty hours.

---

## Watch turnover formula

Watch turnover is itself a formula (`watch_turnover.toml`). It SHALL execute
the following steps:

1. **Bell** — outgoing watch signals "1 minute to relief"
2. **Passdown brief** — outgoing watch produces a structured brief:
   - Current contacts (active convoys, hot beads, in-flight evolutions)
   - Ongoing casualties (open Battle Bill conditions)
   - Night orders in effect (any standing CO orders specific to this watch)
   - Anomalies observed (things worth noting that don't yet rise to alarm)
   - Relief recommendations (anything the next watch should consider)
3. **Read-back** — incoming watch states the situation back in their own
   words, hitting all five categories. Outgoing watch confirms or corrects.
4. **Yeoman log entry** — Yeoman records the turnover with both agents'
   identifiers, timestamp, and the passdown brief content.
5. **Conn transfer** — outgoing watch states "I am relieved." Incoming
   watch states "I have the conn." Authority transfers at the second
   statement.
6. **Despawn** — outgoing watch agent enters cleanup; despawns when complete.

The passdown brief SHALL be written using brevity protocol where possible
(structured fields, not prose).

---

## Handoff quality scoring

Every watch turnover SHALL produce a handoff quality score, computed by the
Yeoman from:

- Was the brief complete (all five categories present)? (40%)
- Did the relief read back correctly the first time? (30%)
- Did the incoming watch ask clarifying questions for items the brief
  failed to mention but that mattered in the next hour? (30% — measured
  retroactively)

Scores below 0.6 trigger a low-priority bead routed to the COB for the
training queue. Scores below 0.3 trigger a Captain's Mast for the outgoing
agent (it failed to brief adequately).

This is the feedback mechanism by which the pack improves its watch-standing
discipline over time.

---

## Night orders

A "night order" is a CO directive specific to the current operational period
that must be honored by every watch standing during that period.
Examples:

- "Do not initiate flight ops between 0200 and 0600 — provider rate limits
  reset at 0600."
- "Bead `gt-x4k7m` is on the critical path; expedite if any blockers."
- "Convoy `gt-fjk23` is on hold pending external review; do not assign new
  beads."

Night orders are issued by the CO and propagated via the Yeoman. They are
included in every watch turnover passdown until canceled.

---

## Standing watch with deterministic monitors

Lookouts and sonar are continuous but not LLM-billed. They are processes
(scripts, cron jobs, jq pipelines, baseline diffs) that watch for specific
patterns and call orders on alarm.

Implementer SHALL NOT implement these as 24/7 LLM sessions. The doctrine
"LLMs sleep until alarm" applies in full here.

A lookout is configured by:
- An input source (log stream, metric, file, webhook)
- A pattern or threshold that constitutes an alarm
- A baseline (what "normal" looks like for diff-based detection)
- The order to fire on alarm

When the alarm condition is met, the order is fired with the alarm context
as payload. The order's handler decides which evolution to invoke. Until
the alarm fires, no LLM tokens are spent on the lookout.

---

## Special watches

### CSOOW at General Quarters

When `general_quarters` is set, the OOD ceases to be the unified command
authority and is split:

- **OOD** retains responsibility for ship survival, navigation, and
  whether to fight through, fall back, or fail over.
- **CSOOW** assumes responsibility for the kill chain inside that
  decision: directing FC, gunner's mates, helmsman, and refinery.

This split SHALL persist for the duration of the GQ evolution and end at
"secure from general quarters."

### Sea Detail and Anchor Detail

`sea_and_anchor_detail` is the deploy formula. While it is running, the
normal OOD watch is augmented by:

- **Sea Detail OOD** (the deploying watch officer)
- **Conning Officer** (specifies the deployment maneuvers)
- **Helmsman** (executes them)

The normal OOD remains in command of the rest of the ship while the Sea
Detail handles the deploy.

---

## Configuration

Defaults SHALL be encoded in `bluewater/watch_bill.toml`. Operators SHALL
be able to override per-deployment in `city.toml`. The configurable
parameters are:

```toml
[watch_bill]
ood_context_threshold = 0.65        # fraction of context window
ood_max_wall_clock_hours = 4
ood_max_beads_dispatched = 100
eoow_context_threshold = 0.70       # CHENG's watch can run hotter
cic_context_threshold = 0.65
bmow_context_threshold = 0.70
turnover_min_quality_score = 0.6    # below this, COB notified
turnover_mast_quality_score = 0.3   # below this, Captain's Mast triggered
```

---

## Implementing this document

The implementing agent SHALL:

1. Translate the tables and rules above into `bluewater/watch_bill.toml`.
2. Implement `watch_turnover.toml` formula in `packs/bluewater/formulas/`.
3. Implement the Yeoman's handoff-quality-score logic in
   `packs/bluewater-admin/`.
4. Wire context-utilization monitoring as part of the OOD's runtime —
   the OOD agent itself is responsible for raising "request relief" when
   it crosses the threshold; the dispatcher is responsible for the
   independent threshold check as backstop.

If the current Gas City runtime does not expose context utilization to the
agent itself, this is a Gas City SDK gap and SHALL be reported per
`BUILD_INSTRUCTIONS.md` step 9 ("when you get stuck"). As a fallback, use
the wall-clock and bead-count thresholds only.
