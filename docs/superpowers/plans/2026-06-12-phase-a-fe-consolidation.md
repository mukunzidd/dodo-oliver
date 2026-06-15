# Phase A — FE Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Collapse the customer, vendor, and admin web apps into one deployable TanStack Start app (`cbatechno-web`) with real Supabase auth and role-gated `/vendor/*` and `/admin/*` route groups, all wired to the live schema via `@cbatechno/shared`.

> **Status (2026-06-15):** Partially executed. Repo-level consolidation **done** —
> `cbatechno-customer-web` renamed to `cbatechno-web`; `cbatechno-vendor-web` and
> `cbatechno-admin-web` folded in and removed; real Supabase auth wired. **Pending:**
> the `_vendor/*` / `_admin/*` route groups and replacing mock `src/data/*` with real
> queries — now tracked as Phases 1–2 in [`roadmap.md`](../../05-development/roadmap.md).
> Checkboxes below are not maintained; the roadmap is authoritative.

**Architecture:** One TanStack Start (SSR) app. A client-hydrated `AuthProvider` exposes session + roles through TanStack Router context; `beforeLoad` guards on pathless `_vendor`/`_admin` layout routes enforce access, with component-level role enforcement handling the SSR/hydration window (vendor/admin render client-side, no sensitive data is server-rendered; RLS protects all queries regardless). Data access goes through the `@cbatechno/shared` SDK + `queryKeys` + TanStack Query.

**Tech Stack:** TanStack Start + Router (file-based, flat dotted routes), React 19, TanStack Query v5, `@supabase/supabase-js` v2, Zod v4, Vite 8, Vitest 4, Bun.

**Key facts established from the codebase:**
- `cbatechno-customer-web` is the base app (SSR, fleshed-out storefront) but its auth is **mock** (`src/store/auth.ts` Zustand + `USER` constant) and its data is **mock** (`src/data/products.ts`, `src/data/account.ts`).
- `cbatechno-vendor-web` / `cbatechno-admin-web` are near-identical skeletons whose `src/lib/auth.tsx` (real `AuthProvider` + `fetchRoles`), `src/lib/query.ts`, `src/lib/supabase.ts`, and `_authenticated.tsx` guard are the parts worth migrating; they differ only by a `REQUIRED_ROLE` constant. They will be **deleted** after migration.
- `@cbatechno/shared` is consumed as `file:../cbatechno-shared`. Public API confirmed: `searchProducts`, `matchProductsByImage`, `getProductBySlug`, `getCategories`, `createOrder`, `queryKeys`, all enums (`USER_ROLES`, `ROLE_LABELS`, `MARKET_ORIGINS`, …), all Zod schemas (`productSearchSchema`, `productInputSchema`, `addressSchema`, `createOrderSchema`, `signUpSchema`, `signInSchema`, …), and `Database`/`Json` types.
- DB role values are `buyer | supplier | admin` (UI labels: Customer/Vendor/Admin via `ROLE_LABELS`).

---

## File structure (created/modified in this phase)

```
cbatechno-web/                         (renamed from cbatechno-customer-web)
  src/
    lib/
      supabase.ts                      MODIFY — keep typed client; add named export note
      auth.tsx                         CREATE — AuthProvider + useAuth + fetchRoles (migrated)
      query.ts                         CREATE — shared QueryClient (migrated)
      roles.ts                         CREATE — role helpers (hasRole, requireRole)
      storage.ts                       CREATE — product image upload helper (A2)
    router.tsx                         MODIFY — inject auth into router context
    routes/
      __root.tsx                       MODIFY — wrap with AuthProvider + QueryClientProvider
      login.tsx                        MODIFY — real supabase auth
      signup.tsx                       MODIFY — real supabase auth + provisioning call
      index.tsx                        MODIFY — live categories/products
      search.tsx                       MODIFY — live search_products
      products.$slug.tsx               MODIFY — live getProductBySlug
      account.tsx / account.*.tsx      MODIFY — live profile/orders/addresses
      _vendor.tsx                      CREATE — pathless guard (role=supplier|admin)
      _vendor/vendor.dashboard.tsx     CREATE
      _vendor/vendor.products.tsx      CREATE — list
      _vendor/vendor.products.new.tsx  CREATE — create/edit form
      _vendor/vendor.products.$id.tsx  CREATE — edit
      _vendor/vendor.orders.tsx        CREATE
      _vendor/vendor.messages.tsx      CREATE
      _vendor/vendor.analytics.tsx     CREATE
      _admin.tsx                       CREATE — pathless guard (role=admin)
      _admin/admin.dashboard.tsx       CREATE
      _admin/admin.suppliers.tsx       CREATE — approve/suspend
      _admin/admin.moderation.tsx      CREATE
      _admin/admin.analytics.tsx       CREATE
      _admin/admin.settings.tsx        CREATE — app_settings editor
    components/
      site-header.tsx                  MODIFY — role-aware nav
      role-nav.tsx                     CREATE — vendor/admin console nav
    hooks/
      use-products.ts                  CREATE — query hooks
      use-account.ts                   CREATE — profile/orders/addresses hooks
      use-vendor.ts                    CREATE — vendor data hooks
      use-admin.ts                     CREATE — admin data hooks
  (delete) cbatechno-vendor-web/, cbatechno-admin-web/
```

