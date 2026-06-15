# CBATechno Roadmap

**Version:** 2.0
**Last updated:** 2026-06-15
**Status:** Active — single source of truth for project status + plan
**Supersedes:** `docs/archive/2025-10-roadmap-v1.md` (the original Next.js plan)

## The pivot

CBATechno re-platformed from a single self-hosted Next.js monolith to **one
TanStack Start web app + an Expo mobile app on Supabase**. Search is
Postgres-native (FTS + `pgvector`), not Typesense. The three planned web apps
(customer/vendor/admin) collapsed into one `cbatechno-web` with role-gated route
groups. Full rationale and ADRs: [`docs/07-replatform/README.md`](../07-replatform/README.md).

Development is **local-first**: the local Supabase stack is the source of truth;
a single cloud cutover happens once features stabilize (Phase 5).

## Status snapshot (2026-06-15)

| Area | State |
|------|-------|
| `cbatechno-backend` | Schema (28 tables, 54 RLS policies, 4 RPCs) + 5 edge functions **written**, validated locally; auth/email configured (confirmations on, mobile redirect allow-list, branded templates). **Missing:** `handle_new_user`, `product-images` bucket, `pg_net`/`pg_cron`, notification triggers, cloud deploy. |
| `cbatechno-shared` | `@cbatechno/shared` builds; consumed via `file:` link; not yet published to GitHub Packages. |
| `cbatechno-web` | TanStack Start storefront built (discovery/search/product/cart/checkout/account/wishlist/auth). **Auth is real**; **catalog + account still mock** (`src/data/*`); **no vendor/admin route groups**. |
| `cbatechno-mobile` | Expo SDK 56 scaffold + Supabase/Query/auth + magic-link deep-linking + local env. Customer-only for V1. No feature screens yet. |
| infra | 5 GitHub repos under `mukunzidd` (SSH), all on `main`; root `Makefile`, local + cloud Supabase MCP, docs consolidated into root `docs/`. |

## Forward plan

### Phase 0 — Reconcile docs ✅ (this exercise)
Retire the old roadmap, publish this one, refresh `07-replatform`, add status headers
to the Phase A/B plans.

### Phase 1 — Real-data customer flow (web) — *next, milestone #1*
- Backend (local migrations): `handle_new_user` trigger (provision `user_profiles` +
  default `user_roles = buyer` on signup); `product-images` storage bucket + RLS;
  `npm run gen:types` from local → real `cbatechno-shared/src/database.ts`.
- Web: replace `src/data/*` with `@cbatechno/shared` queries (`getCategories`,
  `searchProducts`, `getProductBySlug`); real cart / wishlist / account / orders;
  search via `search_products` RPC.
- **Exit:** sign up → browse real catalog → search → product → cart → account/orders,
  all on live local Supabase (web). Checkout/payment still stubbed.

### Phase 2 — Finish consolidation + dashboard QA
- `_vendor/*` + `_admin/*` pathless route groups with `beforeLoad` role guards
  (`current_is_admin()` / `current_supplier_id()`); vendor products(CRUD + image
  upload)/orders/messages/analytics; admin suppliers/moderation/analytics/settings.
- **Test gate:** manually verify vendor **and** admin dashboards end-to-end (role-gated
  access + correct redirects, CRUD, real local data) **before** mobile work begins.

### Phase 3 — Mobile customer buildout
- Customer browse / search / product / cart / account on real (local) data, mirroring
  the web query layer; session + magic-link deep-linking already wired.
- Run as an Expo **prebuild dev client** (`npx expo prebuild` + a dev build), **not
  Expo Go** — the `cbatechnomobile://` deep-link scheme only resolves in a
  dev/standalone build. iOS sim reaches `127.0.0.1`; Android emulator uses `10.0.2.2`.

### Phase 4 — Commerce + comms
Checkout → `create_order` RPC; Stripe (`intent`/`webhook`) + Flutterwave
(`init`/`webhook`) via local functions serve; order status history; messaging;
notification triggers + `push-dispatch`; `currency-sync`; `image-embed` visual search.
Applies to both web and mobile customer flows.

### Phase 5 — Cloud cutover + deploy
`supabase login` + `link` + `db push` + seed + `gen:types --linked` + `advisors`;
edge-fn secrets + deploy; `pg_net`/`pg_cron` schedules; publish `@cbatechno/shared` to
GitHub Packages; deploy web (host TBD — Vercel vs self-host) + mobile via **EAS**
(dev → preview → production).

### Phase 6 — Polish / QA / launch
Reviews, testing/bug-fixes, launch prep.

## Reference

- Decisions / ADRs: [`docs/07-replatform/README.md`](../07-replatform/README.md)
- Execution plans: [`docs/superpowers/plans/`](../superpowers/plans/) (Phase A FE consolidation, Phase B backend wiring)
- Original V1 plan (archived): [`docs/archive/2025-10-roadmap-v1.md`](../archive/2025-10-roadmap-v1.md)
