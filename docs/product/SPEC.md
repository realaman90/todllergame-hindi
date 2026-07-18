---
type: Spec
title: Product spec — Todller Game (Hindi)
description: Vision, target user, design philosophy, core game concept, and MVP scope. Product scope source of truth.
tags: [product, spec, scope]
timestamp: 2026-07-18
status: current
---

# Product Spec — Todller Game (Hindi)

## Vision

An interactive, exploratory Hindi-learning game for toddlers (~3 years
old), for iOS and Android. She wanders open scenes, taps things, hears
Hindi words spoken by a native speaker, and builds vocabulary through
repetition — not through lessons, quizzes, or scores.

## Target user

A ~3-year-old, pre-reading, ~5–10 minute attention span, learns through
repetition and cause-and-effect. Secondary "user": the parent, who needs
visible-but-child-invisible settings and a genuine sense the content is
educational and safe.

## Design philosophy

- **No fail states.** No wrong answers, no timers, no score screens.
  Every tap does *something* delightful.
- **Explore, don't progress.** Open "worlds" full of tappable objects
  instead of levels — she wanders and discovers at her own pace.
- **One input model:** tap/drag only. No swipe gestures, no multi-step
  menus, no reading required to navigate (icons + voice only).
- **Immediate audio-visual reward** for every interaction — object
  animates, native-speaker voice says the Hindi word, then repeats it
  once slower.
- **Short loops, high repetition.** Hearing the same word 20 times is how
  toddler language acquisition works — not a bug to fix with forced
  variety.
- **Parent-visible, child-invisible settings.** A locked gate (e.g., hold
  for 3 seconds, or a simple check) protects settings/store menus from
  little fingers.

See [`../design/interaction-patterns.md`](../design/interaction-patterns.md)
for the concrete UX rules any new scene/interaction must follow.

## Core game concept

Working title: **"Chalo Ghar Ghoome"** (Let's Explore the House).

- **Scenes:** open, tappable environments — Ghar (house: kitchen,
  bedroom, bathroom), Bageecha (garden/farm with animals), Bazaar
  (fruits, veggies, colors), Parivaar (family members), Sharir (body
  parts). 5–8 scenes planned; MVP ships 3.
- **Interaction loop per object:** tap object → it animates/reacts →
  Hindi word spoken (e.g., "गाय" / gaay) → word shown in Devanagari +
  audio + optional English gloss for the parent → tap again to hear it
  again.
- **Light gamification, no scoring:** a passive "sticker book" /
  collection wall fills in as she discovers objects — a sense of
  progress without pressure.
- **Recurring mascot** narrates and, once she's comfortable, can softly
  prompt ("dhoondo gaay!" — find the cow) as an optional matching layer
  — never required to enjoy the app.
- **Music/rhymes mode** (post-MVP): simple Hindi nursery rhymes with
  karaoke-style highlighting.

## MVP scope

1. 3 scenes (House, Farm, Family) — 55 words total (see
   [`../design/curriculum.md`](../design/curriculum.md) for the full
   word list — first draft, pending native-speaker review before
   recording)
2. Tap-to-learn interaction + sticker collection wall
3. Native Hindi voiceover for all words (ADR-003)
4. Parent gate + basic settings (volume, scene unlock)
5. No login, no network, no ads (ADR-004, ADR-002)

## Compliance

This ships toward Apple's Kids Category + COPPA (US) + GDPR-K (EU) — see
[ADR-002](../decisions/ADR-002-shippable-product-kids-category-compliance.md).
Concretely: no behavioral ads, no third-party trackers/analytics beyond
kid-safe-certified ones, no external links out of the app, no data
collection without verified parental consent, parental gate on
settings/purchases.

## Open decisions

Not yet locked — track as they resolve (promote to an ADR once decided):

- Exact monetization model (one-time purchase vs. free-first-scene +
  paid unlock).
- Full scene list beyond MVP's 3 (candidates: Bazaar, Sharir — see
  [`ROADMAP.md`](ROADMAP.md)).
- Whether/when a matching-game prompt layer gets added on top of the pure
  explore loop.
- How the 1–10 counting content (Parivaar scene) is presented — it
  doesn't fit the single-tap object loop the rest of MVP uses; see
  [`../design/curriculum.md`](../design/curriculum.md) "Open items."
