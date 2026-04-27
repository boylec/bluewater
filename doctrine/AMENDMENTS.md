# Amendments

This file records every change to doctrine after v0.1.0 spec snapshot
(commit `9015a5f`). Each entry follows the same shape: who, when, what
changed, and *why* (preferably with a Board of Inquiry reference). Doctrine
is meant to be stable; if you find yourself amending it often, that is a
signal worth examining — see `RATING_PROGRESSION.md` and the
`doctrine_amendment` evolution in `BATTLE_BILL.md`.

## Amendment process

1. Write proposed unified diff against the relevant doctrine markdown.
2. Provide rationale, with Board of Inquiry reference if the amendment
   was triggered by a casualty.
3. Run a casualty drill or simulation that exercises the changed
   behavior (where applicable).
4. Get COB sign-off (or, for ship-wide doctrine, CO sign-off).
5. Append an entry below.

---

## A0001 — Gas City schema reality check (build-time)

**Date:** 2026-04-26
**Originator:** Implementing agent (Phase 1 grounding pass per `BUILD_INSTRUCTIONS.md`).
**Reason:** The spec was written against Gas City `>= 0.13.4`. By v0.1.0 build
time the SDK had reached `v1.0.0` (released 2026-04-21) and Pack V2 became
the active layout. The following spec assumptions had drifted; we update
the pack to reflect current reality, per BUILD_INSTRUCTIONS step 1
("when the spec disagrees with current Gas City on schema, Gas City wins").

**Findings and resolutions:**

1. **Minimum Gas City version.** Spec said `>= 0.13.4`; we require
   `>= 1.0.0`. Pack V2 is the only supported layout.
2. **Order trigger taxonomy.** Spec used `alarm | scheduled | command | order`.
   Real Gas City uses `cooldown | cron | condition | event | manual` (per
   `internal/orders/order.go`). Mapping applied throughout:
   - `alarm` → `event` (with `on = "<event-name>"`)
   - `scheduled` → `cron` (with `schedule = "<cron-expr>"`) or `cooldown`
   - `command` → `manual`
   - `order` (formula step) → not an order at all; encoded as a
     `[[steps]]` entry inside the parent formula
3. **`pack.toml` schema field.** Required: `[pack] name`, `schema = 2`,
   `version`, `requires_gc`, `description`, optional `[imports.<name>]
   source = "..."`. (Note: the Go comment in `config.go` says "currently 1"
   but every shipped Pack V2 example uses `schema = 2`; the tests and
   reality are 2.)
4. **Per-rating model tier.** Encoded as `option_defaults = { model = "opus"
   | "sonnet" | "haiku" }` on each agent. Provider-per-rating (for
   cross-provider concurrence) is `provider = "claude" | "codex" | "gemini"`.
5. **Doctrine and brevity prompt layer.** Spec's `prompts/doctrine.md` and
   `prompts/brevity.md` become Pack V2 template fragments at
   `template-fragments/doctrine.template.md` and `template-fragments/brevity.template.md`,
   each wrapped in `{{ define "doctrine" }} ... {{ end }}` blocks. Agents
   include them via `inject_fragments = ["doctrine", "brevity"]` (V1 spelling)
   or `append_fragments` (V2 spelling). This preserves prompt-cache reuse
   across all agents.
6. **Rating layout.** Spec's `ratings/<rate>.toml` becomes Pack V2's
   `agents/<rate>/agent.toml` + `agents/<rate>/prompt.template.md`. The
   "rating" concept (a stamped agent profile with prompt + tools + tier) maps
   exactly onto a Pack V2 agent; striker → rated → chief progression is
   modelled by swapping `prompt_template` and `option_defaults` atomically
   on the agent identity (per `RATING_PROGRESSION.md`).
7. **Order "gates" renamed to "triggers".** Confirmed in v1.0.0 changelog;
   no impact on us as we use the new spelling everywhere.
