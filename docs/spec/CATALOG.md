# Formula Catalog

Every evolution referenced anywhere in the Bluewater specification is
catalogued here with its trigger, OIC, watchstations, steps, success
criteria, and escalation paths. The implementing agent SHALL produce a
TOML formula file for each, conformant to the current Pack v2 review
formula schema.

This document is **descriptive of intent**, not prescriptive of TOML
syntax. The TOML will look different — exact field names, step types,
and dispatch primitives come from current Gas City. Use this catalog
to know *what* each formula does; consult Gas City's formula
documentation to know *how* to express it.

Conventions used in each entry:

- **Trigger** — what causes the formula to run
- **OIC** — Officer In Charge (which watchstation has command)
- **Watchstations** — who's filling slots
- **Steps** — ordered actions
- **Success criteria** — how we know it worked
- **Escalation** — what happens on failure

---

# Mandatory formulas

These are required by the umbrella pack. Every Bluewater ship runs them.

## `general_quarters`

**Owned by:** `bluewater` (umbrella). High-stakes; cross-departmental.

**Trigger:** Alarm. Fired by `prod_alert`, `ci_failed_on_main` at high
severity, `burn_rate_critical`, or any casualty at high/critical
severity.

**OIC:** CO

**Watchstations:** CO, XO, OOD, CSOOW, CIC Watch, CHENG, EOOW,
DC Alpha, DC Bravo (high-class), FC team, SUPPO, Yeoman

**Steps:**

1. **Sound the alarm.** Yeoman stamps GQ entry with timestamp, originating
   alarm, and severity. CIC Watch broadcasts BREAK BREAK FLASH to all
   active watchstanders.
2. **Awaken the wardroom.** Spawn CO if not already awake. Awaken XO,
   CHENG, CSO. (CSOOW is spawned only at high+ severity.)
3. **Assess.** CIC Watch produces a one-page situation brief: what
   alarmed, current state, immediate scope. CO and XO read it.
4. **Decide intent.** CO sets intent in one of three modes:
   - **Fight through** — continue operations with mitigation
   - **Fall back** — graceful degradation
   - **Fail over** — provider/region/service swap
5. **Split watch.** OOD retains ship-survival authority. CSOOW assumes
   kill-chain coordination (FC retargeting, DC dispatch, helmsman).
6. **Execute.** DC teams run their playbook formulas. CHENG governs
   burn-rate envelope (which may be temporarily elevated for casualty,
   logged). SUPPO routes around outaged providers.
7. **Re-assess every 5 minutes** until the alarm condition clears.
8. **Secure from general quarters.** CO declares secure. CSOOW hands
   back to OOD. DC teams despawn. Yeoman closes the GQ entry.
9. **Schedule Board of Inquiry** if severity was high or critical.

**Success criteria:** Alarm condition cleared. No new high-severity
alarms during the GQ. Convoy state preserved.

**Escalation:** If CO unreachable, XO leads. If both unreachable, the
senior OOD leads and explicitly logs that they are acting in command —
the next CO instance will review and ratify or revert.

---

## `liberty_call`

**Owned by:** `bluewater` (umbrella).

**Trigger:** Scheduled. Default windows configurable in `schedule.toml`
(typical: a 6-hour quiet window once per 24 hours).

**OIC:** CO (issues), XO (executes)

**Steps:**

1. **Announce.** XO publishes a Yeoman log entry: "Liberty call
   commences at HH:MM, secured at HH:MM. Risky evolutions paused."
2. **Pause risky evolutions.** Specifically:
   - `flight_ops` SHALL refuse to start
   - `sea_and_anchor_detail` SHALL refuse to start
   - Mountain convoys SHALL pause (existing in-flight beads
     complete; no new dispatches)
3. **Reduce watch staffing.** EOOW and OOD remain on watch. CIC Watch,
   plane captains, DC teams stand down (despawn).
4. **Lookouts and sonar continue.** They are deterministic; they don't
   cost LLM tokens to keep running.
5. **Casualty exception.** Any alarm-class order during liberty
   automatically invokes its formula and pre-empts liberty. Yeoman logs
   the pre-emption.
6. **Secure from liberty.** XO posts secure entry; risky evolutions
   resume.

**Success criteria:** Risky evolutions correctly paused for the
duration. Casualties (if any) correctly pre-empt and resume liberty
afterward.

---

## `watch_turnover`

