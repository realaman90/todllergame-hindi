---
type: Design
title: Curriculum — scene/word list
description: Working content plan for each scene, structured as the recording script for the native-speaker voiceover session.
tags: [design, curriculum, content]
timestamp: 2026-07-18
status: tbd
---

# Curriculum — Scene/Word List

Status: **template only — word entries not yet authored.** This is the
document that must be finalized before the voiceover recording session
(ADR-003 — re-recording is expensive).

Columns: Hindi word (Devanagari), transliteration, English gloss,
recording note (tone/emphasis), audio filename convention.

## Scene: Ghar (House) — MVP

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| _tbd_ | | | | `house_<slug>.mp3` |

## Scene: Bageecha (Farm) — MVP

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| _tbd_ | | | | `farm_<slug>.mp3` |

## Scene: Parivaar (Family) — MVP

| Devanagari | Transliteration | English | Recording note | Audio file |
|---|---|---|---|---|
| _tbd_ | | | | `family_<slug>.mp3` |

## Scene: Bazaar — v1.1

_Not started._

## Scene: Sharir (Body) — v1.1

_Not started._

## Conventions for filling this in

- One row per word/object that will appear as a tappable target in a
  scene.
- Every row needs both the standard-pace and the slow-repeat take
  recorded (per `../product/SPEC.md`'s tap-again-to-repeat interaction) —
  note this per-row if a word needs special handling.
- Keep the audio filename convention stable — the app's asset loader will
  key off `<scene>_<slug>.mp3`.
- Do not start MVP recording until all three MVP scene tables are fully
  populated and reviewed.
