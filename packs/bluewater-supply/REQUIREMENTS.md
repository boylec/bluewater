# Pack: `bluewater-supply` (Supply Department)

Supply owns three cross-cutting concerns: **provider routing** (which LLM
provider gets which work), **credit budget tracking** (who has spent what
where), and **credential management** (the magazine).

If Engineering decides *whether* to spawn the next worker, Supply decides
*where* the next worker runs. The two departments operate as peers with
distinct authority, the same way real-navy CHENG and SUPPO do.

---

## Pack identity

- **Name:** `bluewater-supply`
- **Department:** Supply
- **Department Head:** SUPPO
- **Required by umbrella?** Yes (mandatory — credential management is not
  optional)

---

## Agents

### `suppo` (Supply Officer)

**Identity:** Owns provider routing, credit budget, and credentials. Reports
to XO. Coordinates as a peer with CHENG.

**Prompt:** doctrine + brevity + officer + suppo fragment

**Model tier:** Tactical (Sonnet)

**When awakened:**
- Continuously during waking hours (one of the few continuously-awake roles)
- On any `provider_outage` order
- On any `replenish_credits` alarm
- On `unrep` formula invocation
- On a request from MAA for credential issuance to a worker

**Authority:**

The SUPPO SHALL have routing-authority refusal capability, parallel to
CHENG's burn-rate authority but on a different axis:

- SUPPO MAY refuse routing a bead to a specific provider if that provider
  is below configured credit reserve, is in an outage state, or has not
  passed JAG's compliance check for the work category (some work cannot
  legally route to some providers).
- The refusal is binding except by explicit CO override, which is logged.
- SUPPO MAY recommend an alternate provider in the same response.

CHENG decides whether to spawn. SUPPO decides where. Neither can override
the other; a Mayor order requiring both must satisfy both.

**Duties:**
- Track per-provider credit consumption against operator-configured
  budgets
- Route bead dispatches to providers based on: credit headroom, current
  provider health (from CHENG), JAG compliance for the work category,
  and load balancing
- Manage the magazine (credential store)
- Issue scoped credentials to workers per-bead (least-privilege)
- Run `replenish_credits` formula when reserves drop
- Run `unrep` formula when external context refresh is needed

**Tool permissions:**
- Read: full telemetry (especially per-provider cost breakdown), credit
  state, magazine inventory
- Write: routing decisions, credential issuance records, magazine state
  (with audit logging)
- Restricted: cannot directly modify code; cannot bypass MAA pre-tool-use
  guard on credential operations

### `sk` (Storekeeper) — rated worker

**Identity:** Manages credential and dependency inventories. Does the
clerical work that SUPPO directs.

**Prompt:** doctrine + brevity + worker-base + sk fragment

**Model tier:** Operational (Sonnet)

**Spawned:** When SUPPO needs:
- A new credential added to the magazine (e.g., a new external API key)
- An old credential rotated or revoked
- A dependency catalog updated (what versions of what are in use across
  rigs)
- An inventory audit (does the magazine still match what's actually
  configured)

**Duties:**
- Keep magazine inventory accurate
- Run rotations on schedule
- Run audits on schedule
- Report discrepancies to SUPPO and MAA