**Owned by:** `bluewater` (umbrella).

**Trigger:** Watch context-pressure threshold reached, or wall-clock
maximum, or explicit relief request.

**OIC:** Outgoing watchstander (until relief), then incoming.

**Steps:**

1. **Bell.** Outgoing watch signals 1-minute warning to
   relief-spawning subsystem.
2. **Spawn relief.** Dispatcher spawns a fresh agent of the same
   rating, prompted with doctrine + the watch's tactical block.
3. **Passdown brief.** Outgoing produces a structured 5-category
   brief:
   - Contacts (active convoys, hot beads, in-flight evolutions)
   - Casualties (open Battle Bill conditions)
   - Night orders (CO directives in effect)
   - Anomalies (notable but sub-alarm)
   - Recommendations (next-watch focus areas)
4. **Read-back.** Incoming states the situation back; outgoing
   confirms or corrects.
5. **Yeoman log.** Yeoman records turnover with both agent identifiers,
   timestamps, brief contents, and computed handoff quality score.
6. **Conn transfer.** Outgoing: "I am relieved." Incoming: "I have
   the conn." Authority passes at the second statement.
7. **Despawn outgoing.** Outgoing exits cleanup; despawns when
   complete.

**Success criteria:** Brief covers all 5 categories. Read-back
verifies. Handoff quality score ≥ 0.6.

**Escalation:** Score < 0.6 routes a low-priority bead to COB for
training queue. Score < 0.3 triggers Captain's Mast for outgoing.

---

## `morning_quarters`

**Owned by:** `bluewater` (umbrella).

**Trigger:** Scheduled (default 0600 ship time).

**OIC:** XO

**Steps:**

1. **Pull POD.** XO reads QM's overnight Plan of the Day from Yeoman
   log.
2. **Review departmental status.** XO requests one-line status from
   each Department Head (OPS, CSO, CHENG, SUPPO).
3. **Set day's intent.** XO publishes today's priorities, hot beads,
   and any standing orders.
4. **Brief the watch.** XO and OOD review POD; OOD commits today's
   night orders to the watch turnover state.

**Success criteria:** POD published. Department heads acknowledged.
Watch is briefed.

---

## `eight_o_clock_reports`

**Owned by:** `bluewater` (umbrella).

**Trigger:** Scheduled (default 2000 ship time).

**OIC:** XO

**Steps:**

1. **Department roll-up.** Each Department Head submits a structured
   end-of-day report: convoys landed today, open issues, tomorrow's
   priorities, anomalies.
2. **XO consolidates.** XO produces a one-page summary.
3. **Yeoman log.** Summary is committed.
4. **Hand off to QM.** QM uses today's report to inform tomorrow's POD.

**Success criteria:** All departments report. Summary committed.

---

## `change_of_command`

**Owned by:** `bluewater` (umbrella).

**Trigger:** Scheduled rotation (CO every 14 days, XO continuous, COB
every 28 days), or unplanned (CO incapacity).

**OIC:** Outgoing officer until handoff complete.

**Steps:**

1. **Spawn relief.** Dispatcher spawns the new officer agent with
   doctrine + officer prompt + relevant tactical blocks.
2. **Briefing.** Outgoing officer produces a structured handoff:
   - Current convoy state
   - In-flight evolutions
   - Open Battle Bill conditions
   - Standing orders
   - Personnel notes (which agents are striking, recent Mast outcomes)
3. **Seance link.** Outgoing seance is made available to incoming so
   incoming can ask predecessor questions during their first watch.
4. **Yeoman log.** Change of command stamped with both identifiers.
5. **Authority transfer.** Outgoing: "I am relieved." Incoming
   accepts.
6. **Despawn outgoing.**

**Success criteria:** New officer is operational within 1 watch.
Convoy state preserved.

---

## `plan_of_the_day`

**Owned by:** `bluewater-ops`.

**Trigger:** Scheduled (default 0200).

**OIC:** QM

**Steps:**

1. **Read inputs.** QM pulls: open beads (priority-ordered),
   dependencies, available rated personnel, configured budget for the
   day, yesterday's eight_o_clock report.
2. **Compute plan.** QM sequences beads against capacity. Estimates
   convoy completion via dead reckoning (extrapolated burn vs.
   remaining complexity).
3. **Identify blockers.** QM flags beads that cannot start due to
   missing dependencies, exhausted credits, or insufficient rated
   personnel.
