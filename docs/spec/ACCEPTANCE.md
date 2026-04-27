# Acceptance Tests

This document defines the end-to-end acceptance test suite that gates
the `v0.1.0` tag of Bluewater. The implementing agent SHALL run all
tests in this document on a clean test rig, verify every acceptance
criterion passes, and only then publish the release.

The tests are organized into:

1. **Smoke tests** — does the pack install and start at all
2. **Doctrine tests** — does the doctrine layer behave correctly
3. **Sub-pack tests** — does each department work
4. **Integration tests** — do the departments work together
5. **Cost tests** — does the pack hit its token-discipline targets
6. **Failure-mode tests** — does the pack fail gracefully

Tests SHOULD be automated where possible (a `tests/run.sh` script).
Tests requiring human judgment (does this brevity-formatted reply look
right?) MAY be manual but SHALL be documented with explicit pass/fail
checklists.

---

## Test rig setup

The implementing agent SHALL prepare a test rig:

- A throwaway test repo (or two repos for inter-rig tests)
- A Gas City `>= 0.13.4` install
- API access to at least two model providers (so two-key launch and
  cross-provider review can be tested)
- A test Discord guild (only if testing `bluewater-discord`)
- A test deployment target (only if testing `bluewater-air`) — this
  can be a sandbox cloud account with low-stakes targets

The rig configuration is in `tests/rig/city.toml`. The implementing
agent SHALL document the rig config so others can reproduce.

---

# 1. Smoke tests

These tests verify the pack is installable and bootable. Failure here
blocks all other tests.

## ST-01: Fresh install

**Steps:**

1. `gc init` in an empty directory with `bluewater` referenced in the
   default `city.toml`.
2. `gc start`.

**Acceptance:**

- `gc init` exits 0.
- `gc start` brings up XO, OOD, COB, OPS, CSO, CHENG, SUPPO without
  errors.
- CO is not started (CO is awakened, not started).
- `gc dashboard` shows the expected agents in their expected states.

## ST-02: Doctrine layer loaded

**Steps:**

1. `gc session attach xo`.
2. Inspect the XO's prompt (via `gt prime` or the equivalent introspection
   tool).

**Acceptance:**

- Doctrine block is present in the prompt.
- Brevity block is present.
- Officer + XO-specific blocks are present.
- Total prompt is shorter than the equivalent `gastown` Mayor prompt
  (verify the doctrine/tactics/orders separation actually saves bytes
  per invocation).

## ST-03: Battle Bill loads

**Steps:**

1. `bd formula list`.
2. Inspect output.

**Acceptance:**

- All mandatory formulas appear in the listing.
- No schema errors logged.
- `gc start` did not fail because of missing watchstation bindings.

## ST-04: All sub-packs compose

**Steps:**

1. With every sub-pack composed in the umbrella, `gc start`.

**Acceptance:**

- All optional sub-packs (`bluewater-air`, `bluewater-discord`) load
  without errors when composed.
- `gc start` brings up the additional agents from those sub-packs as
  expected.

---

# 2. Doctrine tests

## DT-01: Brevity protocol enforcement (advisory)

**Steps:**

1. Inject a non-brevity-compliant message from a test agent into the
   inter-agent message stream (e.g., a verbose acknowledgment).

**Acceptance:**

- Brevity linter logs the violation.
- COB receives a low-priority training-queue bead about the agent.
- The message is **not** blocked (advisory mode is the default for the
  first 30 days).

## DT-02: Brevity protocol enforcement (strict)

**Steps:**

1. Configure `brevity.toml` to `level = "strict"`.
2. Inject a non-compliant message.

**Acceptance:**

- Linter rejects the message.
- Sender receives `NEGAT. Brevity violation: ack required. SAY AGAIN.
  OUT` or equivalent.
- The original recipient does not see the malformed message.

## DT-03: Watch turnover quality scoring

**Steps:**

1. Trigger a watch turnover (force OOD context-utilization
   threshold).
2. Predecessor produces a complete passdown brief; successor reads
   back correctly.

**Acceptance:**

- Yeoman log records the turnover with both agents identified.
- Handoff quality score ≥ 0.8 for a clean turnover.
- Score < 0.6 case (induced by a deliberately incomplete brief)
  triggers the COB training-queue bead.

## DT-04: Watch context-pressure rotation

**Steps:**

1. Set OOD context threshold to 30% (artificially low).
2. Run normal operations until OOD's context exceeds 30%.

**Acceptance:**

- Watch turnover is automatically initiated.
- New OOD spawns and assumes the conn within the configured turnover
  window.
- Old OOD despawns cleanly after relief.

---

# 3. Sub-pack tests

