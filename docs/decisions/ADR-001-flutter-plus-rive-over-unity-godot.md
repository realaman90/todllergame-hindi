# ADR-001 — Flutter + Rive as the app framework, over Unity/Godot (2026-07-18) — Accepted; animation leg amended by ADR-005

> **2026-07-19:** the Flutter framework choice stands; the Rive animation
> leg is amended by
> [ADR-005](ADR-005-code-driven-flutter-animation-rive-deferred.md) —
> MVP animation is code-driven Flutter, Rive deferred to an optional
> upgrade path (its editor is proprietary/skill-gated).

## What

Build the app in Flutter, targeting iOS + Android from one codebase, using
Rive (or Lottie where simpler) for the tappable-object animations.

## Why

The core gameplay is UI/animation/audio-driven — tap an object, it
animates, a Hindi word is spoken — not physics-simulation-driven. Flutter
gives:

- single codebase for iOS + Android
- strong offline-first support (bundle all assets, no network dependency
  — important for a toddler app that should never lag on load)
- mature short-clip audio plugins for the many word/voice clips
- art/animation iteration in Rive without touching app code

This ships faster and costs less to maintain than a game engine, for a
genre where 90% of the delight comes from art + voice-acting quality, not
physics.

## Alternatives rejected

- **Unity 2D** — the industry-standard choice for toddler explore apps
  (Toca Boca, Sago Mini) with the most tactile/physical object
  interactions (squish, bounce, drag-physics). Rejected for v1: heavier
  app size, steeper build/release pipeline, overkill when v1 doesn't need
  physics simulation. Worth revisiting if the desired "feel" later proves
  to need real physics.
- **Godot 2D** — similar 2D strengths to Unity, no licensing cost, lighter
  engine. Kept as the fallback if Flutter's interaction model turns out
  too limited.
- **React Native** — comparable cross-platform story to Flutter, but a
  weaker animation-performance story for a UI that's densely animated at
  all times.