4. **Publish.** QM commits structured POD to Yeoman log.
5. **Despawn.** QM exits.

**Success criteria:** POD covers ≥ 90% of next-day capacity.
Blocker list is accurate.

---

## `man_overboard`

**Owned by:** `bluewater-medical`.

**Trigger:** `agent_stalled` order — a deterministic monitor (Cook)
detects an agent that has stopped progressing.

**OIC:** OOD (initial response), Corpsman (intervention)

**Steps:**

1. **Mark the spot.** Cook records the stalled agent's identity, last
   known state, current bead context.
2. **Check the swimmer.** Corpsman pings the agent: is it stuck on a
   tool call, looping, context-saturated, or zombie?
3. **Recovery decision.** Based on Corpsman finding:
   - Stuck on tool: poke the tool path; if recovered, return to duty
   - Looping: refresh (checkpoint state, respawn with priors)
   - Context-saturated: refresh
   - Zombie: quarantine (kill, no respawn)
4. **Execute recovery.** Run the appropriate sub-formula
   (`agent_refresh` or `agent_quarantine`).
5. **Reassign work.** If the agent's bead is salvageable, reassign;
   if not, mark the bead failed and route to FC for retargeting.
6. **Yeoman log.** Incident logged with cause and resolution.

**Success criteria:** Agent is recovered or cleanly removed. Bead is
not lost.

---

## `sea_and_anchor_detail`

**Owned by:** `bluewater-air` if composed, else `bluewater-cs`.

**Trigger:** Command (operator-initiated deploy or major change
window).

**OIC:** XO

**Steps:**

1. **Set the detail.** XO declares Sea Detail; specific watchstations
   activate (Sea Detail OOD, Conning Officer, Helmsman, Air Boss if
   deploy is involved).
2. **Pre-check.** Helmsman runs pre-land confirmation against all
   beads in the convoy. Air Boss (if applicable) runs flight_ops
   pre-flight color checks.
3. **Two-key concurrence.** For any bead requiring two-key, second
   officer concurrence is collected.
4. **Execute.** Helmsman lands beads in dependency order. Air Boss
   authorizes deploys.
5. **Secure from detail.** XO declares secure when convoy lands.

**Success criteria:** All beads in convoy land. No regressions.

---

## `board_of_inquiry`

**Owned by:** `bluewater-admin`.

**Trigger:** Order — typically post-incident (after `general_quarters`
of high+ severity), or operator-initiated.

**OIC:** XO (chair)

**Steps:**

1. **Convene.** Spawn the panel: chair (XO), one Department Head
   relevant to the incident, one **adversarial reviewer running on a
   different model provider** than the agents involved.
2. **Evidence collection.** CTR (or another fact-finder) pulls all
   relevant Yeoman log entries, telemetry, bead history, and
   transcripts.
3. **Cross-examination.** The adversarial reviewer poses challenge
   questions to the agents involved in the incident. Agents may
   respond; chair may compel response.
4. **Findings.** Panel produces a structured findings document:
   what happened, contributing factors, recommendations.
5. **Recommendations.** Recommendations may include doctrine
   amendments, Battle Bill changes, Captain's Mast for specific
   agents, or no action.
6. **Vote.** Panel votes pass / hold / dissent. Unanimous pass
   required for recommendations to advance.
7. **Yeoman log.** Permanent record committed.
8. **Forward.** Findings forwarded to CO; recommendations forwarded
   per their target (COB for doctrine, OOD for Battle Bill, etc.).

**Success criteria:** Findings are produced. Adversarial review
genuinely challenged (not rubber-stamp). Yeoman log is queryable for
future Boards.

---

## `captains_mast`

**Owned by:** `bluewater-admin`.

**Trigger:** Order — pattern of misconduct, MAA refusals, or specific
Board of Inquiry recommendation.

**OIC:** CO

**Steps:**

1. **Convene.** CO presides. COB advises (witness role). Yeoman
   records.
2. **Charges.** Yeoman presents the structured incident record: what
   happened, evidence, prior history of the agent.
3. **Agent response.** The agent under Mast may respond. Brevity is
   suspended for this purpose; the agent may speak in prose.
4. **Disposition.** CO determines:
   - **Dismissal of charges** — no fault
   - **Counseling** — note in the agent's record; no other action
   - **Restriction** — agent's tool permissions narrowed; prompt
     re-loaded with stricter doctrine
   - **Demotion** — rating reduced one tier
   - **Discharge** — agent identity retired; cannot respawn
