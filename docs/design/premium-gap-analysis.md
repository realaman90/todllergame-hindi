---
type: Design
title: Premium gap analysis — why the build reads sub-premium
description: Root-cause diagnosis of the founder's "still feels sub-premium" verdict (2026-07-22), ranked by contribution, with evidence from Pok Pok / Toca Boca / Sago Mini / Khan Kids / Endless Alphabet, remediation options with effort estimates, and a recommended sequence. Companion to game-feel.md — this covers the axes that doc deliberately did not.
tags: [design, art-direction, premium, gap-analysis, asset-pipeline, scene-composition]
timestamp: 2026-07-22
---

# Premium Gap Analysis

Founder verdict after playing the current build (game-feel P0–P2 shipped):
**"still feels sub-premium."** This doc answers *why*, concretely, against
the best-in-class set (Pok Pok Playroom, Toca Boca, Sago Mini, Khan Kids,
Endless Alphabet).

**Headline:** the remaining gap is almost entirely **visual-spatial, not
reactive**. [`game-feel.md`](game-feel.md) fixed the feel floor (latency,
touch-down registration, tap ladder, idle life, Mithu witness, particles) —
and none of the premium apps beat us meaningfully on tap response anymore.
What they have and we don't is a **world**. Our screens are white sticker
tiles floating in rows on a tinted gradient, framed by a Material app bar.
Theirs are illustrated places where characters and objects *live*. That is
an art-pipeline and composition problem, not a juice problem — roughly
**70% art/layout, 30% code** by the analysis below.

The five root causes, ranked by estimated contribution to the sub-premium
read:

| # | Root cause | Est. contribution | Fix type |
|---|------------|------------------|----------|
| 1 | Everything is a floating tile — no cut-outs, no diegesis | ~35% | Pipeline + shared widget |
| 2 | Environments are washes, not places (and cropped) | ~20% | Art regeneration |
| 3 | Character animation ceiling — Mithu is a 5-frame flipbook in an oval | ~15% | Art + (later) Rive |
| 4 | Adult UI chrome: app bar, text title, Material spinner | ~15% | Code, cheap |
| 5 | Transitions are card swaps; sound bed lacks texture | ~15% | Code + audio assets |

---

## Cause 1 — Everything is a floating tile (no cut-outs, no diegesis)

**~35% of the gap. The single biggest premium signal we are missing.**

### What the build does

Every piece of object art in the app is an **opaque RGB PNG with a baked
white background**. Verified: `assets/art/objects/*.png` are 512×512
RGB (no alpha channel), `assets/art/characters/mithu_*.png` are 800×800
RGB, because `tools/asset-gen/gen_images.py` explicitly prompts
*"Single isolated object on a clean white background"* and gpt-image-2
outputs opaque images only.

Because no asset can be cut out, the entire UI is built around
**containing squares**:

- `lib/widgets/art_tile.dart` wraps every object in a white die-cut rim +
  rounded rect + drop shadows — the "sticker" look is a *workaround* for
  missing alpha, applied to everything.
- **16 of 17 games** render `ArtTile`s in centered `Row`/`Column` layouts
  over `GameBackdrop` (a radial tint + five translucent dots). Grep
  confirms `ArtTile` in every activity except balloons/bubbles.
- Even the **explore scenes** — our most "worldlike" surface — position
  `ArtTile`s at normalized slots *over* the background
  (`lib/scenes/scene_screen.dart`, `tappable_object.dart` line ~135), so
  a cow in the farm is a white-rimmed card hovering above the art, not a
  cow standing on the ground.
- **Mithu is circle-cropped into a medallion** (`ClipOval` in
  `lib/widgets/mithu_talking.dart` line ~171) because his frames are
  opaque squares. The mascot is visibly *a picture of a parrot in a
  porthole*, not a parrot in the room.

### What premium apps do

