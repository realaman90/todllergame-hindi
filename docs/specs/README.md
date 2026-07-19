---
type: Index
title: Engineering specs index
description: Engineering build specs by state — tbd/ (designed, to build) and implemented/ (shipped, with banners).
tags: [index, specs, engineering]
timestamp: 2026-07-18
---

# Specs

Engineering build specs for the app. States:

- [`tbd/`](tbd/) — designed, not yet implemented.
- [`implemented/`](implemented/) — what exists in the app today.

As features ship, specs move to `implemented/` with a banner noting what
shipped and when. Superseded specs keep a banner too — trim, never
delete.

No engineering build has started yet — see
[`../decisions/README.md`](../decisions/README.md) for what's locked and
[`../product/SPEC.md`](../product/SPEC.md) for MVP scope.

### TBD — designed, to build

- [app-shell-and-scene-engine](tbd/app-shell-and-scene-engine.md) — the
  first slice: JSON content model keyed on curriculum slugs, 7-screen
  map from the v1.1 mockups, `TappableObject` interaction primitive,
  asset/audio conventions, M1–M4 milestones (2026-07-19). Covers the
  parent gate and sticker wall — separate specs for those are no longer
  planned unless they outgrow this one.

### Implemented — shipped

_None yet._

Don't start implementation before the corresponding `tbd/` spec exists —
that's the signal the interaction/data model has actually been thought
through, not improvised while coding.