5. **Yeoman log.** Permanent record. The disposition is part of the
   agent's history queryable for future Mast.

**Success criteria:** Disposition is recorded. Agent's profile is
updated atomically if a sanction was imposed.

---

## `rating_board`

**Owned by:** `bluewater-admin`.

**Trigger:** Order — COB nominates a striker (via `striker_review`
nightly order).

**OIC:** COB (chair)

**Steps:**

1. **Convene.** Chair (COB), sponsor (a rated PO of the target rate),
   adversarial reviewer (different model provider).
2. **Examine work product.** Each panel member reviews ≥ 5 of the
   striker's recent beads, producing written findings.
3. **Cross-examination.** Adversarial reviewer poses 3 challenge
   questions. Striker responds. Sponsor advocates.
4. **Casualty drill.** A pre-staged drill scenario is run with the
   striker in the rate's role. Outcome observed.
5. **Vote.** Pass / fail / hold. Unanimous pass advances. Hold
   defers; fail terminates striking.
6. **Stamp the rating.** On pass, atomically update the striker's
   profile: rating advanced, prompt fragments swapped, tool
   permissions broadened.
7. **Yeoman log.** Permanent record with vote tally and rationale.

**Success criteria:** Rating is correctly stamped if passed. Yeoman
record is complete and queryable.

---

# Operational formulas

## `targeting_solution`

**Owned by:** `bluewater-cs`.

**Trigger:** Order — XO has new intent that needs decomposition into
beads.

**OIC:** Senior FC

**Steps:**

1. **FC reads intent.** Includes context: rigs involved, constraints,
   priority, budget.
2. **Decompose into beads.** Each bead has: target rig, target paths,
   success criteria, estimated complexity, suggested rating, suggested
   tier.
3. **Identify dependencies.** Bead A depends on B; sequence them.
4. **Estimate effort.** Rough per-bead estimates feed QM's dead
   reckoning.
5. **Hand to OOD.** OOD dispatches per Battle Bill.

**Success criteria:** Beads are precise enough that a Haiku-tier GM can
execute without further interpretation. Estimated effort within ±50% of
actual.

---

## `pr_review`

**Owned by:** `bluewater-cs`.

**Trigger:** `pr_opened` order, or completion of a non-trivial bead.

**OIC:** CSO (delegates to senior FC for routine)

**Implementation:** This SHALL be a **Pack v2 review formula** per Gas
City `0.13.4+`. Use the v2 schema, not a hand-rolled implementation.

**Steps (per Pack v2 review formula spec):**

1. Spawn 2 review agents on **different model providers**.
2. Each review agent reads the diff and produces structured findings:
   correctness, security, style, risk.
3. Findings are reconciled: agreement → pass; disagreement →
   escalate to senior FC.
4. Refinery is signaled with the result.

**Success criteria:** Two independent providers reviewed. Findings
are structured. Refinery acts on the consolidated result.

---

## `merge_to_main`

**Owned by:** `bluewater-cs`.

**Trigger:** Order — bead complete, success criteria met, review
passed.

**OIC:** Helmsman (BMOW)

**Steps:**

1. **Pre-land confirmation.** Helmsman produces structured artifact:
   branch name, SHA, target branch, success-criteria-met status,
   two-key-required boolean, two-key-status if applicable.
2. **Two-key check.** If required and not satisfied, halt; route
   request to second key.
3. **Refinery engage.** Helmsman submits to Refinery (Bors-style merge
   queue per Gas City convention).
4. **Confirm land.** Refinery returns merge SHA. Helmsman verifies.
5. **Report.** Helmsman reports SHA back to OOD for Yeoman log.

**Success criteria:** Merge lands cleanly. SHA is recorded.

**Escalation:** Refinery rejection routes to FC for re-targeting.
Persistent merge conflicts (3+) trigger `collision_at_sea`.

---

## `flight_ops`

**Owned by:** `bluewater-air`.

**Trigger:** `deploy_requested` order.

**OIC:** Air Boss

**Steps:**

1. **Pre-flight Yellow** — sequence the deploy.
2. **Pre-flight Red** — verify artifact (SHA, signing, source branch).
3. **Pre-flight Green** — confirm CI passed and post-deploy smoke
   test is staged.
4. **Pre-flight Blue** — verify rollback artifacts (kill-switches,
   previous version, reversible migrations).
