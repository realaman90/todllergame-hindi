---
type: Spec
title: App shell & scene engine
description: Build spec for the Flutter scaffold — content model, screen map, interaction primitive, asset conventions, persistence, parent gate.
tags: [spec, engineering, flutter, scaffold]
timestamp: 2026-07-19
status: tbd
---

# App Shell & Scene Engine — build spec

The first engineering slice: a playable Flutter app with the full screen
flow from the v1.1 mockups, driven by data files so scenes/words are
content, not code. Per the spec-shape rule, decisions most likely to
change come first.

## 1. Content model (most likely to change — review this hardest)

Everything a scene shows is data. One JSON file per scene in
`assets/content/`:

```jsonc
// assets/content/farm.json
{
  "id": "farm",
  "title_hi": "बगीचा",
  "title_translit": "Bageecha",
  "title_en": "Farm",
  "theme": "mehndi",              // palette key from the mockup style guide
  "background": "scenes/farm_bg.png",
  "ambient_audio": "music/farm_ambient.mp3",   // optional
  "objects": [
    {
      "slug": "gaay",             // MUST match curriculum.md slug + audio filenames
      "word_hi": "गाय",
      "translit": "gaay",
      "gloss_en": "cow",
      "art": "objects/farm_gaay.png",
      "art_layers": ["objects/farm_gaay_ears.png"],  // optional, animated separately
      "pos": [0.18, 0.55],        // fractional x,y of scene, resolution-independent
      "scale": 1.0,
      "anim": "bounce"            // named preset: bounce | wiggle | pop | float
    }
  ],
  "puzzles": [
    { "ask": "gaay", "decoys": ["bakri", "murgi", "khargosh"] }
  ]
}
```

Rules:
- **`slug` is the universal join key** — curriculum row ↔ audio files
  (`farm_gaay.mp3` / `farm_gaay_slow.mp3`) ↔ art files ↔ sticker
  identity. Never rename a shipped slug.
- Characters (Gauri, Laddoo, Mithu) are objects with an extra
  `"character": true` flag — same tap behavior, but they can also play
  idle animations.
- Puzzles reference only slugs present in the scene's objects (validated
  at load; a bad reference is a build error, not a runtime surprise).

## 2. Screen map (from the v1.1 mockups — user-facing)

| # | Screen | Route | Notes |
|---|---|---|---|
| 01 | Home / scene select | `/` | Mithu + doorway cards, gear icon → parent gate |
| 02 | Scene | `/scene/:id` | scattered tappable objects, back + sticker-count pill |
| 03 | Word reveal | overlay on scene | modal-free overlay: art + word card; tap art again = slow take; tap anywhere else = dismiss |
| 04 | Find-it puzzle | overlay on scene | Mithu asks; 4 candidate cards; wrong tap = gentle idle wobble only, NO failure feedback |
| 05 | Sticker earned | overlay | confetti + sticker flies to the count pill |
| 06 | Sticker wall | `/stickers` | grid fed by discoveries + puzzle finds |
| 07 | Parent gate → settings | `/gate` → `/settings` | hold-to-confirm ring (3s); settings: volume sliders, scene toggle |

All child-facing screens obey `docs/design/interaction-patterns.md`
(no text-dependent navigation, no modals with buttons, no fail states).

## 3. Core interaction primitive

One widget, `TappableObject`, implements the whole loop:

tap → run `anim` preset on the art (transform-based, ADR-005) → play
`<scene>_<slug>.mp3` → show word overlay → second tap on art plays
`_slow.mp3` → dismissal returns to scene → if first-ever discovery,
sticker-earned overlay fires and slug is persisted.

Audio: single playback lane — starting a new word stops the previous
one (toddlers tap fast; overlapping voices are chaos). Ambient/music
ducks to ~30% while a word plays.

## 4. Asset conventions

- Art: PNG (transparent) for objects/characters, JPG/PNG for
  backgrounds, under `assets/art/` mirroring the content-model paths.
  Source of truth for style is `docs/design/mockups/v1.1-cast-and-screens.html`.
- Audio: MP3s under `assets/audio/`, filenames exactly per
  `curriculum.md`. Placeholder TTS lives in the same tree — shipping
  builds swap files, not code (ADR-003).
- Everything bundled; no network fetch anywhere (ADR-004).

## 5. Persistence

`shared_preferences` only:
- `stickers`: list of discovered slugs
- `settings`: volumes (music / sfx / voice), enabled scenes
No accounts, no cloud, no analytics (ADR-002/004).

## 6. Project structure & stack details (mechanical)

```
lib/
  main.dart
  content/    // models + JSON loading + validation
  scenes/     // scene screen, TappableObject, overlays
  puzzles/    // find-it flow
  stickers/   // wall + persistence
  gate/       // parent gate + settings
  audio/      // playback service (single-lane + ducking)
  theme/      // palette + text styles from the mockup style guide
assets/
  content/  art/  audio/  fonts/
```

- Audio plugin: pick `just_audio` or `audioplayers` at scaffold time
  (whichever handles rapid short-clip restarts better on both
  platforms); note the choice in this spec when made.
- Fonts: bundle Baloo 2 + Hind (Devanagari + Latin subsets).
- Orientation: landscape-locked (scenes are wide dioramas).
- Min targets: iOS 15+, Android 8+ (sanity-check at scaffold time).

## 7. Milestones

1. **M1 — walking skeleton:** Home → one scene (Farm) → tap → placeholder
   audio + word overlay. Placeholder rectangles fine.
2. **M2 — full loop:** stickers persist, sticker wall, find-it puzzle,
   sticker-earned moment.
3. **M3 — content complete:** all 3 MVP scenes driven from JSON matching
   curriculum.md; generated art/audio dropped in.
4. **M4 — shell polish:** parent gate, settings, app icon, splash,
   landscape lock, store-readiness pass (ADR-002 checklist).

Move this spec to `implemented/` (with a banner) once M4 lands.
