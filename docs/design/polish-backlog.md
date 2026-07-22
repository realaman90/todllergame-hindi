---
type: Design
title: Polish backlog — audio, animation, transitions, music
description: Founder quality critique (2026-07-21) triaged into shipped-now items and the structural upgrades each area needs.
tags: [design, polish, audio, animation]
timestamp: 2026-07-21
status: living backlog
---

# Polish Backlog

Founder critique 2026-07-21: "inaccuracies in audio, animations very
basic, transitions, bg music." Triage below. The system-level answer
to this critique is now [`game-feel.md`](game-feel.md) (feel rules +
build order); items here are the symptom-level backlog. Rule of thumb: placeholder
quality is capped until the **native recording session** (voice) and the
**Rive decision** (character animation) — everything else is code.

## Shipped in the same-day polish batch

- Game screens carry their titles (app bar) and Mithu SPEAKS the game
  name at round start (रेखा मिलाओ! / जोड़ी मिलाओ! / पैटर्न पूरा करो!).
- Ambient music fades in over ~1.2s, fades out on exit; voice ducking is
  now a smooth ramp (220ms down / 420ms up), not an instant jump.
- Staggered PopIn entrances for all game tiles (springy 0→1 with
  overshoot; plain-Tween-only rule for overshoot curves).
- App icon = Mithu (all iOS + Android sizes); launch screen carries the
  Mithu & Friends wordmark.

## Audio — structural fixes (need the recording session, ADR-003)

1. **Prosody of stitched sequences**: "यह + [word] + नहीं है" is choppy
   TTS concatenation. Record these as NATURAL takes: the session script
   should include per-word negation takes for the ~15 most-confusable
   words, plus a generic "यह नहीं!". Same for "___ कहाँ है?" — record the
   prompt with rising question intonation as one breath per word where
   feasible.
2. **Loudness normalization**: normalize all takes to a target LUFS in
   the session pipeline (record consistently; normalize on export).
3. **Register consistency**: one voice, one distance-to-mic, one energy
   level per lane (words calm; Mithu bright).

## Music — next steps (asset-side, Lyria)

1. Regenerate ambients as **seamless loops** (prompt Lyria explicitly:
   "loops perfectly, identical first and last bar") — current loops have
   audible seams.
2. Per-game short **stingers**: 2-3s completion flourishes to replace
   reusing the celebration SFX everywhere.
3. Consider a quieter "focus" variant of each ambient for game screens
   vs scene exploration.

## Animation — the Rive decision (revisits ADR-005)

Code-driven transforms have hit their ceiling: Mithu can bob and flap
frames, but cannot gesture, walk, point at a doorway, or lip-sync. If
the founder wants character-driven moments (Mithu flying in with the
game title, pointing at the correct column, celebrating with the child),
that is skeletal animation = **Rive**, and worth a dedicated ADR + art
budget. Recommendation: decide after the recording session, when
Mithu's real voice sets the personality bar.

## Transitions — code, incremental

1. Scene entry: transition FROM the tapped doorway card (scale/reveal
   from its rect) instead of a generic center fade.
2. Carousel round-to-round: slide-out/slide-in with a beat of breathing
   room instead of content swapping in place.
3. Sticker flight: add a small arc + squash-and-stretch on landing.
4. Word overlay: art tile should fly from the tapped object's rect
   (rect is already captured at tap time) rather than scaling in place.

## Vision-verdict pass, 8 newest games (Gemini, 2026-07-22)

Recording: iPad tour driven by `integration_test/new_games_tour_test.dart`.
Verdict triaged — rig artifacts excluded (video rotation = portrait-sim
recording artifact; "stuck" periods = the test idling; drag ghosts =
intentional childWhenDragging).

Real polish items, by priority:
- **Whack**: rising tile's square bottom edge reads against the pot's
  slanted sides — soften with a slightly narrower tile or a rim overlap.
- **Load-the-train**: wagon drop zones need clearer affordance contrast
  (bigger hover glow or a dashed opening on the wagon top).
- **Sound match**: unselected tiles vanish abruptly on completion — give
  them a 200ms shrink-fade before the round advances.
- **Peek-a-boo**: choice-tile labels render small/cramped at size 100 —
  bump label scale or tile size.
- **Round transition cross-fade** occasionally reads as "ghosting" of the
  previous round in compressed video (numtrace) — consider a slightly
  shorter fade-out (helps perceived cleanliness, low priority).

Verdict highlights: grow-a-plant and peek-a-boo judged the most polished;
no broken layouts, no off-screen elements, no stuck animations in-app.
