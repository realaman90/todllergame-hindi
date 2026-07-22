---
type: Design
title: Mithu Rive rig — authoring brief (via Rive desktop MCP)
description: Exact spec for authoring Mithu's Rive rig through the official Rive Editor MCP (http://127.0.0.1:9791/mcp, registered in project config). Supersedes ADR-005's "not LLM-authorable" premise.
tags: [design, mascot, rive, animation]
timestamp: 2026-07-22
---

# Mithu Rive rig — authoring brief

Prereqs: Rive desktop app (Early Access) OPEN with a file + artboard;
the MCP server is registered in this project's Claude config (connects
on session start — run this brief from a FRESH session). Founder has the
app installed (2026-07-22).

## Input assets

Transparent layer PNGs of Mithu, produced by the cut-out pass
(alpha pipeline — see premium-gap-analysis.md Week 1). Layers, each
on-model from the ADR-008 canon (docs/design/mascot/mithu-canon-hero.png):
body, head, crest, beak-upper, beak-lower, wing-left, wing-right,
tail, eyes (open), eyes (closed). Generate via the image-edit lane +
rembg if not yet made.

## Rig hierarchy

artboard "mithu" (1:1, ~1024px)
- group body (origin at belly center)
  - group tail (origin at base)
  - group wing-left (origin at shoulder), wing-right (origin at shoulder)
  - group head (origin at neck)
    - crest (origin at base), eyes-open/eyes-closed, beak-upper +
      beak-lower (origins at hinge)

## Animations (linear, loopable unless noted)

- idle (3.2s loop): body bob ±6px sine, tail sway ±4°, blink every
  ~2.8s (eyes swap 120ms), occasional crest perk
- talk (0.8s loop): beak-lower open/close cycle, head bob ±3°,
  crest small bounce
- flutter (0.6s one-shot): both wings up-out-down with overshoot
- gasp (0.5s one-shot): head back 8°, beak wide, crest full perk
- dance_lean (1.6s loop): lean L/R ±10° with hop (body y -14px)
- dance_spin (1.6s one-shot): full body spin with squash landing
- dance_flap (1.2s loop): fast wing flaps + double bob
- fly (1.2s one-shot): wings flap, body arcs up-right off-artboard
  (for round transitions)

Easing: ease-out on every attack, spring-like settles (F6-F8 in
game-feel.md). No linear interpolation anywhere.

## State machine "mithu-sm"

Inputs: bool isTalking, trigger gasp, trigger flutter, number danceStyle
(0 none, 1 lean, 2 spin, 3 flap), trigger fly.
Layers: base (idle <-> talk on isTalking; one-shots gasp/flutter return
to base), dance layer (danceStyle drives the three dances, 0 = exit).

## Flutter integration (after export)

Export .riv into assets/rive/mithu.riv; add `rive` package (needs an
ADR amending ADR-005 — code-driven stays for tiles/particles, Rive for
the mascot only); replace MithuTalking's frame-flipbook internals with a
RiveAnimation + state machine controller behind the SAME widget API
(isPlaying -> isTalking, voicePath praise-substrings -> danceStyle,
existing call sites untouched). Keep the flipbook as a fallback flag
until the rig is founder-approved on both sims.
