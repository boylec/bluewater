# Pack: `bluewater-discord` (Discord Intake Adapter)

The Discord intake adapter is the **Quarterdeck** — the controlled
gateway through which off-ship traffic enters. Every visitor checks in,
gets recognized, and is escorted to the right department.

This sub-pack mirrors the dual-flow intake pattern from
`gastownhall/gascity-packs` (slash commands + ambient gateway events
with durable file-backed state — request_id, locks, receipts) and
adds a brevity-aware routing layer.

This sub-pack is **optional**. Ships that do not have a Discord guild
do not need it. Ships that do gain a clean, auditable, human-facing
interface to the pack.

---

## Pack identity

- **Name:** `bluewater-discord`
- **Department:** Adapter (no department head; reports to OOD)
- **Required by umbrella?** No (optional)

---

## Why this exists separately

Discord is one possible intake channel. GitHub webhooks are another.
Email is another. Each has its own authentication, message format,
durability characteristics, and security profile.

The pack-internal interface is the same regardless of intake source: a
structured request lands on the bead store with a quarterdeck stamp
(who, when, from where, what was requested), and the OOD picks it up.

This sub-pack implements **only Discord**. Other adapters
(`bluewater-github`, `bluewater-mail`) would be separate sub-packs
following the same pattern.

---

## Agents

### `quarterdeck_watch` (Quarterdeck Watch)

**Identity:** Inbound Discord traffic handler. Authenticates, logs,
classifies, and routes.

**Prompt:** doctrine + brevity + watch-base + quarterdeck fragment

**Model tier:** Worker (Haiku) for routine classification; Operational
(Sonnet) for ambiguous or sensitive traffic

**Watchstanding:** Continuous, but mostly idle. Wakes on inbound
Discord events.

**Duties:**
- Receive Discord events (slash commands and ambient gateway events)
- Authenticate the sender against the configured roster (which Discord
  user IDs map to which agent identities or which operator authorities)
- Classify the request: command (slash) vs. ambient chat vs. operator
  intent
- File a structured intake bead with quarterdeck stamp
- Acknowledge to Discord with brevity-formatted reply
- Route to OOD via the dispatch order

**Tool permissions:**
- Read: Discord guild config, sender roster, intake history
- Write: intake beads, Discord acknowledgment messages
- Restricted: cannot directly invoke evolutions; routes via OOD;
  cannot bypass MAA pre-tool-use guard for any sender-controlled
  parameter

**Authority:**
- Quarterdeck Watch SHALL refuse traffic from un-rostered senders
  with a brevity-formatted refusal. Refusals are logged.
- Quarterdeck Watch SHALL NOT take action on commands; it routes
  them. Action is taken by the agent in the chain (OOD then onward).

---

## Dual-flow intake (mandatory pattern)

This pack SHALL implement the same dual-flow pattern as
`gastownhall/gascity-packs` Discord adapter:

### Slash command flow

- Sender invokes `/cmd ...` in Discord
- Discord delivers a slash command interaction to the pack
- Quarterdeck Watch parses, authenticates, classifies
- Files a `request_id`-stamped intake bead with command parameters
- Acknowledges to Discord (`STANDBY` brevity, with `request_id` for
  tracking)
- Routes to OOD

### Ambient gateway flow

- Sender posts a message in a monitored channel
- Discord delivers gateway event
- Quarterdeck Watch parses, classifies (chat? complaint? feature
  request? casualty?)
- For non-actionable chat: log and ignore
- For actionable: file intake bead, route to OOD per Battle Bill

### Durability requirements

The pack SHALL maintain durable file-backed state for:

- **request_id**: every intake gets a unique ID, recorded
- **lock**: in-flight requests have a lock to prevent duplicate
  processing if Discord redelivers
- **receipt**: outbound acknowledgments are durably recorded so we can
  prove (and dedupe) that we replied

The state files SHALL be written to a configurable path (default:
`./quarterdeck/state/`), survive process restarts, and be queryable
by the Yeoman.

This is the same pattern in `gastownhall/gascity-packs` Discord
adapter — implementer SHOULD study that adapter as the reference
implementation before writing this one.

---

## Sender roster

```toml
[[sender]]
discord_id = "123456789012345678"      # Discord user snowflake
operator_authority = "captain"          # captain | xo | crew | guest
agent_identity = "operator_human_alice" # for tracking and seance

[[sender]]
discord_id = "234567890123456789"
operator_authority = "crew"
agent_identity = "operator_human_bob"
allowlist_commands = ["/status", "/seance", "/handoff"]
```

Authority levels map to which commands a sender can issue:

- **captain**: any command, including doctrine amendments and
  Captain's Mast invocation
- **xo**: any operational command; cannot amend doctrine
- **crew**: status, seance, file beads, comment on convoys; cannot
  invoke evolutions or amend doctrine
