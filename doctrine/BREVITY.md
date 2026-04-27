# Brevity Protocol

The brevity protocol is a constrained vocabulary for **agent-to-agent**
communication within Bluewater. It exists for two reasons:

1. **Token economy.** A naive ack like "Thanks, I have received your message
   and will now proceed to do the thing you asked. Here is my plan…" can
   cost 50–100 tokens. The brevity equivalent is `WILCO`. Across thousands
   of inter-agent messages per convoy, the savings are not optional.

2. **Disambiguation.** A defined vocabulary forecloses on the failure mode
   where one agent says "OK" and another agent reads it as "OK, and here's
   my modification" or "OK, but with reservations." `ROGER` means received-
   and-understood. `WILCO` means will-comply. `NEGAT` means refuse. There
   is no ambiguous middle.

This protocol applies to communication **between agents only**. Agents
communicating with humans (Discord, dashboard, mail-to-operator) use
normal prose. Agents calling tools use the tool's native interface.

---

## Vocabulary

### Acknowledgments

| Code         | Meaning                                                                  |
|--------------|--------------------------------------------------------------------------|
| `ROGER`      | Received and understood. Does NOT imply you will act.                    |
| `WILCO`      | Will comply. Implies receipt, understanding, and intent to execute.      |
| `NEGAT`      | Refuse or unable. SHALL be followed by a one-line reason in plain prose. |
| `STANDBY`    | Received, hold while I work on it. Imposes a duty to respond again.      |

### Queries

| Code            | Meaning                                                              |
|-----------------|----------------------------------------------------------------------|
| `INTERROGATIVE` | I have a question. Followed by the question in plain prose.          |
| `SAY AGAIN`     | I did not receive or could not parse. Resend.                        |
| `VERIFY`        | I think I heard X but want confirmation. Followed by what you heard. |

### Status

| Code           | Meaning                                                               |
|----------------|-----------------------------------------------------------------------|
| `EXECUTING`    | Now performing the action. Implicit transition out of `WILCO`.        |
| `COMPLETE`     | Action finished successfully. SHALL include bead reference if any.    |
| `FAILED`       | Action did not complete. SHALL include reason and any partial state.  |
| `HOLDING`      | Paused, awaiting condition or order.                                  |

### Priority

| Prefix          | Meaning                                                              |
|-----------------|----------------------------------------------------------------------|
| `BREAK BREAK`   | Urgent traffic interrupting normal flow. Reserved for casualty alerts. |
| `FLASH`         | Highest priority. Reserved for safety conditions and CO orders.      |
| `IMMEDIATE`     | High priority, but normal flow can briefly continue.                 |
| (no prefix)     | Routine.                                                             |

### Termination

| Code        | Meaning                                                                  |
|-------------|--------------------------------------------------------------------------|
| `OUT`       | End of transmission. No reply expected.                                  |
| `OVER`      | End of transmission. Reply expected.                                     |
| `BREAK`     | End of one thought, beginning of another, in the same transmission.      |

---

## Required usage

### When acknowledging an order

The first word of any agent-to-agent reply to an order SHALL be one of:
`ROGER`, `WILCO`, `NEGAT`, or `STANDBY`. Any further content (e.g., reason
for refusal, ETA estimate) follows on the same line in plain prose.

**Wrong:**
> "Thanks for the order. I will now proceed to fix the bug in the
> authentication module. Here is my plan: first I'll check out the
> branch, then I'll run the tests, then I'll…"

**Right:**
> `WILCO. ETA 8 minutes. OUT`

### When refusing

Any refusal SHALL begin with `NEGAT` and include exactly one line of
reason. Multi-paragraph explanations of refusals are prohibited; the
sender is the wrong audience for them. If an explanation is needed, file a
bead and reference it.

**Right:**
> `NEGAT. Rating GM2 not authorized for production-touching beads. OVER`

### When asking a question

Questions SHALL begin with `INTERROGATIVE` and include the specific
question. No preamble.

**Wrong:**
> "Hi, I hope you're doing well. I had a quick question if you have a
> moment. I was looking at the convoy and I noticed that…"

**Right:**
> `INTERROGATIVE: Bead gt-fjk23 has dependency gt-fjk22 marked complete
> but no merge SHA. Is the merge pending? OVER`

### When transmitting urgent traffic

Casualty alarms and safety conditions SHALL be prefixed with `BREAK BREAK`
to interrupt ongoing traffic. The receiving agent SHALL stop its current
transmission and acknowledge the urgent traffic first.

