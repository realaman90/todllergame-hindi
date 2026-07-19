# ADR-009 — Lyria 3 (Gemini API) as the music backend (2026-07-19) — Accepted

## What

Songs and instrumental loops are generated with **Google Lyria 3**
(`lyria-3-pro-preview`, Gemini API) as the default backend in
`tools/asset-gen/`. ElevenLabs remains the backend for **SFX and
dev-placeholder word voiceover** (the latter still dev-only per ADR-003).
Supersedes the music part of ADR-006; ADR-006's *Suno rejection* stands
unchanged.

Tooling: `gen_audio.py --backend lyria|elevenlabs` — Lyria output is
written as `*_lyria.mp3` next to the ElevenLabs takes so both survive for
A/B curation.

## Why

- Lyria 3 (released after ADR-006 was written, chosen by the founder)
  supports sung vocals with timed lyrics, multi-language vocal delivery,
  vocal timbre control, and full arrangements — a better fit for the
  Hindi songs than ElevenLabs Music, which produced weaker
  instrumentation in practice.
- Devanagari lyrics in the prompt yield native Hindi pronunciation —
  same principle as the ElevenLabs accent fix.
- Clean rights chain: first-party Google API under the project's existing
  `GOOGLE_API_KEY`; all output carries an imperceptible SynthID
  watermark, which is acceptable for shipped content (inaudible,
  provenance-positive).
- No new compliance surface: dev-time tooling only, nothing ships as an
  SDK in the app (ADR-002).

## Alternatives rejected

- **ElevenLabs Music as sole backend** (ADR-006) — kept as secondary for
  A/B, but its arrangements were consistently vocal-dominant despite
  instrumentation-first prompting.
- **Suno (any route)** — still rejected per ADR-006.
