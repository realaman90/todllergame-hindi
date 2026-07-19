# ADR-008 — Mithu is the brand mascot (2026-07-19) — Accepted

## What

Mithu the parrot (मिठू) is elevated from "one of three cast members" to
**the brand mascot**: app icon, store presence, home-screen greeter, and
the face of the product across all future language packs. The canonical
design is the `mithu_hero` concept (2026-07-19 asset-gen batch): three-lobe
marigold crest, mehndi-green body, peacock/kumkum layered wing feathers,
wings-spread welcome pose.

Consequences:

- **On-model pipeline:** future Mithu art is generated via image-*editing*
  from the canonical reference image, not fresh text prompts, to prevent
  design drift (concept batch showed crest drift between generations).
- The scene character sheet gets regenerated on-model from the canonical
  reference.
- Gauri and Laddoo remain scene companions (non-speaking, animal sounds
  only — language-neutral across packs).

## Why

- Competitive gap: category leaders (e.g. RV AppStudios' Lucas) carry the
  brand with a proper mascot; a generic animal trio doesn't.
- A parrot that repeats words **is** the product mechanic embodied —
  tap-again-to-repeat is in-character. मिठू is the archetypal Indian pet
  parrot name, and works across the multi-language roadmap (ADR-007).
- Mithu is not a curriculum word (तोता isn't in the MVP list), so no
  mascot/vocabulary collision.

## Alternatives rejected

- **New invented mascot (non-cast)** — discards locked v1.1 cast work;
  nothing fits a language game better than a talking parrot.
- **Baby peacock concept** (`alt_peacock_hero`) — visually strong, but a
  peacock is a static *display* (the tail fan), not a chatty companion;
  animating the fan well conflicts with ADR-005's simple code-driven
  animation. May be reused as decorative Bageecha art.
- **Elephant/other curriculum animals** — collide with tappable
  vocabulary words (e.g. हाथी).