> **Route file naming:** the app uses flat dotted names that TanStack compiles to nested paths, with pathless layout routes prefixed `_`. After every route file add/rename, run `bun run generate-routes` (`tsr generate`) to regenerate `routeTree.gen.ts` before typechecking.

---

## A0 — Consolidation & auth foundation

### Task A0.1: Rename customer-web → cbatechno-web

**Files:**
- Rename dir: `cbatechno-customer-web/` → `cbatechno-web/`

- [ ] **Step 1: Confirm git ownership of the directory**

Run: `git -C /Users/diemu/dodoc137/dodo-oliver ls-files cbatechno-customer-web | head -1`
Expected: prints a tracked path (root repo tracks it) — if empty, the dir is its own repo; rename with plain `mv` instead of `git mv`.

- [ ] **Step 2: Rename**

```bash
cd /Users/diemu/dodoc137/dodo-oliver
git mv cbatechno-customer-web cbatechno-web   # or: mv, if step 1 showed it's a nested repo
```

- [ ] **Step 3: Update self-references**

Edit `cbatechno-web/package.json` `"name"` to `cbatechno-web`. Grep for the old name and fix any references:
Run: `grep -rl "cbatechno-customer-web" cbatechno-web --include=*.json --include=*.ts --include=*.md`
Edit each hit. (The `@cbatechno/shared` dep path `file:../cbatechno-shared` is unchanged — sibling dir.)

- [ ] **Step 4: Verify install + build still green**

Run: `cd cbatechno-web && bun install && bun run build`
Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: rename customer-web to cbatechno-web"
```

### Task A0.2: Migrate the QueryClient

**Files:**
- Create: `cbatechno-web/src/lib/query.ts`

- [ ] **Step 1: Create the QueryClient** (verbatim from the skeleton — proven config)

```typescript
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60_000, gcTime: 10 * 60_000, retry: 1 },
  },
})
```

- [ ] **Step 2: Commit**

```bash
git add cbatechno-web/src/lib/query.ts && git commit -m "feat(web): add shared QueryClient"
```

### Task A0.3: Migrate the real AuthProvider (SSR-safe)

**Files:**
- Create: `cbatechno-web/src/lib/auth.tsx`
- Test: `cbatechno-web/src/lib/auth.test.tsx`

- [ ] **Step 1: Write the failing test** (roles are fetched and exposed)

```tsx
import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'

const mockGetSession = vi.fn()
const mockOnAuthStateChange = vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } }))
const mockFrom = vi.fn()
vi.mock('./supabase', () => ({
  supabase: {
    auth: { getSession: mockGetSession, onAuthStateChange: mockOnAuthStateChange },
    from: (...a: unknown[]) => mockFrom(...a),
  },
}))

import { AuthProvider, useAuth } from './auth'

function Probe() {
  const { roles, loading } = useAuth()
  return <div>{loading ? 'loading' : roles.join(',')}</div>
}