- **Pok Pok Playroom**: the home screen *is* a playroom — you tap the
  actual toys lying around; "kids just see the toys… no menus, no text"
  ([Common Sense](https://www.commonsensemedia.org/app-reviews/pok-pok-playroom),
  [9to5Mac](https://9to5mac.com/2021/05/20/hands-on-with-pok-pok-playroom-kids-app/)).
  Every object sits in the environment, hand-drawn, never carded.
- **Sago Mini**: characters inhabit landscapes; "beautiful illustration,
  interactive characters… landscapes as supporting actors"
  ([Sago Mini World reviews](https://learningworksforkids.com/apps/sago-mini-world/)).
- **Toca Boca**: kitchens/salons are rooms with shelves and counters;
  their stated principle is grounding in everyday reality — "there is
  still dirt in the corners"
  ([Motionographer](https://motionographer.com/2016/04/27/the-design-process-behind-toca-bocas-infectious-apps/)).
- None of the five reference apps EVER shows a vocabulary item as a
  floating card on a gradient. Tile-on-backdrop is the visual grammar of
  a *flashcard app* — and that is precisely what "sub-premium" is
  detecting. The tile treatment also flattens all six focus areas at
  once: no lighting continuity, no ground contact, no scale
  relationships, no occlusion.

### Remediation options

**1A. Alpha cut-out pipeline (recommended).** gpt-image-2 **cannot**
output transparency (its `background` parameter accepts only
`auto`/`opaque` — [OpenAI image API](https://developers.openai.com/api/docs/guides/image-generation));
the gpt-image-1.5 family **can** (`background: "transparent"` yields a
real alpha channel). Two routes, not exclusive:
- *Post-process the existing 56 objects + 6 Mithu frames* with local
  background removal (rembg, or macOS Vision subject-lift). Hours of
  compute; risk: fringing on soft paper-texture edges — needs a QA eye
  pass. **1–2 days.**
- *Add a `--transparent` lane to `gen_images.py`* using gpt-image-1.5
  with `background: "transparent"` for all future object/character art,
  and regenerate any asset the post-process mangles. **1 day of pipeline
  work + regen cost.** Keep gpt-image-2 for full scenes (where its
  scene-completion strength is an asset, not a bug).

**1B. `ArtTile` gains a `cutout` mode** — renders the alpha PNG directly
with a soft **elliptical contact shadow** under its footprint (the single
cheapest "it's really standing there" cue in all five reference apps)
instead of rim + rounded-rect + box shadows. Because `ArtTile` is the one
shared widget, every game upgrades in a single migration. Keep the
sticker rim **only where sticker semantics are real**: the sticker wall,
the sticker-earned overlay, sticker-play. The sticker look stops being a
crutch and becomes a meaningful reward language. **2–3 days including a
pass over the 16 games.**

**1C. Un-medallion Mithu.** Alpha frames + drop the `ClipOval`; Mithu's
feet get the same contact shadow. Instant, large credibility gain for
the brand character. **Half a day once frames have alpha.**

Total: **~1 week for the pass that changes every screen in the app.**

---

## Cause 2 — Environments are washes, not places (and cropped)

**~20% of the gap.**

### What the build does

- Scene backgrounds are generated **portrait 1024×1536** for a
  **landscape-only app** and displayed `BoxFit.cover`
  (`lib/scenes/scene_screen.dart` `_Background`) — the sides of every
  composition are amputated; what survives is mostly empty wash (see
  `assets/art/scenes/house_bg.png`: a beautiful but *vacant* archway).
- Game screens don't use scene art **at all** — they get the procedural
  `GameBackdrop` (radial tint + dots). There is no ground plane, no
  horizon, no furniture, no play surface. The whack pots are a
  `CustomPainter` trapezoid — charming idea, visually thin next to the
  generated art beside it.
- Net: the app's *places* (house / farm / family) exist only as color
  themes during games, so 90% of session time happens "nowhere."

### What premium apps do

Every activity in the reference set happens **somewhere**: Toca Boca's
food is cooked in a kitchen with counters; Sago Mini's puzzles happen on
a road, in a harbor; Khan Kids exercises sit in illustrated meadows with
a horizon and depth layers; Pok Pok toys rest on the playroom floor.
"Objects physically based on real-world objects *and environments*" was
an explicit Pok Pok foundation
([gamedeveloper.com](https://www.gamedeveloper.com/design/how-just-letting-kids-be-kids-drives-the-design-of-pok-pok-playroom)).
A place gives the child spatial anchoring, gives objects scale and
lighting logic, and gives the brand a memorable image. A gradient gives
none of these.

### Remediation options

**2A. Regenerate the 3 scene backgrounds landscape-first** (1536×1024)
with **designed play zones**: prompt for an intentionally empty
foreground band (ground/table/grass) at a known normalized region where
`TappableObject` slots and game layouts land, so objects sit *on*
surfaces in the art rather than over them. Use the existing image-edit
lane (as with Mithu on-model art) to keep the current palette/paper
style. **2–3 days generation + curation.**

**2B. Per-game micro-sets.** Each game family gets one environment
element instead of a full scene: a wooden **table edge** for
shadow-match and pattern (tiles rest on the table), a **garden bed**
for plant, an illustrated **pot row on grass** replacing `_PotPainter`
for whack, a **shelf** for odd-one-out/sizes, **train tracks with
scenery band** for train. One generated strip per family, reused across
scenes with theme tinting. This is the 80/20 of "diegetic worlds" without
per-scene × per-game art explosion. **~1–2 weeks calendar for all 17
games (art generation dominates; layout code is small).**

**2C. Interim code-only "stage"**: a shared painted ground-plane widget
(horizon line, floor tint, soft vignette) slotted under existing
layouts. **2 days**, worth doing only if 2B stalls — 2B supersedes it.

---

## Cause 3 — Character animation ceiling: Mithu is a flipbook in an oval

**~15% of the gap.**

### What the build does

`MithuTalking` is five swapped PNGs: beak toggled every 140ms while
audio plays, sine bob, three transform-based dance styles. He cannot
walk, point at anything, hand the child anything, or emote beyond
open/closed beak. He is also (Cause 1) trapped in a circle. The corner
witness (F15, shipped) put him *on screen* during games — which makes
his stiffness *more* visible, not less.

### What premium apps do

The premium bar here is literally professional animation labor:
Pok Pok's founders are **classically trained animators**
([gamedeveloper.com](https://www.gamedeveloper.com/design/how-just-letting-kids-be-kids-drives-the-design-of-pok-pok-playroom));
Khan Kids' characters were animated by **The Little Labs**, a motion
studio ([thelittlelabs.com](https://thelittlelabs.com/work/khan-academy-kids)), and Kodi
demonstrates answers, walks children through mistakes, and reacts
continuously; Endless Alphabet's letters are **hand-animated with
individual personalities** — the animation IS the product
([Pixelkin](https://pixelkin.org/2015/02/05/anas-apps-endless-alphabet-and-endless-reader/)).
A toddler reads character believability before anything else on screen
(game-feel F15 already concluded a face beats particles).

### Remediation options

**3A. Interim: expand the flipbook pose set via image-edit** from
`docs/design/mascot/mithu-canon-hero.png` (the on-model lane already
exists in `gen_images.py`): point-left, point-right, clap, look-down,
eyes-closed-happy, and a 3–4 frame hop cycle — with alpha (1A). ~10
frames unlocks: Mithu pointing at the correct column, looking at the
object the child drags, applauding mid-round. Cheap, on-brand,
ship-this-month. **2–3 days.**

**3B. Rive rig (the real answer).** Already flagged in
[`polish-backlog.md`](polish-backlog.md) as revisiting ADR-005:
skeletal animation gives walk/point/lip-sync and, critically,
**state-machine blending** (idle → glance → cheer without frame pops).
Needs an ADR + art budget (vectorize Mithu or rig the paper-cut layers;
consider commissioning the rig — this is the one place outside art
generation where buying professional animation hours is how the
reference apps actually did it). **2–4 weeks calendar, after the native
recording session sets the personality bar (per the backlog's own
sequencing).** 3A is not throwaway — the poses become the rig's key
poses.

---

## Cause 4 — Adult UI chrome

**~15% of the gap. Cheapest fix on the list.**

### What the build does

- `CarouselScreen` (and game/picker screens) use a **Material `AppBar`**
  with the game title as **text**, a back button, and a skip arrow —
  standard adult-app furniture framing every game. Note
  [`interaction-patterns.md`](interaction-patterns.md) already mandates
  "no text-only… for the child-facing flow"; the title text partially
  violates our own rule (Mithu already *speaks* the game name).
- Round loading shows a **`CircularProgressIndicator`** — a Material
  spinner is the single most recognizable "unfinished app" tell.
- The paper look lives *inside* the body while the frame stays stock
  Flutter.

### What premium apps do

Chromeless is the category norm: Pok Pok's entire in-toy UI is **one
circular home icon**; "no menus, no text, not even language"
([Common Sense](https://www.commonsensemedia.org/app-reviews/pok-pok-playroom),
[playpokpok.com FAQ](https://playpokpok.com/faqs/)); Pok Pok's UI is
"mostly language-free"
([Sketch blog](https://www.sketch.com/blog/pok-pok/)); Toca Boca ships
"minimal options and shallow navigation," everything diegetic. The
premium read of "a world, not an app" dies the moment an app bar spans
the top.

### Remediation

**4A. Kill the `AppBar` in child flow.** Float the existing
`ToddlerBackButton` and `_SkipArrow` as loose paper tokens in the top
corners over the scene (both already styled as paper circles — they
just need to stop living in an `AppBar`). Drop the text title entirely;
the spoken title (already shipped) carries it. **1 day.**
**4B. Replace every `CircularProgressIndicator`** with bobbing Mithu +
three pulsing paper dots. **Half a day.**
**4C. Preload rounds** so the loader rarely appears at all (rounds are
small JSON + images; `precacheImage` the next round during play).
**1 day.**

---

## Cause 5 — Transitions are card swaps; sound bed lacks texture

**~15% combined.**

### Transitions (what the build does)

Round-to-round is an `AnimatedSwitcher` slide-0.12-and-fade
(`carousel_screen.dart`); scene entry is a generic fade-scale route;
the celebration is a modal overlay on top of the game. There is no
spatial continuity — screens replace each other; nothing *travels*.
Premium apps maintain continuity: Pok Pok toys open from the toy you
touched and close back into it (one circular icon, zero hard cuts);
Khan Kids' sparkles physically fly to the delivery truck; Endless
Alphabet's monsters barge in from off-screen carrying the letters.
[`polish-backlog.md`](polish-backlog.md) already lists the right items
(doorway-rect scene entry, sticker flight from real rects, word-overlay
flight); they are unshipped.

**Remediation:** ship the backlog's transition section, plus two
additions that buy continuity cheaply: (a) **Mithu bridges rounds** —
he flies across the screen wiping to the next game (he is the constant
between screens; the transition becomes a character beat, and it's a
flipbook-friendly move even before Rive); (b) celebrations happen
**in-scene** (Mithu runs to the completed board) instead of a modal
overlay. **3–5 days total.**

### Sound texture (what the build does)

The reactive layer is now good (SoLoud, ladder, boops, stingers — P0/P2
done). What's missing is the **textural layer**: one ambient loop per
scene **with audible seams** (already in the backlog), no room tone, no
per-material foley (tap_wood/tap_soft exist but per-family wiring is an
open game-feel item), dev-TTS voice (known, ADR-003). Pok Pok's bar:
a sound designer **foley-recorded every object** — soup cans, thrift
store toys — tuned to "be heard a number of times without becoming
fatiguing" ([Apple Behind the Design](https://developer.apple.com/news/?id=5bcex7xf)).

**Remediation:** regenerate ambients as true seamless loops (backlog
item, Lyria prompt fix); add one quiet **room-tone layer** per scene
(house: distant kitchen clinks; farm: birds/breeze; family: soft indoor
air) mixed under the music; wire the per-family tap timbres (open
game-feel item); object-specific foley for the ~15 most-tapped words
via the ElevenLabs SFX lane (cow moo on tap beats a kalimba note for
गाय — *the object sounding like itself* is a premium tell). **2–4 days
code+mix after asset generation.** The native-speaker recording session
(already planned, ADR-003) remains the single biggest audio quality
step and is out of scope here.

---

## Recommended sequence — perceived quality per week of effort

**Week 1 — The cut-out pass (Cause 1). This is the single change that
moves perceived quality most.** Alpha pipeline (post-process existing
objects + gpt-image-1.5 `background: transparent` lane for new art),
`ArtTile` cutout mode with contact shadows, un-medallion Mithu, sticker
rim reserved for actual stickers. One shared widget → every screen in
the app changes at once. Nothing else on this list has that leverage.

**Week 2 — Places + chrome (Causes 2, 4).** Landscape scene regen with
designed play zones; first three per-game micro-sets (table / pots /
garden); delete the AppBar; kill the Material spinner. By end of week 2
the app *photographs* like a premium app — screenshots stop looking
like flashcards, which also matters for the store listing (M4).

**Week 3 — Character & continuity (Causes 3A, 5).** Mithu pose set via
image-edit (point/clap/hop, with alpha); Mithu-bridged round
transitions; doorway-rect scene entry; in-scene celebrations; seamless
ambient loops + room tone.

**Then, as scheduled decisions:** the Rive ADR after the native
recording session (3B — the one item that likely needs outside
animation budget, exactly as the reference studios spent it), remaining
micro-sets for all 17 games, and object foley expansion.

**Explicitly not the problem:** tap feel, latency, reward juice, idle
life — P0–P2 of [`game-feel.md`](game-feel.md) already bought parity
there. Do not spend further weeks on juice before the art-integration
debt above is paid; per the ratios here, the next unit of "premium" is
~70% art pipeline and composition.

## Sources

- Apple, [Behind the Design: Pok Pok Playroom](https://developer.apple.com/news/?id=5bcex7xf)
- Sketch, [Reimagining digital play: Pok Pok](https://www.sketch.com/blog/pok-pok/)
- Game Developer, [How "just letting kids be kids" drives the design of Pok Pok Playroom](https://www.gamedeveloper.com/design/how-just-letting-kids-be-kids-drives-the-design-of-pok-pok-playroom)
- Common Sense Media, [Pok Pok Playroom review](https://www.commonsensemedia.org/app-reviews/pok-pok-playroom); [Pok Pok FAQs](https://playpokpok.com/faqs/); [9to5Mac hands-on](https://9to5mac.com/2021/05/20/hands-on-with-pok-pok-playroom-kids-app/)
- Motionographer, [The design process behind Toca Boca's apps](https://motionographer.com/2016/04/27/the-design-process-behind-toca-bocas-infectious-apps/)
- The Little Labs, [Khan Academy Kids case study](https://thelittlelabs.com/work/khan-academy-kids); Khan Kids [character docs](https://khankids.zendesk.com/hc/en-us/articles/360049358751-Learn-more-about-the-characters-inside-Khan-Academy-Kids)
- Pixelkin, [Endless Alphabet & Endless Reader](https://pixelkin.org/2015/02/05/anas-apps-endless-alphabet-and-endless-reader/); [LearningWorks on Sago Mini World](https://learningworksforkids.com/apps/sago-mini-world/)
- OpenAI, [Image generation API](https://developers.openai.com/api/docs/guides/image-generation) (gpt-image-2 `background` excludes `transparent`; gpt-image-1.5 supports it)
- Repo evidence: `tools/asset-gen/gen_images.py` (white-background prompts, gpt-image-2, portrait scene sizes); `assets/art/**` (RGB, no alpha); `lib/widgets/art_tile.dart`; `lib/widgets/mithu_talking.dart` (ClipOval); `lib/scenes/scene_screen.dart` (BoxFit.cover portrait bg); `lib/activities/*` (ArtTile rows in 16/17 games); `lib/activities/carousel_screen.dart` (AppBar, spinner, AnimatedSwitcher)
