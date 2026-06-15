# Phase B — Backend Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the live backend fully operational end-to-end: auto-provision users on signup, deploy the (already-written) edge functions, wire payments + visual search into the web app, schedule cron jobs, and emit/deliver notifications.

> **Status (2026-06-15):** Not started. Edge functions and schema exist; the glue
> (provisioning trigger, storage bucket, secrets/deploy, payments + visual-search
> wiring, cron, notifications) is unbuilt — now sequenced as Phases 1, 4, and 5 in
> [`roadmap.md`](../../05-development/roadmap.md). Checkboxes below are not maintained;
> the roadmap is authoritative.

**Architecture:** The schema, RPCs, RLS, and all five edge functions already exist in `cbatechno-backend`. This phase adds the missing glue: a `handle_new_user` SQL trigger, a Storage bucket, secrets + function deploys, client→function integration calls, `pg_cron` schedules that invoke functions over HTTP via `pg_net`, and DB triggers that enqueue `notifications` rows for `push-dispatch` to deliver.

**Tech Stack:** Supabase CLI (link/db push/functions deploy/secrets), Postgres (`pg_cron`, `pg_net`), Deno edge functions (Stripe, Flutterwave, OpenAI, Expo Push), the `cbatechno-web` app from Phase A.

**Key facts established from the codebase:**
- Edge functions are **fully implemented**, not stubs: `currency-sync` (Open Exchange Rates → `currency_rates`), `image-embed` (`mode:search|index`, OpenAI `text-embedding-3-small`, **1536-dim**, matching `product_embeddings.embedding`), `payment-stripe` (`?action=intent|webhook`), `payment-flutterwave` (`?action=init|webhook`), `push-dispatch` (polls `notifications` where `channel='push' and sent_at is null`, sends via Expo Push using `user_profiles.metadata->>'expo_push_token'`).
- `_shared/cors.ts` exports `corsHeaders` + `json()`; CORS already allows `stripe-signature` and `verif-hash`.
- `.env.example` keys: `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `FLUTTERWAVE_SECRET_KEY`, `FLUTTERWAVE_WEBHOOK_HASH`, `OPENEXCHANGERATES_APP_ID`. `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY` are auto-injected.
- `pg_cron` extension is enabled but **no `cron.schedule()` calls exist**. `pg_net` is **not yet enabled**.
- **No `handle_new_user` trigger** — `user_profiles`/`user_roles` are not created on signup (confirmed: auth hooks commented out in `config.toml`, no trigger in migrations).
- `package.json` scripts: `link`, `db:push`, `db:reset`, `db:diff`, `migrate:new`, `gen:types`, `functions:serve`, `functions:deploy`, `advisors`.
- `create_order(p_supplier_id, p_items jsonb, p_shipping_address_id, p_billing_address_id, p_shipping_method_id, p_currency, p_buyer_notes) returns orders`.

> **Environment note:** several steps need a real terminal with `supabase login` already done (OAuth) and the project linked (`npm run link`). MCP cannot deploy functions or set secrets. Steps that require the CLI are marked **[CLI]**. SQL-only steps can be applied via migration files (`npm run db:push`) or the Supabase MCP `apply_migration`.

---

## File structure (created/modified in this phase)

```
cbatechno-backend/
  supabase/migrations/
    20260613000001_handle_new_user.sql        CREATE — provisioning trigger
    20260613000002_storage_product_images.sql CREATE — bucket + policies
    20260613000003_pg_net.sql                  CREATE — enable pg_net
    20260613000004_cron_jobs.sql               CREATE — currency-sync + push-dispatch schedules
    20260613000005_notification_triggers.sql   CREATE — enqueue notifications on events
  .env                                         CREATE (gitignored) — real secret values
