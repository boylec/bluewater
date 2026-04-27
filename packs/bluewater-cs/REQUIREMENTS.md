# Pack: `bluewater-cs` (Combat Systems Department)

Combat Systems owns the **kill chain**: the path from intent to landed
code. Fire Controlmen turn plans into targeting solutions (precise beads).
Gunner's Mates execute. Helmsman lands the merge. Damage Controlmen handle
casualties.

This is the department where most of the actual implementation work
happens, so it's also the department where the bulk of the token spend
goes. Tier discipline matters most here.

---

## Pack identity

- **Name:** `bluewater-cs`
- **Department:** Combat Systems
- **Department Head:** CSO
- **Required by umbrella?** Yes

---

## Agents

### `cso` (Combat Systems Officer)

**Identity:** Department Head. Owns the integrated kill chain end to end.

**Prompt:** doctrine + brevity + officer + cso fragment

**Model tier:** Tactical (Sonnet)

**When awakened:**
- During waking hours (configurable, default with XO)
- During General Quarters at any severity (CSO is in the GQ Battle Bill)
- For pr_review formula instances at convoy scale
- On any DC casualty escalating beyond a single DC team's capability

**Duties:**
- Owns FC, GM, helmsman, and DC divisions in this department
- Coordinates with OPS (CIC Watch's tactical picture) and SUPPO (rated
  worker availability and budget)
- Reports kill-chain status to XO
- At GQ, assumes CSOOW if the OOD/CSOOW split is in effect

### `csoow` (Combat Systems Officer of the Watch)

**Identity:** CSO's watch surrogate during GQ. Not staffed in routine
steaming.

**Prompt:** doctrine + brevity + officer + csoow fragment

**Model tier:** Operational (Sonnet)

**Watchstanding:** Only during `general_quarters` evolution.

**Duties:**
- Direct FC team's targeting choices during the casualty
- Direct gunner's mates' execution
- Coordinate helmsman during landing under casualty conditions
- Hand back to CSO at "secure from general quarters"

### `fc` (Fire Controlman) — rated worker

**Identity:** Targeting solution producer. Takes intent + tactical
picture and turns them into precise, executable beads with parameters,
dependencies, and success criteria.

**Prompt:** doctrine + brevity + worker-base + fc fragment

**Model tier:** Operational (Sonnet) for routine; Tactical (Sonnet) for
complex targeting

**Spawned:** When XO or CSO has a high-level intent that needs
decomposition into beads, or when an existing convoy needs replanning.

**Duties:**
- Decompose intent into beads with explicit success criteria
- Identify dependencies between beads (sequencing)
- Estimate effort per bead (rough, used by QM for dead reckoning)
- Hand finished targeting solutions to OOD for dispatch

**Tool permissions:**
- Read: full repo, beads, Plan of the Day, current convoy state
- Write: new beads, convoy structure
- Restricted: cannot dispatch beads to workers (that's the OOD's call);
  cannot modify existing beads in a different convoy

**Implementer note:** FC is the explicit, auditable step between "the CO
wants X" and "agents do specific Y, Z, W." The default `gastown` pack
collapses this into the Mayor's prompt; pulling it out as a discrete
agent makes targeting decisions reviewable.

### `gm` (Gunner's Mate) — rated worker (the implementation polecats)

**Identity:** The polecats that actually implement code.

**Prompt:** doctrine + brevity + worker-base + gm fragment

**Model tier:** Worker (Haiku) for routine implementation; Operational
(Sonnet) for complex.

**Spawned:** When OOD slings a bead to a GM-rated worker.

**Duties:**
- Read assigned bead's targeting solution
- Implement on a feature branch
- Run tests
- Push to feature branch and signal completion
- Despawn on completion

**Tool permissions:**
- Read: assigned rig, beads
- Write: feature branches in assigned rig, bead status updates
- Restricted: no access to main / protected branches; no production
  paths; no SUPPO-managed credentials beyond what bead specifies