5. **Pre-flight Brown** — plane_captain signoff for the target
   service.
6. **Pre-flight White** — safety policy check: timing window, no
   liberty-call freeze, no GQ active, two-key satisfied.
7. **Purple** — SUPPO issues scoped, time-limited deploy credential.
8. **Air Boss authorizes launch.**
9. **Launch** — deploy executes.
10. **Trap or wave-off** — post-deploy smoke test runs. On pass,
    Air Boss authorizes trap (commit). On fail, `wave_off` is invoked.
11. **Post-flight** — Yeoman log; Purple credential expires.

**Success criteria:** Deploy lands without smoke test failure.
Credentials never appear in logs. Rollback was reachable throughout.

---

## `unrep` (replenishment-at-sea)

**Owned by:** `bluewater-supply`.

**Trigger:** Command, or scheduled (e.g., key rotation cadence).

**OIC:** SUPPO

**Steps:**

1. **Announce.** SUPPO posts unrep window to Yeoman.
2. **Identify replenishment.** What's being refreshed: API keys,
   credentials, dependency catalogs, MCP server endpoints.
3. **Stage.** New credentials minted but not yet active.
4. **Switchover.** Atomic swap: new credentials activate, old
   credentials revoked. SK updates inventory.
5. **Verify.** Sample workers test the new state.
6. **Secure unrep.** SUPPO posts complete entry.

**Success criteria:** Refresh completes without halting in-flight
convoys.

---

## `replenish_credits`

**Owned by:** `bluewater-supply`.

**Trigger:** `provider_credit_exhausted` order.

**OIC:** SUPPO

**Steps:**

1. **Pause new dispatch** for the exhausted provider.
2. **Reroute** existing in-flight to other providers (with affinity
   override).
3. **Notify operator** via Yeoman log. If operator-managed credits,
   request top-up.
4. **Wait** for replenishment signal.
5. **Resume** dispatch when balance restored.

**Success criteria:** No bead is lost. In-flight convoys complete.

---

## `field_day`

**Owned by:** `bluewater-eng`.

**Trigger:** Scheduled (default weekly).

**OIC:** COB (administrative); CHENG (technical)

**Steps:**

1. **Inventory dead state.** SK identifies stale branches (>30 days
   inactive), abandoned beads, dep drift, dead MCP entries.
2. **Triage.** COB and CHENG decide: clean now / clean next field
   day / leave.
3. **Spawn cleanup convoy.** Items to clean become beads; FC targets
   them; GMs execute.
4. **Verify clean.** SK re-inventories; deltas committed.

**Success criteria:** Dead-state inventory reduces measurably each
field day.

---

## `loss_of_propulsion`

**Owned by:** `bluewater-eng`.

**Trigger:** `provider_outage` order.

**OIC:** CHENG

**Steps:**

1. **Declare provider out.** CHENG marks provider state.
2. **Stop routing.** SUPPO ceases routing new work to the provider.
3. **Reroute in-flight.** SUPPO migrates in-flight workers to other
   providers (loses provider affinity benefits but preserves work).
4. **Tier upgrade if needed.** If all preferred-tier providers are
   out, escalate routing to next-higher tier (logged as cost increase).
5. **Watch for recovery.** Periodic test pings. On recovery, restore
   provider state.
6. **Yeoman log.** Outage duration and impact recorded.

**Success criteria:** Pack continues operating within 60 seconds of
outage. No bead is lost.

---

## `cheng_refusal`

**Owned by:** `bluewater-eng`.

**Trigger:** XO or CO has issued a spawn order that would breach
burn-rate envelope.

**OIC:** CHENG

**Steps:**