cbatechno-web/
  src/lib/payments.ts                          CREATE — call payment functions
  src/lib/visual-search.ts                     CREATE — call image-embed + match RPC
  src/hooks/use-checkout.ts                    CREATE — createOrder + pay
  src/routes/checkout.tsx                      MODIFY — wire submit (replaces TODO(B3))
  src/routes/search.tsx                        MODIFY — add image-search entry
  src/lib/push.ts                              CREATE — register Expo token (web no-op / mobile)
```

---

## B1 — Auth integration (provisioning + providers + first admin)

### Task B1.1: `handle_new_user` provisioning trigger

**Files:**
- Create: `cbatechno-backend/supabase/migrations/20260613000001_handle_new_user.sql`

- [ ] **Step 1: Write the migration** — on every new `auth.users` row, create a `user_profiles` row and grant the default `buyer` role. `full_name` comes from signup metadata (`raw_user_meta_data->>'full_name'`).

```sql
-- CBATechno — provision profile + default role on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_profiles (id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, 'buyer')
  on conflict (user_id, role) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

- [ ] **Step 2: Apply**

**[CLI]** Run: `cd cbatechno-backend && npm run db:push`
(or apply the same SQL via the Supabase MCP `apply_migration` with name `handle_new_user`.)
Expected: migration applies, no error.

- [ ] **Step 3: Verify the trigger fires**

Create a test user (Supabase dashboard → Authentication → Add user, or `supabase.auth.signUp` from the app), then run:
```sql
select (select count(*) from user_profiles where id = '<new-uid>') as profiles,
       (select count(*) from user_roles where user_id = '<new-uid>' and role = 'buyer') as buyer_role;
```
Expected: `profiles = 1`, `buyer_role = 1`.

- [ ] **Step 4: Run advisors** (new SECURITY DEFINER function)

**[CLI]** Run: `cd cbatechno-backend && npm run advisors` (or MCP `get_advisors security`).
Expected: no new errors; `handle_new_user` has `search_path` pinned (already in the DDL), so no `function_search_path_mutable` warning for it.

- [ ] **Step 5: Commit**

```bash
git add cbatechno-backend/supabase/migrations/20260613000001_handle_new_user.sql
git commit -m "feat(db): provision profile + default role on signup"
```

### Task B1.2: Auth providers config (phone OTP + OAuth)

**Files:**
- Modify: `cbatechno-backend/supabase/config.toml` (local dev parity) + Supabase dashboard (hosted)

- [ ] **Step 1: Decide providers** — email/password is already on. Enable phone OTP (Twilio) and optionally Google/Apple OAuth. These require provider credentials configured in the **hosted dashboard** (Authentication → Providers); `config.toml` controls local dev only.

- [ ] **Step 2: Configure hosted** — in the dashboard set up the SMS provider (Twilio SID/token/messaging-service) for phone OTP, and OAuth client IDs/secrets for any social providers. Document the chosen set in `cbatechno-backend/README.md`.

- [ ] **Step 3: Mirror in `config.toml`** — set `[auth.sms]` / `[auth.external.google]` enable flags for local parity (secrets via `env()` references, not literals).

- [ ] **Step 4: Verify** — from `cbatechno-web` `/login`, request a phone OTP and confirm receipt; sign in with one OAuth provider if enabled.

- [ ] **Step 5: Commit**

```bash
git add cbatechno-backend/supabase/config.toml cbatechno-backend/README.md
git commit -m "feat(auth): enable phone OTP + OAuth providers"
```

### Task B1.3: Create the first admin

**Files:** none (operational)

- [ ] **Step 1: Create the admin auth user** — dashboard → Authentication → Add user (or have the person sign up through the app).

- [ ] **Step 2: Grant admin** — the signup trigger already gave them `buyer`; add `admin`:
```sql
insert into user_roles (user_id, role) values ('<admin-uuid>', 'admin')
on conflict (user_id, role) do nothing;
```

- [ ] **Step 3: Verify** — sign in to `cbatechno-web`, confirm `/admin/*` is reachable and the "Admin console" header link shows.

---

## B-storage — Product images bucket

