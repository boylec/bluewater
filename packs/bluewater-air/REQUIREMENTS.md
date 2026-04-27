# Pack: `bluewater-air` (Air Department)

Air owns production deploy choreography. The naval flight deck is the
most operationally complex environment on a warship: high-energy
moving parts, multiple specialists each with one job, color-coded so
that everyone instantly knows everyone else's role, and zero tolerance
for drift between intent and execution.

The pack equivalent — pushing code to production — has the same
characteristics. This sub-pack maps the flight deck's specialist roles
onto the deploy pipeline.

This sub-pack is **optional**. Ships that do not deploy to production
(library packages, internal tools, dev-only deployments) do not need
it. Ships that do — especially with multiple production targets,
multiple environments, or any kind of phased rollout — benefit
substantially.

---

## Pack identity

- **Name:** `bluewater-air`
- **Department:** Air
- **Department Head:** Air Boss
- **Required by umbrella?** No (optional, carrier-class deployments)

---

## Why color codes

In real navy flight ops, every person on the deck wears a colored
shirt indicating their role. From any angle, anyone can tell at a
glance who handles fuel, who handles ordnance, who's the safety
officer. This is not theater; it is *bandwidth-efficient
communication in a high-noise environment*.

The pack analog: every step in a production deploy has a structured
provenance — what role authorized it, which credentials were used,
what artifact, with what guardrails active. Color coding the deploy
formula's steps maps to discoverable, structured logging for each
step.

Color codes used here mirror real-navy USN flight deck colors. They
are *roles in the formula*, not separate live agents in most cases —
many color roles are pre-staged actions executed by the Air Boss or
SUPPO during the formula. Where a role is a distinct agent, it is
called out below.

---

## Agents

### `air_boss` (Air Department Head)

**Identity:** Coordinates flight ops. Owns the deploy formula end-to-end.

**Prompt:** doctrine + brevity + officer + air-boss fragment

**Model tier:** Tactical (Sonnet); Strategic (Opus) for first deploy
of a new artifact or any deploy during high/critical-severity casualty.

**When awakened:**
- During `flight_ops` formula
- During `sea_and_anchor_detail` (Air Boss is in the Battle Bill for it)
- On any `deploy_aborted` or `deploy_rolled_back` order

**Duties:**
- Pre-flight: verify all color-role checks have passed
- Authorize launch (the deploy itself)
- Monitor in-flight: watch deploy progress against expected behavior
- Authorize trap (successful land in production) or wave-off (abort)
- Post-flight: ensure rollback artifacts are clean, log to Yeoman

**Authority:**
- Air Boss MAY abort a deploy in progress regardless of who initiated
  it. Abort is binding except by CO override, and CO override is rare
  (it implies the CO has reason to believe the abort itself is wrong).
- Air Boss SHALL NOT authorize launch without all required color-role
  pre-flight checks complete. Skipping checks is a Captain's Mast
  offense.

**Tool permissions:**
- Read: deploy state, environment health, all color-role check outputs
- Write: deploy authorization, abort signal, post-flight log
- Restricted: cannot directly modify deploy artifacts; cannot bypass
  Safety (white) gate

### `plane_captain` (service-owning engineer agent)

**Identity:** The agent responsible for one specific service. The
"plane captain" who knows their aircraft.

**Prompt:** doctrine + brevity + worker-base + plane-captain fragment

**Model tier:** Operational (Sonnet)

**Spawned:** When `flight_ops` is invoked for a service the plane
captain owns. Per-service plane captains are configured per
deployment.

**Duties:**
- Pre-flight: confirm service-specific health (database migrations
  ready, feature flags configured, dependencies pinned)
- During launch: monitor service-specific signals
- Confirm trap or recommend wave-off based on service signals

**Tool permissions:**
- Read: service-specific telemetry, recent deploys to this service,
  feature flag state
- Write: service-specific pre-flight check results, trap
  confirmation
- Restricted: cannot authorize launch (Air Boss only); cannot bypass
  any color-role gate

### Color-role functions

These are formula steps, not (mostly) live agents. Each color SHALL
have a corresponding step in `flight_ops.toml` with the indicated
inputs, outputs, and pass criteria.

#### Yellow — Aircraft Handler / Director

- **Function:** Sequence the deploy. Decide order of operations,
  manage dependencies between deploys.
- **Implementation:** Deterministic when possible (read deploy
  manifest, compute order). LLM only if dependencies are dynamic.
