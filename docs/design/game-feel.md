---
type: Design
title: Game feel — research foundation & feel rules
description: Research synthesis (canon + toddler studies + best-in-class studios + Flutter techniques) distilled into numbered feel rules with parameters, an audit of the current build, and the recommended build order. Feeds a build spec in specs/tbd/.
tags: [design, game-feel, juice, audio, animation, research]
timestamp: 2026-07-21
status: research complete — build spec not yet cut
---

# Game Feel — Research Foundation

Founder call 2026-07-21: build proper game feel **before** more content.
This doc is the foundation: what "feel" means for a tap game at age 3,
the numbered rules any interaction must satisfy (with parameters), how
the current build measures up, and the tech choices implied. The
existing [`polish-backlog.md`](polish-backlog.md) is the symptom list;
this is the system. A build spec in `../specs/tbd/` gets cut from here.

Research base: Swink *Game Feel*, Jonasson/Purho "Juice it or lose it",
Nijman "The art of screenshake", Disney's 12 principles, Sesame Workshop
*Best Practices for Preschool Touch Tablets* (50+ studies), Vatavu et
al. 2015 (89 children aged 3–6 — the best numeric dataset), NN/g
children's UX, and published design material from Toca Boca, Pok Pok
(Apple Design Award), Originator/Endless Alphabet, Sago Mini, Duck Duck
Moose, Khan Kids. Full source list at the bottom.

## What "feel" means here

Swink's definition of game feel assumes continuous control (steering
Mario). A tap game has none — so **our game is almost 100% the polish
layer**: response latency, animation grammar, sound, and character
reaction ARE the game feel. Two ideas survive the translation intact:

1. **The 100ms rule.** Something must visibly/audibly change within
   ~100ms of finger-down or the brain decouples cause from effect. For
   a 3-year-old this is stricter: no visible response ≈ "it's broken" ≈
   rage-tapping.
2. **ADSR envelopes.** Every response has attack/decay/sustain/release.
   Attack must be instant; the rest can be slow and watchable. Toddler
   tuning: **fast start, slow middle and end** — never the reverse.

The Miyamoto test, adapted: *mute the app, remove all rewards — is
tapping one object with this squash, bounce and pop still fun for two
minutes?* If not, tune the tap itself before adding more reward juice.
(A 3-year-old happily taps one perfect-feeling object 40 times — and
that repetition is the vocabulary loop. Feel IS curriculum delivery.)

## The Feel Rules

Any new or reworked interaction should satisfy every rule. Same
contract as [`interaction-patterns.md`](interaction-patterns.md): if it
can't, flag it — don't silently make an exception.

### Input registration

- **F1 — Register on touch-DOWN, never on finger-lift.** Sesame's
  explicit recommendation: toddlers press too hard, too long, and
  repeatedly; on-lift registration (Flutter's default `onTap`) reads as
  broken. Use `onTapDown` for the reaction (visual + SFX may fire
  immediately); navigation/side-effects may still complete on up.
  *Highest-leverage single change available to us.*
- **F2 — First feedback frame < 100ms.** Visual pop and SFX attack on
  the same frame as touch-down. Requires preloaded, memory-resident
  SFX (see Tech below) — an asset load on the tap path breaks this rule
  by itself.
- **F3 — Generous, isolated targets.** ≥ 2cm touch targets (NN/g: 4×
  adult minimum); tolerate up to ~10mm miss offset and up to 5s press
  duration (Vatavu); no active controls along the bottom edge (resting
  wrists); no adjacent tappables. Multiple fingers on one object = one
  touch, never an error. Ignore "holdover" re-taps at the previous
  target's location right after screen change.
- **F4 — Tap ≫ drag.** Completion at age 3: tap 98.7%, drag ~92% (and
  much worse on tablets), double-tap 82.8%, two-finger 53.7%. Every
  drag needs: word/entertainment DURING the drag (Endless Alphabet
  letters sing their sound while dragged), partial-completion
  tolerance and friendly re-grab (kids lift mid-drag constantly), and
  gentle snap-back — never a reset. Double-tap/press-hold are for
  parent gates only, precisely *because* toddlers fail them.

### Response grammar

- **F5 — No dead taps, with a strict hierarchy.** Everything on screen
  reacts to touch — but *goal > toy > background*. Background objects:
  small wiggle + soft chirp. Goal objects: the full pop. If everything
  erupts equally the child can't find the goal (both GDC talks' core
  warning).
