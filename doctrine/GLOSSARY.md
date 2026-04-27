# Glossary

A two-way translation between Bluewater's naval vocabulary and Gas City's
primitives. Read this if you are a Gas City user new to naval terms, or a
naval-leaning user new to Gas City.

---

## Naval term → Gas City primitive

| Naval term              | Gas City primitive                                         |
|-------------------------|-----------------------------------------------------------|
| Ship                    | A `gc start` city instance running this pack              |
| Pack                    | (literal: same word) the umbrella `bluewater` pack        |
| Department              | Sub-pack (e.g., `bluewater-cs`)                           |
| Rate / Rating           | A stamped agent profile (prompt + tools + tier)           |
| Watchstation            | A slot in a formula or the watch bill                     |
| Position (in line org)  | An agent identity at a specific level (CO, XO, OOD…)      |
| Agent (the sailor)      | An agent identity with persistent history                 |
| Watch                   | An ongoing live session bound to a watchstation           |
| Evolution               | A formula                                                 |
| Casualty                | A condition triggering an alarm-class evolution           |
| General Quarters        | The `general_quarters.toml` formula                       |
| Battle Bill             | `bluewater/battle_bill.toml`, a structured routing table  |
| Watch Bill              | `bluewater/watch_bill.toml`, the watch rotation rules     |
| Plan of the Day         | The `plan_of_the_day.toml` formula's daily output         |
| Night Orders            | CO directives propagated via Yeoman across watch turnovers|
| Standing Orders         | Doctrine + per-rate prompt fragments                      |
| Captain's Log           | The Yeoman's log file                                     |
| Quarterdeck             | Pack intake (Discord adapter, GitHub webhooks)            |
| Bridge                  | The OOD's session and adjacent watchstanders               |
| CIC (Combat Info Ctr)   | The CIC Watch agent fusing lookout + sonar feeds          |
| Pilot House             | The dashboard view of the ship's current state            |
| Engine Room             | `bluewater-eng`'s runtime — the LLM/tmux/MCP plumbing     |
| Magazine                | Where credentials/secrets live (managed by SUPPO)         |
| Galley                  | Cook agent's monitoring scripts                           |
| Sick Bay                | Corpsman intervention queue                               |
| Wardroom                | Officers' command space (CO, XO, dept heads)              |
| Goat Locker / CPO Mess  | The chiefs' shared knowledge layer (COB-led)              |
| Mess Decks              | Where undesignated personnel start                        |
| Gunnery / Fire Control  | The targeting layer between plan and execution            |
| Damage Control          | Bug-fix and casualty response (DCs in `bluewater-cs`)     |
| Refinery (in Gas Town)  | Bors-style merge queue. Bluewater inherits this.          |
| Deck Force              | Polecats and gunner's mates under the Bosun               |
| Sea Detail              | The deploy-formula choreography                           |
| Convoy (in Gas Town)    | A bundle of beads. Bluewater uses this term unchanged.    |
| Bead (in Gas Town)      | A unit of work. Unchanged.                                |
| Rig (in Gas Town)       | A project / git repo. Unchanged.                          |
| Mountain Convoy         | Epic-scale convoy with autonomous stall detection         |
| Sling                   | Assigning a bead to a worker. Unchanged.                  |
| Hook                    | Git worktree as work container. Unchanged.                |
| Mail (in Gas Town)      | Inter-agent message queue. Unchanged.                     |
| Seance                  | Predecessor session query mechanism. Unchanged.           |
| Wasteland               | Federated trust network across cities. Unchanged.         |

---

## Gas City primitive → Naval term

