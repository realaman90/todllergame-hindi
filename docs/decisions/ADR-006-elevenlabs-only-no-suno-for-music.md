# ADR-006 — ElevenLabs only for generated music; Suno rejected (2026-07-19) — Partially superseded by ADR-009 (music backend → Lyria 3; Suno rejection stands)

## What

All AI-generated audio (songs, instrumental loops, SFX) comes from
ElevenLabs via `tools/asset-gen/`. Suno — specifically third-party
wrappers like sunoapi.org — is not used, even for dev-time generation of
ship-candidate music.

## Why

Songs and music are ship-candidates (unlike word voiceover, which is
placeholder-only per ADR-003), so the rights chain of generated audio
matters for App Store review and the Kids Category compliance posture
(ADR-002):

- Suno has **no official public API**. sunoapi.org and similar services
  are reverse-engineered wrappers run by unaffiliated third parties —
  using them violates Suno's ToS and gives no licensing chain at all.
- Suno's commercial rights attach only to output generated under one's
  own paid Suno account; output via a reseller has no clean provenance.
- Suno faces an ongoing major-label copyright lawsuit ($3B+, still open
  as of March 2026) — supply-chain risk for shipped content.
- ElevenLabs paid plans grant explicit commercial-use rights, and it is
  already the project's audio vendor — one clean chain, one vendor.

## Alternatives rejected

- **sunoapi.org (unofficial Suno wrapper)** — ToS violation, unknown
  operator, no rights chain. Rejected outright.
- **Personal Suno Pro account via their web app** — legitimate and
  remains an option if ElevenLabs music quality proves insufficient:
  generate manually there and drop MP3s into `tools/asset-gen/out/` for
  curation. Adopting it as a wired-in tooling lane would supersede this
  ADR.
