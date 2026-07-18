# ADR-003 — Real native-speaker Hindi voiceover over TTS (2026-07-18) — Accepted

## What

All in-app Hindi audio (words, phrases, rhymes) is recorded by a real
native Hindi speaker against a finalized script — not synthesized via
text-to-speech for the shipped product.

## Why

Toddler-age language acquisition is highly sensitive to natural prosody;
current Hindi TTS doesn't model this well enough for a learning product.
Founder chose real recording over TTS explicitly.

Because re-recording is expensive, this has a direct process consequence:
**the MVP word list/script (see `docs/design/curriculum.md`) must be
finalized before recording begins.** Content changes after recording
starts are costly.

## Alternatives rejected

- **High-quality Hindi TTS** as the shipping audio source — rejected for
  release; may still be used as placeholder audio during app-scaffold
  development before the real recording session happens, purely as a
  development convenience (not a shipped-quality decision).
