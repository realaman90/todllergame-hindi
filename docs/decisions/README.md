---
type: Index
title: Decision Log (ADRs)
description: Why we made each significant product/engineering choice, for traceability.
tags: [index, decisions, adr]
timestamp: 2026-07-18
---

# Decision Log (ADRs)

Why we made each significant choice — for traceability. Append a new entry
as decisions are made; don't rewrite history (supersede instead). Format:
**What** / **Why** / **Alternatives rejected**.

## Index

| ADR | Title | Date | Status |
|---|---|---|---|
| [001](ADR-001-flutter-plus-rive-over-unity-godot.md) | Flutter + Rive as the app framework, over Unity/Godot | 2026-07-18 | Accepted; animation leg amended by ADR-005 |
| [002](ADR-002-shippable-product-kids-category-compliance.md) | Ship as a real product — Kids Category / COPPA / GDPR-K compliance designed in from day one | 2026-07-18 | Accepted |
| [003](ADR-003-native-speaker-voiceover-over-tts.md) | Real native-speaker Hindi voiceover over TTS | 2026-07-18 | Accepted |
| [004](ADR-004-offline-first-no-backend-for-mvp.md) | No backend for MVP — fully offline, bundled content | 2026-07-18 | Accepted |
| [005](ADR-005-code-driven-flutter-animation-rive-deferred.md) | Code-driven Flutter animation for MVP; Rive deferred to an optional upgrade path | 2026-07-19 | Accepted (amends ADR-001) |

### Adding a decision

One file per ADR — `ADR-NNN-slug.md`. **Next number = highest in this
index + 1.** Heading: `# ADR-NNN — <title> (YYYY-MM-DD) — <status>`, then
**What / Why / Alternatives rejected**. Append-only: never rewrite a
shipped decision — supersede it with a new ADR and update the old one's
status. Add a row to this table.
