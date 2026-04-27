# Pack: `bluewater-medical` (Medical Department)

Medical owns agent health: detecting when an agent is stuck, looping,
saturated, or otherwise non-productive, and intervening before the
casualty propagates.

The naval analogy is exact. Real navies have a Corpsman — not a doctor,
but a trained intervention specialist who keeps people functional or
stabilizes them until they can be evacuated. The Cook is more
unexpected: morale is a real engineering concern, and the galley is the
first place to notice when something is off with the crew.

---

## Pack identity

- **Name:** `bluewater-medical`
- **Department:** Medical
- **Department Head:** None — Cook and Corpsman report directly to XO
- **Required by umbrella?** Yes (mandatory — agent health monitoring is
  not optional for any pack running unattended)

---

## Agents

### Cook (deterministic — NOT LLM)

Wait. The Cook is **not** an agent in the LLM sense. The Cook is a set of
deterministic monitors that watch for early warnings of agent
unhealthiness, exactly the way a real-navy ship's cook is the first to
notice when the crew is dragging.

Implementing the Cook as an LLM session would be expensive and slow. The
patterns the Cook watches for are tractable to deterministic detection:

| Pattern                          | Detection method                                      |
|----------------------------------|-------------------------------------------------------|
| Agent stuck (no progress)        | No commits / no bead transitions / no tool calls in N |
| Looping (repeating same actions) | Hash recent tool-call sequences; flag near-duplicates |
| Context bloat                    | Track context utilization growth rate                  |
| Model degradation                | Statistical decline in task completion rate over session |
| Hung session                     | Process alive but no event activity                    |
| Brevity collapse                 | Sudden growth in agent-to-agent message size          |
| Despawn failure                  | Session marked complete but process still running     |

The Cook fires alarms via orders. The Corpsman is the LLM-billing agent
that responds.

### `corpsman` (Hospital Corpsman) — active intervention

**Identity:** Responds to Cook-detected agent health issues.

**Prompt:** doctrine + brevity + chief + corpsman fragment

**Model tier:** Operational (Sonnet)

**When awakened:**
- On `agent_stalled` order (Cook detected no-progress pattern)
- On `agent_looping` order (Cook detected repetition)
- On `agent_context_saturated` order (Cook detected bloat)
- On `man_overboard` formula invocation
- On request from OOD or XO for an agent intervention

**Duties:**
- Assess the unhealthy agent's state
- Choose intervention from the playbook:
  - **Nudge** — send a brevity-coded prompt asking for status; sometimes
    that's enough to break a stuck loop
  - **Refresh** — checkpoint the agent's progress to bead store, despawn
    the agent, respawn fresh with the checkpoint as priors
  - **Quarantine** — kill the agent without respawn; route the bead back
    to OOD for redispatch
  - **Evacuate** — checkpoint and stop; surface to a human for review
    (used when intervention itself appears unsafe)
- Log the intervention in the Yeoman log
- Report patterns of recurring failures to COB

**Tool permissions:**
- Read: agent state (sessions, recent tool calls, context utilization),
  bead state, Yeoman log
- Write: nudge messages, despawn signals, respawn requests, intervention
  records
- Restricted: cannot directly modify code; cannot bypass MAA pre-tool-use
  guard on respawn credential issuance

### Cook monitor scripts (deterministic)

A bundle of scripts under `monitors/cook/`. Each script:

- Runs on schedule or on event-bus trigger
- Compares observed state against thresholds
- Fires the appropriate order on detection

Required monitors:

| Monitor name              | Watches                                              |
|---------------------------|------------------------------------------------------|
| `cook_stall.sh`           | Agents with no event activity in window              |
| `cook_loop.sh`            | Tool-call sequence hash repetition                   |
| `cook_context.sh`         | Per-session context utilization growth rate          |
| `cook_degradation.sh`     | Bead-completion-rate decline over session lifetime   |
| `cook_zombie.sh`          | Sessions marked complete but process still alive     |
| `cook_brevity_collapse.sh`| Agent message size growth rate                       |

Each fires an order with the affected agent's identifier and the pattern
detected.

---

## Watchstation bindings owned by this pack

```toml
[watchstation.corpsman_oncall]
rating = "hm"                     # Hospital Corpsman rating
count = { min = 1, max = 2 }
required = false                  # Corpsman is awakened on demand
```

The Cook has no watchstation because the Cook is not an agent.

---

## Formulas owned by this pack