- **F6 — The scale-punch is the house tap verb.** Finger-down: squash
  to ~0.9 in 80–100ms (volume-preserving: x up while y down). Release
  into overshoot ~1.15–1.3, settle to 1.0 with ease-out-back, total
  300–450ms. Exaggerate more than adult UI — but the object must stay
  recognizable (it's the word being taught).
- **F7 — Nothing moves linearly; ease-out by default.** Entrances
  decelerate, exits accelerate, pops overshoot (`easeOutBack`;
  `elasticOut` for big reward moments only). Duration bands: response
  animations 250–450ms; scene transitions 400–600ms; celebrations
  800–2000ms. Adult UI's 400ms ceiling doesn't apply to *watching*
  moments — only to *response* moments. Never delay the start.
- **F8 — Anticipation and follow-through.** ~100–150ms wind-up before
  hops/launches (doubles as a where-to-look cue); overshoot the target
  by 10–20% and settle with a damped spring; let secondary parts (ears,
  wings, lids) lag the body a few frames. One wind-up, one action, one
  settle — no long chains.
- **F9 — Idle life everywhere.** Every scene breathing: layered-sine
  bob/sway on all tappables with a random per-item phase (lockstep
  wiggling reads as mechanical), blinks every 3–6s, sparkle-hint on the
  goal. A static screen is a broken screen. (Pok Pok's rule that
  everything may "jitter a little" — handmade imperfection reads as
  warm and toy-like.)
- **F10 — Permanence, positive-only.** The child's actions leave
  friendly evidence: placed stickers stay, a popped balloon frees a
  butterfly that stays, a fed animal keeps a happy belly. Proof of
  agency — never wreckage.

### Sound

- **F11 — A sound for every registered touch; the child causes almost
  all audio.** Pok Pok: sound is feedback, not wallpaper. Music stays
  quiet and duck-able; the spoken Hindi word is never masked.
- **F12 — Never the same sample twice in a row.** Pitch-vary repeats
  ±5–10%, or better: map successive taps in a round to an ascending
  **pentatonic scale** (can't hit a wrong note — rage-tapping becomes
  melody). Requires an audio engine with per-play pitch (see Tech).
- **F13 — Organic, non-fatiguing timbres.** Marimba, kalimba, wood,
  bells, real-object foley — warm low-mids, narrow dynamic range, no
  bass hits, no earworm jingles. The two tests: survives the 400th
  repeat; parent never needs to mute it in a restaurant.
- **F14 — The celebration restates the word.** The biggest audio slot
  in every reward moment is the Hindi word again ("शाबाश! आम!") — juice
  amplifies the curriculum, not generic success. Distinct payoff
  fanfares (stingers) vs feedback ticks. Prompts stay interruptible;
  goal-word at the END of instruction sentences ("आम को दबाओ!").

### Reward & redirection

- **F15 — Mithu's reaction IS the reward system.** Jonasson/Purho's
  single most memorable juice was eyes on the paddle; Khan Kids uses
  characters for all encouragement. A character's face beats any
  particle burst at age 3. Mithu should witness play (present during
  games, not only at round end) and react — gasp, cheer, dance.
- **F16 — Warm redirection, never failure (3-level scaffold).** Sesame:
  level 1 cheerful "try again" → level 2 restate goal + hint → level 3
  highlight the answer until tapped (then auto-advance if stuck).
  Near-miss sound: a curious, consonant boop — never a buzzer, never
  minor-key. (In explore scenes, most "wrong" taps are simply small
  fun per F5.)
- **F17 — Idle nudge at 6–8s.** No input for 6–8s in a prompted task:
  sparkle/glow the target + Mithu re-prompts softly. A helping hand,
  never a countdown — no visible timer, no consequence.
- **F18 — Particles: few, big, slow.** Reward bursts of tens (not
  hundreds) of large pieces falling with gentle gravity over 1–2s a
  child can visually track. A screenful of tiny fast sparks is noise
  at 3. Second use: idle sparkle as the tap-here affordance.
- **F19 — Beats, not freezes; pulses, not shakes.** Hit-stop and
  slow-mo read as jank to a toddler. Instead: a calm 300–500ms
  breathing beat after a success before the next prompt. Screenshake
  is cut from the toolkit (disorienting, reads as something wrong) —
  replace with a ≤2% whole-scene scale pulse or a 1.0→1.05 zoom over
  400–600ms on celebrations, or jelly-wobble the *object*.
- **F20 — Haptics as garnish.** `HapticFeedback.lightImpact()` /
  `selectionClick()` alongside SFX on pops and wins. Free on phones,
  **no-op on iPads** (no Taptic Engine) and weak on budget Android —
  so haptics may never carry meaning alone. Avoid heavyImpact/vibrate
  (startling).

### Anti-patterns (canon advice we explicitly refuse)

Screenshake at Vlambeer amplitude · white hit-flash / strobing
(photosensitivity) · hit-stop freezes · buzzers, X-stamps, sad stings,
lives, game-over · any time pressure (countdowns, escaping objects) ·
score counters/combos/streaks · destruction permanence · loud bass and
volume spikes · many tiny fast particles · uniform juice on everything
· registration on finger-lift · double-tap/pinch/flick in child flow ·
small or bottom-edge targets · unskippable prompts · juice as
compensation for a tap loop that isn't fun muted (Miyamoto test).

## Where the current build stands (audit 2026-07-21)

Full audit lives in the session that produced this doc; summary against
the rules:

**Already good:** scene `TappableObject` (instant pop + SFX + word —
closest to F2/F6 today); per-object idle breathing with phase offsets in
scenes (F9); Mithu's idle life (breathing, wing flutters, 3 dance
styles) and the sticker-earned overlay (confetti + sparkle + flight +
dance, interruptible) — the one real celebration; smooth ambient
ducking ramps; carousel round transitions.

