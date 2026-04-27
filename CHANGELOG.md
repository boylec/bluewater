# Changelog

All notable changes to Bluewater are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/); the project
adheres to [Semantic Versioning](https://semver.org).

## [0.1.1] — 2026-04-27

Same-day patch release. No new functionality; corrections,
accessibility, and gastown respect. See `doctrine/AMENDMENTS.md`
A0003 for the full record.

### Fixed

- **CLI commands across docs and prompts.** A complete audit against
  current `gastownhall/gascity` (v1.0.0) found ~28% of distinct
  invocations were invalid. Three of them were in load-bearing order
  `check` shell commands (`gc telemetry burn-rate`, `provider-health`,
  `credit-balance` — none of which are real subcommands), meaning the
  alarm pipeline didn't fire on a real install. Replaced with stub
  scripts under `scripts/` (`check-burn-rate.sh`,
  `check-provider-health.sh`, `check-provider-credits.sh`) plus a
  `scripts/emit-stub-telemetry.sh` that documents how to wire real
  signal in. Other CLI fixes: `gc events fire X --kind Y` →
  `gc event emit X --payload '{"kind":"Y"}'`; `gc events tail N
  --filter "k=v"` → `gc events --type X --since 30m`; `gc orders
  disable` → `enabled = false` + `gc reload`; `gc dolt status` →
  `gc doctor`; `--filter` → `--type` / `--payload-match`. Verified
  with grep.

### Changed

- **README is no longer hostile to gastown.** Rewrote the section
  framing: "Why this pack instead of `gastown`" → "When Bluewater
  fits"; "designed to run cheaper than gastown" → "designed for the
  cost envelope of gastown" with the actual mechanism (CHENG burn-rate
  authority + doctrine prompt-cache amortization). Lineage section
  expanded to acknowledge gastown explicitly as forefather.

### Added

- **Plain-English layer alongside the naval one.** The naval theming
  stays — it's the design's identity — but every term now has a
  software-engineering gloss alongside it.
  - New `docs/concepts.mdx` — plain-English walkthrough of the
    metaphor for readers without a Navy background (~700 words).
  - New `docs/glossary.mdx` — two-column lookup table covering ~50
    naval terms with their software-engineering meanings.
  - Every `agents/*/agent.toml`, `formulas/*.toml`, `orders/*.toml`
    got an "In plain SE terms:" line in its header comment block (90
    files updated).
  - Every `agents/*/prompt.template.md` got an "In plain English:"
    preamble immediately after the role headline (37 files updated).
  - README install code-block comments rewrote with SE-friendly
    language; department table gained "In SE terms" column; "New
    here?" banner at top points to concepts/glossary.
  - The four MDX docs (install, quickstart, use_cases, first_watch)
    got "background reading" callouts and inline first-use glosses.
- **`scripts/`** directory now hosts `cook-check.sh` (existing) plus
  the four new check/emit scripts.

### Build statistics (v0.1.1)

- 184 files (108 TOML, 60 markdown, 5 mdx, 5 shell), ~9100 lines of
  pack content.
- Lint: all 24 evolutions resolve; all 29 watchstations bound; all
  TOML parses; 100% plain-English coverage across
  agents/formulas/orders/prompts; zero invalid CLI invocations
  outside `docs/spec/` historical snapshot.

## [0.1.0] — 2026-04-27

Initial release. Naval-doctrine multi-agent orchestration as a Gas
City Pack V2 pack.

### Pack shape

The umbrella pack `bluewater` is the ship — it contains the wardroom
plus six required departments inline. Three optional sub-packs add
discrete capabilities.

**Required (in the umbrella):**

- **Wardroom** — CO (Strategic/Opus), XO (Tactical/Sonnet on a
  different provider than CO), OOD (always-on), COB (Strategic/Opus
  on a third provider for adversarial diversity), CSOOW (GQ-only).
- **Engineering** — CHENG (refusal authority on token burn), EOOW,
  EM (Electrician's Mate), MM (Machinist's Mate), HT (Hull Tech), DC
  (Damage Controlman).