describe('AuthProvider', () => {
  beforeEach(() => vi.clearAllMocks())
  it('exposes roles fetched for the signed-in user', async () => {
    mockGetSession.mockResolvedValue({ data: { session: { user: { id: 'u1' } } } })
    mockFrom.mockReturnValue({
      select: () => ({ eq: () => Promise.resolve({ data: [{ role: 'supplier' }] }) }),
    })
    render(<AuthProvider><Probe /></AuthProvider>)
    await waitFor(() => expect(screen.getByText('supplier')).toBeInTheDocument())
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd cbatechno-web && bun run test src/lib/auth.test.tsx`
Expected: FAIL — cannot find module `./auth`.

- [ ] **Step 3: Implement** (migrated from skeleton; unchanged logic — it is already correct and SSR-tolerant because the effect only runs client-side)

```tsx
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import type { UserRole } from '@cbatechno/shared'
import { supabase } from './supabase'

export type AuthState = {
  session: Session | null
  user: User | null
  roles: UserRole[]
  loading: boolean
  signInWithPassword: (email: string, password: string) => Promise<{ error: string | null }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

async function fetchRoles(userId: string): Promise<UserRole[]> {
  const { data } = await supabase.from('user_roles').select('role').eq('user_id', userId)
  return ((data ?? []) as Array<{ role: UserRole }>).map((r) => r.role)
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [user, setUser] = useState<User | null>(null)
  const [roles, setRoles] = useState<UserRole[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true
    async function hydrate(s: Session | null) {
      if (!active) return
      setSession(s)
      setUser(s?.user ?? null)
      setRoles(s?.user ? await fetchRoles(s.user.id) : [])
      setLoading(false)
    }
    supabase.auth.getSession().then(({ data }) => hydrate(data.session))
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => hydrate(s))
    return () => { active = false; sub.subscription.unsubscribe() }
  }, [])

  const value: AuthState = {
    session, user, roles, loading,
    signInWithPassword: async (email, password) => {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      return { error: error?.message ?? null }
    },
    signOut: async () => { await supabase.auth.signOut() },
  }
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd cbatechno-web && bun run test src/lib/auth.test.tsx`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add cbatechno-web/src/lib/auth.tsx cbatechno-web/src/lib/auth.test.tsx
git commit -m "feat(web): real Supabase AuthProvider with role fetch"
```

### Task A0.4: Role helpers

**Files:**
- Create: `cbatechno-web/src/lib/roles.ts`
- Test: `cbatechno-web/src/lib/roles.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
import { describe, it, expect } from 'vitest'
import { hasRole } from './roles'

describe('hasRole', () => {
  it('admin satisfies any required role', () => {
    expect(hasRole(['admin'], 'supplier')).toBe(true)
  })
  it('exact role matches', () => {
    expect(hasRole(['supplier'], 'supplier')).toBe(true)
  })
  it('missing role fails', () => {
    expect(hasRole(['buyer'], 'supplier')).toBe(false)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd cbatechno-web && bun run test src/lib/roles.test.ts`
Expected: FAIL — cannot find `./roles`.

- [ ] **Step 3: Implement**

```typescript
import type { UserRole } from '@cbatechno/shared'

/** Admin is a superset of every console. Otherwise require the exact role. */
export function hasRole(roles: UserRole[], required: UserRole): boolean {
  return roles.includes('admin') || roles.includes(required)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd cbatechno-web && bun run test src/lib/roles.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add cbatechno-web/src/lib/roles.ts cbatechno-web/src/lib/roles.test.ts
git commit -m "feat(web): role helper"
```

### Task A0.5: Inject auth into router context

**Files:**
- Modify: `cbatechno-web/src/router.tsx`

- [ ] **Step 1: Add the auth slot to router context**

The router must declare an `auth` context field so `beforeLoad` guards can read it. In `router.tsx`, where the router is created, add `context: { auth: undefined as AuthState | undefined }` to the default context and register its type:

```typescript
import type { AuthState } from './lib/auth'

// inside createRouter({...})
context: { auth: undefined as AuthState | undefined },

// module augmentation (keep alongside the existing Register block)
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
  interface RouteContext {
    auth: AuthState | undefined
  }
}
```

- [ ] **Step 2: Typecheck**

Run: `cd cbatechno-web && bun run generate-routes && bunx tsc --noEmit`
Expected: no errors (router context now carries `auth`).

- [ ] **Step 3: Commit**

```bash
git add cbatechno-web/src/router.tsx && git commit -m "feat(web): carry auth in router context"
```

### Task A0.6: Wire providers + feed live auth into router context at the root

**Files:**
- Modify: `cbatechno-web/src/routes/__root.tsx`

- [ ] **Step 1: Wrap the app with QueryClientProvider + AuthProvider and push auth into router context**

In `__root.tsx`, the root component renders providers around `<Outlet />` (via `children`). Add an inner bridge that calls `useAuth()` and writes it into the router via `router.update`/`useRouter().options.context` so client navigations' `beforeLoad` see the live value. Concretely:

```tsx
import { QueryClientProvider } from '@tanstack/react-query'
import { useRouter } from '@tanstack/react-router'
import { queryClient } from '../lib/query'
import { AuthProvider, useAuth } from '../lib/auth'

function AuthContextBridge({ children }: { children: React.ReactNode }) {
  const auth = useAuth()
  const router = useRouter()
  // keep router context in sync so beforeLoad guards read live auth on client nav
  router.options.context = { ...router.options.context, auth }
  return <>{children}</>
}

// In RootDocument, wrap the body content:
<QueryClientProvider client={queryClient}>
  <AuthProvider>
    <AuthContextBridge>
      {children}
      <QuickView />
      <CartDrawer />
    </AuthContextBridge>
  </AuthProvider>
</QueryClientProvider>
```

- [ ] **Step 2: Run the app and confirm it boots**

Run: `cd cbatechno-web && bun run dev` then open `http://localhost:3000`.
Expected: storefront renders, no console errors about missing AuthProvider.

- [ ] **Step 3: Commit**

```bash
git add cbatechno-web/src/routes/__root.tsx
git commit -m "feat(web): mount QueryClient + AuthProvider, sync auth to router context"
```

### Task A0.7: Delete the skeleton apps

**Files:**
- Delete: `cbatechno-vendor-web/`, `cbatechno-admin-web/`

- [ ] **Step 1: Confirm nothing else references them**

Run: `grep -rl "cbatechno-vendor-web\|cbatechno-admin-web" /Users/diemu/dodoc137/dodo-oliver --include=*.json --include=*.md --include=*.ts | grep -v node_modules`
Expected: no references outside the dirs themselves (and the now-historical spec doc, which is fine).

- [ ] **Step 2: Remove**

```bash
cd /Users/diemu/dodoc137/dodo-oliver
git rm -r cbatechno-vendor-web cbatechno-admin-web   # or rm -rf if nested repos
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove vendor-web/admin-web (folded into cbatechno-web)"
```

---

## A1 — Customer surface: wire to live data + real auth

### Task A1.1: Product query hooks

**Files:**
- Create: `cbatechno-web/src/hooks/use-products.ts`
- Test: `cbatechno-web/src/hooks/use-products.test.tsx`

- [ ] **Step 1: Write the failing test** (search hook calls SDK with parsed input and uses the right query key)

```tsx
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { describe, it, expect, vi } from 'vitest'

const searchProducts = vi.fn(() => Promise.resolve({ data: [{ id: 'p1', name: 'Widget' }], error: null }))
vi.mock('@cbatechno/shared', async (orig) => ({ ...(await orig()), searchProducts }))
vi.mock('../lib/supabase', () => ({ supabase: {} }))

import { useProductSearch } from './use-products'

const wrap = ({ children }: { children: React.ReactNode }) => (
  <QueryClientProvider client={new QueryClient()}>{children}</QueryClientProvider>
)

describe('useProductSearch', () => {
  it('calls searchProducts and returns rows', async () => {
    const { result } = renderHook(() => useProductSearch({ q: 'widget' }), { wrapper: wrap })
    await waitFor(() => expect(result.current.data?.[0].name).toBe('Widget'))
    expect(searchProducts).toHaveBeenCalled()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd cbatechno-web && bun run test src/hooks/use-products.test.tsx`
Expected: FAIL — missing `./use-products`.

- [ ] **Step 3: Implement**

```typescript
import { useQuery } from '@tanstack/react-query'
import {
  searchProducts, getProductBySlug, getCategories, queryKeys,
  productSearchSchema, type ProductSearchInput,
} from '@cbatechno/shared'
import { supabase } from '../lib/supabase'

export function useProductSearch(input: Partial<ProductSearchInput>) {
  const parsed = productSearchSchema.parse(input)
  return useQuery({
    queryKey: queryKeys.products.search(parsed),
    queryFn: async () => {
      const { data, error } = await searchProducts(supabase, parsed)
      if (error) throw error
      return data ?? []
    },
  })
}

export function useProduct(slug: string) {
  return useQuery({
    queryKey: queryKeys.products.detail(slug),
    queryFn: async () => {
      const { data, error } = await getProductBySlug(supabase, slug)
      if (error) throw error
      return data
    },
  })
}

export function useCategories() {
  return useQuery({
    queryKey: queryKeys.categories.tree(),
    queryFn: async () => {
      const { data, error } = await getCategories(supabase)
      if (error) throw error
      return data ?? []
    },
  })
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd cbatechno-web && bun run test src/hooks/use-products.test.tsx`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add cbatechno-web/src/hooks/use-products.* && git commit -m "feat(web): product query hooks"
```

### Task A1.2: Wire search page to live `search_products`

**Files:**
- Modify: `cbatechno-web/src/routes/search.tsx`
- Modify: `cbatechno-web/src/components/product-card.tsx` (accept DB row shape)

- [ ] **Step 1: Map the DB row to the card props**

`search_products` returns rows with `{ id, sku, name, slug, short_description, base_price, compare_at_price, currency, market_origin, stock_quantity, supplier_id, category_id, primary_image, rank, total_count }`. Update `product-card.tsx` to accept this shape (replace the mock `Product` import). Card props:

```typescript
export type ProductCardData = {
  id: string; slug: string; name: string; base_price: number
  compare_at_price: number | null; currency: string | null; primary_image: string | null
}
```

Render `primary_image` (fallback to a placeholder), `name`, formatted `base_price` with `currency`, and a strike-through `compare_at_price` when present.

- [ ] **Step 2: Replace mock data in search.tsx with the hook**

Use `useProductSearch` driven by the route's search params (`q`, `cat`, `sort`). Map `cat` → `category_id` (look up id from `useCategories`), `sort` → `productSearchSchema` `sort` values (`relevance|price_asc|price_desc|newest`). Render results in the existing grid; show loading + empty states.

- [ ] **Step 3: Verify in the running app**

Run: `cd cbatechno-web && bun run dev` → visit `/search?q=` (seed has categories but no products yet, so expect an empty grid with the empty state, no errors). Then in Supabase insert one test product via SQL and confirm it appears.
Expected: query fires (Network tab → `rpc/search_products`), grid renders the row.

- [ ] **Step 4: Commit**

```bash
git add cbatechno-web/src/routes/search.tsx cbatechno-web/src/components/product-card.tsx
git commit -m "feat(web): live product search"
```

### Task A1.3: Wire homepage + product detail

**Files:**
- Modify: `cbatechno-web/src/routes/index.tsx` (categories grid + recent/featured via `useProductSearch({ sort: 'newest', limit: 8 })`)
- Modify: `cbatechno-web/src/routes/products.$slug.tsx` (use `useProduct(slug)`; loader can stay for SSR but call the live SDK)

- [ ] **Step 1: Homepage** — replace mock `PRODUCTS`/categories with `useCategories()` and `useProductSearch({ sort: 'newest', limit: 8 })`. Keep the existing visual layout.

- [ ] **Step 2: Product detail** — replace `getProduct(slug)` mock with `useProduct(slug)`. The SDK's `getProductBySlug` already selects `*, product_images(*), product_specifications(*), suppliers(id,business_name,logo_url,country,status)`. Render images carousel from `product_images`, specs from `product_specifications`, supplier badge from `suppliers`. Throw `notFound()` when `data` is null.

- [ ] **Step 3: Verify in app** — `bun run dev`, visit `/` and a product URL; confirm live queries and no mock imports remain (`grep -rn "data/products" src/routes`).
Expected: no matches except deletion follow-up.

- [ ] **Step 4: Commit**

```bash
git add cbatechno-web/src/routes/index.tsx cbatechno-web/src/routes/products.\$slug.tsx
git commit -m "feat(web): live homepage + product detail"
```

### Task A1.4: Real auth on login/signup + provisioning

**Files:**
- Modify: `cbatechno-web/src/routes/login.tsx`, `cbatechno-web/src/routes/signup.tsx`
- Delete: `cbatechno-web/src/store/auth.ts` (mock store) after migrating its consumers

- [ ] **Step 1: Login** — replace the mock `useAuth().signIn` with `useAuth().signInWithPassword(email, password)` from `lib/auth`. Validate with `signInSchema` (from `@cbatechno/shared`). On success `navigate({ to: '/account' })`; on error show `error`.

- [ ] **Step 2: Signup** — validate with `signUpSchema`; call `supabase.auth.signUp({ email, password, options: { data: { full_name } } })`. Profile/role provisioning is handled server-side by the `handle_new_user` trigger built in **Phase B (B1)**; until then, signup creates the auth user only. Add a code comment pointing to B1. On success, route to `/account` (or a "check your email" state if confirmations are enabled).

- [ ] **Step 3: Replace remaining mock-store consumers** — `grep -rn "store/auth" src` and switch each to `lib/auth`'s `useAuth()` (`user`, `signOut`). Then delete `src/store/auth.ts`.

- [ ] **Step 4: Verify in app** — create a user via Supabase dashboard, sign in through `/login`, confirm `useAuth().user` populates and the header shows the account menu.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(web): real Supabase auth on login/signup"
```

### Task A1.5: Account hooks + pages (profile, orders, addresses)

**Files:**
- Create: `cbatechno-web/src/hooks/use-account.ts`
- Modify: `cbatechno-web/src/routes/account.index.tsx`, `account.orders.tsx`, `account.addresses.tsx`, `account.settings.tsx`

- [ ] **Step 1: Implement hooks** (typed against `Database`; RLS scopes rows to the user)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys, addressSchema, type AddressInput } from '@cbatechno/shared'
import { supabase } from '../lib/supabase'

export function useProfile(userId: string | undefined) {
  return useQuery({
    queryKey: queryKeys.profile.current(),
    enabled: !!userId,
    queryFn: async () => {
      const { data, error } = await supabase.from('user_profiles').select('*').eq('id', userId!).single()
      if (error) throw error
      return data
    },
  })
}

export function useOrders() {
  return useQuery({
    queryKey: queryKeys.orders.list(),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('orders')
        .select('id, order_number, order_status, payment_status, total, currency, created_at, order_items(*)')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data ?? []
    },
  })
}

export function useAddresses() {
  return useQuery({
    queryKey: queryKeys.profile.addresses(),
    queryFn: async () => {
      const { data, error } = await supabase.from('user_addresses').select('*').order('is_default', { ascending: false })
      if (error) throw error
      return data ?? []
    },
  })
}

export function useSaveAddress() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (input: AddressInput & { user_id: string }) => {
      const parsed = addressSchema.parse(input)
      const { error } = await supabase.from('user_addresses').insert({ ...parsed, user_id: input.user_id })
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: queryKeys.profile.addresses() }),
  })
}
```

- [ ] **Step 2: Wire pages** — `account.orders.tsx` lists `useOrders()`; `account.addresses.tsx` lists `useAddresses()` and uses `useSaveAddress()` with a form validated by `addressSchema`; `account.settings.tsx` reads/updates `useProfile()`. Remove `ORDERS`/`ADDRESSES`/`USER` mock imports; delete those mock exports from `src/data/account.ts` once unused.

- [ ] **Step 3: Verify in app** — signed in, add an address, reload; confirm it persists (Network → `user_addresses`).

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(web): live account profile/orders/addresses"
```