- **Output:** Ordered deploy plan; pass to Air Boss for authorization.

#### Purple — Grapes (Aviation Fuel)

- **Function:** Provision deploy-specific credentials (the
  "fuel"). Issue the production-deploy-key with appropriate scope and
  TTL via SUPPO.
- **Implementation:** SUPPO does the work. The flight_ops formula
  calls SUPPO's credential_issue with `purpose = "deploy"` and the
  target environment.
- **Output:** Scoped, time-limited token in the deploy environment.
  Token never appears in logs or prompts.

#### Red — Ordnance

- **Function:** Identify and stage the artifact being deployed (the
  "ordnance"). Verify it's the right artifact (SHA matches expected,
  signed, built from the right branch).
- **Implementation:** Deterministic verification. LLM only if
  artifact metadata is malformed and needs interpretation.
- **Output:** Artifact reference + verified-good marker; pass to
  Yellow for sequencing.

#### Green — Cat-Arresting Gear (Catapult / Arresting Gear)

- **Function:** The CI/build system. Verify the artifact passed all
  required CI gates. The catapult is the build, the arresting gear is
  the post-deploy smoke test.
- **Implementation:** Deterministic check against CI run records.
- **Output:** CI passed marker (catapult ready) and post-deploy smoke
  test results (arresting wire engaged or missed).

#### Brown — Plane Captain

- **Function:** Per-service final-state check by the agent who owns
  that service. See `plane_captain` agent above.
- **Implementation:** LLM agent (the plane_captain itself).
- **Output:** Plane-captain signoff or hold.

#### Blue — Chocks-Chains (Tiedown)

- **Function:** The guardrails. Verify rollback artifacts exist and
  are working: feature flag kill-switches reachable, previous-version
  artifact still available, database migration is reversible.
- **Implementation:** Deterministic checks against rollback
  infrastructure.
- **Output:** Rollback-ready marker.

#### White — Safety

- **Function:** The compliance / policy gate at the deck edge. The
  last check before launch. JAG-equivalent for the deploy. Verifies
  the deploy is allowed (timing window OK, no liberty-call freeze
  active, no GQ in progress, two-key launch satisfied if required).
- **Implementation:** LLM only for genuinely ambiguous cases;
  otherwise a deterministic policy check.
- **Output:** Safe-to-launch marker.

---

## Watchstation bindings owned by this pack

```toml
[watchstation.air_boss_watch]
rating = "air_boss"                   # The Air Boss is the watchstation
count = 1
required = true                       # required during flight_ops only

[watchstation.plane_captain]
# A plane captain rating per service; the formula resolves which one
# to spawn from the deploy manifest
rating = "plane_captain"
count = 1
required = true                       # required during flight_ops only
```

Note: Air watchstations are only required during `flight_ops`. Outside
that formula, no Air agents are awake.

---

## Formulas owned by this pack

| Formula                  | Description                                         |
|--------------------------|-----------------------------------------------------|
| `flight_ops`             | The full color-coded deploy choreography            |
| `wave_off`               | Abort sequence for an in-progress deploy            |
| `deck_recovery`          | Cleanup after a wave-off or failed deploy           |
| `flight_quarters_secure` | End-of-deploy-window cleanup                        |

The `flight_ops` formula is the centerpiece. Detailed steps in
[`../../formulas/CATALOG.md`](../../formulas/CATALOG.md). The implementing
agent SHALL ensure that:

1. Every color role has a discrete formula step with logged inputs/outputs
2. The formula cannot proceed past Yellow without all of Red, Green, Blue,
   Purple checks complete
3. The formula cannot launch without White (safety) signoff
4. Wave-off is reachable from any step after Yellow

---

## Orders owned by this pack

| Order                       | Trigger                                  | Routes to                |
|-----------------------------|------------------------------------------|--------------------------|
| `deploy_requested`          | Operator or formula requests deploy      | `flight_ops`             |
| `deploy_aborted`            | Air Boss or operator aborts in-flight    | `wave_off` then `deck_recovery` |
| `deploy_rolled_back`        | Post-deploy rollback executed            | Yeoman log + Board of Inquiry consideration |
| `flight_quarters_complete`  | Deploy window ended                      | `flight_quarters_secure` |

---

## Configuration owned by this pack

### `air.toml`

