# FE Consolidation + Reordered Roadmap

**Date:** 2026-06-12
**Status:** Approved (design) — implementation deferred to Sprint 2
**Author:** Dieudonné Mukunzi + Claude

## Context

The CBATechno re-platform scaffolding phase is complete: backend schema is live on
hosted Supabase (`kwkhhrjxuleftlinazaz`), the `@cbatechno/shared` contract package
builds against the real schema, and four client repos exist:

- `cbatechno-customer-web` — TanStack Start (SSR), fleshed out (storefront, search,
  cart, checkout, account, wishlist, auth pages). Currently on mock `data/`.
- `cbatechno-vendor-web` — TanStack Router SPA, bare skeleton (`__root`, `login`,
  `_authenticated` guard, one `dashboard` stub).
- `cbatechno-admin-web` — near-identical bare skeleton to vendor-web.
- `cbatechno-mobile` — Expo app (deferred; out of scope for this plan).

## Decision

Collapse the three web apps into **one deployable frontend**. The customer-web app
absorbs vendor and admin as role-gated route groups. Rationale: vendor/admin are
barely started, all three already share the stack (TanStack, supabase-js,
`@cbatechno/shared`), and a single app means one build, one deploy, one domain.

### Confirmed choices
- **Access model:** path prefixes (`/vendor/*`, `/admin/*`) + role guards. One login;
  role decides what's reachable.
- **Existing repos:** fold useful bits into the single app, then **delete**
  `cbatechno-vendor-web` and `cbatechno-admin-web`.
- **FE depth:** build the full core UIs for vendor and admin.
- **Rename:** `cbatechno-customer-web` → `cbatechno-web` (no longer just storefront).
- **Mobile:** `cbatechno-mobile` stays parallel/deferred, not in this plan.
- **Sequencing:** FE first (Phase A), then BE (Phase B), then pause before Sprint 2.

## Target architecture

```
cbatechno-web  (TanStack Start, SSR, Bun)
├── /                       storefront — public            ┐
├── /products/$slug, /search, /cart, /checkout            │ customer (exists)
├── /login, /signup, /order-confirmed                     │
├── /account/*              guard: authenticated          ┘
│
├── _vendor (pathless guard: session + role = 'supplier')
│   └── /vendor/dashboard · /vendor/products · /vendor/products/$id
│       /vendor/orders · /vendor/messages · /vendor/analytics
│
└── _admin (pathless guard: session + role = 'admin')
    └── /admin/dashboard · /admin/suppliers · /admin/moderation
        /admin/analytics · /admin/settings
```

### Shared foundation (built once)
- **One** `lib/supabase.ts` client + **one** SSR-aware auth/session context — replaces
  the three duplicate copies across the old repos.
- **Role-guard pattern** via TanStack Start `beforeLoad` on the pathless `_vendor` /
  `_admin` layout routes: validate session, read role from `user_roles` (using the DB
  helpers `current_is_admin()` / `current_supplier_id()`), redirect unauthorized users.
- **Per-section layout + nav** (storefront chrome / vendor console / admin console) so
  the three experiences feel distinct despite the single deploy.
- All data access via the `@cbatechno/shared` SDK + `queryKeys` factory.

## Roadmap (reordered)

### Phase A — Consolidate + build the one FE app
- **A0. Consolidate (foundation)** — rename `customer-web` → `cbatechno-web`; migrate
  auth guard / `query.ts` / `supabase.ts` from the skeletons; delete
  `cbatechno-vendor-web` + `cbatechno-admin-web`; unify Supabase client, SSR-aware
  auth/session context, and the `_vendor`/`_admin` role-guard pattern.
- **A1. Customer surface finish** — wire existing storefront pages off mock `data/` to
  the live DB via `@cbatechno/shared` (products, search → `search_products`, cart,
  account/addresses, wishlist); real auth (register / login / phone OTP / profile).
- **A2. Vendor console** (`/vendor/*`) — product CRUD (+ image upload to Storage),
  orders list + status updates, messages inbox, basic analytics.
- **A3. Admin console** (`/admin/*`) — supplier approval/suspend workflow, content
  moderation, analytics, app-settings editor.

> **End of Phase A** = one deployable FE with all three role experiences, running
> against the live schema.

### Phase B — Backend wiring
- **B1. Auth integration** — finalize providers (email, phone OTP, OAuth), profile/role
  provisioning trigger, first admin user.
- **B2. Edge functions deploy** — `payment-stripe`, `payment-flutterwave`,
  `image-embed`, `push-dispatch`, `currency-sync` (secrets + deploy; needs a real
  terminal).
- **B3. API integrations** — Stripe / Flutterwave checkout ↔ `create_order`;
  image-embed → `match_products_by_image` visual search.
- **B4. Cron jobs** — `pg_cron`: hourly `currency-sync`, cleanup tasks.
- **B5. Notifications** — `push-dispatch` (FCM/APNs) wired to notification events +
  `user_profiles.notification_preferences`.

### Pause before Sprint 2
This document is the deliverable. Sprint 2 begins by turning Phase A into a detailed
implementation plan (`writing-plans` skill) and executing.

## Out of scope
- `cbatechno-mobile` (parallel track, later).
- Self-hosted Hetzner/Coolify infra from the legacy `roadmap.md` (superseded by hosted
  Supabase).
- Typesense (search is served by the in-DB `search_products` FTS + trigram RPC).
