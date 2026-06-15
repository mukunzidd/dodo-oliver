# Roadmap Reconciliation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconcile the stale CBATechno planning docs to current reality and publish a single canonical, re-sequenced roadmap to V1.

**Architecture:** Docs-only change in the root `dodo-oliver` repo. Canonical-rewrite + archive (Approach A): the old Next.js roadmap moves to `docs/archive/` with a superseded banner; `docs/05-development/roadmap.md` becomes the source of truth; `docs/07-replatform/README.md` loses its stale session-state and points at the roadmap; the Phase A/B plans get a short status header.

**Tech Stack:** Markdown, git. No code, no tests, no cloud ops. Source of truth for content: `docs/superpowers/specs/2026-06-15-roadmap-reconciliation-design.md`.

**Conventions:** All paths are relative to `/Users/diemu/dodoc137/dodo-oliver`. Commit on the current branch (`main`). Verification is `grep`/`ls` content checks, not test runs.

---

### Task 1: Archive the old Next.js roadmap

**Files:**
- Rename: `docs/05-development/roadmap.md` → `docs/archive/2025-10-roadmap-v1.md`
- Modify: `docs/archive/2025-10-roadmap-v1.md` (prepend banner)

- [ ] **Step 1: Move the file with git (preserves history)**

```bash
cd /Users/diemu/dodoc137/dodo-oliver
mkdir -p docs/archive
git mv docs/05-development/roadmap.md docs/archive/2025-10-roadmap-v1.md
```

- [ ] **Step 2: Prepend the superseded banner**

Insert these lines at the very top of `docs/archive/2025-10-roadmap-v1.md`, before the existing `# Development Roadmap - CBATechno Discovery Platform` line:

```markdown
> ⚠️ **SUPERSEDED 2026-06-15.** This is the original (Oct 2025) V1 plan for the
> abandoned stack — Next.js 15 + Typesense + self-hosted Supabase on Hetzner/Coolify.
> The project pivoted to TanStack + Expo + Supabase. Current plan:
> [`docs/05-development/roadmap.md`](../05-development/roadmap.md). Kept for history.

---

```

- [ ] **Step 3: Verify the move and banner**

Run:
```bash
test -f docs/archive/2025-10-roadmap-v1.md && ! test -f docs/05-development/roadmap.md && echo "MOVED OK"
head -1 docs/archive/2025-10-roadmap-v1.md | grep -q "SUPERSEDED" && echo "BANNER OK"
```
Expected: `MOVED OK` and `BANNER OK`.

- [ ] **Step 4: Commit**

```bash
git add -A docs/archive docs/05-development
git commit -m "docs: archive original Next.js roadmap (superseded by re-platform)"
```

---

### Task 2: Write the canonical roadmap

**Files:**
- Create: `docs/05-development/roadmap.md`

- [ ] **Step 1: Write the new roadmap file**

Create `docs/05-development/roadmap.md` with exactly this content:

```markdown
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
```

- [ ] **Step 2: Verify the file renders and links resolve**

Run:
```bash
cd /Users/diemu/dodoc137/dodo-oliver
test -f docs/05-development/roadmap.md && grep -q "Version:** 2.0" docs/05-development/roadmap.md && echo "ROADMAP OK"
test -f docs/07-replatform/README.md && echo "ADR LINK TARGET OK"
test -f docs/archive/2025-10-roadmap-v1.md && echo "ARCHIVE LINK TARGET OK"
```
Expected: `ROADMAP OK`, `ADR LINK TARGET OK`, `ARCHIVE LINK TARGET OK`.

- [ ] **Step 3: Commit**

```bash
git add docs/05-development/roadmap.md
git commit -m "docs: canonical roadmap v2 (reconciled to re-platform reality)"
```

---

### Task 3: Slim and fix `07-replatform/README.md`

**Files:**
- Modify: `docs/07-replatform/README.md`

- [ ] **Step 1: Replace the stale "Session state" section with a status pointer**

In `docs/07-replatform/README.md`, delete the entire block starting at the line
`## ▶ Session state — RESUME HERE (last updated this session)` up to (but **not**
including) the line `## Decisions (ADR summary)`, and replace it with:

```markdown
> **Status & forward plan moved.** Live project status and the phased roadmap now
> live in [`docs/05-development/roadmap.md`](../05-development/roadmap.md). This file
> is the **decision record** (ADRs + rationale + carried-forward risks).

```

- [ ] **Step 2: Fix the repo-layout table**

In the same file, in the "Repo layout" table:

Delete this row entirely (the docs hub now lives in the root `docs/`, not a sibling repo):
```markdown
| `cba-tecno-mobile/` | docs hub (this) | existing |
```

Change this row's name from `cbatechno-customer-web/` to `cbatechno-web/`:
```markdown
| `cbatechno-customer-web/` | TanStack Start | ✅ **storefront UI built**: discovery (filters/search), product page + gallery, quick-view modal, cart drawer, wishlist, login/signup, checkout + order-confirmed, account dashboard (overview/orders/addresses/settings/wishlist); mock auth w/ adaptive nav. All mock data, build green |
```
becomes:
```markdown
| `cbatechno-web/` | TanStack Start | storefront UI built; **auth real**, catalog/account still mock; no vendor/admin routes yet |
```