| Formula                  | Description                                                |
|--------------------------|------------------------------------------------------------|
| `man_overboard`          | Stalled or hung agent recovery                             |
| `agent_refresh`          | Checkpoint and respawn an agent with priors                |
| `agent_quarantine`       | Kill an agent without respawn                              |
| `evacuation`             | Halt agent and surface to human for review                 |
| `health_audit`           | Periodic ship-wide agent health review                     |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                          | Trigger                                          | Routes to                  |
|--------------------------------|--------------------------------------------------|----------------------------|
| `agent_stalled`                | `cook_stall.sh` detection                        | `man_overboard`            |
| `agent_looping`                | `cook_loop.sh` detection                         | Corpsman intervention      |
| `agent_context_saturated`      | `cook_context.sh` detection                      | Corpsman → `agent_refresh` |
| `agent_degrading`              | `cook_degradation.sh` detection                  | Corpsman intervention      |
| `agent_zombie`                 | `cook_zombie.sh` detection                       | Corpsman → cleanup         |
| `agent_brevity_collapse`       | `cook_brevity_collapse.sh` detection             | Corpsman + COB notification |
| `health_audit_due`             | Cron: configurable (default daily)               | `health_audit`             |

---

## Configuration owned by this pack

### `medical.toml`

```toml
[medical.corpsman]
default_tier = "sonnet"
max_concurrent = 2

[medical.cook.thresholds]
stall_window_minutes = 15           # no activity for 15 min → stalled
loop_hash_window = 5                # last 5 tool calls considered for loop
loop_repeat_threshold = 3           # 3 near-duplicate sequences = loop
context_growth_rate_per_min = 0.05  # >5% per min growth = bloat alarm
degradation_window_beads = 10       # last 10 beads considered
degradation_rate_threshold = 0.30   # 30% drop in completion rate = alarm
zombie_grace_seconds = 60           # session "complete" but alive 60s = zombie
brevity_collapse_factor = 3.0       # 3x growth in message size = collapse
```

### `playbook.toml`

Maps detected patterns to intervention choices:

```toml
[playbook.stalled]
first_action = "nudge"
on_nudge_no_response = "refresh"
on_refresh_no_progress = "quarantine"

[playbook.looping]
first_action = "refresh"
on_refresh_loops_again = "quarantine"

[playbook.context_saturated]
first_action = "refresh"             # always refresh; nudge won't help

[playbook.degrading]
first_action = "refresh"

[playbook.zombie]
first_action = "quarantine"          # not a recovery situation

[playbook.brevity_collapse]
first_action = "nudge"
note = "Brevity collapse often signals upstream stress; check what changed"
```

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. All Cook monitor scripts run on schedule and produce structured
   detection records.
3. A simulated stalled agent triggers `agent_stalled`, which invokes
   `man_overboard`, which awakens Corpsman, which executes the
   playbook's `nudge` first action — verified end to end.
4. A simulated looping agent triggers `agent_looping` and Corpsman
   correctly chooses `refresh` per the playbook.
5. A simulated context-saturated agent is correctly checkpointed,
   despawned, and respawned with priors via `agent_refresh`.
6. A zombie session (process alive after marked complete) is
   successfully cleaned up via `agent_quarantine`.
7. `health_audit` runs daily and produces a structured report covering
   all active agents.
8. Corpsman cannot be implemented as a polling LLM (verify the Cook is
   deterministic by checking implementation; this is an architectural
   constraint, not just a config).

---

## Implementer notes

- **The Cook is the load-bearing innovation here.** It's the difference
  between "we have an agent watching agents" (expensive, recursive,
  fragile) and "we have monitors watching agents" (cheap, deterministic,
  reliable). Build the Cook scripts first, then the Corpsman that
  responds to them.
- **Loop detection is harder than it looks.** Naive hashing of tool
  calls catches obvious loops (same git command 5 times) but misses
  semantic loops (different commands accomplishing the same nothing).
  Start with naive; iterate as Boards of Inquiry surface missed cases.
- **`agent_refresh` is the most common intervention.** Most unhealthy
  agents are unhealthy because their context is saturated. Refresh —
  checkpoint, despawn, respawn with priors — solves it cleanly. This is
  also why context-pressure-based watch rotation (see
  [`../../doctrine/WATCH_BILL.md`](../../doctrine/WATCH_BILL.md)) is the
  preventive form of the same intervention.
- **Don't make Corpsman thoughtful.** Corpsman runs on Sonnet, not Opus.
  Its decisions are mostly playbook lookups. The thinking part is in the
  playbook, not in the agent.
- **Evacuation is rare and important.** When Corpsman chooses
  `evacuation`, it's saying "I don't trust my own intervention." This
  is the right answer in some cases (e.g., the agent is suspected of
  having been prompt-injected; intervening might propagate the
  injection). When evacuation fires, surface immediately to a human;
  this is one of the few cases the pack legitimately stops and waits.
- **Health audit is mostly trend-finding.** Daily it produces "agents
  trending healthy / unhealthy / no signal." The interesting output is
  the trend report, surfaced to COB and XO at `morning_quarters`.
