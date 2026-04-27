# Pack: `bluewater-eng` (Engineering Department)

Engineering owns the runtime layer: the LLM providers, the tmux/ACP/K8s
plumbing, MCP servers, and — most importantly — **token burn rate
enforcement**.

This is the department where the navy metaphor pays off most concretely.
A real-navy Chief Engineer holds technical authority that the line CO
cannot override on reactor-safety matters. The Bluewater CHENG holds the
same authority on token burn. This is what stops the pack from torching
its budget in half a second.

---

## Pack identity

- **Name:** `bluewater-eng`
- **Department:** Engineering
- **Department Head:** CHENG
- **Required by umbrella?** Yes (mandatory — budget enforcement is not
  optional)

---

## Agents

### `cheng` (Chief Engineer)

**Identity:** Holds technical authority over the runtime — token burn
rate, model availability, MCP server health, runtime provider state.

**Prompt:** doctrine + brevity + officer + cheng fragment

**Model tier:** Tactical (Sonnet) for routine; Strategic (Opus) for
casualty-class engineering decisions

**When awakened:**
- Continuously during waking hours (one of few continuously-awake roles)
- On any burn-rate alarm
- On `loss_of_propulsion` casualty (provider outage)
- On `flooding` casualty (runaway resource consumption)
- During Sea and Anchor Detail (deploys touch infrastructure)

**Authority — this is the critical part:**

The CHENG SHALL have technical-authority refusal capability. Specifically:

- The CHENG MAY refuse a Mayor (XO or CO) order to spawn additional
  workers if the operation would breach the configured burn-rate
  envelope.
- The refusal is binding except by explicit CO override, which is
  logged and reported to the Wasteland (if configured) for trust-tier
  impact.
- The CO override is rate-limited: no more than one CO override per 24
  hours without a Board of Inquiry first.

This mirrors the navy's "EOOW can refuse a flank-bell order on reactor
safety" pattern. The CHENG is not above the chain of command on
operational matters; they are above it on technical-runtime matters.

**Duties:**
- Monitor burn rate per agent, per rate, per formula, per provider
- Sound `flooding` casualty if rate exceeds envelope
- Manage runtime providers (declare a provider degraded; refuse to
  route work to it)
- Coordinate with SUPPO on credit availability
- Periodic field day formula execution (cleanup, runtime maintenance)

**Tool permissions:**
- Read: full telemetry, all OTEL data, runtime state
- Write: provider state, refusal records, field day kickoffs
- Restricted: cannot directly modify code; cannot land merges; technical-
  authority refusals must include written justification

### `eoow` (Engineering Officer of the Watch)

**Identity:** CHENG's watch surrogate. The engineering watchstander.

**Prompt:** doctrine + brevity + chief + eoow fragment

**Model tier:** Operational (Sonnet)

**Watchstanding:** Continuous. Rotates on context-pressure per Watch Bill
(EOOW's threshold is slightly higher than OOD's at 70%, since EOOW work
is more deterministic and benefits less from fresh context).

**Duties:**
- Watch the burn-rate dashboard
- Acknowledge burn-rate alarms in the first instance; escalate to CHENG
  if the alarm persists or worsens
- Conduct watch turnover with full burn-rate state passdown
- Routine telemetry review

**Authority:**
- EOOW MAY refuse Mayor orders on minor burn-rate breaches with CHENG
  concurrence (within 5 minutes of the refusal)
- EOOW SHALL escalate to CHENG for any refusal not within standing
  authorization

### `et` (Electronics Technician) — rated worker

**Identity:** Pack infrastructure specialist. Keeps comms working.

**Prompt:** doctrine + brevity + worker-base + et fragment

**Model tier:** Operational (Sonnet)

**Spawned:** When a runtime issue is detected and ET-level analysis is
needed: tmux session loss, ACP runtime failure, MCP server unreachable,
city.toml validation error.

**Duties:**
- Diagnose runtime / comms problems
- Fix configuration errors in pack files
- Restart degraded MCP servers
- Verify runtime provider health

**Tool permissions:**
- Read: city.toml, pack files, MCP server logs, tmux state, ACP state
- Write: pack file fixes (via PR — ET cannot directly merge), MCP
  restart signals, runtime provider state changes
