---
type: Design
title: Interaction patterns
description: Concrete UX rules any new scene or interaction must follow, derived from the product design philosophy.
tags: [design, ux, interaction]
timestamp: 2026-07-18
status: current
---

# Interaction Patterns

Concrete rules — any new scene, screen, or interaction built for this app
should satisfy every rule below. If a proposed feature can't, that's a
signal to flag it against `../product/SPEC.md`'s design philosophy before
building it, not to make an exception silently.

## Input

- Tap and drag only. No swipe gestures, no pinch, no multi-finger
  gestures, no long-press-to-discover (a 3-year-old won't find it).
- Every screen must be navigable without reading — icons + voice cues
  only, no text-only buttons/menus for the child-facing flow.

## Feedback

- Every tap on a scene object produces an immediate audio-visual
  reaction. No dead taps.
- Word audio: standard-pace clip first, slower repeat clip second (per
  object), triggered on first tap; a second tap on the same object
  replays from the standard-pace clip.
- No failure feedback of any kind — there is no "wrong" tap on a scene.

## Progression

- No levels, no scores, no timers, no pass/fail gates between scenes.
- Progress is represented passively (sticker/collection wall filling in)
  — never blocks access to content and never resets.

## Session shape

- Sessions should be enjoyable ending at any point — no "you must finish
  this to save progress" pattern. Assume she'll close the app mid-scene
  constantly.
- Avoid modal interruptions (popups, "are you sure" dialogs) in the
  child-facing flow entirely.

## Parent-facing surfaces

- Settings, purchases, and any external action (links, store prompts)
  sit behind a parental gate (e.g., hold-to-confirm or a simple check) —
  never reachable by a single accidental tap.
- Parent-facing text can use normal reading-level copy; child-facing
  surfaces cannot.

## Audio/mascot prompts

- The mascot may narrate ambiently and, once introduced, offer soft
  "find the X" prompts — but this is strictly optional flavor. It must
  never gate content or imply the child did something wrong by not
  responding.
