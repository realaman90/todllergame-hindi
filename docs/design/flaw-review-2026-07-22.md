---
type: Design
title: Adversarial flaw review — Kimi K3, 2026-07-22
description: Read-only line-level review of lib/ after the founder's "still feels sub-premium" verdict — UX flaws, feel bugs, code-level causes, visual inconsistencies, ranked top-10. Companion to premium-gap-analysis.md.
tags: [design, review, qa, game-feel]
timestamp: 2026-07-22
status: findings triaged into the premium program (see premium-gap-analysis.md)
---

# Adversarial flaw review (Kimi K3, 2026-07-22)

- `lib/scenes/word_overlay.dart:85` — the entire word card sits inside the dismiss GestureDetector: **poking the big Hindi word dismisses the card**. The one thing a child will definitely poke punishes her.
- `lib/scenes/scene_screen.dart:183-229` — the object she just named is removed from the scene 850ms after its celebration. F10 says the cow you just named shouldn't vanish while you watch.
- `lib/scenes/home_screen.dart:56-80` — first-launch welcome holds the screen for two full VO clips with no visual "tap to skip" affordance; returning launches enforce a hard 1800ms floor even if audio finished in 500ms (`:74-77`).
- **Deterministic content kills replay**: `peek_activity.dart:57-60`, `shadow_activity.dart:56-58`, `wipereveal_activity.dart:56-58` all seed RNG from `scene.id.hashCode` — the answer, order, and hidden object are **identical every replay**. Toddlers replay endlessly; they'll memorize position, not words. (Bonus: Dart `String.hashCode` is per-isolate randomized, so `art_tile.dart:35` tilt and `scene_screen.dart:116-136` slot jitter aren't even stable across app launches, contradicting their own comments.)

---

## 2. Feel / polish flaws

**The single biggest one:** `lib/scenes/home_screen.dart:44` starts `theme.mp3` in `initState`; `carousel_screen.dart:114` replaces the ambient and `:185` stops it in `dispose` (same in `scene_screen.dart:67,77`). Popping back never re-runs `initState`, so **after the first game or scene visit, Home is permanently silent for the rest of the session.** The front door of the app loses its music after one use — few things read "sub-premium" faster.

**The house tap verb under-delivers.** `lib/juice/tap_bounce.dart:66` — release overshoot is **1.07**, but F6 mandates **1.15–1.3**. The most-executed animation in the app delivers roughly half the prescribed pop on every single touch. Related: `tap_bounce.dart:28` makes `tapSound` opt-in (default null) while haptics default on — inverting F11/F20 — so `doorway_card.dart:31-33`, `sticker_tile.dart:35-37`, and `sticker_count_pill.dart:62-63` are all **silent on tap**. And `:92-105` — a mid-release re-tap snaps scale from ~1.05 to 1.0 in one frame; every toddler mash has a visible discontinuity.

**Celebrations are the least polished moments in the app** (they should be the most):

