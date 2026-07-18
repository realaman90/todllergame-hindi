# CLAUDE.md

Orientation for any agent (or human) working in this repo cold.

## What this is

A Hindi-learning, explore-and-tap mobile game for toddlers (~3 years old),
for iOS and Android. Built by a parent (Gemoniq) for their daughter first;
scoped as a shippable product (App Store / Play Store), not a one-off.

## Status

Pre-code. Product/design/stack decisions are locked (see below); no app
code exists yet. If you're about to scaffold the app, check
`docs/specs/tbd/` first for any build spec already written for the piece
you're about to touch — if none exists, the design isn't locked yet, so
raise that before writing code.

## Start here

- [`docs/README.md`](docs/README.md) — the doc map. Read this first, then
  drill into the specific folder you need. Don't read every doc up front.
- [`docs/decisions/README.md`](docs/decisions/README.md) — the ADR log.
  **Check this before making any architecture/stack/scope call** — it may
  already be decided.
- [`docs/product/SPEC.md`](docs/product/SPEC.md) — product scope source of
  truth (vision, design philosophy, MVP scope).
- [`docs/stack/README.md`](docs/stack/README.md) — locked tech stack.
  Additions or changes require a new ADR.

## Conventions

- **Index-first.** Every doc folder has its own `README.md` that indexes
  its contents — load that before opening individual files.
- **Decisions are append-only.** One file per decision:
  `docs/decisions/ADR-NNN-slug.md`. Never rewrite a shipped decision —
  supersede it with a new ADR and update the old one's status. Add a row
  to `docs/decisions/README.md`.
- **Specs move `tbd/` → `implemented/`** as they ship
  (`docs/specs/`). Don't delete superseded specs — bannner them.
- All docs carry a YAML frontmatter block (`type`, `title`, `description`,
  `tags`, `timestamp`) so agents/tools can scan folders without opening
  every file.
- This project targets Apple's **Kids Category** + COPPA/GDPR-K — before
  adding any third-party SDK (analytics, ads, crash reporting), check
  `docs/product/SPEC.md` "Compliance" section and `docs/decisions/` for
  whether it's allowed.

## Build/run

Not yet applicable — no app scaffold exists. Update this section (and add
a `specs/tbd/app-shell-and-scene-engine.md`) when scaffolding starts.