### Task Bs.1: Create the `product-images` bucket + policies

**Files:**
- Create: `cbatechno-backend/supabase/migrations/20260613000002_storage_product_images.sql`

- [ ] **Step 1: Write the migration** — public-read bucket; authenticated users may write (RLS on `storage.objects`). (Vendor scoping by path prefix can be tightened later; for now any authenticated user can upload, which matches the app gating uploads behind the vendor console.)

```sql
-- CBATechno — product images bucket
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "product images public read"
  on storage.objects for select using (bucket_id = 'product-images');

create policy "authenticated upload product images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images');

create policy "authenticated update own product images"
  on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and owner = auth.uid());

create policy "authenticated delete own product images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and owner = auth.uid());
```

- [ ] **Step 2: Apply** — **[CLI]** `npm run db:push` (or MCP `apply_migration`).
Expected: applies clean.

- [ ] **Step 3: Verify** — from the vendor product-create screen (Phase A A2.4), upload an image; confirm a public URL resolves in the browser.

- [ ] **Step 4: Commit**

```bash
git add cbatechno-backend/supabase/migrations/20260613000002_storage_product_images.sql
git commit -m "feat(storage): product-images bucket + policies"
```

---

## B2 — Deploy edge functions

### Task B2.1: Set secrets

**Files:**
- Create (gitignored): `cbatechno-backend/.env` from `.env.example`

- [ ] **Step 1: Fill `.env`** — real values for `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `FLUTTERWAVE_SECRET_KEY`, `FLUTTERWAVE_WEBHOOK_HASH`, `OPENEXCHANGERATES_APP_ID`. Confirm `.env` is in `.gitignore`.

Run: `grep -q '^\.env$\|^\.env' cbatechno-backend/.gitignore && echo ok`
Expected: `ok`.

- [ ] **Step 2: Push secrets** — **[CLI]**

Run: `cd cbatechno-backend && supabase secrets set --env-file .env`
Expected: lists the keys as set.

- [ ] **Step 3: Verify**

Run: `cd cbatechno-backend && supabase secrets list`
Expected: all six keys present.

### Task B2.2: Deploy all functions

- [ ] **Step 1: Deploy** — **[CLI]**

Run: `cd cbatechno-backend && npm run functions:deploy`
(If it requires per-function names: `supabase functions deploy currency-sync image-embed payment-stripe payment-flutterwave push-dispatch`.)
Expected: each deploys; URLs printed as `https://kwkhhrjxuleftlinazaz.supabase.co/functions/v1/<name>`.

- [ ] **Step 2: Smoke-test currency-sync** — **[CLI]**

Run: `curl -s -X POST https://kwkhhrjxuleftlinazaz.supabase.co/functions/v1/currency-sync -H "Authorization: Bearer <ANON_KEY>"`
Expected: `{"updated":<n>}`; verify rows: `select count(*) from currency_rates where source='openexchangerates';` > 0.

- [ ] **Step 3: Smoke-test image-embed search mode** — **[CLI]**

Run: `curl -s -X POST .../functions/v1/image-embed -H "Authorization: Bearer <ANON_KEY>" -H 'content-type: application/json' -d '{"mode":"search","imageUrl":"https://…/sample.jpg"}'`
Expected: `{"embedding":[…1536 floats…]}`.

- [ ] **Step 4: Configure payment webhooks** — in Stripe dashboard add endpoint `.../functions/v1/payment-stripe?action=webhook` (event `payment_intent.succeeded`); copy its signing secret into `STRIPE_WEBHOOK_SECRET` (re-run `secrets set` if it changed). In Flutterwave dashboard set the webhook to `.../functions/v1/payment-flutterwave?action=webhook` and the secret hash to `FLUTTERWAVE_WEBHOOK_HASH`. Document both URLs in `README.md`.

- [ ] **Step 5: Commit** (docs only; secrets are not committed)

