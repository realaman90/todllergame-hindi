---
type: Index
title: Todller Game (Hindi) documentation index
description: Map of the project's docs — product, design, stack, and engineering specs, kept alongside the app code.
tags: [index, docs]
timestamp: 2026-07-18
---

# Todller Game — Hindi — Documentation

> An explore-and-tap Hindi learning game for toddlers (~3 years old), for
> iOS and Android. Built by Gemoniq, for the founder's daughter first,
> scoped as a shippable product.

This structure is adapted from a larger sibling project's docs repo
(`kontentplus-docs`), scaled down for a solo/early-stage project. Docs
live inside this repo (not a separate one) since there's no code/docs
split to justify yet — revisit if the team or repo size grows (that would
be its own ADR).

## Map

| Directory | What it holds | Status notes |
|---|---|---|
| [`decisions/`](decisions/README.md) | The ADR log — one file per decision (`ADR-NNN-slug.md`) + a registry index. | Start here for "why did we do it this way." Append-only; supersede, never rewrite. |
| [`product/`](product/README.md) | Product layer. | `SPEC.md` = **product scope source of truth**. |
| [`design/`](design/README.md) | Game design: curriculum/content plan, interaction patterns. | Curriculum is a live working doc — fill in as content is authored. |
| [`specs/`](specs/README.md) | Engineering build specs. | `tbd/` = designed, to build; `implemented/` = shipped. Empty until the app scaffold begins. |
| [`stack/`](stack/README.md) | Locked tech stack + rationale. | Current; additions require an ADR. |

## Conventions

- **Index-first:** this page is the map; each folder keeps its own
  `README.md` index you load before drilling in.
- **Append-only decision log → per-entry files + a generated index.**
  Decisions are `ADR-NNN-slug.md` + `decisions/README.md` (the registry);
  supersede, never rewrite.
- Specs move `tbd/` → `implemented/` as they ship; trim, don't delete.
  Superseded docs get an explicit banner instead of deletion.
- Every doc carries YAML frontmatter (`type`, `title`, `description`,
  `tags`, `timestamp`) so an agent can scan a folder's purpose without
  opening every file.
