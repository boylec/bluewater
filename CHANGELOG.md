# Changelog

All notable changes to Bluewater are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/); the project
adheres to [Semantic Versioning](https://semver.org).

## [0.1.0] — 2026-04-26

Initial release. Naval-doctrine multi-agent orchestration as a Gas
City Pack V2 pack.

### Added

- **Umbrella pack `bluewater`** plus eight department sub-packs:
  - `bluewater-eng` — CHENG, EOOW, ET; token-burn governance
  - `bluewater-supply` — SUPPO, SK; provider routing, credentials
  - `bluewater-admin` — Yeoman, MAA, JAG; records, security, compliance
  - `bluewater-medical` — Cook (deterministic), Corpsman; agent health
  - `bluewater-ops` — OPS, CIC Watch, QM, Lookouts, Sonar, CT
  - `bluewater-cs` — CSO, FC, GM, DC, Helmsman; the kill chain
  - `bluewater-air` — Air Boss + 7 flight-deck colors; carrier deploys
  - `bluewater-discord` — Quarterdeck Watch; intake adapter
- **Wardroom** in the umbrella: CO (Strategic/Opus), XO, OOD (always-on),
  COB (Strategic/Opus), CSOOW (GQ-only). Cross-provider distribution:
  CO=claude, XO=codex, COB=gemini, OOD=claude, CSOOW=codex.
- **Doctrine layer** (template fragments injected into every agent):
  doctrine + brevity, sourced from `doctrine/DOCTRINE.md` and
  `doctrine/BREVITY.md` (kept canonical at `doctrine/`).
- **Battle Bill** (`battle_bill.toml`) — 24 named evolutions across
  routine, operational, casualty, administrative.
- **Watchstation bindings** (`watchstation_bindings.toml`) — every
  watchstation referenced anywhere bound to a rating + count + required
  flag, including cross-provider constraint for adversarial reviewers.
- **Watch Bill** (`watch_bill.toml`) — context-pressure thresholds and
  handoff-quality scoring weights.
- **Brevity protocol** with deterministic linter (default `advisory`,
  COB-promoted to `strict` after 30 days).
- **Schedule** for every scheduled evolution (morning quarters, POD,
  eight o'clock reports, liberty call, field day, change of command,
  replenish credits).
- **Mandatory formulas:** `general_quarters`, `liberty_call`,
  `watch_turnover`, `plan_of_the_day`, `morning_quarters`,
  `eight_o_clock_reports`, `man_overboard`, `sea_and_anchor_detail`
  (CS variant + Air variant), `board_of_inquiry`, `captains_mast`,
  `rating_board`.
- **Optional formulas:** `field_day`, `unrep`, `flight_ops`,
  `sigint_collection`, plus casualty formulas (`fire_in_compartment`,
  `flooding`, `loss_of_propulsion`, `collision_at_sea`, `grounding`,
  `radiation_leak`, `replenish_credits`, `convoy_landed_review`,
  `striker_review`, `doctrine_amendment`, `change_of_command`,
  `discord_intake_route`, `maa_review_tool_call`).
- **Orders** (event handlers): `pre_tool_use`, `pr_opened`,
  `ci_failed_on_main`, `prod_alert`, `convoy_landed`, `agent_stalled`,
  `provider_outage`, `provider_credit_low`, `burn_rate_exceeded`,
  `secret_leaked`, `forbidden_action_executed`,
  `merge_conflict_persistent`, `discord_message`, `striker_review`.
- **Examples:** `examples/small_ship.city.toml` (umbrella + transitive
  imports of mandatory sub-packs) and `examples/carrier.city.toml`
  (full eight-pack deployment).
- **Mintlify docs:** `docs/install.mdx`, `docs/quickstart.mdx`,
  `docs/first_watch.mdx`.
- **Spec preserved at `docs/spec/`** — original `BUILD_INSTRUCTIONS`,
  `ARCHITECTURE`, `CATALOG`, `ACCEPTANCE`, all sub-pack `REQUIREMENTS`.
- **CONTRIBUTING.md** points at the doctrine amendment process for
  doctrine changes; standard PR practice for everything else.
- **doctrine/AMENDMENTS.md** with the first amendment (A0001)
  recording the schema drift between the spec (Gas City >= 0.13.4) and
  current reality (v1.0.0 with Pack V2 active). The pack is built
  against current Gas City; spec-vs-reality deltas (trigger taxonomy,
  per-agent provider/model defaults, template-fragment plumbing) are
  documented there.

### Build statistics

- 153 files (96 TOML, 51 markdown, 3 mdx, 1 shell), ~6800 lines of
  pack content (excluding the preserved spec).
- All TOML parses (Python `tomllib`).
- `battle_bill.toml` lint: all 24 evolutions reference existing
  formula files; all 29 named watchstations have bindings.

### Known unfinished items

- **Acceptance test against a real `gc init`** is not part of this
  release. The build was structurally validated (TOML syntax + battle-
  bill coverage); end-to-end smoke testing on a Gas City rig per
  `docs/spec/ACCEPTANCE.md` is the v0.1.1 gate.
- **CI** is not configured; no GitHub Actions workflow ships with
  v0.1.0.
- **Real-world rating-board telemetry plumbing** (the OTEL pipeline
  feeding `striker_review` weighted-score computation) is documented
  but not implemented as a runnable check; this lands in a follow-up.
- **`option_defaults = { model = "..." }`** assumes Gas City's provider
  preset registers `opus`, `sonnet`, `haiku` choices; if your provider
  config exposes different model identifiers, override per-agent.
- **Discord intake** depends on `gastownhall/gascity-packs/discord-intake`
  being available as an import; verify upstream version compatibility
  before installing carrier-class.

[0.1.0]: https://github.com/boylec/bluewater/releases/tag/v0.1.0