```bash
git add cbatechno-backend/README.md && git commit -m "docs: edge function URLs + webhook setup"
```

---

## B3 — Client ↔ function integration (web)

### Task B3.1: Payments client

**Files:**
- Create: `cbatechno-web/src/lib/payments.ts`

- [ ] **Step 1: Implement** — thin callers for the two payment functions via `supabase.functions.invoke`.

```typescript
import { supabase } from './supabase'

export async function createStripeIntent(orderId: string, amount: number, currency: string) {
  const { data, error } = await supabase.functions.invoke('payment-stripe?action=intent', {
    body: { order_id: orderId, amount, currency },
  })
  if (error) throw error
  return data as { client_secret: string; payment_intent_id: string }
}

export async function initFlutterwave(orderId: string, amount: number, currency: string, customer: { email: string; name?: string }, redirectUrl: string) {
  const { data, error } = await supabase.functions.invoke('payment-flutterwave?action=init', {
    body: { order_id: orderId, amount, currency, customer, redirect_url: redirectUrl },
  })
  if (error) throw error
  return data as { link: string }
}
```

- [ ] **Step 2: Commit** — `git add cbatechno-web/src/lib/payments.ts && git commit -m "feat(web): payment function clients"`

### Task B3.2: Checkout flow

**Files:**
- Create: `cbatechno-web/src/hooks/use-checkout.ts`
- Modify: `cbatechno-web/src/routes/checkout.tsx`

- [ ] **Step 1: Implement the checkout hook** — split the cart by `supplier_id`, call `createOrder` per supplier (returns the `orders` row), then start payment for the total.

```typescript
import { createOrder, type CreateOrderInput } from '@cbatechno/shared'
import { supabase } from '../lib/supabase'
import { createStripeIntent, initFlutterwave } from '../lib/payments'

export async function placeOrderAndPay(params: {
  perSupplier: CreateOrderInput[]            // one entry per supplier in the cart
  provider: 'stripe' | 'flutterwave'
  customer: { email: string; name?: string }
}) {
  const orders = []
  for (const input of params.perSupplier) {
    const { data, error } = await createOrder(supabase, input)
    if (error) throw error
    orders.push(data)
  }
  const total = orders.reduce((s, o) => s + Number(o.total), 0)
  const currency = orders[0]?.currency ?? 'USD'
  const primaryOrderId = orders[0]!.id
  if (params.provider === 'stripe') {
    return { kind: 'stripe' as const, orders, intent: await createStripeIntent(primaryOrderId, total, currency) }
  }
  const { link } = await initFlutterwave(primaryOrderId, total, currency, params.customer, `${location.origin}/order-confirmed`)
  return { kind: 'flutterwave' as const, orders, link }
}
```

- [ ] **Step 2: Wire `checkout.tsx`** — replace the `// TODO(B3)` submit handler: build `CreateOrderInput[]` from cart + selected addresses + shipping method (validate each with `createOrderSchema`), call `placeOrderAndPay`. For Stripe, mount Stripe.js Elements with the returned `client_secret` and confirm payment; for Flutterwave, redirect to `link`. On success route to `/order-confirmed`.

- [ ] **Step 3: Verify (test mode)** — with Stripe test keys, complete a checkout; confirm the webhook flips the order to `payment_status='paid'` (`select payment_status, order_status from orders order by created_at desc limit 1;`). Repeat for Flutterwave test mode.
Expected: order rows + a `payments` row with `status='paid'`.

- [ ] **Step 4: Commit** — `git add -A && git commit -m "feat(web): checkout → create_order + payment"`

### Task B3.3: Visual search

**Files:**
- Create: `cbatechno-web/src/lib/visual-search.ts`
- Modify: `cbatechno-web/src/routes/search.tsx`

- [ ] **Step 1: Implement** — upload the query image to Storage (reuse `uploadProductImage` into a `search` prefix, or a dedicated temp path), call `image-embed` `mode:search` for its embedding, then `matchProductsByImage`.

