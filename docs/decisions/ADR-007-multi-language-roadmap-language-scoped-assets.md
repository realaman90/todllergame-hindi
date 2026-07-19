# ADR-007 — Multi-language roadmap; language-scoped asset paths (2026-07-19) — Accepted

## What

The product's long-term shape is a multi-language toddler vocabulary game;
the **MVP remains Hindi-only exactly as specced** (3 scenes, 55 words,
`docs/product/SPEC.md` unchanged in scope). Two decisions take effect now,
while no app code exists:

1. **Asset paths gain a language dimension.** The asset loader convention
   amends from flat `<scene>_<slug>.mp3` (curriculum.md) to
   language-scoped `audio/<lang>/<scene>_<slug>.mp3` (BCP-47 codes:
   `hi`, `en`, `sv`, `fr`, `te`, `es`). Slugs stay language-neutral and
   stable. Same for any word-level visuals if they ever diverge by
   language. The `<scene>_<slug>` filename itself is unchanged.
2. **One universal world, not per-language art.** Scenes, characters, and
   object art are shared across all languages — the paper-cutout
   Indian-material-culture look is the brand signature, not a Hindi-only
   skin. Scene *names* localize; art does not. Culture-specific vocabulary
   rows (e.g., roti, daal) may be per-language swappable slots in each
   language's curriculum.

## Language sequencing

Gated by ADR-003 (shipped VO must be a native speaker) — a language enters
active development only when a native voice is committed:

| Phase | Language | Native voice |
|---|---|---|
| MVP (locked) | Hindi | founder |
| Next | English | founder |
| Next | Swedish | founder's wife |
| Later | French, Telugu, Spanish | native recruits (friends may cover te/es) |

For Swedish/English, classic public-domain rhyme structures already used
for the Hindi song adaptations (Bä bä vita lamm, Finger Family, etc.) can
appear in their original languages.

## Why

- Founder is a native Hindi and English speaker; his wife is a native
  Swedish speaker — three languages are recordable in-house to ADR-003's
  bar with zero recruiting. This makes multi-language a realistic roadmap
  rather than an aspiration.
- Competitors (e.g., RV AppStudios) treat non-English languages as thin UI
  localizations of English-teaching content. Native-recorded,
  language-as-subject content is the differentiator, and it scales with
  the founders' actual abilities.
- The language path segment costs nothing now but avoids a breaking asset
  reorganization + loader rewrite after the scene engine ships.
- Shared art keeps marginal cost per language ≈ audio + curriculum
  authoring only (no re-illustration).

## Alternatives rejected

- **Simultaneous multi-language MVP** — spreads a solo project thin;
  Hindi-first is already locked and stays.
- **Per-language culturally-skinned art worlds** — ~6× art cost for
  marginal toddler value; the universal world with swappable
  culture-specific vocab rows covers it.
- **Fluent-non-native narration to ship more languages sooner** —
  violates the reasoning of ADR-003; a language ships when a native voice
  exists, not before.
- **Flat filenames with language suffix** (`house_paani_hi.mp3`) — folder
  scoping keeps per-language packs droppable/removable as units (relevant
  for possible per-language store listings later).
