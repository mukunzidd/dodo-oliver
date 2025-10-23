# Technical Architecture Options - CBATechno Discovery Platform

**Version**: 1.0
**Last Updated**: 2025-10-18
**Status**: Research Complete - Awaiting Decisions

---

## Table of Contents

1. [Frontend Framework](#1-frontend-framework)
2. [Backend & Database](#2-backend--database)
3. [State Management](#3-state-management)
4. [AI Image Search](#4-ai-image-search)
5. [Payment Gateways](#5-payment-gateways)
6. [Hosting & Deployment](#6-hosting--deployment)
7. [Analytics & Monitoring](#7-analytics--monitoring)
8. [Recommended Architecture](#8-recommended-architecture)

---

## 1. Frontend Framework

### Option A: Next.js 15 (App Router) ⭐ RECOMMENDED

**Description**: Latest version of Next.js with mature App Router and React Server Components support.

**Key Features (2025)**:
- **Turbopack**: Up to 700x faster builds compared to Webpack (default in dev mode)
- **React Server Components (RSC)**: Server-first rendering, reduced client bundle size
- **Partial Prerendering**: Prerender page shell + stream dynamic content
- **View Transitions API**: Smooth animations between routes (experimental in 15.2)
- **Edge-First Rendering**: Deploy to edge globally for low latency
- **React Compiler Support**: Reduces manual memoization (experimental)

**Pros**:
- ✅ Best-in-class DX (developer experience)
- ✅ Excellent SEO (server-side rendering by default)
- ✅ File-based routing (intuitive navigation structure)
- ✅ Built-in image optimization, font optimization
- ✅ API routes for backend logic
- ✅ Large community, extensive ecosystem
- ✅ Vercel's tight integration (creators of Next.js)

**Cons**:
- ⚠️ Learning curve for App Router + Server Components
- ⚠️ Some third-party libraries not yet RSC-compatible
- ⚠️ Can be opinionated about architecture

**Best For**: Our web client (primary platform), admin dashboard, supplier dashboard

**Compatibility**: Works seamlessly with Supabase, all modern state management, and deployment platforms

---

### Option B: React + Vite

**Description**: Vanilla React with Vite bundler for faster builds.

**Pros**:
- ✅ Maximum flexibility
- ✅ Extremely fast HMR (Hot Module Replacement)
- ✅ Simpler mental model (pure client-side)

**Cons**:
- ❌ No built-in SSR (bad for SEO)
- ❌ Manual routing setup (React Router)
- ❌ More boilerplate configuration
- ❌ No automatic code splitting

**Best For**: Internal tools where SEO doesn't matter

**Verdict**: Not recommended for our public-facing web client due to SEO requirements.

---

## 2. Backend & Database

### Option A: Supabase (PostgreSQL) ⭐ RECOMMENDED

**Description**: Open-source Firebase alternative built on PostgreSQL with realtime, auth, storage, and edge functions.

**Key Features (2025)**:
- **PostgreSQL 16+**: World-class relational database
- **Row-Level Security (RLS)**: Database-level authorization
- **Realtime Subscriptions**: WebSocket-based live updates
- **Automatic Vector Embeddings**: Built-in support for AI/semantic search
- **pgvector**: Native vector similarity search for image embeddings
- **Auth**: Email, phone OTP, OAuth (Google, Apple, etc.), guest/anonymous
- **Storage**: File uploads with signed URLs, image transformations
- **Edge Functions**: Serverless functions (Deno runtime)
- **PostgREST**: Auto-generated REST API from database schema

**Pros**:
- ✅ All-in-one platform (reduces integration complexity)
- ✅ PostgreSQL (battle-tested, ACID compliant)
- ✅ Built-in auth, storage, realtime out of the box
- ✅ Row-Level Security (security at DB level)
- ✅ Excellent Next.js integration
- ✅ Generous free tier (50,000 MAU)
- ✅ Open-source (self-hostable if needed)
- ✅ Vector embeddings support (critical for image search)
- ✅ Active development, growing ecosystem

**Cons**:
- ⚠️ Vendor lock-in (mitigated by being open-source)
- ⚠️ Edge Functions are Deno-based (different from Node.js)
- ⚠️ Realtime has per-connection costs at scale

**Pricing** (Estimated for V1):
- Free tier: Up to 50K MAU, 500MB database, 1GB storage
- Pro ($25/mo): 100K MAU, 8GB database, 100GB storage, daily backups
- Likely cost for launch: **$25-75/month** (Pro + add-ons)

**Best For**: Our entire backend (database, auth, storage, realtime messaging)

---

### Option B: Firebase

**Description**: Google's mobile/web BaaS platform.

**Pros**:
- ✅ Mature ecosystem
- ✅ Excellent mobile SDKs
- ✅ Realtime database

**Cons**:
- ❌ Firestore (NoSQL) not ideal for relational e-commerce data
- ❌ More expensive at scale
- ❌ Limited complex querying compared to SQL
- ❌ Google's history of deprecating services

**Verdict**: Not recommended due to relational data needs (products, orders, suppliers).

---

### Option C: Custom Backend (Node.js + PostgreSQL)

**Description**: Build API from scratch with Express/NestJS + PostgreSQL.

**Pros**:
- ✅ Maximum control and flexibility
- ✅ No vendor lock-in

**Cons**:
- ❌ Months of development time (auth, realtime, storage, etc.)
- ❌ Maintenance burden
- ❌ Security complexity
- ❌ Not feasible for 3-month timeline

**Verdict**: Not recommended given timeline constraints.

---

## 3. State Management

### Recommended Hybrid Approach ⭐

Use **multiple tools** for different state types (industry best practice in 2025):

#### **TanStack Query (React Query)** - Server State
**Use For**: All data fetching from Supabase (products, orders, suppliers)

**Features**:
- Automatic caching, refetching, cache invalidation
- Optimistic updates
- Pagination, infinite scroll
- Request deduplication
- Background refetching

**Why**: Eliminates ~80% of state management needs by handling server state properly. Works perfectly with Server Components.

**Example Use Cases**:
- Product catalog data
- User orders
- Supplier information
- Search results

---

#### **Zustand** - Client UI State
**Use For**: UI-specific state that doesn't belong on server

**Features**:
- Minimal boilerplate
- Hook-based API
- No providers needed
- Middleware for persistence, devtools
- Server Component compatible

**Why**: Lightweight, simple, modern. Only use for client-specific state.

**Example Use Cases**:
- Shopping cart (persist to localStorage + sync to Supabase)
- UI modals, drawer states
- Filter selections (before search)
- Theme preferences

---

#### **Next.js Server Components** - Server State (Native)
**Use For**: Data that can be fetched directly in Server Components

**Why**: No client-side state library needed. Fetch directly in RSCs, pass to Client Components as props.

**Example Use Cases**:
- Product detail page data (SSR)
- Static category pages
- SEO-critical content

---

### Alternative: Redux Toolkit

**Pros**: Powerful, predictable, great DevTools
**Cons**: Too much boilerplate for our needs, overkill in 2025
**Verdict**: Not recommended. TanStack Query + Zustand covers all needs with less complexity.

---

## 4. AI Image Search

### Requirement
Users upload product photo → AI finds visually similar products in catalog. Phase 1 feature.

---

### Option A: OpenAI GPT-4 Vision API ⭐ RECOMMENDED FOR MVP

**How It Works**:
1. User uploads image
2. Send to GPT-4 Vision → generates product description + attributes
3. Convert description to embeddings via OpenAI Embeddings API
4. Search Supabase pgvector for similar product embeddings
5. Return ranked results

**Pros**:
- ✅ Fastest to implement (single API)
- ✅ Excellent at understanding product attributes
- ✅ Can generate search keywords from image
- ✅ Flexible (works with any product type)
- ✅ No model training required

**Cons**:
- ⚠️ More expensive per query (~$0.01-0.03 per image)
- ⚠️ Requires internet connection
- ⚠️ 3rd-party dependency

**Pricing**:
- GPT-4 Vision: $0.01 per image (low res), $0.03 (high res)
- Embeddings: $0.0001 per 1K tokens
- **Estimated**: $0.015 per image search

**Implementation Timeline**: 1-2 weeks

---

### Option B: Google Cloud Vision API + Custom Embeddings

**How It Works**:
1. Google Vision extracts labels, objects, colors
2. Generate custom embeddings based on features
3. Store in Supabase pgvector
4. Similarity search

**Pros**:
- ✅ Lower per-query cost (~$1.50 per 1000 images)
- ✅ Fast response times
- ✅ Proven for e-commerce

**Cons**:
- ⚠️ More complex implementation
- ⚠️ May need custom training for product categories

**Pricing**:
- Label Detection: $1.50 per 1K images
- Web Detection: $3.50 per 1K images

**Implementation Timeline**: 2-3 weeks

---

### Option C: Algolia Visual Search

**Description**: Specialized e-commerce visual search service.

**Pros**:
- ✅ Purpose-built for product search
- ✅ Handles indexing, search, ranking
- ✅ High accuracy for fashion, electronics

**Cons**:
- ❌ Expensive ($1/1K searches + base fee)
- ❌ Vendor lock-in
- ❌ Less flexible for custom categories

**Pricing**: $0.50 base/month + $1 per 1K searches

**Verdict**: Too expensive for MVP. Consider post-launch if OpenAI solution needs improvement.

---

### Option D: Open-Source CLIP Model (Self-Hosted)

**Description**: Run OpenAI's CLIP model locally/self-hosted for image→text embeddings.

**Pros**:
- ✅ No per-query costs after setup
- ✅ Full control, privacy
- ✅ Open-source

**Cons**:
- ❌ Infrastructure costs (GPU hosting)
- ❌ Maintenance complexity
- ❌ Slower to implement
- ❌ Not feasible for 3-month timeline

**Verdict**: Consider for post-launch optimization if costs become prohibitive.

---

### **Recommended Approach for Phase 1**:

**OpenAI GPT-4 Vision + Embeddings**
- Fastest implementation
- Flexible for all product categories
- Acceptable cost for MVP (<$100/month for 5K searches)
- Can switch to cheaper alternatives post-launch if needed

**Architecture**:
```
User uploads image
  ↓
Next.js API Route → Supabase Edge Function
  ↓
OpenAI GPT-4 Vision (extract product description + attributes)
  ↓
OpenAI Embeddings API (convert to vector)
  ↓
Supabase pgvector (similarity search against product embeddings)
  ↓
Return ranked product matches
```

---

## 5. Payment Gateways

### Strategy: Dual Integration ⭐ RECOMMENDED

Integrate **both** Stripe and Flutterwave to serve international and African markets.

---

### **Stripe** - International Payments

**Use For**:
- International buyers (outside Africa)
- Credit/debit cards (Visa, Mastercard, Amex)
- Apple Pay, Google Pay
- Bank transfers (ACH, SEPA)

**Pros**:
- ✅ Industry standard, trusted globally
- ✅ Excellent documentation, developer experience
- ✅ Robust fraud prevention
- ✅ Supports 135+ currencies
- ✅ Great Next.js integration
- ✅ Built-in invoicing, subscriptions

**Cons**:
- ⚠️ Limited African mobile money support
- ⚠️ Higher fees (2.9% + $0.30 per transaction)

**Pricing**:
- 2.9% + $0.30 per successful card charge
- 3.9% + $0.30 for international cards

**Implementation**: 1 week

---

### **Flutterwave** - African Markets

**Use For**:
- African buyers
- Mobile Money (M-PESA, MTN, Airtel, etc.)
- Local cards
- USSD, bank transfer

**Key Features (2025)**:
- **34 African countries** supported
- **Mobile Money** in Kenya, Uganda, Ghana, Zambia, Rwanda, Tanzania
- Local payment methods per country
- Multi-currency (NGN, KES, GHS, etc.)
- Cross-border payments infrastructure

**Pros**:
- ✅ Dominates African payment space
- ✅ Mobile Money (critical for our market)
- ✅ Local currency settlement
- ✅ Regulatory compliance across Africa
- ✅ Lower fees for local transactions (1.4% + local fees)

**Cons**:
- ⚠️ Less polished developer experience than Stripe
- ⚠️ More complex settlement timing

**Pricing**:
- 1.4% + local fees (varies by country)
- Mobile Money: 1.4% + carrier fees

**Implementation**: 1-2 weeks

---

### **Payment Flow Architecture**

```
Checkout Page
  ↓
User selects currency (USD, NGN, KES, etc.)
  ↓
Next.js determines gateway:
  - USD/International → Stripe
  - African currencies → Flutterwave
  ↓
Create payment intent via API
  ↓
Gateway processes payment
  ↓
Webhook confirms payment
  ↓
Update order status in Supabase
  ↓
Send confirmation email
```

**Multi-Currency Handling**:
- Store prices in USD (base currency)
- Fetch live exchange rates from **Open Exchange Rates API** (free tier: 1K requests/month)
- Cache rates for 1 hour
- Display prices in user's selected currency
- Convert at checkout time

---

## 6. Hosting & Deployment

### Web Client (Next.js)

#### Option A: Vercel ⭐ RECOMMENDED

**Pros**:
- ✅ Built by Next.js creators (best integration)
- ✅ Zero-config deployment
- ✅ Automatic preview deployments per PR
- ✅ Edge network (global CDN)
- ✅ Built-in analytics
- ✅ Excellent performance

**Cons**:
- ⚠️ Can get expensive at scale
- ⚠️ Vendor lock-in (mitigated by Next.js portability)

**Pricing**:
- Hobby (free): Personal projects, non-commercial
- Pro ($20/month): Commercial projects, 100GB bandwidth
- **Estimated for V1**: $20-50/month

**Verdict**: Best for MVP and launch. Monitor costs, can migrate later if needed.

---

#### Option B: Cloudflare Pages

**Pros**:
- ✅ Excellent edge performance
- ✅ Generous free tier (unlimited sites, bandwidth, requests)
- ✅ Fast global CDN
- ✅ Great Next.js support (via @cloudflare/next-on-pages)

**Cons**:
- ⚠️ Requires adapter for full Next.js compatibility
- ⚠️ Some Next.js features have limitations (ISR, etc.)

**Pricing**: Free tier covers most needs, $20/month Pro tier

**Verdict**: Great alternative to Vercel if costs become concern. Consider post-launch.

---

#### Option C: Self-Hosted (Coolify, Dokploy)

**Pros**:
- ✅ Full control
- ✅ Predictable costs
- ✅ Can run on DigitalOcean, Hetzner (~$5-20/month)

**Cons**:
- ❌ Requires DevOps expertise
- ❌ Manual setup for CI/CD, monitoring
- ❌ No automatic edge distribution
- ❌ Not ideal for 3-month timeline

**Verdict**: Consider post-launch for cost optimization.

---

### Backend (Supabase)

**Hosting**: Supabase Cloud (managed)

**Pros**:
- ✅ Zero DevOps
- ✅ Automatic backups, SSL, monitoring
- ✅ Global edge network
- ✅ Scalable to millions of users

**Alternative**: Self-host Supabase (Docker) if privacy or cost becomes critical. Not recommended for MVP.

---

### CDN for Images

**Cloudflare CDN** (in front of Supabase Storage)

**Why**:
- ✅ Global edge caching
- ✅ Image transformations (resize, format, quality)
- ✅ Protects origin server
- ✅ Free tier generous

**Setup**: Configure Cloudflare as reverse proxy to Supabase Storage URLs

---

## 7. Analytics & Monitoring

### Product Analytics

#### Option A: PostHog ⭐ RECOMMENDED

**Features**:
- Event tracking, funnels, cohorts
- Session recording
- Feature flags, A/B testing
- Self-hostable (open-source)

**Pros**:
- ✅ Privacy-friendly (GDPR compliant)
- ✅ All-in-one (analytics + feature flags + A/B testing)
- ✅ Generous free tier (1M events/month)
- ✅ Can self-host if needed

**Pricing**:
- Free: 1M events/month
- Paid: $0.00031 per event after free tier
- **Estimated V1 cost**: Free tier sufficient

---

#### Option B: Mixpanel

**Pros**: Powerful, proven for e-commerce
**Cons**: Expensive at scale, not open-source
**Verdict**: PostHog offers better value for our needs.

---

### Error Tracking

**Sentry**

**Features**:
- Error monitoring, stack traces
- Performance monitoring
- Release tracking
- Integrates with Next.js

**Pricing**:
- Free: 5K errors/month
- Team ($26/month): 50K errors/month

---

### Performance Monitoring

**Vercel Analytics** (if using Vercel) or **Cloudflare Web Analytics**

**Features**:
- Core Web Vitals
- Page load times
- Geographic distribution

**Pricing**: Free with hosting plan

---

### Business Analytics

**Metabase** (connects to Supabase PostgreSQL)

**Features**:
- SQL-based dashboards
- Custom reports
- Commission tracking
- Supplier performance

**Hosting**: Self-host on DigitalOcean (~$6/month)

**Why**: Direct access to database for complex business queries. Export to spreadsheets.

---

## 8. Recommended Architecture

### Final Tech Stack ⭐

#### **Frontend**
- **Framework**: Next.js 15 (App Router, React Server Components)
- **Styling**: Tailwind CSS + shadcn/ui components
- **State Management**: TanStack Query + Zustand
- **Forms**: React Hook Form + Zod validation
- **Type Safety**: TypeScript strict mode

#### **Backend & Database**
- **Platform**: Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions)
- **Vector Search**: pgvector extension
- **Type Generation**: Supabase CLI → TypeScript types

#### **AI & Search**
- **Image Search**: OpenAI GPT-4 Vision + Embeddings API
- **Text Search**: PostgreSQL full-text search (ts_vector)
- **Recommendations**: Collaborative filtering (post-launch)

#### **Payments**
- **International**: Stripe (cards, Apple Pay, Google Pay)
- **Africa**: Flutterwave (Mobile Money, local cards)
- **Currency**: Open Exchange Rates API

#### **Hosting & Infrastructure**
- **Web Client**: Vercel (Next.js optimized)
- **Backend**: Supabase Cloud
- **CDN**: Cloudflare (images, static assets)
- **Email**: SendGrid or Resend
- **SMS**: Twilio or Africa's Talking

#### **Analytics & Monitoring**
- **Product Analytics**: PostHog
- **Error Tracking**: Sentry
- **Performance**: Vercel Analytics
- **Business Intelligence**: Metabase

#### **Developer Tools**
- **Version Control**: Git + GitHub
- **CI/CD**: Vercel (auto-deploy on push to main)
- **Code Quality**: ESLint, Prettier, Husky (pre-commit hooks)
- **Testing**: Vitest (unit), Playwright (E2E)

---

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER DEVICES                             │
│  (Desktop Browsers, Mobile Browsers, Native Apps - Post-Launch)  │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │ HTTPS
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       CLOUDFLARE CDN                             │
│              (Global Edge Cache, DDoS Protection)                │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     VERCEL EDGE NETWORK                          │
│                      (Next.js 15 App)                            │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │
│  │  Web Client    │  │ Supplier       │  │  Admin           │  │
│  │  (Public)      │  │ Dashboard      │  │  Dashboard       │  │
│  │                │  │                │  │                  │  │
│  │ - Discovery    │  │ - Products     │  │ - Approval       │  │
│  │ - Search       │  │ - Orders       │  │ - Moderation     │  │
│  │ - Checkout     │  │ - Messages     │  │ - Analytics      │  │
│  └────────────────┘  └────────────────┘  └──────────────────┘  │
│                                                                  │
│  Server Components + Client Components                          │
│  TanStack Query + Zustand                                       │
└───────────────┬─────────────────────────────────────────────────┘
                │
                │ Supabase Client SDK
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        SUPABASE PLATFORM                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              PostgreSQL 16 Database                        │ │
│  │  - Users, Suppliers, Products, Orders, Messages           │ │
│  │  - pgvector (image embeddings)                            │ │
│  │  - Full-text search (ts_vector)                           │ │
│  │  - Row-Level Security (RLS)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │   Auth       │  │   Storage    │  │   Realtime         │   │
│  │              │  │              │  │                    │   │
│  │ - Email/Pass │  │ - Images     │  │ - Messages         │   │
│  │ - Phone OTP  │  │ - Docs       │  │ - Order Updates    │   │
│  │ - OAuth      │  │ - Avatars    │  │ - Notifications    │   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Edge Functions (Deno)                         │ │
│  │  - Payment processing                                      │ │
│  │  - Image search (OpenAI integration)                       │ │
│  │  - Email/SMS notifications                                 │ │
│  │  - Currency conversion                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────┬────────────┬────────────────────────────────────┘
                │            │
                │            │
    ┌───────────┘            └────────────┐
    │                                     │
    ▼                                     ▼
┌─────────────────┐               ┌─────────────────┐
│   OPENAI API    │               │   PAYMENT       │
│                 │               │   GATEWAYS      │
│ - GPT-4 Vision  │               │                 │
│ - Embeddings    │               │ - Stripe        │
│   (Image Search)│               │ - Flutterwave   │
└─────────────────┘               └─────────────────┘

         │                                │
         └────────────┬───────────────────┘
                      │
                      ▼
         ┌────────────────────────────┐
         │   EXTERNAL SERVICES        │
         │                            │
         │ - SendGrid (Email)         │
         │ - Twilio (SMS)             │
         │ - PostHog (Analytics)      │
         │ - Sentry (Error Tracking)  │
         │ - Open Exchange Rates      │
         └────────────────────────────┘
```

---

## Estimated Infrastructure Costs (Monthly)

### MVP / Launch (First 3 Months)
- **Vercel Pro**: $20
- **Supabase Pro**: $25
- **Cloudflare** (CDN, DNS): $0 (free tier)
- **OpenAI API** (5K image searches): ~$100
- **Stripe + Flutterwave**: Transaction fees only (% of sales)
- **SendGrid** (Email): $0 (free tier: 100 emails/day)
- **PostHog** (Analytics): $0 (free tier)
- **Sentry** (Errors): $0 (free tier)
- **Open Exchange Rates**: $0 (free tier)

**Total Fixed Costs**: ~$145/month
**Variable Costs**: Transaction fees (2-4% of revenue) + AI search costs

### Growth Phase (10K+ Monthly Users)
- Vercel: $50-100
- Supabase: $75-150
- OpenAI API: $200-500 (optimize with caching)
- Other services scale with usage

**Total**: $400-800/month + transaction fees

---

## Decision Points

Before proceeding to database schema design, please confirm:

1. ✅ **Frontend**: Next.js 15 with App Router?
2. ✅ **Backend**: Supabase for database, auth, storage, realtime?
3. ✅ **State Management**: TanStack Query + Zustand?
4. ✅ **Image Search**: OpenAI GPT-4 Vision + Embeddings?
5. ✅ **Payments**: Stripe + Flutterwave dual integration?
6. ✅ **Hosting**: Vercel for web client, Supabase Cloud for backend?
7. ✅ **Analytics**: PostHog + Sentry?

**Any changes or alternatives you'd like to explore?**

---

## Next Steps

Once architecture is confirmed:

1. Set up project structure (monorepo or separate repos)
2. Initialize Next.js 15 with TypeScript
3. Connect Supabase (create project, configure)
4. Design database schema (next document)
5. Set up authentication flows
6. Begin Phase 1 development

---

## References

- [Next.js 15 Announcement](https://nextjs.org/blog/next-15)
- [Supabase Documentation](https://supabase.com/docs)
- [TanStack Query Docs](https://tanstack.com/query/latest)
- [OpenAI Vision API](https://platform.openai.com/docs/guides/vision)
- [Stripe Docs](https://stripe.com/docs)
- [Flutterwave Docs](https://developer.flutterwave.com/)