> **Cart & checkout** UI exists on mock state. Cart can remain client-side (Zustand) for now; the **`createOrder` + payment** wiring is Phase B (B3), which replaces checkout's submit handler. Leave a `// TODO(B3)` at checkout's submit.

---

## A2 — Vendor console (`/vendor/*`)

### Task A2.1: Vendor guard layout

**Files:**
- Create: `cbatechno-web/src/routes/_vendor.tsx`
- Create: `cbatechno-web/src/components/role-nav.tsx`

- [ ] **Step 1: Implement the pathless guard layout**

```tsx
import { createFileRoute, redirect, Outlet } from '@tanstack/react-router'
import { useAuth } from '../lib/auth'
import { hasRole } from '../lib/roles'
import { RoleNav } from '../components/role-nav'

export const Route = createFileRoute('/_vendor')({
  beforeLoad: ({ context, location }) => {
    // client navigations: context.auth is live. On the SSR/first paint it may be
    // undefined; the component below enforces the role once auth hydrates.
    if (context.auth && !context.auth.loading && !context.auth.user) {
      throw redirect({ to: '/login', search: { redirect: location.href } })
    }
  },
  component: VendorLayout,
})

const VENDOR_LINKS = [
  { to: '/vendor/dashboard', label: 'Dashboard' },
  { to: '/vendor/products', label: 'Products' },
  { to: '/vendor/orders', label: 'Orders' },
  { to: '/vendor/messages', label: 'Messages' },
  { to: '/vendor/analytics', label: 'Analytics' },
] as const

function VendorLayout() {
  const { user, roles, loading, signOut } = useAuth()
  if (loading) return <div className="p-8 text-neutral-500">Loading…</div>
  if (!user) return <div className="p-8">Please <a href="/login" className="underline">sign in</a>.</div>
  if (!hasRole(roles, 'supplier')) return <div className="p-8">Access restricted — vendor account required.</div>
  return (
    <div className="flex min-h-screen">
      <RoleNav title="Vendor" links={VENDOR_LINKS} email={user.email} onSignOut={signOut} />
      <main className="flex-1 p-6"><Outlet /></main>
    </div>
  )
}
```

