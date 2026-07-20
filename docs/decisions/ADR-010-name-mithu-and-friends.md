# ADR-010 — The game is named "Mithu & Friends" (2026-07-20) — Accepted

## What

The product name is **Mithu & Friends**, replacing the working title
"Chalo Ghar Ghoome". Applied to: app display name (iOS/Android), in-app
home title, and the store-listing pattern. "चलो घर घूमें!" survives as
the Hindi tagline under the brand title (it is also Mithu's greeting
line). Chosen by the founder from mascot-led candidates.

Store-listing pattern for the multi-language roadmap (ADR-007):
**"Mithu & Friends: Hindi for Toddlers"** (then …Swedish, …English, per
pack or per listing).

## Why

- ADR-008 made Mithu the brand; the name should carry the mascot, which
  travels unchanged across all six planned languages — "Chalo Ghar
  Ghoome" is Hindi-only and describes one scene's frame, not the
  product.
- "& Friends" grows with the cast (Gauri, Laddoo, future characters)
  and follows a proven kids-brand pattern (e.g. Lucas & Friends) while
  the mascot name itself stays distinctive.

## Open item

Bundle id remains `com.gemoniq.chaloGharGhoome` (internal, never
user-visible). Decide at M4 store setup whether to re-create the project
identifier as `com.gemoniq.mithuandfriends` before first store upload —
cheap now, impossible after shipping.

## Alternatives rejected

- **Mithu ki Duniya / "Mithu's World"** — warm, but weaker on
  non-Indian storefronts and duplicates the "world/duniya" framing that
  scene names already carry.
- **Bolo Mithu!** — punchy, but reads as a command to the parrot rather
  than an invitation to the child, and romanizes awkwardly on
  non-Hindi storefronts.
- **Keeping "Chalo Ghar Ghoome"** — founder rejected 2026-07-20.
