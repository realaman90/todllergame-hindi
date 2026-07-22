---
type: Decision
title: ADR-013 — Curated ElevenLabs voice (Krusha) ships Hindi v1 voiceover, superseding ADR-003's recording requirement
description: Founder auditioned Hindi-native TTS voices 2026-07-22, selected Krusha with per-register settings; native recording becomes an optional future upgrade rather than a ship-blocker.
tags: [decision, audio, voiceover, ship]
timestamp: 2026-07-22
---

# ADR-013 — Krusha TTS ships Hindi v1 (2026-07-22) — Proposed (pending founder in-app confirmation)

**What.** The shipping Hindi voiceover for v1 is generated with ElevenLabs
voice **Krusha** ("Calm Storytelling Creator", id `TnYB2ffExJibiE7F67qW`,
model eleven_multilingual_v2), in two founder-approved registers:

- **Word takes** (standard + slow): calm-baseline settings
  (stability 0.50 / similarity 0.80 / style 0.60) — maximum clarity and
  take-to-take consistency; slow takes add stability 0.85 + speed 0.7.
- **Mithu host lines**: parrot-host settings
  (stability 0.20 / similarity 0.75 / style 1.00) — the bright hosting
  energy that carries the character.

This supersedes the *ship-blocking* part of ADR-003. ADR-003's quality
bar stands — the bar is now met by a curated, founder-audited voice
rather than requiring a recording session.

**Why.** Structured audition (2026-07-22): 7 candidates (6 Hindi-native
library voices + the Noorie placeholder) over a fixed script of
phonetically hard words (nasals, clusters) and host lines, followed by a
three-step expression ladder on the winner. The founder — a native Hindi
speaker — judged Krusha's pronunciation clear at both the calm and
parrot-host settings (the mid "lively" setting slurred ग़ायब and was
rejected). Practical wins: retakes cost seconds, new content (25-level
roadmap ≈ 250 words) needs no studio sessions, and per-language scaling
(ADR-007) becomes an audition per language instead of a native speaker
recruitment per language.

**Alternatives rejected.**
- Founder recording session (ADR-003's original plan) — still possible
  as a future warmth upgrade, no longer gating ship.
- Noorie (incumbent placeholder) — audibly weaker pronunciation than
  Krusha at the same settings.
- Mid-intensity single register — the rejected "lively" rung; two
  registers match how a voice actor would work the script anyway.

**Consequences.** Full 155-file set regenerated in Krusha; ElevenLabs
commercial-use terms cover library voices on the current plan. ADR-003
status updated to "Superseded by ADR-013 (recording now optional
upgrade)". Kids-Category note: synthetic voice is policy-compatible; no
disclosure requirement applies. Acceptance gate: founder listens to the
Krusha build in-app; on approval this ADR flips to Accepted.