- [ ] **Step 2: Implement RoleNav** (shared by vendor + admin)

```tsx
import { Link } from '@tanstack/react-router'

export function RoleNav(props: {
  title: string
  links: ReadonlyArray<{ to: string; label: string }>
  email?: string | null
  onSignOut: () => void
}) {
  return (
    <aside className="w-60 shrink-0 border-r bg-white p-4">
      <div className="mb-6 font-semibold">CBATechno {props.title}</div>
      <nav className="flex flex-col gap-1 text-sm">
        {props.links.map((l) => (
          <Link key={l.to} to={l.to} className="rounded px-2 py-1.5 hover:bg-neutral-100 [&.active]:bg-neutral-900 [&.active]:text-white">
            {l.label}
          </Link>
        ))}
      </nav>
      <button onClick={props.onSignOut} className="mt-6 text-xs text-neutral-500 hover:text-neutral-900">
        Sign out{props.email ? ` (${props.email})` : ''}
      </button>
    </aside>
  )
}
```

- [ ] **Step 3: Regenerate routes + typecheck**

Run: `cd cbatechno-web && bun run generate-routes && bunx tsc --noEmit`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add cbatechno-web/src/routes/_vendor.tsx cbatechno-web/src/components/role-nav.tsx
git commit -m "feat(web): vendor guard layout + role nav"
```

### Task A2.2: Vendor data hooks

**Files:**
- Create: `cbatechno-web/src/hooks/use-vendor.ts`

- [ ] **Step 1: Implement** (current vendor's `supplier_id` comes from the `suppliers` row for the signed-in user; products/orders are RLS-scoped to that supplier)

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys, productInputSchema, type ProductInput } from '@cbatechno/shared'
import { supabase } from '../lib/supabase'

export function useMySupplier() {
  return useQuery({
    queryKey: ['suppliers', 'me'],
    queryFn: async () => {
      const { data, error } = await supabase.from('suppliers').select('*').maybeSingle()
      if (error) throw error
      return data
    },
  })
}

export function useVendorProducts(supplierId: string | undefined) {
  return useQuery({
    queryKey: supplierId ? queryKeys.products.bySupplier(supplierId) : ['products', 'supplier', 'none'],
    enabled: !!supplierId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('products').select('*').eq('supplier_id', supplierId!).is('deleted_at', null)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data ?? []
    },
  })
}

export function useSaveProduct() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (input: ProductInput & { supplier_id: string; id?: string }) => {
      const parsed = productInputSchema.parse(input)
      const slug = parsed.name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
      const row = { ...parsed, supplier_id: input.supplier_id, slug }
      const { error } = input.id
        ? await supabase.from('products').update(row).eq('id', input.id)
        : await supabase.from('products').insert(row)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: queryKeys.products.all }),
  })
}

export function useVendorOrders(supplierId: string | undefined) {
  return useQuery({
    queryKey: supplierId ? queryKeys.orders.list({ supplierId }) : ['orders', 'supplier', 'none'],
    enabled: !!supplierId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('orders').select('*, order_items(*)').eq('supplier_id', supplierId!)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data ?? []
    },
  })
}

export function useUpdateOrderStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (p: { orderId: string; status: string }) => {
      const { error } = await supabase.from('orders').update({ order_status: p.status }).eq('id', p.orderId)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: queryKeys.orders.all }),
  })
}
```

