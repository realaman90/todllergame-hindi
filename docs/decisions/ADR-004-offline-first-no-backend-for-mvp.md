# ADR-004 — No backend for MVP — fully offline, bundled content (2026-07-18) — Accepted

## What

The MVP ships with zero backend. All scenes, words, art, and audio are
bundled into the app binary. No login, no account, no network calls
required to play.

## Why

The MVP content set (3 scenes, ~40 words) is small and fixed. Offline-first
avoids network dependency/latency for a toddler app (it should never stall
on load), and it minimizes the data-collection surface — which also
simplifies Kids Category / COPPA compliance (ADR-002): less data
collected means less to disclose and less that can go wrong.

## Alternatives rejected

- **Cloud sync / backend from day one** (e.g., to sync progress across a
  sibling's second device, or to push remote content updates without an
  app-store release) — deferred, not rejected outright. Revisit once
  there's a concrete need; add a new ADR rather than retrofitting silently.
