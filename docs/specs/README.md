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

**Status: empty.** No engineering build has started yet — see
[`../decisions/README.md`](../decisions/README.md) for what's locked and
[`../product/SPEC.md`](../product/SPEC.md) for MVP scope. The first specs
to write here, in order, are likely:

1. `tbd/app-shell-and-scene-engine.md` — navigation shell, scene
   loading/asset-bundling model, the tap-to-learn interaction primitive.
2. `tbd/parental-gate.md` — the gate mechanism guarding settings/purchase
   surfaces (ADR-002).
3. `tbd/sticker-collection-wall.md` — passive progress tracking/storage.

Don't start implementation before the corresponding `tbd/` spec exists —
that's the signal the interaction/data model has actually been thought
through, not improvised while coding.