```typescript
import { matchProductsByImage } from '@cbatechno/shared'
import { supabase } from './supabase'

export async function visualSearch(imageUrl: string) {
  const { data: emb, error } = await supabase.functions.invoke('image-embed', {
    body: { mode: 'search', imageUrl },
  })
  if (error) throw error
  const { data, error: matchErr } = await matchProductsByImage(supabase, (emb as { embedding: number[] }).embedding)
  if (matchErr) throw matchErr
  return data ?? []
}
```

- [ ] **Step 2: Add the UI entry** — on `search.tsx`, an "search by image" file input: upload → public URL → `visualSearch(url)` → render results in the same grid as text search.

- [ ] **Step 3: Index products on create/update** — in `cbatechno-web` `useSaveProduct` success (Phase A A2.2), after a product has a primary image, fire `supabase.functions.invoke('image-embed', { body: { mode: 'index', product_id, imageUrl } })` so it becomes searchable. (Add this call in the vendor product save flow.)

- [ ] **Step 4: Verify** — index a product with an image, then run a visual search with a similar image; confirm it appears.

- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat(web): visual search + product indexing"`

---

## B4 — Cron jobs (pg_cron + pg_net)

### Task B4.1: Enable pg_net

**Files:**
- Create: `cbatechno-backend/supabase/migrations/20260613000003_pg_net.sql`

- [ ] **Step 1: Write the migration**

```sql
-- pg_net lets pg_cron call edge functions over HTTPS
create extension if not exists pg_net with schema extensions;
```

- [ ] **Step 2: Apply** — **[CLI]** `npm run db:push` (or MCP). **Step 3: Commit** — `git commit -m "feat(db): enable pg_net"`.

### Task B4.2: Schedule currency-sync (hourly) + push-dispatch (every minute)

**Files:**
- Create: `cbatechno-backend/supabase/migrations/20260613000004_cron_jobs.sql`

- [ ] **Step 1: Store the service key as a DB setting** (so the cron HTTP calls can authorize). Do this once via SQL (value not committed):

```sql
-- run manually against the project (do not commit the key)
alter database postgres set "app.functions_base_url" = 'https://kwkhhrjxuleftlinazaz.supabase.co/functions/v1';
alter database postgres set "app.service_role_key" = '<SERVICE_ROLE_KEY>';
```

- [ ] **Step 2: Write the cron migration** — schedule HTTP POSTs via `pg_net`.

```sql
-- hourly currency refresh
select cron.schedule(
  'currency-sync-hourly', '0 * * * *',
  $$
  select net.http_post(
    url := current_setting('app.functions_base_url') || '/currency-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := '{}'::jsonb
  );
  $$
);

-- push delivery every minute
select cron.schedule(
  'push-dispatch-minute', '* * * * *',
  $$
  select net.http_post(
    url := current_setting('app.functions_base_url') || '/push-dispatch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := '{}'::jsonb
  );
  $$
);
```

- [ ] **Step 3: Apply + verify** — **[CLI]** `npm run db:push`. Then:
```sql
select jobname, schedule, active from cron.job;
-- after a minute:
select status, count(*) from net._http_response group by status;   -- expect 200s
```
Expected: two jobs listed/active; HTTP responses 200.

- [ ] **Step 4: Commit** — `git add cbatechno-backend/supabase/migrations/20260613000004_cron_jobs.sql && git commit -m "feat(db): schedule currency-sync + push-dispatch"`

> **Note:** Step 1's `app.service_role_key` setting is applied manually (never committed). Document this in `README.md` as a one-time setup step.

---

## B5 — Notifications (enqueue + deliver + tokens)

### Task B5.1: Enqueue notifications on order events

**Files:**
- Create: `cbatechno-backend/supabase/migrations/20260613000005_notification_triggers.sql`