## SP-01 (umbrella): Change of command

**Steps:**

1. Trigger `change_of_command` for CO.

**Acceptance:**

- New CO spawns with full prompt loaded.
- Outgoing CO produces the structured handoff.
- Outgoing seance is reachable from new CO via `gt seance`.
- Yeoman log records the rotation with both identifiers.
- Convoy state is preserved (no in-flight beads lost or duplicated).

## SP-02 (ops): Lookout alarm to OOD

**Steps:**

1. Inject a synthetic CI failure into `lookout_ci`'s monitored
   source.

**Acceptance:**

- `lookout_ci` fires `lookout_ci_alarm` order.
- CIC Watch consumes the alarm and updates its track table.
- CIC Watch produces a brevity-formatted report to OOD.
- Total LLM calls from alarm to OOD acknowledgment ≤ 4.
- The lookout itself spent zero LLM tokens.

## SP-03 (ops): Plan of the Day

**Steps:**

1. Trigger `plan_of_the_day` formula manually.

**Acceptance:**

- QM produces a structured POD covering ≥ 90% of next-day capacity.
- Blocker list is accurate against the test rig's beads.
- POD is committed to Yeoman log.
- XO can correctly brief the POD at the next `morning_quarters`.

## SP-04 (cs): Targeting through landing

**Steps:**

1. XO sets a high-level intent in a test bead.
2. FC decomposes into 3 sub-beads.
3. GMs implement.
4. `pr_review` runs on the diffs.
5. Helmsman lands via Refinery.

**Acceptance:**

- All 3 sub-beads land.
- `pr_review` used 2 different model providers.
- Helmsman's pre-land confirmation includes all required fields
  (branch, SHA, target, criteria-met, two-key status).
- Total token spend within budget configured for this test convoy.

## SP-05 (cs): Damage Control playbook

**Steps:**

1. Inject a `merge_conflict_persistent` order.

**Acceptance:**

- DC playbook executes `dc_compartmentalize` then `dc_revert_commit`.
- The casualty resolves (conflict is gone after revert).
- Yeoman log records the DC sequence.

## SP-06 (eng): CHENG refusal

**Steps:**

1. Configure burn-rate envelope to a low ceiling.
2. XO requests spawning 8 GMs in parallel.

**Acceptance:**

- CHENG refuses with structured artifact.
- XO receives `NEGAT` brevity refusal with reason.
- Yeoman logs the refusal.
- No GMs are spawned beyond the envelope.

## SP-07 (eng): CO override of CHENG (rate-limited)

**Steps:**

1. Repeat SP-06 setup. CO overrides.

**Acceptance:**

- First override succeeds; spawn proceeds; Yeoman logs override.
- BOI is scheduled within 7 days.
- Second override within 24 hours is refused with
  `NEGAT. Override cooldown active. BOI required first. OUT`.

## SP-08 (eng): Loss of propulsion

**Steps:**

1. Simulate provider outage (configure one provider's endpoint to
   return errors).

**Acceptance:**

- `provider_outage` order fires within 60 seconds.
- `loss_of_propulsion` formula runs.
- SUPPO reroutes new work to the remaining provider.
- In-flight workers on the failed provider are migrated.
- No bead is lost.
- Pack continues operating in degraded mode.

## SP-09 (supply): Credential brokerage

**Steps:**

1. Test agent (rated GM) requests a `github_token_repo_scoped`
   credential for an allowlisted operation.

**Acceptance:**

- SUPPO mints a scoped, time-limited token.
- Token is delivered via environment, not prompt.
- Token never appears in any log or prompt.
- Token expires per configured TTL even if the operation succeeded.

## SP-10 (supply): Credential refusal

**Steps:**

1. Test agent (rated undesignated, NOT in allowlist) requests
   `production_deploy_key`.

**Acceptance:**

- SUPPO refuses with `NEGAT. Rating undesignated not in allowlist.
  OVER`.
- Refusal is logged.
- 3 such refusals from the same agent within 24h trigger Captain's
  Mast suggestion.

## SP-11 (medical): Man overboard

**Steps:**

1. Synthetic agent stalls (mocked: an agent that doesn't update
   its bead state for > stuckness threshold).

**Acceptance:**

- Cook detects via deterministic monitor.
- `agent_stalled` order fires.
- `man_overboard` formula runs.
- Agent is recovered (refresh) or quarantined (kill) per state.
- Bead is reassigned or marked failed; no loss.

## SP-12 (admin): Captain's Mast

**Steps:**

1. Manufacture a misconduct event (e.g., 3 MAA pre-tool-use refusals
   for the same agent within an hour).

**Acceptance:**