| Gas City primitive                | Naval term                                       |
|-----------------------------------|--------------------------------------------------|
| `gc init`                         | Commission a new ship                            |
| `gc start`                        | Underway                                         |
| `gc session attach mayor`         | Talk to the XO (in Bluewater; Gas Town's Mayor)  |
| `gc pack add`                     | Bring a department aboard                        |
| `bd create "..."`                 | File a bead (work item)                          |
| `bd convoy create`                | Form up a convoy                                 |
| `gt sling <bead> <worker>`        | Assign work                                      |
| `gt nudge`                        | Bell — get an agent's attention                  |
| `gt prime`                        | Brief the agent (load context)                   |
| `gt handoff`                      | Watch turnover                                   |
| `gt seance`                       | Talk to your predecessor                         |
| `gt escalate`                     | Sound a casualty alarm                           |
| `bd formula list`                 | Show the evolutions library                      |
| `bd cook <formula>`               | Pre-compose a formula (build the molecule)       |
| `bd mol pour <formula>`           | Run an evolution                                 |
| `gc dashboard`                    | Pilot house view                                 |

---

## Roles by department

### Wardroom (umbrella `bluewater`)

- **CO** — Captain. Strategic command.
- **XO** — Executive Officer. Execution command.
- **OOD** — Officer of the Deck. Has the conn during their watch.
- **CSOOW** — Combat Systems Officer of the Watch. Splits from OOD at GQ.
- **COB** — Chief of the Boat. Senior enlisted, runs the Goat Locker.

### Operations (`bluewater-ops`)

- **OPS** — Department Head, Operations.
- **CIC Watch Officer** — Fuses lookout + sonar into tactical picture.
- **QM** — Quartermaster (Navigator). Plans the Plan of the Day.
- **Lookouts** — Deterministic monitors with overlapping arcs.
- **Sonar (STG/STS)** — Passive pattern-matching on event streams.
- **CT (CTN/CTR/CTI/CTT)** — Cryptologic Technicians. SIGINT and threat intel.

### Combat Systems (`bluewater-cs`)

- **CSO** — Department Head, Combat Systems.
- **FC** — Fire Controlmen. Targeting solutions (intent → bead parameters).
- **GM** — Gunner's Mates. Implementation polecats.
- **Helmsman / BMOW** — Lands the merge.
- **DC** — Damage Controlmen. Bug fix and casualty response.

### Engineering (`bluewater-eng`)

- **CHENG** — Chief Engineer. Technical authority on token burn.
- **EOOW** — Engineering Officer of the Watch. CHENG's watch surrogate.
- **ET** — Electronics Technicians. Pack infrastructure (tmux, MCP, runtime).

### Supply (`bluewater-supply`)

- **SUPPO** — Department Head, Supply. Provider routing and credit budget.
- **SK** — Storekeepers. Manage credential and dependency inventories.

### Air (`bluewater-air`)

- **Air Boss** — Department Head, Air. Coordinates flight ops (deploys).
- **Yellow / Aircraft Handler** — Director, signals movement.
- **Purple / Grapes** — Fuel — secrets/credentials provider for deploy.
- **Red / Ordnance** — The artifact being deployed.
- **Green / Cat-Arresting Gear** — CI/build system.
- **Brown / Plane Captain** — Service-owning engineer agent.
- **Blue / Chocks-Chains** — Guardrails: rollback, feature flags.
- **White / Safety** — Compliance/policy gate at the deck edge.

### Medical (`bluewater-medical`)

- **Cook** — Crew morale = agent-health early warning. Detects stuckness.
- **Corpsman** — Intervention. Active recovery from agent failure.

### Admin (`bluewater-admin`)

- **Yeoman** — Captain's log. Records all watch turnovers, decisions, board
  outcomes.
- **MAA** — Master-at-Arms. Pre-tool-use guard. Stops bad actions.
- **JAG / Sea Lawyer** — License, compliance, contractual review.

### Adapter (`bluewater-discord`)

- **Quarterdeck Watch** — Discord intake. Authenticates, logs, and
  routes inbound traffic to the appropriate department.

---

## Concepts that don't map cleanly

A few naval concepts were considered and deliberately **not** translated:

- **Saluting and ceremony.** Token waste with no operational benefit.
- **Uniform regulations.** No uniform for agents.
- **Liberty card / shore patrol.** Liberty Call is a real evolution
  (rest periods); shore patrol is not modeled.
- **Captain's gig.** No physical transport.
- **Boat deck.** Use of small craft for inspections is not modeled; if a
  light-touch inspection workflow is needed, file it as a `field_day`-class
  formula instead.

A few Gas City concepts that don't map to a naval term:

- **Wisps** (ephemeral beads). No clean naval analogy. Use the term
  unchanged.
- **Polecat** (ephemeral worker). The closest naval analog is "working
  party" but that's a temporary group of personnel from a watch, not the
  worker itself. Bluewater retains "polecat" but rates can be applied to
  them (a polecat with FC rating is an FC polecat).
- **The Wasteland** (federated trust network). Stays as the Wasteland.
  The closest naval analog is "convoy escort" or "task force" but neither
  fits the federated-trust mechanism.

---

## When in doubt

Use the naval term in pack-internal documents (battle bill, watch bill,
formulas, agent prompts) and the Gas City term in user-facing
documentation (README, install guide, gc command examples). Agent prompts
SHALL use naval terminology because that is what their doctrine layer
trains them on. Tool inputs and CLI output SHALL use Gas City terminology
because that is what `gc` and `bd` understand.
