---
type: Design
title: Game formats — activity library & carousel
description: Founder-approved direction for a library of mini-game formats beyond tap-to-hear, organized as a finish-one-flow-to-next carousel with skip. Wave 1 pulled into current scope.
tags: [design, games, activities]
timestamp: 2026-07-20
status: direction approved by founder 2026-07-20 — individual formats need build specs before implementation
---

# Game Formats — Activity Library

Founder feedback from M3 device testing: the free-explore scene alone is
not enough structure ("game is just stickers, not interactive");
toddlers thrive on short, varied, completable activities. Direction:
grow the app into a library of mini-game formats sharing one vocabulary
system and one set of rules.

## Non-negotiable rules (inherited from interaction-patterns.md)

- Everything by ear — no reading required, ever.
- No fail states: a wrong action wobbles gently and waits; nothing
  scolds, dims, counts errors, or times out.
- Tap-first; drag only where it is the point (assembly), always with a
  huge forgiving snap radius.
- Every activity completable in 1–3 minutes, ends in a celebration +
  sticker; every activity skippable.
- **≤6 interactive elements on screen** (density rule, born from the
  cluttered-scene feedback 2026-07-20) — applies to every format.

## The carousel (activity flow)

After finishing an activity, the next one slides in automatically
(non-text arrow affordance also present); the child can skip forward at
any time. Order interleaves formats so two similar games never run
back-to-back. Completion is the only goal — no scores, no locks
(everything playable from the start; the carousel is a suggestion, not
a gate).

Architectural note: each format is a module behind a common Activity
interface (start(vocab subset) → celebrate/skip); the carousel is a
playlist over those modules.

## Format library

| # | Format | Vocab it teaches | Core action | Notes |
|---|---|---|---|---|
| 1 | खोजो (Find-it) | any | tap | **exists** — MVP puzzle |
| 2 | थाली बनाओ (Make a thali) | foods | drag→snap | flagship "making" game; template extends to fruit chaat, फूलों की माला (colors), packing a bag |
| 3 | गिनती (Counting-tap) | numbers 1–10 | sequential tap | resolves curriculum's open "numbers interaction" item |
| 4 | जोड़ी मिलाओ (Pairs) | any | tap two | face-up find-the-twin first; memory-flip variant later |
| 5 | लड्डू कहाँ छुपा? (Hide-and-seek) | objects + spatial words | tap | Laddoo hides behind objects; Mithu gives audio clues |
| 6 | आवाज़ पहचानो (Sound match) | animals | tap | hear the animal sound, tap who made it |
| 7 | मिठू के अंग (Body parts on Mithu) | body parts | tap | "मिठू की नाक कहाँ?" — tap the mascot's features |
| 8 | रंग के फूल (Color sorting) | colors | drag→snap | feed laal/peela/hara flowers to matching pots |
| 9 | फल खिलाओ (Feed the animals) | foods + animals | drag→snap | feed Gauri/Laddoo; pairs two vocab groups |
| 10 | टुकड़े जोड़ो (Big-piece jigsaw) | scene names | drag→snap | 2–4 giant pieces of scene art |
| 11 | गुब्बारे फोड़ो (Balloon pop) | colors + objects | tap | balloons drift up carrying an object/color; pop = word + confetti; pure tap-joy |
| 12 | अलग कौन? (Odd-one-out) | any | tap | three of one thing, one different — tap the different one; existing art |
| 13 | आकार (Shapes) | NEW vocab: गोल, तिकोना, चौकोर… | tap/drag | **requires curriculum addition + recording** |
| 14 | बड़ा-छोटा (Big & small) | NEW vocab: बड़ा, छोटा | tap | "कौन सा बड़ा है?" comparisons — **requires curriculum addition + recording** |

**Declined: crosswords** — requires reading/spelling, which
interaction-patterns.md forbids for this age band ("everything by ear,
no reading required"). Parked for a possible future 5+ mode.

## Sequencing (founder pulled wave 1 into current scope, 2026-07-20)

1. **Wave 1 (NOW):** activity carousel shell + जोड़ी मिलाओ (pairs) +
   गिनती (counting-tap) + गुब्बारे फोड़ो (balloon pop) — all tap-only,
   no new vocabulary, no new art beyond existing tiles. Build spec:
   `../specs/tbd/activity-carousel-and-first-games.md`.
2. **Wave 2:** थाली बनाओ (introduces the drag primitive), hide-and-seek,
   sound match, body parts, odd-one-out.
3. **Wave 3:** color sorting, feed-the-animals, jigsaw, shapes +
   big-small (after their vocabulary lands in curriculum + recording).

Each wave needs: a build spec in `../specs/tbd/`, and any new VO lines
added to curriculum.md BEFORE the native recording session (ADR-003 —
counting voice, hide-and-seek clues, praise variants, etc.).