8. **`global_fragments` deprecated for `append_fragments` at workspace level.**
   We use the V2 spelling.

**Result:** The pack is built against Gas City `v1.0.0` Pack V2 from the start;
no V1 layout is shipped. Where spec text in `doctrine/` references prompt
files (`prompts/doctrine.md`), the canonical mechanism is now template
fragments — content is identical, plumbing is V2.

---

## A0002 — Real-navy rate-and-department alignment

**Date:** 2026-04-27
**Originator:** v0.1.0 build, post-review correction.
**Reason:** The first pass placed several rates in the wrong departments,
used outdated rate codes, and underpopulated some departments. The pack
is themed on real-navy doctrine; the rate-to-department mapping should
match real-navy organization for the metaphor to hold up.

**Findings and resolutions:**

1. **ET (Electronics Technician) is a Combat Systems rate, not Engineering.**
   ET works combat-system electronics (sensors, fire-control wiring,
   targeting comms). Moved out of Engineering's role description into
   Combat Systems'. Engineering now uses EM (Electrician's Mate) for
   electrical infrastructure work.
2. **DC (Damage Controlman) is an Engineering rate, not Combat Systems.**
   DCs handle hull integrity, fire/flood/smoke response, and engineering-
   side casualty work. Moved into Engineering's role description.
3. **CS (Culinary Specialist; "Cook") is a Supply rate, not Medical.**
   Real Navy: Cook is in Supply department (logistics/services). Moved
   out of Medical. Medical now contains only HM (the only LLM-bearing
   Medical rate). The agent dir name remains `cook` to avoid
   abbreviation collision with "CS" = Combat Systems.
4. **SK (Storekeeper) is retired; LS (Logistics Specialist) is current.**
   The Navy merged SK into LS in 2009. Renamed agent dir, watchstation
   bindings, and battle-bill rate references.
5. **HM, MA, YN are the rate codes;** "Corpsman", "Master-at-Arms",
   "Yeoman" are role names. Renamed agent dirs to rate codes. Role-name
   prose in prompts is preserved (it's what other agents call you).
6. **Engineering needed proper rates after losing ET.** Added EM
   (Electrician's Mate, signal/event-bus/electrical work), MM
   (Machinist's Mate, daemon/process/scaling work), HT (Hull Maintenance
   Tech, filesystem/dolt/data-layer hygiene). DC moves into Engineering
   alongside these.
7. **Combat Systems gained MN (Mineman).** Maps cleanly to vulnerability
   detection / static analysis / dependency CVE scanning — finding and
   disarming threats before they activate. MN partners with MA (the
   pre-tool-use guard); MN sweeps the field, MA blocks at the gate.
8. **Operations gained OS (Operations Specialist) and IS (Intelligence
   Specialist).** OS is the rated personnel under CIC Watch Officer. IS
   does intel analysis (paired with CT for collection).
9. **Undesignated tier added.** SN (Seaman), FN (Fireman), AN (Airman)
   represent the entry rate — the default landing for new agent
   identities. BM (Boatswain's Mate) leads working parties of
   undesignated personnel on the smallest beads (mess-decks duty).
10. **CT not split.** Real navy splits Cryptologic Tech into CTI / CTN
   / CTR / CTT; v0.1.0 keeps a single `ct` rate and notes the
   specializations in the prompt. Splitting is deferred to a later
   release where the workload differentiation justifies separate
   profiles.

**Files affected:** `agents/{em,mm,ht,mn,os,is,bm,sn,fn,an}/` (added),
`agents/{corpsman→hm, sk→ls, maa→ma, yeoman→yn}/` (renamed),
`watchstation_bindings.toml`, `pack.toml` named_session entries,
`rating.toml` per-rate overrides, several prompts that referenced rates
by old name. `agents/et/` and `agents/dc/` content updated to reflect
their correct departments; directory paths unchanged (rate codes did
not change for those, only department assignment did).