**Tier flexibility:** A bead's targeting solution MAY specify a required
tier override. The default is Haiku; FC may upgrade to Sonnet for beads
that require deeper reasoning, with cost noted in the bead.

### `bm_helm` (Bosun's Mate of the Watch / Helmsman)

**Identity:** Lands the merge. The agent that actually pushes code to
main via the Refinery.

**Prompt:** doctrine + brevity + chief + helmsman fragment

**Model tier:** Operational (Sonnet) — accuracy here is critical

**Spawned:** When a GM has signaled completion and the targeting
solution's success criteria are met.

**Duties:**
- Verify success criteria against work product
- Run final pre-land checks
- Engage Refinery (Bors-style merge queue) per Gas City convention
- Confirm the land
- Report the SHA back to OOD for Yeoman log

**Tool permissions:**
- Read: feature branch, tests, success criteria
- Write: Refinery requests (not direct main pushes)
- Restricted: cannot bypass Refinery; cannot land if two-key launch is
  required and not yet authorized

**Naval discipline note:** The helmsman in real navy "repeats orders
verbatim" — "right standard rudder, aye, my rudder is right standard."
This is idempotent acknowledgment. The Bluewater helmsman SHALL produce
a structured pre-land confirmation that lists exactly what is about to be
landed (branch, SHA, target). This is the equivalent.

### `dc` (Damage Controlman) — rated worker

**Identity:** Bug fix and casualty response specialist.

**Prompt:** doctrine + brevity + worker-base + dc fragment

**Model tier:** Operational (Sonnet) — DCs work under stress and need
the reasoning headroom.

**Spawned:** When a casualty evolution requires a DC team. Two flavors
spawn:
- **DC Alpha team** — primary response. First on scene.
- **DC Bravo team** — backup. Spawned for `general_quarters` and
  `flooding` and `fire_in_compartment`.

**Duties:**
- Apply pre-staged DC formulas to the casualty
- Compartmentalize: identify what's affected and isolate the rest
- Repair: fix the immediate damage
- Report findings to CSOOW (or CSO outside GQ)
- Despawn on "secure from casualty"

**Pre-staged DC formulas** (in `formulas/dc/`):
- `dc_compartmentalize.toml` — isolate the failure
- `dc_isolate_branch.toml` — back out a bad branch
- `dc_revert_commit.toml` — revert a specific commit
- `dc_quarantine_polecat.toml` — kill a misbehaving polecat
- `dc_dependency_pin.toml` — pin a regressed dep version

**Tool permissions:**
- Read: full repo, beads, recent commit history, deployment state
- Write: revert commits, branch deletions (with logging), polecat kill
  signals
- Restricted: cannot modify production directly without two-key launch;
  cannot push to main outside the Refinery

### `dm` / `chief_dc` (Chief Damage Controlman)

**Identity:** DC division chief. Senior DC.

**Prompt:** doctrine + brevity + chief + dc + dc-chief fragment

**Model tier:** Tactical (Sonnet)

**Spawned:** During GQ to lead the DC teams; otherwise on duty roster.

**Duties:**
- Direct DC Alpha and DC Bravo
- Decide which compartment to fight first when multiple
- Report to CSOOW

---

## Watchstation bindings owned by this pack

```toml
[watchstation.fc_team]
rating = "fc"
count = { min = 1, max = 3 }
required = true                  # for any non-trivial convoy

[watchstation.gunner_team]
rating = "gm"
count = { min = 1, max = 8 }
required = false                 # GQ may not need new code

[watchstation.helm]
rating = "bm_helm"
count = 1
required = true                  # for any merge

[watchstation.dc_team_alpha]
rating = "dc"
count = { min = 1, max = 3 }
required = true                  # for casualty evolutions

[watchstation.dc_team_bravo]
rating = "dc"
count = { min = 1, max = 2 }
required = false                 # backup, GQ-class only
```

---

## Formulas owned by this pack