- `lib/stickers/sticker_earned_overlay.dart:77` — confetti seeded by `sticker.key?.hashCode ?? 42`; both call sites pass no key → **seed is always 42. Every celebration in the app is pixel-identical, forever.** `particle_burst.dart:62` similarly seeds from the trigger counter (burst #1 identical every session).
- `lib/scenes/scene_screen.dart:255` → `sticker_count_pill.dart:51` — `discover()` notifies immediately, so the pill's landing bounce fires at celebration *start* and plays **invisibly behind the opaque overlay**, ~1400ms before the sticker "arrives." The code comment describes an intent the wiring defeats.
- `lib/activities/carousel_screen.dart:293-295` → `sticker_earned_overlay.dart:131-136` — the carousel has no sticker pill, so the earned sticker flies across the screen and shrinks into **empty air** at a hardcoded corner rect. The payoff lands on nothing.
- `sticker_earned_overlay.dart:144-146` — flight uses `easeInOutCubic` (F7 says ease-out), consumes the whole 1400ms, and has **no arrival thump/sound** at the destination. Dismissal at `:71-74` is a fixed 1400ms decoupled from the voice line, which regularly outlives it — overlay vanishes mid-sentence.
- `lib/widgets/mithu_talking.dart:50-57` — `_dancing` is substring-matched on `currentVoicePath`; during `playPraise`'s second clip (the word restatement) the path changes and **Mithu stops dancing exactly at the celebration peak**. Also `:79-81` — beak flaps at a fixed 140ms metronome through the inter-clip dead air: ventriloquism during silence.
- `lib/audio/audio_service.dart:276` — hard-coded 120ms gap + serialized load between every sequence clip → "शाबाश! … आम!" comes out with audible dead air; robot cadence, not a warm person. `:332-347` — ambient ducking quantized to 6 audible volume steps.
- Missing/patchy: no `ParticleBurst` on correct answers in oddone, bigsmall, pattern (four siblings have it); wipereveal has no burst at all; none of the four trace/drag activities ever call `playPraise` — the best celebration asset is reserved for puzzles only. Celebration-exit durations are a dice roll: 1100/1200/1100/900/1100/1300/900ms across the seven selection games; 600/1400/900/900/700/800+1100/1500ms across the other eight.

**Abrupt, linear, or missing motion.**

- `lib/activities/plant/plant_activity.dart:58-59,133` — the plant's growth, the hero animation, is **linear** (controller forwarded with no curve, consumed raw). The butterfly at `:179-191` pops into existence mid-flap — no entrance path (F8).
- `lib/activities/pattern/pattern_activity.dart:213-229` — the answer fill-in scale tween has **no curve** (default linear) — the payoff is the only linear motion in the seven selection games.
- `lib/scenes/tappable_object.dart:64-93` — every scene-object tap animation is `Curves.easeInOut` with **no press-down squash at all**; bypasses TapBounce entirely, so also no haptics, no pentatonic ladder (`:98` plays raw `tap_pop` every time — F12 violated on the app's core toy).
- Instant unanimated scale snaps: `shadow_activity.dart:198-199` and `plant_activity.dart:121-122` (DragTarget hover), `train_activity.dart:178-179` (wagon excitement).
- `lib/activities/peek/peek_activity.dart:207` — wrong-answer wobble is `sin(idle·2π·14)·0.07`: a 14Hz buzz that can start at a non-zero angle (visible snap), and its visible length depends on where the 3000ms idle phase happens to be. Same idle-derived wobble in sizes/missing/soundmatch vs. a dedicated 350ms controller in oddone/bigsmall/pattern — **two different wrong-tap wobbles across sibling games**.
- `lib/juice/particle_burst.dart:69,115` — pieces are 9–16px "fingernail specks" with a **linear** alpha fade ending in an abrupt disappearance at t=1. The docstring claims "few, BIG, slow"; the code delivers many/small/fast. Same for the earned overlay's 26 pieces at 7–14px + 14 sparkles at 4–9px (`sticker_earned_overlay.dart:93-101`).
- Idle-tempo drift: breath period 3200ms (oddone/bigsmall), 3000ms (pattern/sizes/missing/soundmatch), 3400ms (linematch). Carousel neighbors visibly breathe at different tempos. `missing_activity.dart:189-231` — shown tiles don't breathe at all during the intro; wipereveal's frost window (`:129-146`) is fully static — the two most "invitation needed" screens have none (F9).
- `lib/scenes/scene_picker_screen.dart:27-58` — picker cards are completely static: no breathing, no PopIn stagger, no sound. Home → picker is a step *down* in aliveness. No `NudgeTimer` exists anywhere outside activities — idle on Home (where a 3-year-old idles most) produces nothing (F17).
- `lib/scenes/home_screen.dart:96-106` — the "choose a door" pulse stops the instant the voice line ends (`_currentVoicePath` nulled at clip end), i.e. exactly when the child starts deciding.
- `lib/activities/bubbles/bubbles_activity.dart:101` — a bubble pop plays only the generic `playTapNote()`. The most satisfying moment of the breather sounds like tapping a button.
- `lib/stickers/sticker_wall_screen.dart:102-104` + `pop_in.dart` — PopIn runs in `initState`; `GridView.builder` recycles tiles, so stickers **re-pop every time they scroll back into view**. And `delayMs: 40 * (index % 12)` means the stagger visibly restarts at sticker #13.

---

## 3. Code-level issues that *cause* the feel problems

**Rebuild/paint sins in hot paths.**

- `lib/activities/bubbles/bubbles_activity.dart:83-95` and `balloons_activity.dart:106-124` — `_tick` is an `addListener` on a repeating controller calling **`setState` every frame**, rebuilding the entire Stack at display rate. Worse, `b.phase += speed/(60*12)` is **frame-rate-dependent physics pinned to 60Hz**: on a 120Hz iPad everything rises twice as fast; on a janky spell it slows. The two games whose entire point is calm, smooth motion.
- `lib/activities/wipereveal/wipereveal_activity.dart:199-207` — `_FrostPainter.paint` runs `canvas.saveLayer` + `BlendMode.clear` + `MaskFilter.blur` **per wipe circle**, `_wipes` grows unbounded (`:80`), and `:158` copies the whole list per wipe → O(n²) copying mid-gesture. The classic low-end Android GPU-killer combo, in a game that's one long gesture.
- `lib/scenes/scene_screen.dart:326-366` — six objects each with an infinite controller + nested AnimatedBuilders, each tile painting **two blurred BoxShadows** every frame (`art_tile.dart:44-57`), zero `RepaintBoundary`s. Continuous blur repaint on low-end Android. `TapBounce` (`tap_bounce.dart:125-132`) and `PopIn` (`pop_in.dart:44-46`) also lack the `RepaintBoundary` that `IdleBreath:55` has — inconsistent discipline between house primitives.
- `lib/widgets/mithu_talking.dart:79-85` — `Timer.periodic` + `setState` 7×/s while talking (the file already has the correct AnimatedBuilder pattern for idle); the 5 Mithu frames are never precached (`:171-173`) so the first celebration frame-swap can decode-jank at the worst moment.

**Audio races and latency.**

- `lib/audio/audio_service.dart:83-85,136-145` — only 6 SFX are preloaded; **word clips load on first use via temp-file staging**. The pop is instant but the *word itself* — the actual teaching feedback — lands 300–800ms late on cold cache. F2 is met for the pop, not the lesson.
- `lib/audio/audio_service.dart:242-249` — the same-clip "let it finish" guard only covers single clips; a re-tap during `playPraise`'s two-clip sequence supersedes it **mid-word** (rapid tapping systematically truncates the F14 restatement), and `_pendingSfx = thenSfx` is unconditional, so a superseding op silently eats a queued win stinger.
- `lib/juice/nudge_timer.dart:16-19` — audio-blind: the 7s nudge can fire while a 3-clip prompt is still playing and `playPromptSequence` kills the voice **mid-word** (e.g. `whack_activity.dart:92-96`). Mithu interrupts himself. Same class: `pattern_activity.dart:84-102` — nudge can launch a second `_speakSequence` with no in-flight guard → interleaved, garbled instructions.
- `lib/audio/audio_service.dart:208` — F14 word-restatement is silently conditional on sceneId/slug/language being passed; call sites that omit them (`balloons_activity.dart:153`) get a generic cheer with no warning. Silent curriculum degradation.
- `lib/scenes/tappable_object.dart:113-117` + `scene_screen.dart:138-147` — two objects tapped within 350ms: the second `_showObject` overwrites `_pendingSlug`; the first object silently never gets discovered. Lost sticker race.
- Unawaited futures racing the voice lane: `train_activity.dart:87-88` fires SFX + word unawaited (quick double-load cuts the first word mid-syllable); `main.dart:36-42` fire-and-forget init.

**Layout that breaks on small phones / tablets.**

- `lib/scenes/tappable_object.dart:132` × `lib/widgets/art_tile.dart:31` — **double uiScale**: scene objects multiply by `uiScale` twice (1.82× intended on tablets), while `scene_screen.dart:333-339` positions them with the *unscaled* size → mis-centered, edge-clipped objects on every iPad, and inconsistent with the overlay card's single-scaled art.
- `lib/theme/ui_scale.dart:7-8` — `(shortestSide/600).clamp(1.0, 1.35)` means **sizes never shrink on small phones**. Combined with fixed budgets: `peek_activity.dart:135-186` (~405dp) and `plant_activity.dart:123-207` (~390dp) overflow a ~360dp-tall landscape phone, clipping the exact tiles the child must tap; `numtrace_activity.dart:180` (320dp box on a 320dp-tall screen); `home_screen.dart:152-207` fixed 614dp-wide Row with no FittedBox fallback.
- `lib/activities/linematch/line_match_activity.dart:144-145,52` — row spacing is height-relative (0.28h) but tiles are fixed 104dp → on a 360dp-tall phone adjacent rows **visually overlap**; a finger between rows can snap to the wrong one.
- `lib/activities/balloons/balloons_activity.dart:188-196` — hardcoded -44/-55 offsets computed pre-scale, then `Transform.scale(uiScale)` applied → on tablets the painted balloon drifts off its anchor and the burst position.
- `lib/activities/pathtrace/pathtrace_activity.dart:138-139` — unscaled `+44`/`-4` fudge offsets mixed into scaled math.
- **No image precaching anywhere** — every `Image.asset` (`art_tile.dart:61`, `scene_screen.dart:513`, all activities, `doorway_card.dart:52-56` which also lacks the `errorBuilder` ArtTile has) decodes on first frame; PopIn plays on a white rim on cold cache.

**State/lifecycle bugs.**

- `lib/settings/parent_gate.dart:53,59-64` — **the gate is mashable.** Hold progress resumes from the current value and decays over 200ms; a toddler double-tapping at 4–6Hz interrupts the decay before zero, ratcheting the ring to completion. The doc comment claims release resets progress; the code doesn't. Difficulty calibration is inverted — hard for parents (any 18px drift fires `onTapCancel`, `:101-104`), beatable by mashers.
- `lib/stickers/sticker_service.dart:43-49` — `discover()` awaits the disk write *before* `notifyListeners()` (UI waits on I/O); process death in between loses the sticker. `markIntroSeen()` never notifies. `load()` (`:34-41`, and `settings_service.dart:27-36`) has no error handling → the `loaded` completer can hang forever.
- `lib/settings/settings_screen.dart:94-97` — one unawaited SharedPreferences write **per slider drag tick**.
- `lib/scenes/scene_screen.dart:331` — `_slotAssignment[object.slug]!` force-unwrap: a rotation race hard-crashes the scene. `carousel_screen.dart:216-221` — round-load error silently pops the route with zero feedback. `sticker_wall_screen.dart:58-61` — load failure renders the same widget as "no stickers yet."
- Uncancelled delays everywhere (mounted-guarded but racy): `pop_in.dart:32-34`, `home_screen.dart:85-87`, `whack_activity.dart:152-157`, `plant_activity.dart:101-103`, `train_activity.dart:91-100` (~3s of chained uninterruptible delays, with the 4th word VO talking over the chug notes).
- `lib/activities/missing/missing_activity.dart:75-91` — nudge arms only after the serial-audio intro completes; any hung clip leaves the screen dead with untappable tiles and no recovery.
- Dead code/authored-content traps: `scene_object.dart:12` — `pos` parsed but consumed nowhere (JSON positions silently ignored); `balloons_activity.dart:112-115,122` — `escaped` computed then cleared unread; `pattern_activity.dart:153` — unused LayoutBuilder; `carousel_screen.dart:60` — scene ids hard-coded, new scenes silently never played.

---

## 4. Visual-design flaws visible in code

**Material chrome breaking the toy world.**

- Default `CircularProgressIndicator` in three child-facing places: `carousel_screen.dart:224`, `scene_screen.dart:289-292`, `sticker_wall_screen.dart:63` — a stock spinner flashing between every carousel round.
- Material AppBars on scene, picker (unstyled `paper2` bar over the backdrop — `scene_picker_screen.dart:14-20` vs carousel's transparent one, `:196-212`), sticker wall; flat black `Colors.black` scrims at 0.35 alpha in `word_overlay.dart:93` and `puzzle_overlay.dart:83` (and `puzzle_overlay.dart:78` lets any stray palm touch dismiss the puzzle).
- Stock Material glyphs: `Icons.auto_awesome` (puzzle door), `Icons.volume_up_rounded` (puzzle overlay — the only Material icon in a game screen), `Icons.collections` / `Icons.arrow_back_rounded` / `Icons.arrow_forward_rounded` — three different icon styles across three nav controls; `Icons.grid_view_rounded`/`Icons.pin_rounded` as activity identity badges (`activity_sticker_tile.dart:48-55`) that a pre-reader cannot decode; `home_screen.dart:340-346` — the only default ink splash in the app (settings IconButton).
- `lib/settings/settings_screen.dart:32-35` — raw Material back arrow, `AlertDialog`, `TextButton` one gate away from the child flow — fine *if* the gate held (it doesn't, §3).

**Cross-game inconsistency (the 17 games look like 17 apps).**

- Tile sizes with no system: 112 (oddone) / 156+88 (bigsmall) / 116+88 (pattern) / 104 (linematch) / 64-104-148 (sizes) / 108+97 (missing) / 116 (soundmatch) / 92 (pairs) / 100 (peek) / 110 vs 93.5 within one screen (shadow) / 96 (whack) / 66 tray (stickerplay) / 88 (train, puzzles) / 76 (numtrace mangoes).
- Corner radii: shelf slots 14, answer slot 20, cloth 22, ArtTile `artSize*0.22`, word card 28, activity sticker 0.18·size with a 2.5 border vs ArtTile's borderless layered shadows — object and activity stickers on the *same wall grid* don't read as one family. Border weights 2/2.5/3/3.5/4 scattered.
- Theme hardcodes ignoring the scene palette: `soundmatch_activity.dart:161-162` (always mehndi green), `plant_activity.dart:110-111,217-218` (always mehndi — jarring from the farm scene), `train_activity.dart:133-143` (marigold/peacock wagons in every world), `sticker_count_pill.dart:71` (always mehndiDeep), while everything else uses `AppColors.forTheme(scene.theme)`.
- Label presence inconsistent (soundmatch/missing show labels; five siblings don't); pairs is the only game rendering its title on-canvas (`pairs_activity.dart:115-118`).
- `app_text_styles.dart:21-33` — text sizes never multiplied by uiScale: on a 12.9" iPad art tiles grow 1.35× but labels stay 28pt — text looks relatively smaller on bigger screens (the reverse of the complaint that motivated ui_scale).
- `home_screen.dart:321-330` — the English wordmark appears twice on one screen transition plus two different Hindi taglines.
- `sticker_wall_screen.dart:121-128` — `puzzle:` stickers render art identical to the object sticker with no badge → the wall shows apparent duplicates.
- `mithu_talking.dart:140` — spin-hop dance does a full 360° head rotation inside a ClipOval; reads glitchy/scary at 3 vs. the other two gentle dances.

---

## 5. Top 10 improvements, ranked by feel-impact ÷ effort

1. **Fix the TapBounce release overshoot: 1.07 → 1.22.** One constant at `lib/juice/tap_bounce.dart:66`. The atomic tap of the entire app currently delivers half the F6-mandated pop; this is the cheapest, highest-frequency feel upgrade available. (While there: start the re-press tween from the current rendered scale, `:92-105`, to kill the mash snap.)
2. **Restart Home music on return.** `home_screen.dart:44` plays theme only in `initState`; move/resume it in a `didChangeDependencies`/route-aware hook (or have `carousel_screen.dart:185`/`scene_screen.dart:77` hand the theme back instead of `stopAmbient`). A silent front door after one game is the loudest "sub-premium" signal in the build.
3. **Make sound non-optional on TapBounce call sites.** Pass `tapSound` (or default it) at `doorway_card.dart:31`, `sticker_tile.dart:35`, `sticker_count_pill.dart:62`, and wrap `back_button.dart:14` + `home_screen.dart:373` (sticker entry) in TapBounce with a ≥64–72dp hit area. Fixes five always-visible silent/undersized controls in one sweep.
4. **Kill the dead taps in the drag games.** Add `onTapDown` grab+speak to `line_match_activity.dart:282-287` (and fix the wrong-row burst at `:224` — pass `_rightRowOf(pair)`), give `train_activity.dart:264` cargo an onTap word+bounce, switch `puzzle_card.dart:144` to touch-down, and make trace-misses play a soft note while widening the forward window (`numtrace_activity.dart:134`, `pathtrace_activity.dart:79`). One pattern, four games, removes the most frustrating silent failures.
5. **Repair the celebration payoff chain.** (a) `sticker_earned_overlay.dart:77`: seed `Random()` — celebrations stop being pixel-identical; (b) trigger the pill bounce on flight *completion* instead of at `discover()` (`scene_screen.dart:255`, `sticker_count_pill.dart:51`); (c) in the carousel, fly to a real target or add a pill (`carousel_screen.dart:293-295` vs `sticker_earned_overlay.dart:131-136`); (d) flight curve → ease-out + arrival ding (`:144-146`). Four small diffs fixing the app's biggest moment.
6. **Inflate hit targets on required small answers** with a transparent halo inside TapBounce (or a minimum hit-size floor in the primitive): `sizes_activity.dart:41` (64dp final answer), `big_small_activity.dart:40` (88dp), `scene_screen.dart:463` (puzzle door), `tappable_object.dart:186-190` (scene objects). Guaranteed-missed "correct" taps read as the game ignoring the child.
7. **Preload the words.** In `audio_service.dart` + scene load, preload the visible scene's word clips (and each activity's round clips) into memory before first tap. Closes the 300–800ms gap between the instant pop and the actual teaching feedback (F2), which is currently only met for the pop sound.
8. **Fix the frame-rate-locked tickers in bubbles/balloons.** Replace `setState`-per-frame + `phase += speed/(60*12)` (`bubbles_activity.dart:83-95`, `balloons_activity.dart:106-124`) with time-based positions driven off controller value + per-item AnimatedBuilder. Eliminates 2×-speed motion on 120Hz iPads and the worst jank on cheap Android — in the two "calm" games.
9. **De-randomize-proof the replays + gate.** Replace `hashCode`-seeded RNG with unseeded `Random()` in `peek_activity.dart:57`, `shadow_activity.dart:56`, `wipereveal_activity.dart:56` (different answer each replay), and make `parent_gate.dart:53,59-64` snap progress to 0 on release. Replayability is the curriculum loop; the gate is a compliance surface.
10. **Unify the celebration/transition timing constants.** One shared `JuiceTiming` (solve-exit, re-prompt delay, breath period, wobble controller) replacing the 1100/1200/900/1300/1400/600/1500ms scatter across all 17 activities and the idle-derived 14Hz wobble in `peek_activity.dart:207` / `sizes_activity.dart:136-138`. This is the "17 games feel like one app" pass — moderate effort, but it's the difference between a collection of demos and a product.

**Honorable mentions (cheap, real):** cancel stale re-ask timers in `sizes_activity.dart:124-129`/`soundmatch_activity.dart:139-143`; add `key: UniqueKey()` to `pairs_activity.dart:26`; swap the three `CircularProgressIndicator`s for a branded pulse; make the word-overlay card swallow taps instead of dismissing (`word_overlay.dart:85`); fix the double-uiScale + positioning math (`tappable_object.dart:132` × `scene_screen.dart:333-339`) before any iPad testing; small-phone overflow pass on peek/plant/numtrace (`ui_scale.dart:7-8` clamps at 1.0 — no shrink path exists).

**What NOT to touch** (verified good): TapBounce's touch-down mechanics and unclipped-release guard; the pentatonic ladder; warm redirection with named objects; whack's no-timing-pressure rig; trace games' forward-only progress; linematch's ValueNotifier finger-line; the carousel's generation-stamp debounce; IdleBreath's RepaintBoundary + per-item phases; word overlay's entrance-from-tapped-rect; the audio service's generation-counter voice supersede and same-clip stutter guard.

One caveat on method: this was a static read-only review — I did not run the app or profile frame times. The perf findings (§3) are pattern-certain (setState-in-ticker, saveLayer+blur, unprecached images) but their on-device severity should be confirmed on a cheap Android 8 device per the game-feel doc's own profiling rule.
