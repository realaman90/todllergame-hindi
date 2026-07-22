---
type: Decision
title: ADR-011 — flutter_soloud replaces just_audio as the only audio engine
description: Game-feel research (game-feel.md F2/F12) showed just_audio cannot meet the <100ms tap-feedback rule or do per-play pitch; SoLoud becomes the single engine for SFX, voice, and ambient.
tags: [decision, audio, stack, game-feel]
timestamp: 2026-07-21
---

# ADR-011 — flutter_soloud replaces just_audio as the only audio engine (2026-07-21) — Accepted

**What.** `flutter_soloud` (4.x) becomes the app's only audio engine —
SFX, voice lane, and ambient loop all run on it. `just_audio` is
removed. The `AudioService` public API (three lanes, queued voice
sequences, ducking ramps) is unchanged; only the engine underneath
swaps. New capabilities turned on immediately: memory-resident
preloaded SFX (first feedback under 100ms — feel rule F2) and per-play
playback rate (pitch-varied taps / pentatonic ladders — F12).

**Why.** The game-feel research audit
([`../design/game-feel.md`](../design/game-feel.md)) found the tap path
loads every asset from disk per play (`stop → setAsset → play`), which
breaks the 100ms rule on every single tap — the highest-ranked feel gap
in the build. just_audio is a music/podcast player by design: no
preload-to-memory, no pitch control, no latency guarantees, and its
platform-channel load futures already forced two workarounds we carry
(per-player op serialization, the PlatformDispatcher 'abort' filter).
SoLoud is FFI-based (no platform-channel hop on the play path), built
for exactly this use case (polyphonic game SFX), and is the official
Flutter cookbook recommendation for game audio. One engine for
everything because mixed audio plugins fight over the iOS audio
session.

**Alternatives rejected.**
- **Keep just_audio, preload via warm players** — still platform-channel
  latency per play, still no pitch; pooling N players per SFX is fighting
  the plugin's design.
- **audioplayers** — better than just_audio for SFX but weaker iOS
  latency story than SoLoud and no per-play rate control.
- **soundpool** — right idea, discontinued upstream.
- **Mixed engines (SoLoud for SFX, just_audio for voice/music)** —
  iOS audio-session contention; two audio stacks to debug instead of one.

**Consequences.** just_audio's completion/interruption quirks (the
`ProcessingState.completed` dedupe, "Loading interrupted" serialization)
disappear with the engine; the PlatformDispatcher 'abort' filter in
`main.dart` becomes dormant and can be removed once the migration has
soaked. Voice clips are cached as loaded sources after first use;
`AudioService.init()` preloads all SFX at startup. Stack doc updated.