1. **CHENG produces refusal artifact:** target operation, current
   burn-rate state, rationale, recommended alternative (e.g., "wait 15
   minutes for envelope window," "downsize the request to 3 workers
   instead of 8").
2. **Notify requester.** Brevity-formatted: `NEGAT. Burn-rate
   envelope: 92% of window. Spawn would breach. Recommend reduce by
   half. OVER`.
3. **Yeoman log.** Refusal recorded.
4. **If CO override:** trigger `co_override_of_cheng` formula.

**Success criteria:** Refusal is binding unless CO override. Logged
either way.

---

## `co_override_of_cheng`

**Owned by:** `bluewater-eng`.

**Trigger:** CO explicitly overrides a CHENG burn-rate refusal.

**OIC:** CO

**Steps:**

1. **CO produces override artifact:** rationale, expected impact,
   acknowledged risk.
2. **Rate-limit check.** If this is the second override in 24 hours,
   block with `NEGAT. Override cooldown active. Board of Inquiry
   required first. OVER` to CO.
3. **Stamp the override.** Yeoman logs override with permanent record.
4. **Schedule mandatory Board of Inquiry** within 7 days.
5. **Allow the operation.**

**Success criteria:** Override is logged and rate-limited. BOI follows.

---

# Damage Control formulas

These are pre-staged DC playbook formulas in `bluewater-cs`. Each is
short, deterministic-when-possible, and chained per the DC playbook
(`dc_playbook.toml`).

## `dc_compartmentalize`

**Steps:** Identify the affected scope (rig, branch, agent, dep).
Mark it. Block new work into the scope. Notify CSOOW/CSO.

## `dc_isolate_branch`

**Steps:** Take branch out of merge candidates. Notify any agents
working on it. Mark blocking bead.

## `dc_revert_commit`

**Steps:** Identify the commit. Verify it is the one to revert
(not the symptom). Open revert PR. Run `pr_review`. Land via
`merge_to_main`.

## `dc_quarantine_polecat`

**Steps:** Identify the misbehaving polecat. Capture state for
forensics. Kill the session. Mark its bead failed. Re-target the
bead via FC if recoverable.

## `dc_dependency_pin`

**Steps:** Identify the regressed dependency and version. Pin to last
known good version in dep manifest. Open PR. Run `pr_review`. Land.

---

# Administrative formulas (further detail)

## `doctrine_amendment`

**Owned by:** `bluewater-admin`.

**Trigger:** Order — Board of Inquiry recommendation, or operator-
initiated.

**OIC:** COB (proposes), CO (approves)

**Steps:**

1. **Proposal package.** COB produces: proposed change as unified
   diff, rationale, originating BOI reference if applicable, simulation
   result against test rig.
2. **Review.** XO and at least one Department Head review.
3. **CO decision.** Approve / reject / hold for revision.
4. **Apply.** On approval, COB merges via `merge_to_main` with
   appropriate two-key. AMENDMENTS.md is updated.
5. **Propagate.** New doctrine takes effect on next agent spawn.

**Success criteria:** Doctrine change is auditable, reviewed,
attributable.

---

## `health_audit`

**Owned by:** `bluewater-medical`.

**Trigger:** Scheduled (default daily).

**OIC:** Corpsman

**Steps:** Cook scripts ran-and-aggregated by Corpsman. Identify
agents trending toward stuckness, looping, context bloat, brevity
collapse. Route to interventions.

---

## `agent_refresh`

**Owned by:** `bluewater-medical`.

**Trigger:** From `man_overboard` or `health_audit`.

**Steps:** Checkpoint relevant state to seance. Despawn agent.
Respawn fresh agent of same identity with priors loaded. Resume work.

---

## `agent_quarantine`

**Owned by:** `bluewater-medical`.

**Trigger:** From `man_overboard` for zombie or untrustworthy agents.

**Steps:** Capture forensic state. Kill agent. Mark identity for
review. No respawn until COB approves.

---

## `evacuation`

**Owned by:** `bluewater-medical`.

**Trigger:** Repeated agent failures across an entire convoy.

**Steps:** Halt convoy. Surface to operator with full state for
human review. Resume only on operator command.

---

## `intake_classify`

**Owned by:** `bluewater-discord`.

**Steps:** Classify ambient gateway message. If actionable, file
intake bead. If chat, log and ignore. If ambiguous, route to OOD as
ambiguous-traffic.

---

## `unauthorized_traffic`

**Owned by:** `bluewater-discord`.

**Steps:** Refuse with brevity-formatted reply. Log refusal. If
pattern of refusals from same sender ID, notify MAA.

---

# Optional formulas

## `sigint_collection`

**Owned by:** `bluewater-ops`.

**Trigger:** Order — Board of Inquiry needs evidence.

**OIC:** CT (CTR flavor)

**Steps:** Aggregate logs and events around the incident timeframe.
Correlate across sources. Produce structured evidence package for BOI.

---

## `intel_brief`

**Owned by:** `bluewater-ops`.

**Trigger:** Scheduled daily, or operator request.

**OIC:** OPS

**Steps:** OPS summarizes recent CIC Watch track table state and
sonar contacts into a daily brief for XO. Used at morning_quarters.

---

## `track_table_update`

**Owned by:** `bluewater-ops`.

**Trigger:** Lookout or sonar alarm.

**OIC:** CIC Watch

**Steps:** CIC Watch reads the alarm payload, updates the track
table artifact (add contact, update existing, drop stale), reports
delta to OOD.

---

## `wave_off`

**Owned by:** `bluewater-air`.

**Trigger:** Air Boss aborts in-flight deploy.

**Steps:** Halt deploy. Trigger rollback via Blue color-role
artifacts. Notify plane_captain. Yeoman log. Schedule
`deck_recovery`.

---

## `deck_recovery`

**Owned by:** `bluewater-air`.

**Steps:** Verify rollback completed. Run smoke test on rolled-back
state. Confirm service health. Despawn Air agents. Yeoman log
records duration and impact.

---

## `flight_quarters_secure`

**Owned by:** `bluewater-air`.

**Steps:** End of deploy window. Verify Purple credential expired.
Verify all Air agents despawned. Record window outcomes.

---

## `et_diagnose`

**Owned by:** `bluewater-eng`.

**Trigger:** `mcp_server_unreachable`, `tmux_session_lost`, or city.toml
validation failure.

**Steps:** Spawn ET. Diagnose. Produce fix as PR (no direct merge).
Route to `pr_review`. Land via `merge_to_main`.

---

## `inventory_audit`

**Owned by:** `bluewater-supply`.

**Trigger:** Scheduled (typically with field_day).

**Steps:** SK enumerates current dependencies, MCP endpoints, model
availability across all rigs. Diff against last audit. Surface drift.

---

## `credential_issue`

**Owned by:** `bluewater-supply`.

**Trigger:** Agent requests credential.

**Steps:** Validate request against allowlist. Mint scoped, time-
limited token. Deliver via environment (not prompt). Log issuance.
Do not log token value.

---

## `flooding_recovery`

**Owned by:** `bluewater-eng`.

**Trigger:** `burn_rate_critical` order — burn rate at 100% of
envelope.

**OIC:** CHENG

**Steps:**

1. **Stop the bleeding.** CHENG halts new spawns immediately.
2. **Identify source.** Which formula, which agent, which provider
   account for the breach?
3. **Quarantine source.** If a single agent or formula, kill or
   pause it.
4. **Reset envelope.** Reset rolling-window measurement.
5. **Yeoman log + BOI.** Mandatory Board of Inquiry follows.

---

## `license_review`

**Owned by:** `bluewater-admin`.

**Trigger:** `new_dependency_proposed` order.

**OIC:** JAG

**Steps:** JAG inspects dependency license. Cross-references against
the project's licensing policy. Approves, requests modification, or
refuses. Findings logged.

---

## `secrets_scan_pre_land`

**Owned by:** `bluewater-admin`.

**Trigger:** Bead pre-land (before Helmsman engages Refinery).

**OIC:** MAA

**Steps:** MAA runs secret-detection scan against the diff. On
detection, fires `secret_leaked` order which becomes
`radiation_leak` casualty. Otherwise, signals safe-to-land to
Helmsman.

---

## `policy_update`

**Owned by:** `bluewater-admin`.

**Trigger:** Order — MAA or JAG proposes a ruleset change.

**OIC:** MAA (proposes), COB (concurs), CO (approves on substantive
change)

**Steps:** Like `doctrine_amendment` but scoped to MAA/JAG rules
rather than ship doctrine. Same approval and audit pattern.

---

# Implementation notes

- **Don't be clever.** Where a formula step can be deterministic, make
  it deterministic. Most pre-flight checks, most lookout/sonar
  fan-in, most credential validations are deterministic. Only spend
  LLM tokens where judgment is genuinely required.
- **Composability over completeness.** The DC formulas chain via the
  playbook. The flight_ops color steps gate each other. Build
  formulas as small composable units; let the playbook drive the
  combination.
- **Two-key everywhere it matters.** Two-key launch isn't only for
  production deploys. Doctrine amendments, policy updates, CO
  override of CHENG — all require two-key. Build the two-key
  primitive once and reuse.
- **The Yeoman log is canonical.** Every formula's success criteria
  ends with a Yeoman log entry. If the entry isn't written, the
  formula didn't run. Treat the log write as the formula's
  commit point.
