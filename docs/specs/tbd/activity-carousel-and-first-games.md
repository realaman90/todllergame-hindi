---
type: Spec
title: Activity carousel + first three games
description: Build spec for the activity layer — carousel shell, pairs, counting-tap, balloon pop. Wave 1 of docs/design/game-formats.md, pulled into current scope.
tags: [spec, engineering, flutter, activities, games]
timestamp: 2026-07-20
status: tbd
---

# Activity Carousel + First Games — build spec

Wave 1 of `../../design/game-formats.md`. Everything inherits the
non-negotiables: audio-first, no reading, no fail states, ≤6 interactive
elements, 1–3 minute activities, always skippable, sticker at the end.

## 1. Activity abstraction (most likely to change — review hardest)

```dart
abstract class Activity {
  String get id;                        // "pairs", "counting", "balloons"
  /// Builds the activity UI for a scene's vocabulary subset.
  Widget build(BuildContext context, ActivitySession session);
}

class ActivitySession {
  final Scene scene;            // vocabulary + theme source
  final List<SceneObject> vocab; // ≤6 objects chosen for this round
  final AudioService audio;
  final void Function() onComplete; // fires celebration + sticker + advance
  final void Function() onSkip;     // advance without celebration
}
```

- Each game is a self-contained widget behind this interface, in
  `lib/activities/<id>/`.
- Vocabulary subset selection prefers words the child has already
  discovered in explore mode (reinforcement), fills with undiscovered.
- Completing any activity awards a namespaced sticker
  (`activity:<id>:<scene>`), fires Mithu praise + celebration (existing
  audio flows), then the carousel advances.

## 2. Carousel shell

- Entry: a new big activity door on the Home screen (Mithu-adjacent,
  art-based, no text dependency) → `/play`.
- The carousel builds a playlist interleaving formats × scenes so the
  same format never repeats back-to-back.
- On activity complete: auto-advance after the sticker moment. A large
  paper-style arrow button (≥56pt) is always present to skip forward.
  Back button exits to Home.
- No locks, no scores, no progression gates.

## 3. The three games

### जोड़ी मिलाओ (Pairs) — `lib/activities/pairs/`
- 6 face-up cards (3 pairs) using the object art tiles, shuffled grid.
- Tap a card: it says its word and lifts slightly (selected). Tap its
  twin: both pop + word plays again; pair flies off. Tap a non-twin: the
  new card becomes the selection instead (NO fail feedback; the previous
  selection just settles back).
- All 3 pairs matched → complete.

### गिनती (Counting-tap) — `lib/activities/counting/`
- A target count N (3–10, ramps slowly with plays) of one object
  (e.g. N laddoos/apples) scattered per the density rule (N≤6 on screen;
  for N>6 use two waves of ≤5).
- Tapping an object plays the NEXT number VO (`family_ek.mp3`,
  `family_do.mp3`, …) and marks it counted (small bounce + tint).
  Re-tapping a counted object just replays its number (no fail state).
- All counted → Mithu says the final number again + complete.
- This implements the counting-corner interaction owed by curriculum.md;
  the counting corner in the family scene stays as-is for now.

### गुब्बारे फोड़ो (Balloon pop) — `lib/activities/balloons/`
- Balloons (≤5 on screen) drift slowly upward, each carrying an object
  art tile; tap = pop (sfx `tap_pop` + a small burst) + the word plays.
- Balloons that float off-screen just re-enter later (nothing is ever
  missed/failed). After ~10 pops → complete.
- Colors: balloon bodies use the palette; when a balloon carries a color
  word's art (लाल/पीला/हरा), the balloon body matches that color.

## 4. Audio

Existing single voice lane + ambient + sfx lanes; carousel plays the
scene ambient of whichever scene's vocab is active. Mithu praise on
completion reuses `playPraise()`. No new audio assets required for
wave 1 (numbers, words, praise, sfx all exist).

## 5. Persistence

- `activity:` namespaced stickers via the existing StickerService.
- `counting_level`: highest N completed (int) — the only progression
  state, used for gentle ramp.

## 6. Out of scope for wave 1

Drag primitive (थाली बनाओ — wave 2), any new vocabulary, any new VO
lines, memory-flip pairs variant, per-activity icons on a picker screen
(carousel is the only surface for now).

## Milestones

1. **A1**: Activity interface + carousel shell + pairs, reachable from
   Home; complete/skip/stickers working.
2. **A2**: counting-tap + balloon pop; playlist interleaving; ramp
   persistence.
3. Move this spec to `implemented/` when A2 lands and the founder has
   played all three on device.
