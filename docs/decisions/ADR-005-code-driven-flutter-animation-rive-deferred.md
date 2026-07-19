# ADR-005 — Code-driven Flutter animation for MVP; Rive deferred to an optional upgrade path (2026-07-19) — Accepted (amends ADR-001)

## What

MVP animations are implemented in Flutter code (`AnimationController`,
implicit animations, optionally `flutter_animate`) applied to static art
layers generated via the Imagen asset pipeline. Rive is removed from the
MVP critical path and kept as an optional later upgrade for organic
character motion. Lottie (open JSON format, programmatically authorable)
is the fallback for pre-baked flourishes that outgrow code-driven
transforms.

Amends ADR-001: the framework choice (Flutter) stands unchanged; only
the animation tooling within it changes.

## Why

- Rive's **editor is proprietary and skill-gated**: the runtimes are
  open source, but `.riv` files can realistically only be authored in
  Rive's visual editor (rigging, bones, state machines) — a tool the
  founder doesn't know and doesn't want on the critical path. That made
  "Flutter + Rive" quietly dependent on acquiring a design-tool skill
  nobody planned for.
- The MVP's actual animation needs — float, bounce, pulse, wiggle,
  pop-in, confetti (see the v1.1 mockups) — are all simple transforms on
  static images, fully expressible in Dart code that an agent can write
  and iterate on directly.
- Code-driven animation keeps the whole asset pipeline generative:
  Imagen produces static layers (optionally split parts on transparent
  backgrounds), code moves them.

## Alternatives rejected

- **Rive as planned (ADR-001)** — deferred, not rejected: revisit if/when
  character motion needs squash-and-stretch or walk cycles that
  transforms can't fake. Adopting it later is additive and needs no
  unwinding.
- **Lottie as the primary animation layer** — kept as fallback rather
  than primary; for our simple motions, plain code is fewer moving parts
  than generating/maintaining Lottie JSON.
- **Learning the Rive editor anyway** — rejected for MVP: the schedule
  cost buys polish the MVP doesn't need.