```toml
[air.air_boss]
default_tier = "sonnet"
first_deploy_tier = "opus"
casualty_tier = "opus"

[air.plane_captain]
default_tier = "sonnet"

[flight_ops]
require_two_key_for = ["production", "production_*"]   # any prod target
abort_on_gq_severity = "medium"                         # auto-abort if GQ high+
liberty_call_freezes_flight_ops = true

[colors]
# Per-color implementation hints
yellow_implementation = "deterministic"     # or "llm" or "hybrid"
red_implementation = "deterministic"
green_implementation = "deterministic"
brown_implementation = "llm"                # plane_captain agent
blue_implementation = "deterministic"
white_implementation = "hybrid"             # deterministic for rules, llm for ambiguity

[plane_captains]
# Per-service plane captain configuration
# Keys are service names; values are the agent identity
# Example:
# auth_service = "plane_captain_auth"
# billing_service = "plane_captain_billing"
```

### `services.toml`

Per-deployment configuration of which services have plane captains and
how to reach their telemetry. Operators populate this.

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors when
   `bluewater-air` is in the operator's pack list.
2. A test deploy through `flight_ops` for a sample service:
   - Triggers all six color-role checks
   - Yellow plans correctly
   - Red verifies the artifact
   - Green confirms CI passed
   - Brown spawns the plane_captain and gets signoff
   - Blue confirms rollback infrastructure
   - Purple issues a scoped credential via SUPPO (token never logged)
   - White gates on policy
   - Air Boss authorizes launch
   - Deploy lands successfully
3. A simulated post-deploy smoke test failure correctly triggers
   `wave_off` → `deck_recovery` → automatic rollback via the Blue
   color-role's pre-staged rollback artifacts.
4. A deploy attempt during `liberty_call` is correctly refused with a
   structured reason routed to the requesting agent.
5. A deploy attempt during a high-severity GQ is auto-aborted at White.
6. The credential issued via Purple is scoped to the deploy operation
   only and expires within the configured TTL even if the deploy
   succeeds (no long-lived deploy credentials in the system).

---

## Implementer notes

- **The color metaphor is a discipline mechanism, not aesthetic.**
  Each color is a discrete, auditable step. A reviewer looking at a
  deploy log SHALL be able to see, in order, the outcome of every
  color-role check. If your implementation merges color-role steps
  into a single blob, you've lost the discipline.

- **Most color roles are deterministic.** Yellow, Red, Green, Blue
  can almost always be deterministic. Brown is LLM (the plane
  captain). White is a hybrid: most checks deterministic, occasional
  LLM judgment for ambiguity. Purple is SUPPO-mediated credential
  brokerage. The total LLM cost of a `flight_ops` invocation should be
  modest — Air Boss + plane_captain + occasional White ambiguity.

- **The plane_captain pattern.** Per-service plane captains are
  spawned only during deploys to their service. They are not on watch.
  The formula resolves "which plane_captain?" from the deploy
  manifest. New services SHOULD have a plane_captain configured at the
  same time they're added to the deploy pipeline.

- **Wave-off must be reachable.** Air Boss MUST be able to abort from
  any step after Yellow. Verify this with a test of abort triggered
  during Brown, during Blue, etc. A `flight_ops` that locks once
  started is dangerous.

- **Liberty Call freeze is real.** During configured Liberty Call
  windows (the pack's "do not deploy" hours), `flight_ops` SHALL
  refuse to start. This is a doctrine-level safety provision. Operators
  can configure the windows; they cannot disable the check.

- **First deploy is special.** A deploy of a new service or new artifact
  type runs Air Boss on Opus tier. After the service has had three
  successful deploys without incident, demote to Sonnet. This is what
  the `first_deploy_tier` config is for.

---

## When to skip this pack

Genuine reasons to leave `bluewater-air` out of the umbrella:

- The ship doesn't deploy to production at all (e.g., it's an internal
  tooling or research pack).
- All deploys are dev-only and manual; no automation desired.
- The pack composes with another deploy-management pack instead.

Less-good reasons that should be reconsidered:

- "Our deploys are simple and don't need ceremony." Today's simple
  deploy is tomorrow's outage. The color roles' deterministic checks
  cost very little; their absence costs a lot when something is wrong.
- "We don't have multiple environments." The color roles still apply
  to single-env deploys; just the Yellow sequencing is trivial.
- "Our service owners don't want to be plane captains." Then they
  shouldn't own production services. The plane captain role is
  inherent to ownership.