- [ ] **Step 2: Typecheck + commit**

Run: `cd cbatechno-web && bunx tsc --noEmit`
```bash
git add cbatechno-web/src/hooks/use-vendor.ts && git commit -m "feat(web): vendor data hooks"
```

### Task A2.3: Storage helper for product images

**Files:**
- Create: `cbatechno-web/src/lib/storage.ts`

- [ ] **Step 1: Implement** (uploads to a `product-images` bucket; bucket creation is a Phase B/storage setup item — note it)

```typescript
import { supabase } from './supabase'

const BUCKET = 'product-images'

/** Uploads a file and returns its public URL. Requires the `product-images` bucket (see Phase B storage setup). */
export async function uploadProductImage(productId: string, file: File): Promise<string> {
  const path = `${productId}/${crypto.randomUUID()}-${file.name}`
  const { error } = await supabase.storage.from(BUCKET).upload(path, file, { upsert: false })
  if (error) throw error
  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path)
  return data.publicUrl
}
```

- [ ] **Step 2: Commit**

```bash
git add cbatechno-web/src/lib/storage.ts && git commit -m "feat(web): product image upload helper"
```

### Task A2.4: Vendor screens

**Files:**
- Create: `vendor.dashboard.tsx`, `vendor.products.tsx`, `vendor.products.new.tsx`, `vendor.products.$id.tsx`, `vendor.orders.tsx`, `vendor.messages.tsx`, `vendor.analytics.tsx` (all under `src/routes/_vendor/`)

