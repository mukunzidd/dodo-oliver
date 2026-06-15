# 07 — Multi-Client Re-Platform

Re-platforming CBATechno from a single Next.js monolith (self-hosted) to **three
TanStack web clients + an Expo mobile app on Supabase Cloud**. Full rationale and
the approved implementation plan: `~/.claude/plans/1-mobile-scope-humming-boot.md`.

---

## ▶ Session state — RESUME HERE (last updated this session)

**Where we are:**
- **customer-web** is the focus and is **substantially built out (UI, mock data)** — see its row below.
- **Supabase CLI**: installed globally (v2.106) and **logged in**. Backend repo is **linked** to `cba-techno` (`kwkhhrjxuleftlinazaz`).
- **Supabase MCP**: configured in `cbatechno-backend/.mcp.json` and `cbatechno-customer-web/.mcp.json` using **PAT-header auth** (`Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}`) because the OAuth `/mcp` flow returned `Unauthorized`.

**To resume:**
1. Create a PAT at https://supabase.com/dashboard/account/tokens → `export SUPABASE_ACCESS_TOKEN=sbp_…` (add to `~/.zshrc`).
2. `cd cbatechno-backend && claude` → `/mcp` should show **supabase connected** (no Authenticate step).
3. Then say "go" — apply migrations via the **MCP** (`apply_migration`/`execute_sql`), run `db advisors`, seed, then `npm run gen:types` to replace the placeholder types in `@cbatechno/shared` (clears its 3 cosmetic TS errors). This avoids `supabase db push` (denied as a prod action) and the DB password.

**Blocked / still pending:**
- Schema NOT yet pushed to cloud (waiting on the above). Cloud DB is empty.
- `@cbatechno/shared` not yet published to GitHub Packages (clients use it via local `file:` link for now).
- Edge-function secrets not set; functions not deployed.
- Vendor/admin/mobile = scaffold only (no feature screens yet).

**Run the storefront UI now (no backend needed):**
`cd cbatechno-customer-web && npm run dev` → http://localhost:3000

---

## Decisions (ADR summary)

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Supabase **Cloud** now (`kwkhhrjxuleftlinazaz`); self-host later | Fastest path; matches the provided hosted MCP |
| 2 | **TanStack Start** (SSR) for customer; **Router+Vite SPA** for vendor & admin | SEO where it matters; light SPAs for dashboards |
| 3 | **Separate repo per app**; shared contract via **`@cbatechno/shared`** (own repo, GitHub Packages) | Independent deploys; one versioned source of truth |
| 4 | **Postgres FTS (`tsvector`/`pg_trgm`) + `pgvector`** | Supabase-native; no extra search infra |
| 5 | Mobile is **customer-only** for V1 | Vendor/admin stay on web |
| 6 | DB enum keeps `buyer`/`supplier`; UIs label **customer/vendor** | Avoids a churny rename migration |

## Repo layout (siblings inside `dodo-oliver/`, each its own git repo, gitignored)

| Repo | Stack | Status |
|------|-------|--------|
| `cba-tecno-mobile/` | docs hub (this) | existing |
| `cbatechno-backend/` | Supabase-as-code | ✅ schema authored + **validated locally** |
| `cbatechno-shared/` | `@cbatechno/shared` pkg | ✅ built (placeholder types pending `gen:types`) |
| `cbatechno-mobile/` | Expo SDK 56 | ✅ scaffolded + Supabase/Query/auth wired |
| `cbatechno-customer-web/` | TanStack Start | ✅ **storefront UI built**: discovery (filters/search), product page + gallery, quick-view modal, cart drawer, wishlist, login/signup, checkout + order-confirmed, account dashboard (overview/orders/addresses/settings/wishlist); mock auth w/ adaptive nav. All mock data, build green |
| `cbatechno-vendor-web/` | TanStack Router SPA | ✅ scaffolded + role-guarded auth; **build passes** |
| `cbatechno-admin-web/` | TanStack Router SPA | ✅ scaffolded + role-guarded auth; **build passes** |

> All four clients typecheck clean and the three web apps `npm run build` green.
> What remains per client is **feature buildout** (the screens/flows from the
> feature specs), not scaffolding.

## What's verified

`supabase db reset` against a local stack applied all 5 migrations + seed cleanly:
**28 tables · 4 RPCs · RLS on all 28 · 54 policies · 6 categories · 3 shipping methods**;
`search_products` RPC executes.

## Manual steps to bring it live (require your auth — I can't do these)

```bash
# 1. Backend → hosted project
cd cbatechno-backend
npx supabase login                 # browser OAuth
npm run link                       # link --project-ref kwkhhrjxuleftlinazaz
npm run db:push                    # apply migrations to the cloud project
npx supabase db seed               # load seed.sql
npm run gen:types                  # → cbatechno-shared/src/database.ts (real types)
npm run advisors                   # security/RLS check

# 2. Edge function secrets + deploy
cp .env.example .env && $EDITOR .env
npx supabase secrets set --env-file .env
npm run functions:deploy

# 3. Activate the Supabase MCP for Claude Code (regular terminal, not IDE ext.)
claude /mcp                        # select "supabase" → Authenticate

# 4. Publish the shared contract
cd ../cbatechno-shared && npm version 0.1.0 && git tag v0.1.0 && git push --tags
# (needs a GitHub repo + GITHUB_TOKEN with packages:write)

# 5. Mobile env + run
cd ../cbatechno-mobile && cp .env.example .env   # fill EXPO_PUBLIC_SUPABASE_* (publishable key)
npx expo start
```

> Local dev DB is currently running (9 healthy containers). Stop with
> `cd cbatechno-backend && npx supabase stop` when done.

## Notes / risks carried into code

- **Type generation is gated on `supabase login`** — even `--local`/`--db-url` require a token in CLI 2.106. `gen:types` produces the real `database.ts`; until then `@cbatechno/shared` ships a permissive placeholder.
- **Data API grants**: tables aren't auto-exposed post-Apr-2026 — `…_rls.sql` does explicit `grant`s.
- **Keys**: use `sb_publishable_*` (legacy anon key deprecates EOY 2026).
- **Flutterwave** on mobile uses hosted WebView checkout (RN SDK unmaintained); see `payment-flutterwave` edge fn.