**The gaps, ranked:**

1. **Audio latency breaks F2 on every tap.** `AudioService` reloads
   every asset from disk per play (`stop → setAsset → play`), including
   `tap_pop`. No preloading, no pooling, no pitch control (F12
   impossible on `just_audio`).
2. **Registration on finger-lift everywhere** — violates F1 across the
   app (`onTap`/`GestureDetector` defaults).
3. **Four of eight carousel games have silent taps** (bigsmall, oddone,
   pattern, linematch selections play no SFX — voice only, which loads
   late). Violates F11.
4. **Zero haptics** (F20).
5. **First-touch dead zones:** home doorway cards, scene picker, sticker
   wall (untappable, static, no entrance) — the child's first taps each
   session get nothing (F5).
6. **Mithu absent during all mini-games** — reward presence only at
   round end (F15).
7. **Mid-round successes under-celebrated:** fixed `Future.delayed`
   gaps + modest glow; no mid-round particles or Mithu reaction; sticker
   flight from carousel games flies to a corner fallback, and the
   sticker-count pill never reacts on landing (F14/F18, missed payoff
   beat).
8. **Only 3 SFX exist** (`tap_pop`, `celebration`, `sticker_earned`) —
   no per-family sounds, no pentatonic ladder set, no stingers (F12/13).
9. **Juice code is duplicated, not shared:** wobble ×5, squash ×1
   one-off, particles ×3 painters; `PopIn` skipped by pairs/home/
   sticker wall; pairs tiles fully static (F9).
10. **No idle-nudge system** (F17) and no 3-level redirection — wrong
    taps get one voice line (F16).

## Tech implications (Flutter, plain-widget — per ADR-005)

- **Audio engine: `flutter_soloud` 4.x — requires an ADR** (stack
  change; current stack doc names just_audio/audioplayers).
  Memory-resident preloaded sources, FFI (no platform-channel latency),
  designed polyphony, per-play `setRelativePlaySpeed` (pitch ladders:
  rate = 2^(n/12)), fades/loops; it's now the official Flutter cookbook
  recommendation for game SFX. `just_audio` is a music/podcast player:
  no preload-to-memory, no pitch, no latency guarantees. Migration
  note: run SoLoud as the **only** engine (SFX + voice + music) — mixed
  audio plugins fight over the iOS audio session. `soundpool` is
  discontinued; `audioplayers` weaker on iOS latency.
