# CLAUDE.md

Orientation for any agent (or human) working in this repo cold.

## What this is

A Hindi-learning, explore-and-tap mobile game for toddlers (~3 years old),
for iOS and Android. Built by a parent (Gemoniq) for their daughter first;
scoped as a shippable product (App Store / Play Store), not a one-off.

## Status

Flutter app scaffolded and playable: milestones **M1–M3** of
`docs/specs/tbd/app-shell-and-scene-engine.md` are implemented (all 3
MVP scenes from curriculum.md, generated art/audio staged in `assets/`,
sticker loop, find-it puzzles), plus post-M3 growth: 17 mini-game
formats, breathers, game-feel P0–P3 (ADR-011 SoLoud), welcome screen,
tablet scaling. **M4 is underway** (2026-07-22): parent gate + settings
shipped; bundle id renamed to `com.mithuandfriends.app` (ADR-012);
first Android build in progress. Remaining: store assets, privacy
policy, native-speaker recording (the ship-blocker). Word voiceover in `assets/audio/hi/` is dev-placeholder TTS —
must be replaced with native-speaker recordings before ship (ADR-003).
Asset generation tooling lives in `tools/asset-gen/` (see its README).
Before building any new piece, check `docs/specs/tbd/` for a build spec
— if none exists, the design isn't locked yet, so raise that before
writing code.

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

## Model routing

Which model/mode to use for what kind of work in this repo:

- **Planning, architecture, ADRs, specs, reviews:** Claude **Fable 5 at
  xhigh reasoning effort**. Anything that locks a decision or shapes a
  spec goes through Fable.
- **Game-feel code (mini-games, animations, interactions, anything the
  child directly touches):** implemented **directly by Fable** (founder
  decision 2026-07-20 after Kimi rounds produced invisible-animation and
  startup regressions), verified through the E2E test +
  screen-recording + vision-model-verdict loop.
- **Structural/mechanical implementation (new screens, persistence,
  content plumbing, scaffolding):** shell out to **Kimi K3 in
  yolo (auto-approve) mode** via its CLI, driven from the specs written
  above. Invocation (kimi-code v0.29.0, installed at `~/.kimi-code/bin`):
  `kimi -m kimi-code/k3 -p "<implementation brief>"` from the repo root —
  ALWAYS pin `-m kimi-code/k3` (founder caught an early dispatch running
  K2.7 under an older default; config.toml now defaults to K3, but the
  pin makes dispatches robust against config drift). Prompt mode is
  implicitly auto-approve — do NOT add `-y`/`--auto` (they error when
  combined with `-p`; they're for interactive mode). Use
  `kimi -r <session-id> -p "..."` to continue a prior Kimi session for
  follow-ups. Fable stays in the loop as orchestrator/reviewer — Kimi
  output gets reviewed against the spec before commit, since yolo mode
  skips approval prompts. **Warning:** Kimi must never revert or "clean
  up" uncommitted working-tree changes in files it didn't itself change —
  those are the orchestrator's work in progress (it once reverted staged
  curriculum + tooling edits it mistook for its own accidents). Say so in
  every brief, and prefer committing docs/tools work before dispatching.

## Build/run

Standard Flutter (repo root is the app): `flutter pub get`, then
`flutter run` (or `flutter build ios --simulator` / `flutter analyze`).
Requires Flutter (Homebrew cask), Xcode with the iOS simulator runtime,
and CocoaPods. Landscape-only, iOS 15+ / Android 8+. Simulator deploy
order matters: terminate → install → launch (installing over a running
app silently keeps the old build).
