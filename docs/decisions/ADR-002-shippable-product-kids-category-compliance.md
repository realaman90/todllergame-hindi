# ADR-002 — Ship as a real product — Kids Category / COPPA / GDPR-K compliance designed in from day one (2026-07-18) — Accepted

## What

Target public release on the App Store (Kids Category) and Play Store —
not just a personal build for one device — with COPPA (US) and GDPR-K (EU)
compliance considered from the first line of code, not bolted on before
submission.

## Why

Founder chose "shippable product" over "personal only" when scoping the
project. This changes tooling choices immediately:

- no third-party ad SDKs
- no third-party analytics/crash-reporting SDKs unless kid-safe certified
- no external links out of the app
- a parental gate required in front of settings/purchases/any external
  action
- a privacy policy + data-collection disclosure required at store
  submission

These constraints are cheap to satisfy if designed in from the start and
expensive to retrofit right before submission, so every future ADR that
proposes adding a dependency should check this one first.

## Alternatives rejected

- **Personal-only build** (skip store submission and compliance
  overhead) — would iterate faster short-term but produces something that
  can't be distributed as a product, which was explicitly not the goal.