**Right:**
> `BREAK BREAK. FLASH. Secret detected in commit a3f4b21. Suggesting
> radiation_leak evolution. OVER`

### When ending transmissions

`OVER` if a reply is expected. `OUT` if not. Failure to terminate is a
discipline lapse and SHOULD be corrected by the receiving agent.

---

## Examples of full exchanges

### Order and acknowledgment

> XO → OOD: `Spawn one GM2 polecat against bead gt-x4k7m. OVER`
>
> OOD → XO: `WILCO. OUT`
>
> *(later)*
>
> OOD → XO: `Polecat fox-7 dispatched to gt-x4k7m. EXECUTING. OUT`

### Status query

> CO → XO: `INTERROGATIVE: Status on convoy gt-fj22. OVER`
>
> XO → CO: `5 of 8 beads landed. 2 in review. 1 blocked on
> gt-fjk19 awaiting external dependency. ETA 2 hours pending external. OVER`

### Refusal

> XO → MAA: `Allow polecat fox-3 to read /etc/secrets. OVER`
>
> MAA → XO: `NEGAT. /etc/secrets is outside MAA pre-tool-use allowlist.
> SUPPO holds credentials. Route via SUPPO. OVER`

### Casualty alert

> Sonar (deterministic) → OOD via order: `BREAK BREAK. FLASH. CI failed
> on main, last 3 commits. Sound general_quarters. OUT`

### Question with read-back

> Helmsman → BMOW: `INTERROGATIVE: Bead gt-x4k7m says merge to main.
> VERIFY: target branch is main. OVER`
>
> BMOW → Helmsman: `ROGER. Target branch confirmed: main. Two-key launch
> required. OUT`

### Watch turnover (excerpt)

> Outgoing OOD → Incoming OOD:
> ```
> Passdown brief.
> Contacts: 3 active convoys (gt-fj22, gt-x4k, gt-aa9). 12 active polecats.
> Casualties: None.
> Night orders: CO directs no flight_ops 0200-0600 (provider rate reset).
> Anomalies: Codex provider showing 2x latency since 0145. SUPPO notified.
> Recommendations: Watch for retries on gt-aa9. OVER
> ```
>
> Incoming OOD: `ROGER. Read-back: 3 convoys (gt-fj22, gt-x4k, gt-aa9),
> 12 polecats, no casualties, no flight_ops 0200-0600, codex latency
> elevated, gt-aa9 needs retry watch. VERIFY. OVER`
>
> Outgoing OOD: `ROGER VERIFY. I am relieved. OUT`
>
> Incoming OOD: `I have the conn. OUT`

---

## Implementing this document

The implementing agent SHALL:

1. Produce `prompts/brevity.md` containing the vocabulary and required-usage
   sections, suitable for inclusion in every Bluewater agent's prompt.

2. Implement a brevity linter (a deterministic check, not an LLM) that
   reads agent-to-agent messages from the event bus and flags violations.
   Specifically:
   - Replies to orders that don't begin with `ROGER`, `WILCO`, `NEGAT`, or
     `STANDBY`
   - Refusals without a reason line
   - Questions not prefixed with `INTERROGATIVE`
   - Transmissions over a configurable token threshold (default 60 tokens)
   - Missing `OVER` / `OUT` terminators

3. Route linter findings to the COB. Repeated violations by the same agent
   instance trigger a low-priority training-queue bead.

4. Configure the protocol's enforcement level in `bluewater/brevity.toml`:
   - `level = "advisory"` — log violations, don't reject
   - `level = "strict"` — reject malformed messages and require resend
   - `level = "off"` — disabled (for debugging only; SHALL NOT be the
     default)

The default level is `advisory` for the first 30 days of a fresh ship's
operation, then `strict`. This gives newly-spawned agents a window to
adapt while still measuring.

---

## What this protocol is not

- It is **not** a wire protocol. Agents still send normal text messages.
  The protocol governs the *opening words and shape* of those messages.
- It is **not** a programming language. Agents do not compile brevity codes
  to actions.
- It does **not** apply to human-facing communication. Discord messages,
  dashboard text, and mail to the operator use plain prose.
- It does **not** apply to tool calls. Tool inputs and outputs use the
  tool's native interface.
- It does **not** prohibit clarifying detail. `WILCO` followed by a one-line
  ETA or note is fine; `WILCO` followed by a four-paragraph plan is not.

The test for whether a message is brevity-compliant: would a real-navy
radio operator recognize the shape of it? If yes, you're fine. If it sounds
like a customer service email, you're not.
