# Contributing to Bluewater

Bluewater is a [Gas City](https://github.com/gastownhall/gascity) pack
implementing naval doctrine for multi-agent orchestration. Contributions
fall into two categories with different review bars.

## Ordinary changes (bugs, formula tweaks, agent prompts, docs)

Standard PR practice. Open an issue describing the bug or improvement,
fork, branch, write tests where applicable, open a PR. Tag a reviewer.

## Doctrine changes

Anything under `doctrine/` (DOCTRINE, BATTLE_BILL, WATCH_BILL, BREVITY,
RATING_PROGRESSION, GLOSSARY) is held to a higher bar. Doctrine is meant
to be stable across years, and is the prompt-cached base every agent on a
ship inherits. See [`doctrine/AMENDMENTS.md`](doctrine/AMENDMENTS.md) for
the amendment process. In short:

1. Open an issue or draft PR with the proposed unified diff.
2. State the rationale, ideally with a Board of Inquiry reference if a
   casualty drove the amendment.
3. Run a casualty drill or simulation exercising the changed behavior.
4. Get COB sign-off (for crew-affecting amendments) or CO sign-off (for
   ship-wide doctrine).
5. Append an entry to `doctrine/AMENDMENTS.md` and merge.

## Tests

Acceptance tests live in [`docs/spec/ACCEPTANCE.md`](docs/spec/ACCEPTANCE.md).
A clean `gc init` + `gc pack add bluewater` + smoke-test convoy must pass
all acceptance criteria before tagging a release.

Pack-internal linters that must stay green:

- **Watchstation-binding lint** — every named watchstation referenced in
  any formula has a binding in `watchstation_bindings.toml`.
- **Battle-bill coverage lint** — every formula in `battle_bill.toml`
  exists at the path it names.
- **Brevity lint** — agent-to-agent traffic samples conform to the
  brevity protocol vocabulary at the configured enforcement level.

## Code of conduct

Be respectful. Disagreements are settled through Board of Inquiry, not
in comments. There is no shore patrol; please don't make us invent one.