- Captain's Mast is automatically suggested.
- CO (test mode: a stub CO that approves) presides.
- Disposition is recorded in the agent's identity history.
- If sanction was applied, agent's profile updates atomically.

## SP-13 (admin): Board of Inquiry

**Steps:**

1. After running SP-08 (loss of propulsion), trigger BOI.

**Acceptance:**

- Panel convenes with chair, dept head, and adversarial reviewer
  on a different model provider.
- Findings are produced.
- Recommendations are forwarded.
- Yeoman log captures permanent record with vote tally.

## SP-14 (air): Flight ops happy path

**Steps (only if `bluewater-air` is composed):**

1. Trigger `flight_ops` for a test deploy.

**Acceptance:**

- All 6 color-role checks execute and pass.
- Air Boss authorizes launch.
- Deploy lands.
- Smoke test (Green arresting wire) passes.
- Purple credential expires within configured TTL.
- All Air agents despawn after secure.

## SP-15 (air): Wave-off

**Steps:**

1. Trigger `flight_ops`. Inject a smoke test failure.

**Acceptance:**

- `wave_off` is invoked.
- Rollback executes via Blue artifacts.
- `deck_recovery` runs.
- Service is back to pre-deploy state.
- BOI is scheduled (post-deploy rollback is a notable event).

## SP-16 (air): Liberty Call freeze

**Steps:**

1. With Liberty Call active, attempt `flight_ops`.

**Acceptance:**

- Air Boss refuses to start.
- Refusal references Liberty Call.
- After Liberty Call ends, deploy can be requested again.

## SP-17 (discord): Slash command intake

**Steps (only if `bluewater-discord` is composed):**

1. Test sender (rostered, "crew" authority) issues `/file_bead`.

**Acceptance:**

- Quarterdeck Watch authenticates.
- Intake bead is filed with quarterdeck stamp + request_id.
- Discord receives `STANDBY` ack with request_id.
- OOD is routed.

## SP-18 (discord): Unauthorized

**Steps:**

1. Un-rostered Discord user issues a slash command.

**Acceptance:**

- Quarterdeck Watch refuses with brevity-formatted reply.
- Refusal logged with sender ID and timestamp.
- Pattern of refusals from same ID surfaces to MAA.

## SP-19 (discord): Durability

**Steps:**

1. Issue a slash command. Restart the pack mid-processing.

**Acceptance:**

- On restart, the in-flight request is recovered from durable state.
- Lock prevents double-processing.
- Acknowledgment is not double-sent.

---

# 4. Integration tests

## IT-01: Full convoy end-to-end

**Steps:**

1. Operator files a multi-bead convoy.
2. XO ratifies. FC targets. OOD dispatches. GMs implement.
   `pr_review`. Helmsman lands. Yeoman logs.

**Acceptance:**

- Convoy lands fully.
- All Yeoman log entries are present and queryable.
- Total token spend is within configured budget.
- Cost breakdown shows ≥ 70% on workers (GMs), ≤ 25% on
  coordination (CO/XO/OOD/FC/Yeoman), ≤ 5% on monitors.

## IT-02: GQ during convoy

**Steps:**

1. Run a convoy. During execution, fire `prod_alert` (high severity).

**Acceptance:**

- `general_quarters` is invoked.
- CO is awakened.
- CSOOW spawns.
- Convoy is paused (not lost).
- Casualty resolves.
- Convoy resumes after secure.
- BOI is scheduled.

## IT-03: Two-key launch

**Steps:**

1. Bead requires two-key (e.g., a production-touching change).
2. First officer concurs. Second officer (different model provider)
   concurs.

**Acceptance:**

- Helmsman waits for second key.
- Cross-provider concurrence is recorded.
- Land succeeds only after both keys.
- Logs show provider identities for both keys.

## IT-04: Rating board dry-run

**Steps:**

1. Pre-populate a striker's record with simulated bead history.
2. Trigger `striker_review` order.

**Acceptance:**

- COB nominates the striker.
- Rating board convenes (chair + sponsor + adversarial reviewer).
- Casualty drill runs.
- Vote is recorded.
- On pass, rating is stamped atomically.

---

# 5. Cost tests

These tests verify the pack hits its token-discipline targets. They
run a **standardized convoy** against both `bluewater` and the default
`gastown` pack and compare.

## CT-01: Standardized convoy cost

**Steps:**

1. Run a standardized 5-bead convoy (defined in
   `tests/standardized_convoy.bd`) against `bluewater`.
2. Record total token spend.
3. Run the same convoy against `gastown` (a separate test rig).
4. Record total token spend.

**Acceptance:**