- [ ] **Step 1: Write the trigger** — when an order's `order_status` changes, insert a push `notifications` row for the buyer (respecting their `notification_preferences`). `push-dispatch` (scheduled in B4.2) delivers it.

```sql
create or replace function public.notify_order_status()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  wants_push boolean;
begin
  if new.order_status is distinct from old.order_status then
    select coalesce((notification_preferences->>'push')::boolean, true)
      into wants_push from user_profiles where id = new.buyer_id;
    if wants_push then
      insert into notifications (user_id, type, channel, title, message, data)
      values (
        new.buyer_id, 'order_update', 'push',
        'Order ' || new.order_number,
        'Your order is now ' || new.order_status,
        jsonb_build_object('order_id', new.id, 'status', new.order_status)
      );
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_notify_order_status
  after update on orders
  for each row execute function public.notify_order_status();
```

- [ ] **Step 2: Apply + verify** — **[CLI]** `npm run db:push`. Update a test order's status; confirm a `notifications` row appears:
```sql
select type, channel, title, sent_at from notifications order by created_at desc limit 1;
```
Expected: one `order_update`/`push` row, `sent_at` null (until push-dispatch runs).

- [ ] **Step 3: Run advisors** — **[CLI]** `npm run advisors` (new SECURITY DEFINER fn already has `search_path` pinned). Expected: no new errors.

- [ ] **Step 4: Commit** — `git add cbatechno-backend/supabase/migrations/20260613000005_notification_triggers.sql && git commit -m "feat(db): enqueue push notification on order status change"`

### Task B5.2: Push token registration (client)

**Files:**
- Create: `cbatechno-web/src/lib/push.ts`

- [ ] **Step 1: Implement** — `push-dispatch` reads `user_profiles.metadata->>'expo_push_token'`. The token is produced by the **Expo mobile app**; web has no Expo token, so the web helper is a documented no-op and the real registration lives in `cbatechno-mobile` (separate track). Provide the writer both use:

```typescript
import { supabase } from './supabase'

/** Stores an Expo push token on the current user's profile metadata. Called by the mobile app. */
export async function registerPushToken(userId: string, expoPushToken: string) {
  const { data: profile } = await supabase.from('user_profiles').select('metadata').eq('id', userId).single()
  const metadata = { ...(profile?.metadata as object ?? {}), expo_push_token: expoPushToken }
  const { error } = await supabase.from('user_profiles').update({ metadata }).eq('id', userId)
  if (error) throw error
}
```

- [ ] **Step 2: Verify** — manually set a token (`update user_profiles set metadata = metadata || '{"expo_push_token":"ExponentPushToken[test]"}' where id='<uid>';`), change an order status, wait for the minute cron, confirm the notification's `sent_at` gets set.
Expected: `sent_at` populated; (a real device receives the push).

- [ ] **Step 3: Commit** — `git add cbatechno-web/src/lib/push.ts && git commit -m "feat: push token registration helper"`

---

## Phase B self-review checklist (run before handing off)
- [ ] New user signup creates `user_profiles` + `buyer` role (B1.1).
- [ ] `product-images` bucket exists and public URLs resolve (Bs.1).
- [ ] All 6 secrets set; all 5 functions deployed; `currency-sync` + `image-embed` smoke tests pass (B2).
- [ ] Stripe + Flutterwave test checkouts flip orders to `paid` via webhook (B3.2).
- [ ] Visual search returns indexed products (B3.3).
- [ ] `cron.job` shows both schedules active; `net._http_response` shows 200s (B4).
- [ ] Order status change enqueues a notification; push-dispatch sets `sent_at` (B5).
- [ ] `npm run advisors` shows no new errors after all migrations.

## Out of scope (later)
- Native FCM/APNs (current delivery is Expo Push; fine for the Expo app).
- CLIP self-hosted embeddings (image-embed documents the 1536-dim → 512 migration path).
- Multi-supplier single-payment splitting (current flow pays the combined total against the primary order; per-supplier settlement is a finance follow-up).