- **Shared juice kit** (new `lib/juice/`): `TapBounce` wrapper
  (touch-down squash, release overshoot — controller pattern, ~90ms
  press / ~350ms release), shared wobble + squash-stretch helpers, one
  `CustomPainter` particle system (`repaint: controller`, per-paint
  alpha, tens of particles, `RepaintBoundary`-wrapped) replacing the 3
  bespoke painters, scene-pulse helper. `flutter_animate` (already
  permitted by ADR-005) fits entrances/idle loops/shimmer-shake;
  hand-rolled controllers stay for gesture-phase work. Spring physics
  via built-in `SpringSimulation` (underdamped, pass release velocity)
  for drag-release wobble. Keep the repo's existing rule: overshoot
  curves via plain Tween drive, not inside TweenSequence items (known
  crash, `pop_in.dart`).
- **Frame budget:** our scale (10–30 scoped idle animations + a burst)
  is fine on Android-8-era hardware IF ticks hit leaf
  `Transform`s/paints, not rebuilds: `AnimatedBuilder(child:)` or
  `*Transition` widgets, `RepaintBoundary` around each animated item
  and the static backdrop, no `Opacity` widget / blurs / saveLayer in
  hot paths, decode images at display size, `precacheImage` during
  transitions. Android ≤9 runs the GL path (no Impeller/Vulkan) —
  **profile on a real cheap Android 8 device, not a Pixel.**
- **Sound assets needed** (asset-gen pipeline): pentatonic pop ladder
  (~8 notes, one sample pitch-shifted at runtime once SoLoud lands),
  per-family tap sounds (soft/wood/bell), curious near-miss boop, 2–3s
  win stingers per game, sticker-pill "ding". Organic timbres per F13.

## Build order (proposal for the spec)

- **P0 — Foundation (feel floor):** SoLoud ADR + migration with
  preloaded SFX; touch-down registration app-wide; universal tap SFX
  (all four silent games); haptics helper; kill the first-touch dead
  zones (TapBounce on doorway cards, picker, skip arrow, sticker wall).
  *P0 alone fixes "taps feel dead."*
- **P1 — Shared juice kit:** `lib/juice/` (TapBounce, wobble, squash,
  particles, pulse); migrate the 5 duplicated implementations; pairs +
  puzzle cards + sticker wall get idle life and entrances.
- **P2 — Reward pass:** pentatonic ladders; mid-round micro-
  celebrations (burst + Mithu reaction); sticker flight from real rects
  + pill bounce on landing; per-game stingers; celebration restates the
  word (F14).
- **P3 — Presence & scaffolding:** Mithu present during games
  (corner witness: gasp/cheer); idle-nudge system (6–8s); 3-level warm
  redirection; scene pulse on wins; polish-backlog transition items
  (doorway-rect scene entry, word-overlay flight, sticker arc).

Verification stays the founder-decided loop: E2E + screen recording +
vision-model verdict per change (feel regressions are invisible in
unit tests).

## Sources

Canon: Swink *Game Feel*; Jonasson & Purho, *Juice it or lose it* (GDC
2012); Nijman, *The art of screenshake* (2013); Disney 12 principles
(UI applications: UX Collective, IxDF, Marvel); GMTK *Secrets of Game
Feel and Juice*; Miyamoto interviews (gamedeveloper.com); Material
Design motion specs; GameAnalytics juice guide.
Children's research: Sesame Workshop, *Best Practices: Designing Touch
Tablet Experiences for Preschoolers* (joanganzcooneycenter.org PDF);
Vatavu, Cramariuc & Schipor, IJHCS 74 (2015); NN/g children's UX;
Anthony et al.; TIDRC (ACM 2019); NPR/Harvard on toddler repetition.
Studios: Apple *Behind the Design: Pok Pok Playroom*; Sketch blog on
Pok Pok; gamedeveloper.com on Pok Pok; Motionographer on Toca Boca's
design process; Björn Jeffery interviews (funambulism, SuperAwesome);
GeekDad (Jens Peter de Pedro); Mother Mag (Sago Mini); Kidscreen (Dr.
Panda); Originator/Endless Alphabet coverage (Pixelkin, Common Sense);
Khan Kids docs; Stanford GSB (Duck Duck Moose).
Flutter: pub.dev — flutter_soloud 4.0.13 / audioplayers 6.8.1 /
just_audio 0.10.6 / flutter_animate 4.5.2 / confetti 0.8.0;
docs.flutter.dev cookbook (SoLoud, physics simulation) and perf best
practices; api.flutter.dev HapticFeedback; flutter_soloud issue
tracker (#318, #220); nutrient.io on iPad haptics.
