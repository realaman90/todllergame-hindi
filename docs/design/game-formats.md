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
| 11 | गुब्बारे फोड़ो (Balloon pop) | numbers 1–5 | tap | **BUILT 2026-07-21** as the counting breather: Mithu asks a number, the child pops that numeral's balloon; wrong balloons still pop joyfully. Woven after every 3rd game win, alternating with बुलबुले |
| 11b | बुलबुले (Soap bubbles) | none — pure fidget | tap | **BUILT 2026-07-21** — second breather type: iridescent bubbles drift up, tap to burst into droplets; no goal at all. Alternates with balloons at the every-3rd-win slot |
| 12 | अलग कौन? (Odd-one-out) | any | tap | three of one thing, one different — tap the different one; existing art |
| 13 | आकार (Shapes) | NEW vocab: गोल, तिकोना, चौकोर… | tap/drag | **requires curriculum addition + recording** |
| 14 | बड़ा-छोटा (Big & small) | NEW vocab: बड़ा, छोटा | tap | "कौन सा बड़ा है?" comparisons — **requires curriculum addition + recording** |

| 15 | रेखा मिलाओ (Line matching) | any pairs: word-art↔art, animal↔sound, color↔object | **finger-drag line** | founder priority 2026-07-20: drag a line from an item on the left to its match on the right; the line draws under the finger, snaps + glows on a correct match, gently fades on a miss (no fail state); both items speak on connect. 3 pairs max on screen. |
| 15b | आइसक्रीम बनाओ (Ice-cream parlor) | foods (fruit flavors) | tap + drag | **BUILT 2026-07-21, parlor upgrade same day** — choose a flavor (scoop plops on the waffle cone), tap toppings (fruit bits + sprinkles), then drag the finished cone to Mithu, who slides in, munches it and dances. Every choice is right. (Was "kulfi", then a mixing bowl — founder asked for a proper parlor flow) |
| 15c | अच्छा खाना (Healthy food) | foods | tap/drag | founder idea 2026-07-21: pick the fruits / build a healthy plate — framed positively (choose the good things), never food-shaming |
| 16 | पैटर्न पूरा करो (Pattern completion) | any | tap | simple AB/ABC sequences of art tiles (गाय-फूल-गाय-फूल-?) with 2 big answer choices; foundational pre-math skill |

**Declined: crosswords** — requires reading/spelling, which
interaction-patterns.md forbids for this age band ("everything by ear,
no reading required"). Parked for a possible future 5+ mode.

## Expansion library (founder ask 2026-07-21: "at least 20 more")

Twenty more formats, all ear-first / no-reading / no-fail. Grouped by
the interaction primitive they reuse — formats sharing a primitive are
cheap to build once the first of the group exists. `NEW-VO` marks
formats needing new recorded lines; `NEW-vocab` needs curriculum words
first (see `level-roadmap.md` — many pair with a planned level).

| # | Format | Vocab | Core action | Notes |
|---|---|---|---|---|
| **Tap-primitive (engine exists)** |||||
| 17 | क्या ग़ायब? (What's missing) | any | tap | 3 objects shown, one hides under a cloth — tap what's missing among 2 choices; first memory game |
| 18 | झटपट बोलो (Whack-a-word) | any | tap | objects peek out of pots/windows; tap the one Mithu names; gentle pace, nothing "escapes" |
| 19 | छोटा-मझला-बड़ा (3-size sort) | sizes | tap | extends big-small to three sizes; tap in size order |
| 20 | दिन-रात छाँटो (Day/night) | routine words | tap | sun or moon in the corner — tap the things that belong (NEW-vocab: level 26) |
| 21 | आवाज़ का क्रम (Sound simon) | animals | tap | Gauri then Laddoo call out — tap them in the order heard; 2-step max, pre-memory skill |
| 22 | ताल मिलाओ (Music taps) | instruments/animals | tap | tap characters to build a little rhythm loop; every tap sounds good (NEW-vocab: level 25) |
| **Drag-primitive (built for ice cream / thali)** |||||
| 23 | परछाईं मिलाओ (Shadow match) | any | drag→snap | drag object onto its silhouette; art pipeline can bake silhouettes automatically |
| 24 | रेल गाड़ी भरो (Load the train) | categories | drag→snap | fruits wagon vs animals wagon — first sorting-by-category; train chugs off as reward |
| 25 | टावर बनाओ (Stack the blocks) | colors/sizes | drag→snap | stack 4 blocks big→small; wobble physics feel, tower cheers |
| 26 | पौधा उगाओ (Grow a plant) | garden words | drag→snap | seed→water→sun in order; flower blooms + butterfly lands (pairs with level 28) |
| 27 | कपड़े पहनाओ (Dress Mithu) | clothes | drag→snap | put टोपी/मोज़े on Mithu for the weather; every outfit is right (NEW-vocab: level 7) |
| 28 | मछली पकड़ो (Fishing) | sea words | drag | drag the hook-line to the fish Mithu names; reuses line-match finger math (NEW-vocab: level 14) |
| 29 | स्मूदी बनाओ (Smoothie mixer) | fruits | drag→snap | ice-cream template reskin: fruits into blender, whirl animation, colored smoothie out |
| 30 | खाना खिलाओ (Feed by sequence) | foods + family | drag→snap | "पहले दादी को…" — serve family members in the asked order (builds on #9) |
| **Finger-line primitive (built for line-match)** |||||
| 31 | रास्ता दिखाओ (Trace the path) | any | finger-trace | guide Laddoo home along a wiggly dotted road; finger-line follows, pre-writing motor skill |
| 32 | आकार बनाओ (Shape tracing) | shapes | finger-trace | trace a big गोल/तिकोना with sparkle trail; shape comes alive (eyes + giggle) (NEW-vocab: level 20) |
| 33 | नंबर बनाओ (Number tracing) | numbers 1–5 | finger-trace | trace the numeral, then that many mangoes pop up counted aloud; pairs with counting balloons |
| **Reveal/gesture novelties** |||||
| 34 | पोंछो और देखो (Wipe & reveal) | any | rub | steamy window — rub to reveal the object underneath, word plays when enough is clear; hugely satisfying |
| 35 | कौन छुपा है? (Peek-a-boo zoom) | animals | tap | extreme close-up (fur/beak) slowly zooms out — tap when she knows; guessing without reading |
| 36 | चिपकाओ मन से (Sticker scene, free-play) | earned stickers | drag | creative mode: place earned stickers anywhere on a scene, no goal, saves her arrangement; makes the sticker book a toy (NEW-VO: invite line) |

Build order recommendation: **23, 34, 17, 31** first — zero new
vocabulary, maximum novelty per effort (shadow match and wipe-reveal are
the two most-loved formats in this genre), then pull formats as their
levels land per `level-roadmap.md`.

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