- **guest**: read-only; can query status and seance, cannot file
  beads

---

## Watchstation bindings owned by this pack

```toml
[watchstation.quarterdeck]
rating = "quarterdeck_watch"
count = 1
required = true                  # if this pack is composed
```

---

## Formulas owned by this pack

| Formula                    | Description                                 |
|----------------------------|---------------------------------------------|
| `intake_classify`          | Classify ambient gateway events             |
| `unauthorized_traffic`     | Standardized response to un-rostered senders|

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                       | Trigger                                  | Routes to               |
|-----------------------------|------------------------------------------|-------------------------|
| `discord_slash_command`     | Slash command interaction received       | Quarterdeck Watch       |
| `discord_gateway_event`     | Monitored channel message received       | Quarterdeck Watch       |
| `discord_unauthorized`      | Un-rostered sender                       | `unauthorized_traffic`  |
| `discord_command_routed`    | Quarterdeck classified and routed        | OOD                     |

---

## Configuration owned by this pack

### `discord.toml`

```toml
[discord]
guild_id = "${DISCORD_GUILD_ID}"        # populated from env or city.toml
monitored_channels = [
  { id = "${SHIP_BRIDGE_CHANNEL}", classify = "operational" },
  { id = "${SHIP_LOUNGE_CHANNEL}", classify = "ambient" },
]

[quarterdeck]
state_dir = "./quarterdeck/state"
lock_ttl_minutes = 5
receipt_retention_days = 30
```

### `roster.toml`

The sender roster per the schema above. Operators populate per
deployment.

### `command_authority.toml`

Maps slash commands to required authority levels:

```toml
[[command]]
name = "/status"
required_authority = "guest"

[[command]]
name = "/file_bead"
required_authority = "crew"

[[command]]
name = "/general_quarters"
required_authority = "captain"

[[command]]
name = "/captains_mast"
required_authority = "captain"
require_two_key = true
```

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors when
   `bluewater-discord` is in the operator's pack list.
2. A test slash command from a rostered sender:
   - Is received and authenticated
   - Produces a structured intake bead with request_id and quarterdeck
     stamp
   - Is acknowledged to Discord with `STANDBY` and request_id
   - Routes to OOD per Battle Bill
3. A test slash command from an un-rostered sender is refused with a
   brevity-formatted reply and the refusal is logged.
4. A test ambient gateway event in an "operational" channel is
   classified and either files an intake bead or is logged-and-ignored
   appropriately.
5. The durable state survives a pack restart: in-flight requests are
   recovered, locks are honored, receipts are not double-sent.
6. A test command requiring two-key launch (e.g., `/captains_mast`)
   correctly waits for the second key before routing onward.
7. The state directory's contents are queryable by the Yeoman for
   audit purposes.

---

## Implementer notes

- **Study the reference adapter first.** Before implementing this,
  the implementing agent SHALL study `gastownhall/gascity-packs`'s
  Discord adapter. The dual-flow pattern, the durability model, and
  the lock mechanism are non-trivial; the reference implementation
  has already worked through the edge cases. Re-deriving them invites
  bugs.

- **Authentication is not authorization.** Quarterdeck Watch
  authenticates (the sender is who they claim to be) and routes
  requests with their authority level. The actual authorization check
  (this command, this authority) happens in `command_authority.toml`
  and is enforced by the receiving agent (OOD or further down the
  chain). Don't conflate these two.

- **Durability is non-negotiable.** Discord can redeliver events.
  Your pack can restart. Without durable request_id, lock, and
  receipt, you get duplicate processing or lost acknowledgments. Both
  are very bad in a production pack.

- **Don't make Quarterdeck Watch smart.** Its job is classify and
  route. The temptation to have it interpret intent ("the user
  probably wants to file a bead about authentication") is high; resist
  it. Ambiguous traffic routes to OOD as ambiguous; OOD asks via
  brevity-formatted clarifying question if needed.

- **Two-key launch on Discord-initiated commands.** When a Discord
  command requires two-key launch (per `command_authority.toml`), the
  Quarterdeck Watch records the first key and waits for a second
  authorized sender to confirm. The structured workflow is the same as
  for internal two-key requirements; the `request_id` carries the
  state.

---

## Other intake adapters (out of scope here)

This pack handles only Discord. Other intake channels would be
separate sub-packs:

- **`bluewater-github`** — GitHub webhooks (issues, PRs, comments)
- **`bluewater-mail`** — Email-based intake (operator-friendly,
  asynchronous)
- **`bluewater-api`** — Direct HTTP API for programmatic intake
- **`bluewater-pager`** — PagerDuty or equivalent for casualty alarms

These are not in scope for v0.1.0 of Bluewater. The Quarterdeck Watch
pattern (authenticate, classify, durable intake, route to OOD) is the
template; future adapters reuse the structure.
