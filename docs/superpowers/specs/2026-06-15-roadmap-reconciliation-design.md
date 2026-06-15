# Roadmap Reconciliation + Forward Plan

**Date:** 2026-06-15
**Status:** Approved (design)
**Author:** Dieudonné Mukunzi + Claude

## Context

The canonical planning docs no longer match reality:

- `docs/05-development/roadmap.md` (v1.0, 2025-10-18) describes the **abandoned**
  stack — Next.js 15 + Typesense + self-hosted Supabase on Hetzner/Coolify, a
  12-week plan. Superseded by the re-platform pivot.
- `docs/07-replatform/README.md` documents the pivot (TanStack + Expo + Supabase
  Cloud) but its "Session state — RESUME HERE" block is itself stale: it places the
  docs hub in `cba-tecno-mobile/` (now consolidated into root `docs/`), still lists
  `cbatechno-customer-web` (renamed `cbatechno-web`), and predates this session's
  auth/email/mobile work and the GitHub publish.
- `docs/superpowers/plans/2026-06-12-phase-a-fe-consolidation.md` (82 tasks) and
  `…phase-b-backend-wiring.md` (57 tasks) show 0 checkboxes ticked, yet Phase A's
  repo-level consolidation already happened and real auth is wired.

This spec reconciles the docs to current reality and lays out a re-sequenced,
**local-first** path to V1.

## Decisions (this exercise)

| # | Decision | Source |
|---|----------|--------|
| 1 | Outcome = reconcile docs **and** produce a forward roadmap | Q1 |
| 2 | **Local-first**: local Supabase is the source of truth; single cloud cutover later | Q2 |
| 3 | First milestone = **real-data customer flow** (web) | Q3 |
| 4 | Doc strategy = **canonical rewrite + archive** (Approach A) | design review |
| 5 | Mobile runs as an Expo **prebuild dev client** (and EAS builds), **not Expo Go** — the `cbatechnomobile://` auth deep-link scheme only resolves in a dev/standalone build | review |
| 6 | **QA gate**: vendor + admin dashboards are tested before mobile feature work begins | review |

## Current status snapshot (2026-06-15)

| Area | State |
|------|-------|
| `cbatechno-backend` | Schema (28 tables, 54 RLS policies, 4 RPCs) + 5 edge functions **written** and validated locally; auth/email configured (confirmations on, mobile redirect allow-list, branded templates). **Missing:** `handle_new_user` trigger, product-images storage bucket, `pg_net`/`pg_cron` schedules, notification-enqueue triggers, cloud deploy. |
| `cbatechno-shared` | `@cbatechno/shared` builds; consumed via `file:` link; **not** yet published to GitHub Packages. |
| `cbatechno-web` | TanStack Start storefront built (discovery/search/product/cart/checkout/account/wishlist/auth pages). **Auth is real** (login, signup, magic link, forgot/reset). **Catalog + account still mock** (`src/data/*`). **No `vendor`/`admin` route groups.** |
| `cbatechno-mobile` | Expo SDK 56 scaffold + Supabase/Query/auth + magic-link deep-linking (this session) + local env. Customer-only for V1. No feature screens yet. |
| infra | 5 GitHub repos under `mukunzidd` (SSH), all on `main`; root `Makefile`, local + cloud Supabase MCP, docs consolidated into root `docs/`. |

## Forward roadmap (re-sequenced to V1, local-first)

- **Phase 0 — Reconcile docs** *(this exercise)*: produce the artifacts below.
- **Phase 1 — Real-data customer flow (web)** *(milestone #1)*:
  - Backend-lite (local migrations): `handle_new_user` trigger (provision
    `user_profiles` + default `user_roles = buyer` on signup); `product-images`
    storage bucket + RLS policies; `npm run gen:types` from local → real
    `cbatechno-shared/src/database.ts`.
  - Web: replace `src/data/*` with `@cbatechno/shared` queries (`getCategories`,
    `searchProducts`, `getProductBySlug`); real cart / wishlist / account / orders
    via Supabase; search via the `search_products` RPC.
  - **Exit:** sign up → browse real catalog → search → product → add to cart → view
    account/orders, all on live local Supabase (web). Checkout/payment still stubbed.
- **Phase 2 — Finish consolidation + dashboard QA** *(Phase A remainder)*:
  - `_vendor/*` + `_admin/*` pathless route groups with `beforeLoad` role guards
    (`current_is_admin()` / `current_supplier_id()`); vendor products(CRUD + image
    upload)/orders/messages/analytics; admin suppliers/moderation/analytics/settings.
  - **Test gate (Decision #6):** manually verify the vendor **and** admin dashboards
    end-to-end — role-gated access (correct redirects for the wrong role), CRUD, and
    data on real local Supabase — **before** any mobile feature work begins.
- **Phase 3 — Mobile customer buildout**:
  - Customer browse / search / product / cart / account on real (local) data,
    mirroring the web query layer; session + magic-link deep-linking already wired.
  - Run as an Expo **prebuild dev client** (`npx expo prebuild` + a dev build),
    **not Expo Go** (Decision #5) — the `cbatechnomobile://` deep-link scheme only
    resolves in a dev/standalone build. iOS sim reaches `127.0.0.1`; Android emulator
    uses `10.0.2.2`.
- **Phase 4 — Commerce + comms** *(Phase B core)*: checkout → `create_order` RPC;
  Stripe (`intent`/`webhook`) + Flutterwave (`init`/`webhook`) via local functions
  serve; order status history; messaging (`conversations`/`messages`); notification
  triggers + `push-dispatch`; `currency-sync`; `image-embed` visual search. Applies to
  both the web and mobile customer flows.
- **Phase 5 — Cloud cutover + deploy** *(the "later" of Decision #2)*: `supabase
  login` + `link` + `db push` + seed + `gen:types --linked` + `advisors`; edge-fn
  secrets + deploy; `pg_net`/`pg_cron` schedules; publish `@cbatechno/shared` to
  GitHub Packages; deploy web (host TBD) + mobile via **EAS** (dev → preview →
  production profiles, consistent with the prebuild dev-client approach).
- **Phase 6 — Polish / QA / launch**: reviews, testing/bug-fixes, launch prep
  (carried over from the original Phase 3).

> Open item deferred to Phase 5: **web hosting target** (Vercel vs self-host) — not
> needed for the local-first phases 1–4.

## Deliverables (the doc changes)

1. **`docs/05-development/roadmap.md`** — rewrite as the single source of truth:
   intro (pivot summary), the status snapshot, and the forward roadmap above.
2. **`docs/archive/2025-10-roadmap-v1.md`** — the original Next.js/Typesense/Hetzner
   roadmap, moved here verbatim with a top banner: *"SUPERSEDED 2026-06-15 by the
   re-platform; see `docs/05-development/roadmap.md`. Kept for historical context."*
3. **`docs/07-replatform/README.md`** — remove the stale "Session state" block; keep
   the ADR/decisions table and rationale; fix the repo-layout table (`cbatechno-web`,
   docs in root `docs/`, GitHub remotes); add a pointer to `roadmap.md` for status.
4. **Phase A & Phase B plan docs** — prepend a short `## Status (2026-06-15)` header
   to each: what's executed vs pending (do **not** rewrite the task bodies).

## Out of scope

- No code changes in this exercise (docs only).
- No cloud operations (local-first).
- Web hosting decision (deferred to Phase 5).