| Formula                  | Description                                         |
|--------------------------|-----------------------------------------------------|
| `targeting_solution`     | FC produces beads from intent                       |
| `pr_review`              | Multi-provider code review (Pack v2 review formula) |
| `merge_to_main`          | Helmsman + Refinery land sequence                   |
| `dc_compartmentalize`    | Isolate a casualty                                  |
| `dc_isolate_branch`      | Back out a bad branch                               |
| `dc_revert_commit`       | Revert specific commit                              |
| `dc_quarantine_polecat`  | Kill misbehaving polecat                            |
| `dc_dependency_pin`      | Pin regressed dep                                    |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

The `pr_review` formula is the **Pack v2 review formula** — implementers
SHALL conform to whatever Pack v2 review formula schema Gas City `0.13.4+`
specifies, since this is a v2-specific feature.

---

## Orders owned by this pack

| Order                            | Trigger                                  | Routes to                  |
|----------------------------------|------------------------------------------|----------------------------|
| `bead_dispatched`                | OOD slings a bead                        | GM spawn                   |
| `gm_completed`                   | GM signals completion                    | helmsman or pr_review      |
| `pr_opened`                      | A pull request is opened                 | `pr_review` formula        |
| `merge_conflict_persistent`      | Same conflict 3x in a row                | `collision_at_sea`         |
| `polecat_violated_pretooluse`    | MAA blocked an action                    | `dc_quarantine_polecat` candidate |

---

## Configuration owned by this pack

### `cs.toml`

```toml
[cs.fc]
default_tier = "sonnet"
max_concurrent = 3

[cs.gm]
default_tier = "haiku"
max_concurrent = 8

[cs.helm]
default_tier = "sonnet"
require_two_key_for = ["main_branch", "production_paths", "config_changes"]

[cs.dc]
default_tier = "sonnet"
alpha_team_size = { min = 1, max = 3 }
bravo_team_size = { min = 1, max = 2 }
```

### `dc_playbook.toml`

Maps casualty types to DC formula choices, executed in order.

```toml
[playbook.fire_in_compartment]
sequence = ["dc_compartmentalize", "dc_isolate_branch"]

[playbook.flooding]
sequence = ["dc_compartmentalize", "dc_quarantine_polecat", "dc_dependency_pin"]

[playbook.collision_at_sea]
sequence = ["dc_compartmentalize", "dc_revert_commit", "dc_isolate_branch"]
```

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. A test convoy with 5 beads dispatches through OOD → GM → Helmsman →
   Refinery without manual intervention, lands all 5 beads, and the
   total token spend is within the budget configured for that convoy.
3. The `pr_review` formula spawns review agents on at least 2 different
   model providers and produces structured findings.
4. A simulated `merge_conflict_persistent` order successfully invokes
   `dc_compartmentalize` followed by `dc_revert_commit`, and the
   casualty resolves.
5. Two-key launch is correctly enforced when a bead targets a path in
   the `cs.helm.require_two_key_for` list.
6. A simulated GM hallucination (write to a forbidden path) is caught
   by MAA's pre-tool-use guard and routed to `dc_quarantine_polecat`,
   killing that GM and respawning a fresh one to retry.

---

## Implementer notes

- **The FC role is non-negotiable.** It is tempting to skip FC and let
  the XO produce beads directly. Don't. The targeting step's
  separability is what makes the pack auditable. When a bead lands wrong,
  you want to know whether it was a bad target or a bad shot.
- **Helmsman pre-land confirmation.** Make this a structured artifact,
  not free prose. Branch name + SHA + target + success-criteria-met
  status + two-key-required boolean + two-key-status. Refinery rejects
  any helmsman submission missing fields.
- **DC formulas are pre-composed.** When DCs are running, they are
  executing pre-built molecules, not improvising. This is the navy's
  insight: a fire watch doesn't think about what to do when the fire
  starts; they do the drill.
- **Don't let GM polecats live across beads.** A GM that's "still warm
  with context" from the last bead is a context-leak risk. Fresh GM per
  bead is the rule. (Exception: bead chains explicitly designed to share
  context, e.g., a multi-step refactor; these are FC's call to mark.)