Delete the `cbatechno-vendor-web/` and `cbatechno-admin-web/` rows (consolidated into `cbatechno-web`):
```markdown
| `cbatechno-vendor-web/` | TanStack Router SPA | ✅ scaffolded + role-guarded auth; **build passes** |
| `cbatechno-admin-web/` | TanStack Router SPA | ✅ scaffolded + role-guarded auth; **build passes** |
```

- [ ] **Step 3: Replace the now-stale "four clients" blockquote under the table**

The blockquote after the repo-layout table is stale once vendor/admin rows are gone.
Replace this block:

```markdown
> All four clients typecheck clean and the three web apps `npm run build` green.
> What remains per client is **feature buildout** (the screens/flows from the
> feature specs), not scaffolding.
```

with:

```markdown
> `cbatechno-web` and `cbatechno-mobile` typecheck clean; the web app builds green.
> All repos are published on GitHub under `mukunzidd` (SSH remotes), tracked on `main`.
> What remains is **feature buildout** — see [`roadmap.md`](../05-development/roadmap.md).
```

- [ ] **Step 4: Verify the stale content is gone and pointer is present**

Run:
```bash
cd /Users/diemu/dodoc137/dodo-oliver
! grep -q "RESUME HERE" docs/07-replatform/README.md && echo "SESSION-STATE REMOVED"
! grep -q "cbatechno-customer-web" docs/07-replatform/README.md && echo "RENAME OK"
! grep -q "cba-tecno-mobile" docs/07-replatform/README.md && echo "DOCS-HUB ROW REMOVED"
grep -q "Status & forward plan moved" docs/07-replatform/README.md && echo "POINTER OK"
grep -q "Decisions (ADR summary)" docs/07-replatform/README.md && echo "ADRS KEPT"
```
Expected: all five OK lines.

- [ ] **Step 5: Commit**

```bash
git add docs/07-replatform/README.md
git commit -m "docs: slim 07-replatform to decision record; point status at roadmap"
```

---

### Task 4: Add status headers to the Phase A/B plans

**Files:**
- Modify: `docs/superpowers/plans/2026-06-12-phase-a-fe-consolidation.md`
- Modify: `docs/superpowers/plans/2026-06-12-phase-b-backend-wiring.md`

- [ ] **Step 1: Add status header to the Phase A plan**

Insert immediately after the Phase A `**Goal:** …` line (before the `**Architecture:**`
line) in `docs/superpowers/plans/2026-06-12-phase-a-fe-consolidation.md`:

```markdown

> **Status (2026-06-15):** Partially executed. Repo-level consolidation **done** —
> `cbatechno-customer-web` renamed to `cbatechno-web`; `cbatechno-vendor-web` and
> `cbatechno-admin-web` folded in and removed; real Supabase auth wired. **Pending:**
> the `_vendor/*` / `_admin/*` route groups and replacing mock `src/data/*` with real
> queries — now tracked as Phases 1–2 in [`roadmap.md`](../../05-development/roadmap.md).
> Checkboxes below are not maintained; the roadmap is authoritative.
```

- [ ] **Step 2: Add status header to the Phase B plan**

Insert immediately after the Phase B `**Goal:** …` line (before the `**Architecture:**`
line) in `docs/superpowers/plans/2026-06-12-phase-b-backend-wiring.md`:

```markdown

> **Status (2026-06-15):** Not started. Edge functions and schema exist; the glue
> (provisioning trigger, storage bucket, secrets/deploy, payments + visual-search
> wiring, cron, notifications) is unbuilt — now sequenced as Phases 1, 4, and 5 in
> [`roadmap.md`](../../05-development/roadmap.md). Checkboxes below are not maintained;
> the roadmap is authoritative.
```

- [ ] **Step 3: Verify both headers are present**

Run:
```bash
cd /Users/diemu/dodoc137/dodo-oliver
grep -q "Status (2026-06-15)" docs/superpowers/plans/2026-06-12-phase-a-fe-consolidation.md && echo "PHASE A OK"
grep -q "Status (2026-06-15)" docs/superpowers/plans/2026-06-12-phase-b-backend-wiring.md && echo "PHASE B OK"
```
Expected: `PHASE A OK` and `PHASE B OK`.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-06-12-phase-a-fe-consolidation.md docs/superpowers/plans/2026-06-12-phase-b-backend-wiring.md
git commit -m "docs: add reality-status headers to Phase A/B plans"
```

---

### Task 5: Final verification

**Files:** none (read-only checks)

- [ ] **Step 1: Confirm the doc tree and a clean working state**

Run:
```bash
cd /Users/diemu/dodoc137/dodo-oliver
echo "--- docs/ ---"; ls docs docs/05-development docs/archive
echo "--- links from roadmap resolve ---"
for f in docs/07-replatform/README.md docs/archive/2025-10-roadmap-v1.md; do test -f "$f" && echo "ok: $f" || echo "MISSING: $f"; done
echo "--- working tree ---"; git status --short
```
Expected: `roadmap.md` under `docs/05-development`, `2025-10-roadmap-v1.md` under `docs/archive`, both link targets `ok:`, and a clean (or only-intended) `git status`.

- [ ] **Step 2: (Optional) push**

```bash
git push origin main
```

---

## Notes for the executor

- This plan only edits Markdown in the root repo. Do not touch the `cbatechno-*`
  sub-repos.
- If `git mv` in Task 1 reports the file is already moved (re-run), skip to the banner step.
- Keep edits surgical — preserve all other content in `07-replatform/README.md`
  (ADRs, "What's verified", "Manual steps", "Notes / risks").