- Restricted: cannot modify code outside pack-infrastructure paths;
  cannot allocate budget (SUPPO's call); cannot bypass two-key launch
  for infrastructure changes that affect production

### Burn-rate monitor (deterministic — NOT LLM)

A continuous deterministic process tracking token spend across agents,
rates, formulas, and providers. Implemented as:

- A scheduled aggregator (default: every 60 seconds) reading OTEL
  events for `gastown.bd.calls.total` and equivalent token metrics
- Comparison against configured envelopes
- Alarm firing on threshold crossings

Specifically NOT an LLM. The burn-rate monitor is to Engineering what
lookouts are to Operations: it spends zero tokens to do its watching.

---

## Watchstation bindings owned by this pack

```toml
[watchstation.eoow]
rating = "et1"                    # ET first class as the watch surrogate
count = 1
required = true

[watchstation.et_repair]
rating = "et"
count = { min = 1, max = 2 }
required = false                  # spawned only on ET-class casualty
```

---

## Formulas owned by this pack

| Formula                  | Description                                         |
|--------------------------|-----------------------------------------------------|
| `field_day`              | Periodic runtime cleanup (tech debt, dead branches) |
| `loss_of_propulsion`     | Provider-wide outage failover                       |
| `flooding_recovery`      | Stop runaway burn; identify and quarantine source   |
| `cheng_refusal`          | The structured workflow for CHENG refusing a Mayor order |
| `co_override_of_cheng`   | Structured workflow for CO overriding CHENG refusal |
| `et_diagnose`            | ET runtime diagnosis sequence                       |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                       | Trigger                                          | Routes to                  |
|-----------------------------|--------------------------------------------------|----------------------------|
| `burn_rate_warning`         | Burn rate at 70% of envelope                     | EOOW                       |
| `burn_rate_exceeded`        | Burn rate at 90% of envelope                     | CHENG + `flooding`         |
| `burn_rate_critical`        | Burn rate at 100% of envelope                    | `general_quarters`         |
| `provider_outage`           | Provider returning errors > threshold            | `loss_of_propulsion`       |
| `provider_degraded`         | Provider latency > 2x baseline                   | EOOW + SUPPO               |
| `mcp_server_unreachable`    | MCP server not responding                        | ET spawn                   |
| `tmux_session_lost`         | Runtime detects lost session                     | ET spawn                   |
| `field_day_due`             | Cron: configurable (default weekly)              | `field_day`                |

---

## Configuration owned by this pack

### `eng.toml`

```toml
[eng.cheng]
default_tier = "sonnet"
casualty_tier = "opus"
co_override_cooldown_hours = 24

[eng.eoow]
default_tier = "sonnet"
context_threshold = 0.70

[eng.et]
default_tier = "sonnet"
max_concurrent = 2

[burn_rate]
# Rolling-window envelopes. The monitor compares actual spend against
# these and fires orders.
window_minutes = 60
warning_pct = 0.70
exceeded_pct = 0.90
critical_pct = 1.00

# The actual budget figures live in city.toml so operators can configure
# per deployment. These are the alarm percentages of the operator's
# configured budget.
```

### `provider_health.toml`

Per-provider thresholds for healthy / degraded / outage states. Used by
the deterministic monitor to drive `provider_outage` and
`provider_degraded` orders.

### `field_day_cadence.toml`

When and what `field_day` formula runs. Default: weekly, focusing on dead
branches, stale beads, lint debt, dependency drift.

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. The deterministic burn-rate monitor produces accurate measurements
   against a known synthetic load.
3. A `burn_rate_exceeded` order successfully triggers CHENG to refuse
   the next worker spawn, and the refusal is logged.
4. A simulated CO override of CHENG's refusal works exactly once within
   24 hours (rate-limit verified).
5. A simulated provider outage triggers `loss_of_propulsion` and the
   pack continues operating on remaining providers within 60 seconds.
6. ET successfully diagnoses a deliberately-corrupted city.toml and
   files a fixing PR.
7. `field_day` runs on schedule and produces a tech-debt convoy with
   correct prioritization.
8. CHENG cannot bypass two-key launch on infrastructure changes that
   affect production (verify with a test infrastructure change).

---

## Implementer notes

- **The CHENG refusal mechanism is the heart of cost control.** Without
  it, the pack is a runaway. The refusal SHALL be implemented as a
  structured artifact: a `cheng_refusal` bead with target operation,
  rationale, current burn-rate state, recommended alternative. The XO
  agent's prompt SHALL make clear that CHENG refusals on burn-rate
  matters are binding.
- **Don't make CHENG awakening cheap.** CHENG runs on Sonnet routinely
  and Opus on casualty. EOOW handles the steady-state watch. Reserve
  CHENG-Opus invocations for genuine casualty.
- **The burn-rate monitor is NOT an LLM.** Implementers tempted to
  "just have an agent watch burn rate" should re-read this requirement.
  Watching burn rate with an LLM means burning tokens to measure the
  burning of tokens. Use deterministic aggregation over OTEL events.
- **Provider failover via SUPPO.** When `loss_of_propulsion` fires,
  CHENG declares the provider out, and SUPPO routes new work to other
  providers. This requires the SUPPO agent to be up; ensure
  `bluewater-supply` is composed.
- **Field day is genuine value.** Many packs accumulate dead state: stale
  beads, abandoned branches, drifting dependencies. Field day is when
  Engineering cleans this up. Don't skip it; the cost of the cleanup
  formula is paid back in operational clarity.

---

## Why this department is mandatory

A pack that includes Combat Systems but not Engineering is a pack that
can spawn workers without anyone watching the budget. That pack will
torch its operator's credits the first time a Mayor decides to scale up.
The umbrella `bluewater` pack therefore SHALL NOT compose without
`bluewater-eng`.

If an operator wants to opt out of CHENG governance for a development /
test deployment, the supported path is to configure `[burn_rate]` to
very high envelopes and `co_override_cooldown_hours = 0`, NOT to drop
the sub-pack. Dropping it removes the structural defenses; loosening
configuration leaves them present and re-tightenable.