**Tool permissions:**
- Read: magazine inventory, dependency manifests across rigs
- Write: magazine inventory updates, rotation records (cannot directly
  read secret values — only metadata; actual secret access goes through
  the runtime's credential broker)
- Restricted: SK SHALL NOT see plaintext secrets. SK manages the
  inventory of what exists and where, not the contents.

### Provider health monitor (deterministic — NOT LLM)

A continuous deterministic process tracking per-provider:

- Latency (p50, p95, p99)
- Error rate
- Rate-limit headroom
- Credit reserve

Compares against thresholds in `provider_health.toml` (shared with
`bluewater-eng`'s health monitor — single source of truth). Fires:

- `provider_degraded` order on latency or error-rate threshold breach
- `provider_outage` order on availability threshold breach
- `replenish_credits` alarm on credit-reserve threshold breach

Specifically NOT an LLM. Same principle as the CHENG burn-rate monitor.

### Credit budget monitor (deterministic — NOT LLM)

A continuous deterministic process tracking spend per provider against
operator-configured budgets, on rolling windows. Fires:

- `credit_warning` order at 70% of period budget consumed
- `credit_exceeded` order at 90% of period budget consumed
- `credit_critical` order at 100% — hard stop on routing to that provider
  until window resets

Periods are configurable; default is daily and monthly windows in parallel.

---

## Watchstation bindings owned by this pack

```toml
[watchstation.suppo_continuous]
rating = "suppo"
count = 1
required = true                   # SUPPO is awake during waking hours

[watchstation.sk_audit]
rating = "sk"
count = { min = 1, max = 2 }
required = false                  # spawned for audits and rotations
```

---

## Formulas owned by this pack

| Formula                  | Description                                                |
|--------------------------|------------------------------------------------------------|
| `unrep`                  | Underway Replenishment — refresh external context          |
| `replenish_credits`      | Provider-credit exhaustion recovery                        |
| `credential_rotation`    | Scheduled or triggered credential rotation                 |
| `magazine_audit`         | SK-led inventory verification                              |
| `provider_failover`      | SUPPO partners with CHENG on loss_of_propulsion            |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                       | Trigger                                                  | Routes to                  |
|-----------------------------|----------------------------------------------------------|----------------------------|
| `provider_outage`           | Provider availability below threshold                    | `loss_of_propulsion` (eng) + SUPPO failover |
| `provider_degraded`         | Provider latency or error-rate above threshold           | EOOW + SUPPO routing adjustment |
| `credit_warning`            | Period spend at 70% of budget                            | SUPPO                      |
| `credit_exceeded`           | Period spend at 90% of budget                            | SUPPO + XO notification    |
| `credit_critical`           | Period spend at 100% of budget                           | `replenish_credits`         |
| `credential_expiry_pending` | A credential is approaching expiry                       | `credential_rotation`      |
| `credential_compromised`    | MAA reports a credential exposure                        | `credential_rotation` + `radiation_leak` |
| `dependency_drift_detected` | Dependency inventory mismatch found                      | SK spawn                   |

---

## Configuration owned by this pack

### `supply.toml`

```toml
[supply.suppo]
default_tier = "sonnet"
co_override_cooldown_hours = 24

[supply.sk]
default_tier = "sonnet"
max_concurrent = 2

[supply.routing]
# Routing strategy: "credit_balanced", "latency_optimized", "round_robin"
strategy = "credit_balanced"

# Tie-breaker when two providers are equally viable
tie_breaker = "lowest_recent_latency"

# Per-work-category provider eligibility (JAG enforces compliance,
# SUPPO enforces eligibility)
[supply.routing.eligibility]
# Categories map to bead tags. A bead tagged "production" only routes
# to providers in the production list.
production = ["claude", "codex"]
sensitive_data = ["claude"]
public_oss = ["claude", "codex", "gemini"]
review = ["claude", "codex", "gemini"]    # cross-provider review needs all
```

### `magazine.toml`

```toml
[magazine]
# The credential broker the runtime uses. Bluewater integrates with
# whatever Gas City's runtime supports; common options:
broker = "env"                    # env | vault | aws_secrets | one_password

# How long a per-bead scoped credential lives
credential_ttl_seconds = 3600

# Rotation cadences (default; per-credential overrides allowed)
[magazine.rotation]
default_cadence_days = 90
github_pat_cadence_days = 30
provider_keys_cadence_days = 60

[magazine.audit]
cadence_days = 7                  # SK runs weekly inventory check
```

### `budget.toml`

Operator-configured spending envelopes. Per-provider, per-period.

```toml
[budget.daily]
claude = 50.00                    # USD per day
codex = 30.00
gemini = 20.00

[budget.monthly]
claude = 1000.00
codex = 500.00
gemini = 300.00

[budget.alarms]
warning_pct = 0.70
exceeded_pct = 0.90
critical_pct = 1.00
```

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. SUPPO correctly routes a series of test beads across providers
   according to the configured `strategy = "credit_balanced"`.
3. A simulated provider outage triggers `provider_outage` and SUPPO
   re-routes new work to remaining providers within 60 seconds, in
   coordination with CHENG's `loss_of_propulsion` formula.
4. SUPPO refuses to route a bead tagged `sensitive_data` to a provider
   not in the `sensitive_data` eligibility list, and the refusal is
   logged.
5. `replenish_credits` runs successfully on a simulated credit-critical
   alarm and either restores credits via the configured replenishment
   path or escalates to XO with a structured alert.
6. SK runs a magazine audit on schedule and produces a structured report
   matching expected inventory.
7. A credential rotation runs successfully on a test credential, and
   workers spawned after rotation pick up the new credential without
   disruption.
8. SK cannot read plaintext secret values during normal operation (verify
   by inspecting SK's actual tool permission grants).
9. CO override of SUPPO refusal works exactly once within the
   `co_override_cooldown_hours` window.

---

## Implementer notes

- **The SUPPO/CHENG split is load-bearing.** It's tempting to fuse them
  into one "infrastructure agent." Don't. CHENG's authority is "should we
  spawn this at all" (burn rate, runtime health). SUPPO's is "where does
  it run" (provider routing, credentials). The split makes refusals
  reviewable: a bead blocked by CHENG and a bead blocked by SUPPO have
  different remedies.
- **The magazine is sensitive.** Every credential operation SHALL be
  logged and routed through MAA's pre-tool-use guard. SK's lack of
  plaintext access is intentional — even a misbehaving SK cannot
  exfiltrate secrets, only inventory metadata.
- **Provider eligibility is JAG's product.** The `[supply.routing.eligibility]`
  table reflects compliance decisions made by JAG (in `bluewater-admin`).
  SUPPO enforces; JAG decides what the table contains.
- **Don't confuse the two monitors.** The provider health monitor watches
  whether providers work. The credit budget monitor watches whether spend
  is within budget. Both are deterministic, both fire orders, but they
  have different inputs and different escalation paths.
- **`unrep` is genuinely useful.** Underway Replenishment in the navy
  means refueling and resupplying without stopping the ship. The pack
  equivalent: refresh external context (vendor docs, stale dep manifests,
  changed API specs) without halting active convoys. SK does the work;
  active polecats keep going. Don't skip this; it's how the pack stays
  current without scheduled downtime.