Each route uses `createFileRoute('/_vendor/vendor/...')`. Build them in this order; after each, run `bun run generate-routes` and verify in the app while signed in as a supplier.

- [ ] **Step 1: `vendor.dashboard.tsx`** — KPIs from `useVendorOrders` + `useVendorProducts` (counts: products, open orders, revenue sum of paid orders). Commit `feat(web): vendor dashboard`.

- [ ] **Step 2: `vendor.products.tsx`** — table of `useVendorProducts(supplier.id)` (name, sku, price, stock, status); row link to edit; "New product" → `/vendor/products/new`. Commit `feat(web): vendor products list`.

- [ ] **Step 3: `vendor.products.new.tsx`** — form bound to `productInputSchema` via react-hook-form; fields: name, sku, short_description, description, category_id (select from `useCategories`), market_origin (select `MARKET_ORIGINS`), base_price, compare_at_price, stock_quantity, low_stock_threshold, allow_backorder, moq, weight_grams, status (`PRODUCT_STATUSES`). On submit: `useSaveProduct()`, then optional image upload via `uploadProductImage` → insert `product_images` row. Commit `feat(web): vendor product create`.

- [ ] **Step 4: `vendor.products.$id.tsx`** — same form prefilled from the product row; calls `useSaveProduct({ id })`. Commit `feat(web): vendor product edit`.

- [ ] **Step 5: `vendor.orders.tsx`** — `useVendorOrders`; per-order status select wired to `useUpdateOrderStatus` (`ORDER_STATUSES`). Commit `feat(web): vendor orders`.

- [ ] **Step 6: `vendor.messages.tsx`** — list `conversations` where `supplier_id = supplier.id` (ordered by `last_message_at`); open one → `messages` thread; send via `messages` insert validated by `messageSchema`. Commit `feat(web): vendor messages`.

- [ ] **Step 7: `vendor.analytics.tsx`** — simple aggregates over the vendor's paid orders (revenue by month) using a client-side group on `useVendorOrders` data. Commit `feat(web): vendor analytics`.

- [ ] **Step 8: Verify** — signed in as a supplier (create one: insert a `suppliers` row + grant `supplier` role in SQL), walk every `/vendor/*` screen.
Expected: each loads, queries are RLS-scoped, no console errors.

---

## A3 — Admin console (`/admin/*`)

### Task A3.1: Admin guard layout

**Files:**
- Create: `cbatechno-web/src/routes/_admin.tsx`

- [ ] **Step 1: Implement** — identical structure to `_vendor.tsx` but `hasRole(roles, 'admin')` and the admin link set:

```tsx
const ADMIN_LINKS = [
  { to: '/admin/dashboard', label: 'Dashboard' },
  { to: '/admin/suppliers', label: 'Suppliers' },
  { to: '/admin/moderation', label: 'Moderation' },
  { to: '/admin/analytics', label: 'Analytics' },
  { to: '/admin/settings', label: 'Settings' },
] as const
```

(Guard component reuses `RoleNav` with `title="Admin"`; role check is `hasRole(roles, 'admin')`.)

