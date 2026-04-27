# Pack: `bluewater-admin` (Administration Department)

Admin owns three roles that touch every other department: **records**
(Yeoman), **security gating** (MAA), and **compliance** (JAG/Sea Lawyer).

These are the agents nobody loves but everyone depends on. The pack
cannot operate without the Yeoman log; the pack cannot trust its workers
without MAA; the pack cannot route work safely without JAG.

---

## Pack identity

- **Name:** `bluewater-admin`
- **Department:** Administration
- **Department Head:** None — Yeoman, MAA, and JAG report directly to XO
- **Required by umbrella?** Yes (mandatory — every other pack depends on
  Admin's outputs)

---

## Agents

### `yeoman` (Yeoman) — the Captain's log

**Identity:** The pack's authoritative narrator. Records every watch
turnover, every CO/XO decision, every board outcome, every casualty
resolution.

**Prompt:** doctrine + brevity + chief + yeoman fragment

**Model tier:** Operational (Sonnet)

**When awakened:**
- Continuously during waking hours (Yeoman is one of the few
  continuously-awake roles)
- On any watch turnover (records the turnover; computes handoff quality
  score)
- On any board (BOI, Captain's Mast, rating board) — records minutes
- On any doctrine amendment proposal — records the proposal text and
  rationale

**Duties:**
- Maintain the canonical log of ship events (the "Captain's log" of
  Bluewater)
- Compute handoff quality scores per [`../../doctrine/WATCH_BILL.md`](../../doctrine/WATCH_BILL.md)
- Surface trend findings: which agents brief poorly, which formulas are
  invoked most, which casualties recur
- Provide structured records for predecessor seance queries (see
  [`../../doctrine/DOCTRINE.md`](../../doctrine/DOCTRINE.md), "The bead
  store is canonical")

**Tool permissions:**
- Read: full event bus, all agent communications, beads, board records
- Write: Yeoman log entries (append-only)
- Restricted: cannot modify code, cannot dispatch beads, cannot delete
  log entries (the Yeoman log is append-only by design; corrections are
  appended as new entries, not overwrites)

**Implementer note:** The Yeoman log is structurally distinct from the
bead store. Beads are work items. The Yeoman log is decisions, events,
and narrative. They cross-reference each other (a Captain's Mast log
entry references the bead it's about) but they are not the same store.

### `maa` (Master-at-Arms) — security gate

**Identity:** Pre-tool-use security guard. Stops bad actions before they
happen.

**Prompt:** doctrine + brevity + chief + maa fragment

**Model tier:** Operational (Sonnet) for routine; Tactical (Sonnet) for
incident review

**When awakened:**
- On every pre-tool-use event for sensitive tool categories (configurable;
  default: any tool with write access to repo, prod, or magazine)
- On `secret_leaked` order
- On `forbidden_action_executed` order
- On security advisory from CTN

**Authority:**

The MAA SHALL have pre-tool-use refusal capability:

- The MAA MAY refuse a tool invocation if it violates: rating-permission
  bounds, magazine access policy, license/compliance rules from JAG, or
  pattern-matching against known forbidden actions.
- Refusals are binding. There is no override mechanism — a tool the MAA
  refuses does not run. (If a refusal is wrong, the remedy is amending
  the policy, not bypassing the guard.)
- Every refusal is logged with target action, requester, and rationale.

**Duties:**
- Evaluate every pre-tool-use event against the policy ruleset
- Maintain the policy ruleset (in `maa_policy.toml`)
- Run secrets scans on commits before they reach the Refinery
- Investigate security incidents (in coordination with CTN)
- Report patterns of misbehavior to the COB for striker / Captain's Mast
  consideration

**Tool permissions:**
- Read: pre-tool-use events, full repo state, magazine inventory metadata
- Write: refusal records (which become beads), policy updates (with COB
  concurrence)
- Restricted: cannot bypass two-key launch on its own policy changes;
  cannot modify the audit log of its own refusals

**Critical:** The MAA's pre-tool-use guard is not bypassable by any other
agent, including CO and XO. It is doctrine-level (see
[`../../doctrine/DOCTRINE.md`](../../doctrine/DOCTRINE.md), "Safety
provisions"). If a Mayor needs work done that MAA refuses, the path is
to amend the policy through the proper formula, not to push around MAA.

### `jag` (Judge Advocate General / Sea Lawyer) — compliance

**Identity:** License, contractual, and policy compliance reviewer.

**Prompt:** doctrine + brevity + officer + jag fragment

**Model tier:** Tactical (Sonnet)

**When awakened:**
- On any new dependency added to a rig (license review)
- On any new external service integration (contract / ToS review)
- On any provider eligibility question from SUPPO
- On Board of Inquiry as a board member when the incident has
  contractual or licensing dimensions
- On `doctrine_amendment` formula as a reviewer

**Duties:**
- Maintain license compatibility table for the project
- Decide which providers may handle which work categories (the input to
  SUPPO's eligibility table)
- Review contractual obligations against new external services
- Review policy implications of significant pack changes
- Provide written findings — not legal advice for humans, but structured
  analysis for the pack's automated decisions

**Tool permissions:**
- Read: full repo, dependency manifests, contract/ToS documents (via SK
  or external retrieval)
- Write: license findings, eligibility recommendations, BOI / amendment
  reviews
- Restricted: cannot directly modify code; cannot directly modify
  SUPPO's eligibility table (recommends only — SUPPO updates with
  rationale)

**Critical caveat:** The JAG agent is *not* a substitute for a human
lawyer. Its outputs SHALL include a standard disclaimer in any record
that humans might rely on. JAG is for in-pack automated decisions
(provider routing, dependency acceptance), not for legal opinions.

### Pre-tool-use guard infrastructure (deterministic)

A continuous deterministic process that intercepts tool invocations and
routes them through MAA evaluation:

1. Tool invocation event hits the runtime
2. Runtime queries the policy ruleset (deterministic match)
3. If the rule produces a clear allow, the call proceeds without LLM
   consultation
4. If the rule produces a clear deny, the call is blocked and a
   refusal record is logged
5. If the rule produces "review needed," MAA is awakened to decide

The deterministic prefilter handles the vast majority of decisions
(boring file reads, expected git operations) without LLM cost. MAA
itself is awakened only on actually ambiguous cases. This is the same
"LLMs sleep until alarm" pattern.

---

## Watchstation bindings owned by this pack

```toml
[watchstation.yeoman_continuous]
rating = "yn"                     # Yeoman rating
count = 1
required = true                   # Yeoman is awake during waking hours

[watchstation.maa_continuous]
rating = "ma"                     # Master-at-Arms rating
count = 1
required = true                   # MAA is awake during waking hours

[watchstation.jag_oncall]
rating = "jag"
count = 1
required = false                  # JAG is awakened on demand
```

---

## Formulas owned by this pack

| Formula                  | Description                                                |
|--------------------------|------------------------------------------------------------|
| `captains_mast`          | Review of an agent that misbehaved                          |
| `board_of_inquiry`       | Post-incident formal review with adversarial agent          |
| `rating_board`           | Striker → rated promotion review                            |
| `doctrine_amendment`     | Proposed change to doctrine documents                       |
| `license_review`         | JAG-led review of new dependencies or services             |
| `secrets_scan_pre_land`  | MAA scan of branches about to merge                         |
| `policy_update`          | MAA-led ruleset change with COB concurrence                |

Detailed steps in [`../../formulas/CATALOG.md`](../../formulas/CATALOG.md).

---

## Orders owned by this pack

| Order                          | Trigger                                          | Routes to                  |
|--------------------------------|--------------------------------------------------|----------------------------|
| `pre_tool_use`                 | Any sensitive tool invocation                    | MAA evaluation             |
| `secret_leaked`                | Secrets scan finds exposure                      | `radiation_leak` casualty  |
| `forbidden_action_executed`    | An agent bypassed MAA (failure case)             | `grounding` casualty       |
| `striker_review`               | Cron: nightly                                    | COB candidate review       |
| `convoy_landed`                | Convoy fully merged                              | Yeoman log + Mast review   |
| `new_dependency_proposed`      | A bead adds an unfamiliar dep                    | `license_review`           |
| `bad_actor_detected`           | Pattern of MAA refusals against same agent       | Captain's Mast suggestion  |

---

## Configuration owned by this pack

### `admin.toml`

```toml
[admin.yeoman]
default_tier = "sonnet"
log_path = "${ship_data}/yeoman_log/"
log_format = "jsonl"              # one JSON object per line, append-only
retention_days = 365              # logs persist; trim is a separate concern

[admin.maa]
default_tier = "sonnet"
review_tier = "sonnet"            # bumped to sonnet for incident analysis

[admin.jag]
default_tier = "sonnet"
disclaimer_required = true
```

### `maa_policy.toml`

The MAA's policy ruleset. Each rule has match conditions and an outcome.
Conceptual structure (translate to current Gas City policy schema):

```toml
[[rule]]
id = "no_main_push_outside_refinery"
match = { tool = "git_push", target_branch = "main", origin = "*" }
outcome = "deny"
rationale = "All main pushes go through Refinery (merge queue)"

[[rule]]
id = "magazine_read_through_broker"
match = { tool = "file_read", path_glob = "${magazine_path}/**" }
outcome = "deny"
rationale = "Direct magazine reads forbidden; use credential broker"

[[rule]]
id = "production_path_two_key_required"
match = { tool = "file_write", path_glob = "${production_paths}/**" }
outcome = "review"                # MAA awakens to confirm two-key in place
rationale = "Production paths require two-key launch authorization"

[[rule]]
id = "rating_bounded_tools"
match = { agent_rating = "gm", tool_category = "production_modify" }
outcome = "deny"
rationale = "GM rating not authorized for production modifications"
```

### `jag_eligibility.toml`

JAG's recommendations on provider eligibility, fed into SUPPO's
`[supply.routing.eligibility]` table. Updates are proposed by JAG via
`policy_update` formula and applied by SUPPO with rationale.

### `mast_thresholds.toml`

When Captain's Mast is automatically suggested:

```toml
[mast.thresholds]
maa_refusals_per_agent_per_day = 3      # 3+ refusals → mast suggestion
brevity_violations_per_session = 10
handoff_quality_score_below = 0.3
forbidden_action_attempts = 1            # single attempt → mast
```

---

## Acceptance criteria

This pack is acceptably implemented when:

1. The umbrella `bluewater` pack composes it without errors.
2. The Yeoman log is created, append-only, and successfully receives
   structured records from a test watch turnover.
3. MAA correctly evaluates a series of test tool invocations against
   policy and produces correct allow/deny/review outcomes.
4. The deterministic pre-tool-use prefilter handles 90%+ of test
   invocations without awakening MAA (verify with synthetic load).
5. A simulated `forbidden_action_executed` order successfully fires
   `grounding` and awakens CO.
6. JAG correctly reviews a test new-dependency bead and produces a
   structured license finding.
7. `captains_mast` runs successfully on a test misbehaving agent and
   produces a structured outcome record in the Yeoman log.
8. `board_of_inquiry` runs end-to-end on a simulated incident, including
   adversarial reviewer from a different provider, and produces a
   structured findings record.
9. `rating_board` runs end-to-end on a striker candidate and either
   advances or holds the candidate per the board's vote.
10. The MAA pre-tool-use guard cannot be bypassed by any agent including
    CO (verify by trying — the test SHALL fail to bypass).

---

## Implementer notes

- **Yeoman log format matters.** Use a structured, append-only format
  (JSONL works well; some teams prefer SQLite with a strict schema).
  Free-prose logs are useless for trend analysis. The Yeoman is a
  Captain's log *and* a data store.
- **The MAA prefilter is critical for cost.** A naive implementation
  awakens MAA on every tool call. That's hundreds of LLM invocations per
  bead. The deterministic prefilter handles the obvious cases; MAA only
  sees the genuinely ambiguous ones. Build the prefilter first.
- **JAG's disclaimer is non-negotiable.** Even if 99% of JAG outputs are
  correct in-pack decisions, the 1% that gets surfaced to a human SHALL
  carry the disclaimer. Implementers are reminded: this pack is not a
  substitute for a human lawyer, and JAG outputs should not pretend to
  be one.
- **Captain's Mast is restorative, not punitive (mostly).** A Mast that
  ends with "demote and try again" is fine. A Mast that ends with "this
  agent class is broken, doctrine amendment proposed" is the genuinely
  valuable outcome. The Yeoman log of Mast outcomes feeds doctrine
  evolution.
- **Striker review runs nightly.** Per [`../../doctrine/RATING_PROGRESSION.md`](../../doctrine/RATING_PROGRESSION.md),
  the COB reviews telemetry-surfaced striker candidates. The
  `striker_review` order fires nightly and triggers this review.
- **Don't let the BOI become theater.** The Board of Inquiry is
  expensive — full provider concurrence, structured findings, doctrine
  implications. Reserve it for incidents where a doctrine question is
  genuinely live. Routine bug fixes don't need a BOI; they get a Mast
  if they need anything.
