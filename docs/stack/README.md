---
type: Index
title: Locked tech stack and rationale
description: The dependency lockdown for the app — framework, animation, audio, storage, compliance-relevant choices; additions require an ADR.
tags: [stack, dependencies, rationale]
timestamp: 2026-07-18
status: current
---

# Stack — locked choices & rationale

Additions or changes to anything below require a new ADR in
[`../decisions/`](../decisions/README.md).

## Framework

| Technology | Purpose | Why | ADR |
|---|---|---|---|
| Flutter | Cross-platform app framework, single codebase for iOS + Android | UI/animation-heavy, offline-first genre; faster to ship and cheaper to maintain than a game engine for this genre | [ADR-001](../decisions/ADR-001-flutter-plus-rive-over-unity-godot.md) |

## Animation

| Technology | Purpose | Why | ADR |
|---|---|---|---|
| Rive | Tappable-object animations for scene interactions | Designers iterate animation without touching app code | [ADR-001](../decisions/ADR-001-flutter-plus-rive-over-unity-godot.md) |
| Lottie | Fallback for simpler animations where Rive is overkill | — | — |

## Audio

| Technology | Purpose | Why |
|---|---|---|
| `just_audio` or `audioplayers` (Flutter plugin, to be finalized when scaffolding starts) | Playback of short word/voice clips | Mature, well-supported Flutter audio plugins for many short bundled clips |

## Storage

| Technology | Purpose | Why | ADR |
|---|---|---|---|
| Bundled app assets only (no database, no cloud) for MVP | Content storage | MVP content set is small and fixed; offline-first avoids network dependency | [ADR-004](../decisions/ADR-004-offline-first-no-backend-for-mvp.md) |
| Local device storage (e.g., `shared_preferences` or similar) | Sticker/collection progress, settings | Simple key-value state, no sync requirement yet | — |

## Explicitly not using (for MVP)

| Technology/category | Why not |
|---|---|
| Backend / cloud database | No sync requirement yet — [ADR-004](../decisions/ADR-004-offline-first-no-backend-for-mvp.md) |
| Third-party ad SDKs | Disallowed for Kids Category — [ADR-002](../decisions/ADR-002-shippable-product-kids-category-compliance.md) |
| Third-party analytics/crash SDKs (unless kid-safe certified) | Same — [ADR-002](../decisions/ADR-002-shippable-product-kids-category-compliance.md) |
| TTS for shipped audio | Real native-speaker recording chosen instead — [ADR-003](../decisions/ADR-003-native-speaker-voiceover-over-tts.md) (TTS may still be used as dev-time placeholder audio) |

## Alternatives considered

| Category | Chosen | Alternative | Why not |
|---|---|---|---|
| App framework | Flutter | Unity 2D | Heavier app size, steeper build pipeline, overkill without physics needs — [ADR-001](../decisions/ADR-001-flutter-plus-rive-over-unity-godot.md) |
| App framework | Flutter | Godot 2D | Kept as fallback if Flutter's interaction model proves limiting |
| App framework | Flutter | React Native | Weaker animation-performance story for a densely-animated always-on-screen UI |