- [ ] **Step 2: Regenerate + typecheck + commit**

```bash
cd cbatechno-web && bun run generate-routes && bunx tsc --noEmit
git add cbatechno-web/src/routes/_admin.tsx && git commit -m "feat(web): admin guard layout"
```

### Task A3.2: Admin data hooks

**Files:**
- Create: `cbatechno-web/src/hooks/use-admin.ts`

- [ ] **Step 1: Implement**

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@cbatechno/shared'
import { supabase } from '../lib/supabase'

export function usePendingSuppliers() {
  return useQuery({
    queryKey: queryKeys.suppliers.pending(),
    queryFn: async () => {
      const { data, error } = await supabase.from('suppliers').select('*').eq('status', 'pending')
        .order('created_at', { ascending: true })
      if (error) throw error
      return data ?? []
    },
  })
}

export function useSetSupplierStatus() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (p: { id: string; status: 'approved' | 'suspended' | 'rejected' }) => {
      const patch: Record<string, unknown> = { status: p.status }
      if (p.status === 'approved') patch.approved_at = new Date().toISOString()
      const { error } = await supabase.from('suppliers').update(patch).eq('id', p.id)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['suppliers'] }),
  })
}

export function useAppSettings() {
  return useQuery({
    queryKey: ['app_settings'],
    queryFn: async () => {
      const { data, error } = await supabase.from('app_settings').select('*').order('key')
      if (error) throw error
      return data ?? []
    },
  })
}

export function useSaveAppSetting() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (p: { key: string; value: unknown }) => {
      const { error } = await supabase.from('app_settings').update({ value: p.value }).eq('key', p.key)
      if (error) throw error
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['app_settings'] }),
  })
}
```

- [ ] **Step 2: Typecheck + commit**

```bash
cd cbatechno-web && bunx tsc --noEmit
git add cbatechno-web/src/hooks/use-admin.ts && git commit -m "feat(web): admin data hooks"
```

### Task A3.3: Admin screens

**Files:**
- Create under `src/routes/_admin/`: `admin.dashboard.tsx`, `admin.suppliers.tsx`, `admin.moderation.tsx`, `admin.analytics.tsx`, `admin.settings.tsx`

- [ ] **Step 1: `admin.suppliers.tsx`** — `usePendingSuppliers()` table with Approve / Suspend / Reject buttons wired to `useSetSupplierStatus()`. Commit `feat(web): admin supplier approval`.

- [ ] **Step 2: `admin.dashboard.tsx`** — platform KPIs (counts of suppliers by status, products, orders) via lightweight count queries. Commit `feat(web): admin dashboard`.

- [ ] **Step 3: `admin.moderation.tsx`** — recent `reviews` + `products` with a "hide" action (set product `status='discontinued'` or delete a review). Commit `feat(web): admin moderation`.

- [ ] **Step 4: `admin.analytics.tsx`** — orders/revenue over time (client-side group over `orders`). Commit `feat(web): admin analytics`.

- [ ] **Step 5: `admin.settings.tsx`** — `useAppSettings()` list; edit each `value` (JSON editor) via `useSaveAppSetting()`. Commit `feat(web): admin settings editor`.

- [ ] **Step 6: Verify** — signed in as admin (grant `admin` role to a user in SQL), walk every `/admin/*` screen and approve a test pending supplier.
Expected: status flips to `approved`; the supplier becomes publicly visible (RLS `approved suppliers public`).

### Task A3.4: Role-aware header nav

**Files:**
- Modify: `cbatechno-web/src/components/site-header.tsx`

- [ ] **Step 1: Add console links by role** — read `useAuth().roles`; in the account dropdown render a "Vendor console" link when `hasRole(roles,'supplier')` and an "Admin console" link when `hasRole(roles,'admin')`, at the documented insertion point.

- [ ] **Step 2: Verify + commit** — sign in as each role, confirm the right links appear.

```bash
git add cbatechno-web/src/components/site-header.tsx && git commit -m "feat(web): role-aware header nav"
```

---

## Phase A self-review checklist (run before handing off)

- [ ] `cd cbatechno-web && bunx tsc --noEmit` clean.
- [ ] `bun run test` green.
- [ ] `bun run build` green.
- [ ] No remaining imports from `src/data/*` mock or `src/store/auth` (`grep -rn "data/products\|data/account\|store/auth" src`).
- [ ] `cbatechno-vendor-web` / `cbatechno-admin-web` deleted.
- [ ] Signed-out user hitting `/vendor` or `/admin` is redirected/blocked; wrong-role user sees "access restricted"; correct role sees the console.

## Deferred to Phase B (explicit handoffs)
- Checkout submit (`createOrder` + payment) — B3.
- `handle_new_user` provisioning trigger (signup currently creates only the auth user) — B1.
- `product-images` Storage bucket + policies — B (storage setup).
- Visual search UI (image upload → `image-embed` → `match_products_by_image`) — B3.
