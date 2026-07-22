---
type: Decision
title: ADR-012 — Published under the app's own brand, not Gemoniq; bundle id com.mithuandfriends.app
description: Founder ruled out gemoniq.com as this app's publisher identity (2026-07-22); the app ships under its own "Mithu & Friends" brand.
tags: [decision, store, branding, m4]
timestamp: 2026-07-22
---

# ADR-012 — Publisher identity: the app's own brand (2026-07-22) — Accepted

**What.** "Mithu & Friends" is its own publisher identity. Bundle id /
application id: **`com.mithuandfriends.app`** (iOS and Android), replacing
the dev-time `com.gemoniq.chaloGharGhoome` before the first store upload.
The Apple Developer / Play Console accounts (the public "seller" name
parents see) should be enrolled under this brand, and a matching domain
(mithuandfriends.com or equivalent) should be registered by the founder
before enrollment.

**Why.** Founder 2026-07-22: "gemoniq.com is not for this app" — Gemoniq
is a separate venture, and the kids' brand must stand alone. The seller
name on a Kids Category listing is parent-facing trust surface; it should
say the brand of the app, not an unrelated company.

**Alternatives rejected.**
- `com.gemoniq.mithuandfriends` — conventional umbrella pattern, but ties
  the family brand to an unrelated entity (explicitly ruled out).
- Personal-name publishing — weaker trust signal on a kids' store listing.

**Consequences.** The rename is the first task of M4 (it pairs with the
first Android build): iOS bundle identifier + Info.plist, Android
applicationId, deploy tooling and the sim-deploy notes that reference the
old id. Bundle ids are permanent per store listing after first upload —
this must land before any upload, and never change after. Founder action:
register the domain and enroll the developer accounts under the brand.