- **Operations** — OPS, CIC Watch Officer, QM, OS (Operations
  Specialist), IS (Intelligence Specialist), CT (Cryptologic Tech),
  Lookouts and Sonar (deterministic — no LLM until alarm).
- **Combat Systems** — CSO, FC (Fire Controlman), GM (Gunner's Mate
  on Haiku — load-bearing cost decision), ET (Electronics Tech), MN
  (Mineman — vuln/static-analysis), Helmsman.
- **Supply** — SUPPO (refusal authority on credentials), LS
  (Logistics Specialist), CS (Cook — deterministic agent-health
  monitor).
- **Medical** — HM (Hospital Corpsman; intervenes on man_overboard).
- **Admin** — YN (Yeoman; durable log), MA (Master-at-Arms; pre-
  tool-use guard), JAG (advisory; license/compliance/BoI adversary).
- **Undesignated** — BM (Boatswain's Mate), SN (Seaman), FN (Fireman),
  AN (Airman) — the entry rate that strikers come from.

**Optional sub-packs (`packs/`):**

- `bluewater-air` — Air Boss + 7 deterministic flight-deck colors;
  `flight_ops` and `sea_and_anchor_detail` (Air variant takes
  precedence over CS variant when installed).
- `bluewater-discord` — Quarterdeck Watch on Discord.
- `bluewater-slack` — Quarterdeck Watch on Slack.

### Doctrine layer

Template fragments injected into every agent's prompt:

- `template-fragments/doctrine.template.md` — chain of command, five
  exceptions, brevity-is-law, watch-standing rules, safety provisions,
  token discipline.
- `template-fragments/brevity.template.md` — agent-to-agent
  vocabulary (ROGER/WILCO/NEGAT/STANDBY/INTERROGATIVE/etc.).

Backed by the original markdown sources at `doctrine/{DOCTRINE,
BATTLE_BILL, WATCH_BILL, BREVITY, RATING_PROGRESSION, GLOSSARY}.md`.

### Configuration data

- `battle_bill.toml` — 24 named evolutions across routine,
  operational, casualty, administrative; OIC + watchstations + formula
  + severity for each.
- `watchstation_bindings.toml` — every named watchstation bound to a
  rating + count + required flag, with cross-provider constraints for
  adversarial reviewers.
- `watch_bill.toml` — context-pressure rotation thresholds; handoff
  quality scoring weights; duty-day window.
- `brevity.toml` — enforcement level (advisory; COB-promoted to
  strict after 30 days).
- `schedule.toml` — cron entries for every scheduled evolution.
- `rating.toml` — six telemetry signal weights with per-rate
  overrides (DC weights drills, FC weights first-try, MN weights
  seance value, etc.).

### Formulas

**Mandatory:** `general_quarters`, `liberty_call`, `watch_turnover`,
`plan_of_the_day`, `morning_quarters`, `eight_o_clock_reports`,
`man_overboard`, `sea_and_anchor_detail`, `board_of_inquiry`,
`captains_mast`, `rating_board`.

**Specialty:** `field_day`, `unrep`, `flight_ops` (in air sub-pack),
`sigint_collection`, plus casualty formulas (`fire_in_compartment`,
`flooding`, `loss_of_propulsion`, `collision_at_sea`, `grounding`,
`radiation_leak`), administrative (`replenish_credits`,
`convoy_landed_review`, `striker_review`, `doctrine_amendment`,
`change_of_command`, `discord_intake_route`, `slack_intake_route`,
`maa_review_tool_call`).

**Worker:** `mol-bluewater-work` — the bluewater-native lifecycle
formula every rated worker uses (replaces gastown's
`mol-polecat-work`; bluewater is standalone).

### Orders (event handlers)

`pre_tool_use`, `pr_opened`, `ci_failed_on_main`, `prod_alert`,
`convoy_landed`, `agent_stalled`, `provider_outage`,
`provider_credit_low`, `burn_rate_exceeded`, `secret_leaked`,
`forbidden_action_executed`, `merge_conflict_persistent`,
`discord_message`, `slack_message`, `striker_review`.

### Examples + docs

- `examples/small_ship.city.toml` — single-import baseline.
- `examples/carrier.city.toml` — umbrella + air + discord + slack.
- `docs/install.mdx` — install walkthrough + per-rating
  provider/model tier table.
- `docs/quickstart.mdx` — six steps to a first ship + smoke-test convoy.
- `docs/use_cases.mdx` — eight concrete entry-point recipes (when you
  need to → you do → ship will → you verify by). The doc that
  answers "what do I actually do with this?"
- `docs/first_watch.mdx` — narrative walkthrough of one OOD watch
  including a flooding casualty and watch turnover.
- `docs/spec/` — original v0.1.0 specification preserved (BUILD_INSTRUCTIONS,
  ARCHITECTURE, sub-pack REQUIREMENTS, formulas/CATALOG, tests/ACCEPTANCE).

### Notes

- **Built against Gas City `>= 1.0.0`.** Pack V2 is the active layout;
  no V1 layouts ship. See `doctrine/AMENDMENTS.md` A0001 for the
  schema-drift record (spec was written against `>= 0.13.4`; reality
  caught up).
- **Real-navy rate alignment.** Per `doctrine/AMENDMENTS.md` A0002:
  ET is in Combat Systems (not Engineering), DC is in Engineering
  (not Combat Systems), CS-Cook is in Supply (not Medical), SK is
  retired in favor of LS (Logistics Specialist). Rate codes used as
  agent dir names: `hm`, `ma`, `yn`, `ls`. Added rates: EM, MM, HT,
  MN, OS, IS, BM, SN, FN, AN.
- **Bluewater is standalone.** No dependency on the gastown pack. The
  worker formula `mol-bluewater-work` replaces `mol-polecat-work`;
  Helmsman is our merge-queue agent (no "Refinery" borrowing).
- **Cross-provider distribution** across the wardroom: CO=claude,
  XO=codex, COB=gemini, OOD=claude, CSOOW=codex, MA=codex, JAG=gemini.
  Any two-key requiring CO+other naturally spans providers.

### Build statistics

- 167 files (108 TOML, 56 markdown, 4 mdx, 1 shell), ~7800 lines of
  pack content (excluding the preserved spec at `docs/spec/`).
- All TOML parses (Python `tomllib`).
- Battle-bill lint: all 24 evolutions reference existing formula
  files; all 29 named watchstations have bindings; all 47 ratings
  referenced in bindings have agent dirs.

### Known unfinished items

- **Acceptance test against a real `gc init`** is not part of this
  release. Build was structurally validated (TOML syntax + battle-
  bill coverage); end-to-end smoke testing on a Gas City rig per
  `docs/spec/ACCEPTANCE.md` is the v0.1.1 gate.
- **CI** is not configured; no GitHub Actions workflow ships with
  v0.1.0.
- **OTEL pipeline plumbing** for the rating-board `striker_review`
  weighted-score computation is documented but not implemented as a
  runnable check; this lands in a follow-up.
- **`bluewater-slack`** assumes an upstream `gastownhall/gascity-packs/
  slack-intake` adapter mirroring `discord-intake`. If the upstream
  isn't yet published when you install, consumers ship a local
  slack-intake adapter and override the import source.
- **CT split** into CTI/CTN/CTR/CTT (Cryptologic Tech specializations)
  is deferred; v0.1.0 keeps a single generic `ct` rate.
- **dc_oic seniority constraint** ("rating = dc, constraint =
  seniority >= po1") assumes Gas City supports a constraint syntax
  on watchstation bindings; if it doesn't yet, dispatcher selects any
  available DC rather than enforcing seniority — documented as
  v0.2.0 enhancement.

[0.1.1]: https://github.com/boylec/bluewater/releases/tag/v0.1.1
[0.1.0]: https://github.com/boylec/bluewater/releases/tag/v0.1.0