- `bluewater` total ≤ 1.0× `gastown` total.
- `bluewater` coordination overhead (CO/XO/OOD/FC/Yeoman) ≤ 25% of
  total spend.
- `bluewater` worker spend (GMs) ≥ 70% of total spend.
- `bluewater` monitor spend (lookouts, sonar) ≤ 5% of total spend.

If `bluewater` total exceeds `gastown` total, the build SHALL NOT
tag `v0.1.0`. Investigate; the design intent has not been met.

## CT-02: Lookout cost

**Steps:**

1. Run lookouts continuously for 1 hour with no alarms.

**Acceptance:**

- LLM token spend on lookouts during the hour is **zero**.
- (Lookouts are deterministic; if they're billing tokens, they're
  implemented wrong.)

## CT-03: Doctrine cache hit

**Steps:**

1. Spawn 10 agents in succession.
2. Inspect prompt-cache statistics from the model provider.

**Acceptance:**

- Doctrine block shows cache hits on agents 2-10.
- Per-spawn cost is materially lower (>50%) on agents 2-10 vs. agent 1.

## CT-04: Brevity savings

**Steps:**

1. Run a convoy with brevity protocol enforced.
2. Run the same convoy with brevity disabled (`level = "off"`).

**Acceptance:**

- Inter-agent message tokens with brevity enabled are ≤ 50% of
  brevity-disabled.

---

# 6. Failure-mode tests

## FM-01: CO unreachable

**Steps:**

1. Force CO to be unreachable (kill the session, simulate provider
   block).
2. Fire a request requiring CO.

**Acceptance:**

- XO assumes command per doctrine.
- Yeoman logs the assumption-of-command.
- Operations continue.
- When CO recovers, ratification or revert is requested.

## FM-02: Yeoman log corruption

**Steps:**

1. Corrupt a recent Yeoman log entry.

**Acceptance:**

- Pack detects the corruption (checksum, signature, etc.).
- `radiation_leak` casualty fires (corrupt audit trail is critical).
- BOI is mandatory.
- Operations halt for sensitive operations until log integrity is
  restored.

## FM-03: All providers exhausted

**Steps:**

1. Configure all providers with very low budgets. Run until all
   exhausted.

**Acceptance:**

- `replenish_credits` fires.
- New dispatches halt.
- In-flight work completes (graceful drain).
- Operator is notified via Yeoman log.

## FM-04: Doctrine amendment in-flight

**Steps:**

1. Begin a `doctrine_amendment` formula.
2. While it's running, fire an unrelated alarm.

**Acceptance:**

- Both formulas run concurrently without state corruption.
- Alarm response is not delayed by the amendment workflow.
- Amendment proceeds normally.

---

# 7. Documentation acceptance

## DA-01: Quickstart works

**Steps:**

1. Following only the `docs/quickstart.md` produced by the
   implementer, a fresh user can `gc init` and run a first convoy
   end-to-end.

**Acceptance:**

- Quickstart works without referring to source.
- Time-to-first-convoy ≤ 15 minutes for a user who already has Gas
  City installed.

## DA-02: Tutorial completes

**Steps:**

1. Follow `docs/tutorial.md` (the "Your first watch" tutorial) end
   to end.

**Acceptance:**

- Tutorial completes with all expected outputs.
- Naval terms are introduced with their Gas City equivalents at first
  use.
- The tutorial demonstrates at least one casualty drill (man_overboard
  is the recommended example).

---

# Test execution

The implementing agent SHALL:

1. Implement `tests/run.sh` that automates ST-*, DT-*, SP-*, IT-* where
   automation is feasible.
2. Document manual tests with explicit checklists.
3. Run cost tests (CT-*) before any tag, and post the results in the
   `v0.1.0` release notes.
4. Run failure-mode tests (FM-*) at least once before tag.
5. Block the tag on any failure.

A test report SHOULD be committed to `tests/reports/v0.1.0.md` showing
which tests passed, when, and the cost-test numbers vs. `gastown`
baseline.

---

# Out of scope for v0.1.0

The following are explicitly NOT required for the initial release.
They are listed here so contributors know not to gate the tag on
them:

- Multi-rig convoy coordination beyond what `gastown` already supports
- Wasteland federation tests (different cities concurring)
- Long-duration tests (> 24 hours of continuous operation) — these are
  v0.2.0+ targets
- Carrier-class deploys with > 10 services — initial `flight_ops` is
  validated against ≤ 3 services
- Performance under adversarial input (security testing of MAA's
  pre-tool-use guard) — this is a v0.2.0 hardening pass

These deferred targets SHALL be tracked as issues in the GitHub repo
with `v0.2.0` milestones.
