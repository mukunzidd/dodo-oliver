# Technical Architecture - Self-Hosted Approach

**Version**: 2.0 (Self-Hosted Optimized)
**Last Updated**: 2025-10-18
**Status**: Research Complete - Awaiting Final Decisions

---

## Architecture Philosophy

**Self-Hosted First**: Maximize cost efficiency and control by self-hosting on Hetzner infrastructure using modern PaaS tools (Coolify/Dokploy). Reserve cloud services only where absolutely necessary.

**Cost Optimization**:
- AI image search will be **capped/rate-limited** due to costs
- Regular text search will be **unlimited and free** (self-hosted Typesense/Meilisearch)
- Hosting on Hetzner vs cloud services: **~10x cheaper** (€50/month vs $500+/month at scale)

---

## Table of Contents

1. [Self-Hosting Platform](#1-self-hosting-platform)
2. [Frontend Framework](#2-frontend-framework)
3. [Backend & Database](#3-backend--database)
4. [Product Search Engine](#4-product-search-engine)
5. [Vector Database (Image Search)](#5-vector-database-image-search)
6. [AI Image Recognition](#6-ai-image-recognition)
7. [Payment Gateways](#7-payment-gateways)
8. [Infrastructure & Hosting](#8-infrastructure--hosting)
9. [Recommended Self-Hosted Architecture](#9-recommended-self-hosted-architecture)
10. [Cost Comparison](#10-cost-comparison)

---

## 1. Self-Hosting Platform

### Option A: Coolify ⭐ RECOMMENDED

**Description**: Open-source, self-hostable alternative to Vercel/Netlify/Heroku with 5 years of development maturity.

**Key Features (2025)**:
- **46,344 GitHub stars** (80% more popular than Dokploy)
- **5 years mature** (vs Dokploy's 1 year)
- One-click deployment for Next.js, databases, services
- Multi-server management from single UI
- Compatible with any language/framework
- Git integration (GitHub, GitLab, Gitea, Bitbucket)
- Automatic SSL via Let's Encrypt
- Built-in monitoring & logs
- Webhooks & API support
- ARM support (Raspberry Pi)

**Pros**:
- ✅ Most mature, largest community
- ✅ Extremely user-friendly UI
- ✅ Proven in production by thousands
- ✅ Active development, frequent updates
- ✅ Comprehensive documentation
- ✅ One-click templates for popular stacks
- ✅ Free & open-source

**Cons**:
- ⚠️ Monitoring less advanced than Dokploy
- ⚠️ Single-server focus (can manage multiple, but built for simplicity)

**Best For**: Our use case - rapid deployment, ease of use, stability

**Deployment Time**: 1-2 hours to set up, deploy Next.js app in 10 minutes

---

### Option B: Dokploy

**Description**: Modern Docker-centric PaaS with superior monitoring and multi-server capabilities.

**Key Features**:
- **25,684 GitHub stars** (newer but growing fast)
- **1 year old** (very active development)
- Native multi-server deployment
- Built-in load balancer
- Superior monitoring & metrics
- Dockerfile, Nixpacks, Git support
- Docker Compose native support

**Pros**:
- ✅ Better for large-scale, complex deployments
- ✅ Superior monitoring dashboards
- ✅ Modern Docker-first approach
- ✅ Better scaling features

**Cons**:
- ⚠️ Less mature (1 year vs 5 years)
- ⚠️ Smaller community
- ⚠️ Steeper learning curve

**Verdict**: Great alternative if we need advanced monitoring, but Coolify's maturity wins for MVP.

---

## 2. Frontend Framework

### Next.js 15 (App Router) - CONFIRMED ✅

**Same as cloud version** - Next.js works perfectly self-hosted via Coolify/Dokploy.

**Key Features**:
- Turbopack (700x faster builds)
- React Server Components
- Partial Prerendering
- Edge-first rendering
- View Transitions API

**Self-Hosting Notes**:
- Coolify supports Next.js out-of-the-box (detects automatically)
- Builds via Nixpacks or Docker
- Automatic deployments on git push

---

## 3. Backend & Database

### Option A: Self-Hosted Supabase ⭐ RECOMMENDED

**Description**: Run Supabase stack on our own infrastructure via Docker Compose.

**What You Get (Self-Hosted)**:
- PostgreSQL 16+ (database)
- PostgREST (auto-generated REST API)
- GoTrue (authentication)
- Storage (S3-compatible file storage)
- Realtime (WebSocket subscriptions)
- pgvector extension (for vector embeddings)

**Pros**:
- ✅ All Supabase features without costs
- ✅ Full control over data
- ✅ No vendor lock-in (true self-hosted)
- ✅ Same APIs as Supabase Cloud (easy migration)
- ✅ PostgreSQL = battle-tested, ACID compliant
- ✅ Built-in auth, storage, realtime
- ✅ Row-Level Security (RLS)

**Cons**:
- ⚠️ Requires maintenance (backups, updates)
- ⚠️ We manage availability/uptime
- ⚠️ Need monitoring setup

**Deployment**:
- One-click deploy via Coolify (Supabase template available)
- Or Docker Compose (official Supabase self-hosting guide)

**Resource Requirements**:
- Minimum: 4GB RAM, 2 vCPU
- Recommended: 8GB RAM, 4 vCPU (shares server with other services)

---

### Option B: Managed Supabase Cloud (Hybrid Approach)

**Use Cloud For**: Database, Auth, Storage (managed)
**Self-Host**: Next.js app, Typesense, Vector DB, AI models

**Pros**:
- ✅ Less DevOps burden for critical data
- ✅ Automatic backups, point-in-time recovery
- ✅ Professional support

**Cons**:
- ⚠️ Costs scale with usage ($25-150/month)
- ⚠️ Some vendor lock-in

**Verdict**: Good middle ground. Consider if DevOps time is limited.

---

### Option C: PostgreSQL + Custom Services

**Description**: Raw PostgreSQL + custom auth/storage services.

**Pros**:
- ✅ Maximum flexibility
- ✅ Lightweight

**Cons**:
- ❌ Months to build auth, storage, realtime
- ❌ Not feasible for 3-month timeline

**Verdict**: Not recommended. Supabase (self-hosted) gives us batteries-included.

---

## 4. Product Search Engine

### Option A: Typesense ⭐ RECOMMENDED FOR E-COMMERCE

**Description**: Blazing-fast, typo-tolerant search engine built for speed and relevance.

**Key Features (2025)**:
- **RAM-based indexing** (extremely fast)
- **Field weighting & boosting** (critical for e-commerce)
- **Typo tolerance** (automatic fuzzy matching)
- **Faceted search** (filters by category, price, brand, etc.)
- **Geo-search** (if needed for shipping/location)
- **Dynamic sorting** (sort by price, relevance, date at query time)
- **Real-time indexing** (instant product updates)

**Why Better for E-commerce**:
- Can boost product title matches over description matches
- Example: Search "iPhone 15" → prioritize title matches
- Critical for conversion optimization

**Performance**:
- Sub-50ms query times even with millions of products
- Scales horizontally (add more nodes)

**Pros**:
- ✅ Purpose-built for e-commerce product catalogs
- ✅ Field weighting = better relevance = higher conversions
- ✅ Fast (RAM-based)
- ✅ Easy to set up & maintain
- ✅ Great documentation
- ✅ Active community

**Cons**:
- ⚠️ Uses more RAM than Meilisearch (disk-based)
- ⚠️ Requires RAM proportional to index size

**Resource Requirements**:
- Small catalog (10K products): 1-2GB RAM
- Medium catalog (100K products): 4-8GB RAM
- Large catalog (1M products): 16GB+ RAM

**Deployment**:
- One-click via Coolify
- Or Docker: `docker run typesense/typesense`

**Cost**: FREE (self-hosted, only infrastructure costs)

---

### Option B: Meilisearch

**Description**: Developer-friendly search engine with excellent out-of-box performance.

**Key Features**:
- **Disk-based storage** (lower RAM usage)
- **Excellent typo tolerance**
- **Simple setup** (5 minutes to production)
- **Great DX** (developer experience)

**Pros**:
- ✅ Uses disk + memory-mapped files (lower RAM)
- ✅ Simpler setup than Typesense
- ✅ Great for rapid prototyping
- ✅ Beautiful web UI for testing

**Cons**:
- ❌ **No field weighting yet** (in development, not available)
- ⚠️ Slightly slower than Typesense for large datasets

**Verdict**: Excellent engine, but **Typesense wins for e-commerce** due to field weighting/boosting. Use Meilisearch if simplicity is more important than conversion optimization.

---

### Recommendation: **Typesense**

Field weighting is critical for product search relevance. Worth the extra RAM cost.

---

## 5. Vector Database (Image Search)

### Option A: Qdrant ⭐ RECOMMENDED FOR PERFORMANCE

**Description**: High-performance, Rust-based vector database optimized for similarity search.

**Key Features (2025)**:
- **Rust-based** (fast, memory-safe)
- **Advanced filtering** (search by category + visual similarity)
- **Binary Quantization** (compress embeddings, save storage)
- **Hybrid search** (combine vector + keyword search)
- **Clustering support**
- **High-cardinality metadata** (product attributes)

**Performance Benchmarks**:
- **39% better p95 latency** than pgvector (36.73ms vs 60.42ms)
- **48% better p99 latency** than pgvector
- Excellent for real-time image search

**Pros**:
- ✅ Best-in-class performance for vector search
- ✅ Built for production scale
- ✅ Great filtering (search within category)
- ✅ Self-hostable (Docker, Kubernetes)
- ✅ Excellent documentation
- ✅ Active development

**Cons**:
- ⚠️ Lower throughput than pgvector on single node (41 QPS vs 471 QPS)
- ⚠️ Separate service to maintain

**Resource Requirements**:
- Small dataset (10K products): 2GB RAM
- Medium (100K products): 8GB RAM
- Scales horizontally

**Deployment**:
- Docker: `docker run qdrant/qdrant`
- Deploy via Coolify (custom Docker container)

**Cost**: FREE (self-hosted)

---

### Option B: pgvector (PostgreSQL Extension)

**Description**: Add vector search to PostgreSQL (Supabase includes this by default).

**Key Features**:
- **Native PostgreSQL extension**
- **SQL queries** combining vector + relational data
- **ACID compliance**
- **JOINs** with product tables

**Pros**:
- ✅ No separate service needed (if using Supabase/Postgres)
- ✅ Combine vector search with SQL queries
- ✅ Simpler architecture
- ✅ **11.4x higher throughput** than Qdrant (471 QPS vs 41 QPS)

**Cons**:
- ⚠️ Slower single-query latency than Qdrant
- ⚠️ Maxes out at 10-100M vectors (not as scalable)
- ⚠️ Basic indexing (no advanced optimization)

**Verdict**: Great if you're already using Supabase/PostgreSQL and want simplicity. If performance is critical, Qdrant wins.

---

### Option C: Weaviate

**Hybrid vector + graph database** with multi-modal support.

**Pros**:
- ✅ Multi-modal (text, image, video)
- ✅ Knowledge graph features
- ✅ Built-in embeddings via 3rd-party APIs

**Cons**:
- ⚠️ More complex than needed
- ⚠️ Slower for pure vector search
- ⚠️ Higher resource usage

**Verdict**: Overkill for product image search. Qdrant or pgvector better fit.

---

### Recommendation: **Qdrant** (best performance) OR **pgvector** (simplicity)

**Decision factor**:
- If AI image search is **heavily used** → Qdrant (faster per-query)
- If AI image search is **capped/limited** → pgvector (simpler, one less service)

Since image search will be **capped**, **pgvector** might be sufficient and simpler.

---

## 6. AI Image Recognition

### Requirement
User uploads product image → AI finds visually similar products. **Capped/rate-limited** due to costs.

---

### Option A: Self-Hosted LLaVA 1.5 ⭐ BEST VALUE

**Description**: Open-source multi-modal LLM (Vision + Language), comparable to GPT-4 Vision.

**How It Works**:
1. User uploads image
2. LLaVA analyzes image → generates product description
3. Convert description to embeddings (via CLIP or sentence-transformers)
4. Search pgvector/Qdrant for similar products
5. Return ranked results

**Key Features**:
- **Open-source** (MIT license)
- **Self-hostable** (run on your GPU server)
- **7B-13B parameter models** (fits on consumer GPUs)
- Trained on CLIP + Vicuna LLM
- **One day training on 8x A100s** (~$300 total cost if training from scratch)

**Performance**:
- Competitive with GPT-4 Vision on many benchmarks
- Runs on 1x A100 (40GB VRAM) or 2x RTX 4090 (24GB each)

**Pros**:
- ✅ **Zero ongoing API costs** (only infrastructure)
- ✅ Privacy (data stays on your server)
- ✅ No rate limits (control your own limits)
- ✅ Customizable (fine-tune on your product categories)
- ✅ Fast inference (< 1 second per image)

**Cons**:
- ⚠️ Requires GPU infrastructure
- ⚠️ More complex setup than API
- ⚠️ Need ML engineering expertise for fine-tuning

**Infrastructure Needs**:
- **Hetzner GPU Server** (if available) OR
- **RunPod / Vast.ai** (GPU rental: ~$0.50-1/hour, pause when not in use)
- **Storage**: 20GB for model weights

**Monthly Cost** (estimated):
- Hetzner dedicated GPU server: ~€100/month (if available)
- OR rent GPU on-demand: $0.50/hour × 100 hours/month = **$50/month**
- Can pause during low-traffic hours

**Implementation Timeline**: 2-3 weeks

---

### Option B: Self-Hosted CLIP Model

**Description**: OpenAI's open-source image-text embedding model.

**How It Works**:
1. User uploads image
2. CLIP generates image embedding (vector)
3. Compare against pre-computed product image embeddings in vector DB
4. Return top matches

**Pros**:
- ✅ Simpler than LLaVA (no LLM, just embeddings)
- ✅ Faster inference (~100ms per image)
- ✅ Lower GPU requirements (runs on CPU with reasonable speed)
- ✅ Open-source, free

**Cons**:
- ⚠️ No natural language understanding (pure visual similarity)
- ⚠️ Less accurate than LLaVA for complex products

**Infrastructure**:
- Can run on CPU (Hetzner VPS without GPU)
- Or GPU for faster batch processing

**Monthly Cost**:
- **€0** (runs on main Hetzner VPS)

**Verdict**: **Best bang-for-buck** if we just need visual similarity without descriptions. Much simpler than LLaVA.

---

### Option C: OpenAI GPT-4 Vision API (Cloud Fallback)

**Use Case**: Premium users or when self-hosted model is down.

**Pros**:
- ✅ Best accuracy
- ✅ Zero infrastructure
- ✅ No maintenance

**Cons**:
- ❌ **$0.01-0.03 per image** (expensive at scale)
- ❌ Requires internet, 3rd-party dependency

**Cost** (if primary solution):
- 5K searches/month × $0.015 = **$75/month**
- 50K searches/month = **$750/month** (untenable)

**Verdict**: Use as **fallback only** or for **premium tier users**. Self-host for free tier.

---

### Option D: Budget Open-Source Alternatives

**BakLLaVA**: Lighter version of LLaVA (Mistral 7B base), runs on laptops with GPU.

**Qwen2.5-VL**: Latest Chinese open-source vision model (2025), competitive with GPT-4V.

**PaliGemma 2**: Google's open-source vision model (3B, 10B, 28B variants).

All follow same pattern as LLaVA: self-host, zero API costs, GPU required.

---

### Recommended Approach (Tiered)

#### **Phase 1 (MVP)**: OpenAI GPT-4 Vision API (capped)
- Fast to implement (1 week)
- Cap at 100 searches/day/user (prevents abuse)
- Cost: ~$50-100/month (controlled via caps)

#### **Phase 2 (Post-Launch)**: Self-Host CLIP
- Migrate to self-hosted CLIP for unlimited, free search
- Keep OpenAI as premium tier or fallback
- Timeline: 2-3 weeks after launch
- Cost: **€0** (runs on Hetzner VPS)

#### **Future (Optional)**: LLaVA for Advanced Features
- If we want natural language queries ("find red dresses under $50")
- Requires GPU infrastructure
- Cost: €50-100/month

---

### Final Recommendation: **Start with OpenAI (capped) → Migrate to CLIP**

Fastest path to MVP, then optimize for zero-cost self-hosted.

---

## 7. Payment Gateways

**No Change** - Same as cloud version:
- **Stripe** (international)
- **Flutterwave** (Africa, Mobile Money)
- Multi-currency via Open Exchange Rates API

Payments are external services regardless of hosting approach.

---

## 8. Infrastructure & Hosting

### Hetzner Cloud Servers ⭐ RECOMMENDED

**Why Hetzner**:
- **~10x cheaper** than AWS/GCP/Azure
- Excellent performance benchmarks
- European data centers (GDPR-friendly)
- US & Singapore locations available
- 20TB bandwidth included (EU locations)

---

### Server Sizing Recommendations

#### **Production Server (MVP)**

**Hetzner CX42** (or CCX22 for dedicated vCPU):
- **8 vCPUs** (shared) OR 4 vCPUs (dedicated)
- **16GB RAM**
- **160GB NVMe SSD**
- **20TB bandwidth**
- **€16.40/month** (CX42 shared) or ~€30/month (CCX22 dedicated)

**Runs**:
- Next.js app (via Coolify)
- Self-hosted Supabase (PostgreSQL, Auth, Storage, Realtime)
- Typesense search engine
- pgvector (within PostgreSQL)
- Monitoring (Prometheus, Grafana)

---

#### **Database Server (Growth Phase)**

**Hetzner CCX32**:
- **8 dedicated vCPUs**
- **32GB RAM**
- **240GB NVMe SSD**
- ~€60/month

**Runs**:
- PostgreSQL (dedicated)
- Qdrant (if separating vector DB)
- Backups

---

#### **GPU Server (If Self-Hosting AI)**

**Hetzner doesn't offer GPU instances** - Use external GPU cloud:

**RunPod / Vast.ai** (on-demand GPU rental):
- 1x A100 (40GB): ~$1/hour
- Pause when not in use
- Monthly cost (100 hours usage): **$100/month**

OR **Lambda Labs** (reserved GPU):
- 1x A100: ~$1.10/hour = ~$800/month 24/7
- Use spot instances: ~$200-300/month

**Verdict**: Rent GPU on-demand only when needed. Most cost-effective.

---

### CDN & Edge Caching

**Cloudflare** (Free Plan):
- Global CDN for images, static assets
- DDoS protection
- SSL certificates
- Cache rules
- **Cost**: €0

**Setup**: Point DNS to Cloudflare → configure caching rules

---

### Backups & Disaster Recovery

**Hetzner Snapshots**:
- Automated daily snapshots: €0.012 per GB/month
- 100GB snapshot = €1.20/month

**Database Backups**:
- Supabase self-hosted: pg_dump scheduled via cron
- Store in Hetzner Object Storage (S3-compatible)
- Or Backblaze B2 (very cheap: $0.005/GB)

**Estimated Backup Costs**: €5-10/month

---

### Monitoring & Observability

**Self-Hosted Monitoring Stack**:

**Grafana + Prometheus** (deployed via Coolify):
- Server metrics (CPU, RAM, disk)
- Application metrics (Next.js, PostgreSQL)
- Alerts (email, Slack)

**Plausible Analytics** (self-hosted, privacy-friendly):
- Web analytics alternative to Google Analytics
- GDPR-compliant
- Lightweight

**Uptime Kuma** (self-hosted uptime monitoring):
- Monitor website availability
- Status page
- Alerts

**All Free** (self-hosted on same Hetzner server)

---

## 9. Recommended Self-Hosted Architecture

### Final Tech Stack ⭐

#### **Frontend**
- **Framework**: Next.js 15 (App Router, RSC)
- **Styling**: Tailwind CSS + shadcn/ui
- **State**: TanStack Query + Zustand
- **Deployment**: Coolify (self-hosted on Hetzner)

#### **Backend & Database**
- **Database**: Self-hosted Supabase (PostgreSQL 16)
- **Auth**: Supabase Auth (GoTrue)
- **Storage**: Supabase Storage (S3-compatible)
- **Realtime**: Supabase Realtime
- **Vector Search**: pgvector extension (or Qdrant if needed)

#### **Search & Discovery**
- **Product Search**: Typesense (self-hosted, RAM-based)
- **Image Search (MVP)**: OpenAI GPT-4 Vision (capped, 100/day/user)
- **Image Search (Phase 2)**: Self-hosted CLIP model
- **Vector DB**: pgvector OR Qdrant (if performance critical)

#### **Payments** (External Services)
- **International**: Stripe
- **Africa**: Flutterwave
- **Currency**: Open Exchange Rates API

#### **Infrastructure**
- **Hosting**: Hetzner Cloud (CX42 or CCX22)
- **PaaS Platform**: Coolify (self-hosted)
- **CDN**: Cloudflare (free tier)
- **Backups**: Hetzner Snapshots + Object Storage
- **SSL**: Let's Encrypt (via Coolify)

#### **Monitoring & Analytics**
- **Server Monitoring**: Grafana + Prometheus
- **Web Analytics**: Plausible (self-hosted)
- **Uptime**: Uptime Kuma
- **Error Tracking**: Sentry (free tier or self-hosted)

#### **Developer Tools**
- **Version Control**: Git + GitHub
- **CI/CD**: Coolify (auto-deploy on push)
- **Code Quality**: ESLint, Prettier, Husky
- **Testing**: Vitest (unit), Playwright (E2E)

---

### Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│                      USER DEVICES                          │
│        (Desktop, Mobile Web, Native Apps Later)            │
└────────────────────┬───────────────────────────────────────┘
                     │
                     │ HTTPS
                     ▼
┌────────────────────────────────────────────────────────────┐
│                  CLOUDFLARE CDN (Free)                     │
│      Global Edge Cache | DDoS Protection | SSL            │
└────────────────────┬───────────────────────────────────────┘
                     │
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│           HETZNER CLOUD SERVER (€16-30/month)              │
│                   CX42 or CCX22                            │
│              (8 vCPU, 16GB RAM, 160GB SSD)                 │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              COOLIFY (Self-Hosted PaaS)              │ │
│  │                                                      │ │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │ │
│  │  │ Next.js 15 │  │  Supplier  │  │    Admin     │  │ │
│  │  │ Web Client │  │  Dashboard │  │  Dashboard   │  │ │
│  │  │            │  │            │  │              │  │ │
│  │  │ - Discovery│  │ - Products │  │ - Approvals  │  │ │
│  │  │ - Checkout │  │ - Orders   │  │ - Analytics  │  │ │
│  │  └────────────┘  └────────────┘  └──────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │         SELF-HOSTED SUPABASE STACK                   │ │
│  │                                                      │ │
│  │  ┌────────────────────────────────────────────────┐ │ │
│  │  │     PostgreSQL 16 (Database + pgvector)        │ │ │
│  │  │  - Users, Products, Orders, Messages           │ │ │
│  │  │  - Row-Level Security (RLS)                    │ │ │
│  │  │  - pgvector for image embeddings               │ │ │
│  │  └────────────────────────────────────────────────┘ │ │
│  │                                                      │ │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────────┐  │ │
│  │  │   Auth   │  │  Storage │  │    Realtime     │  │ │
│  │  │ (GoTrue) │  │ (MinIO)  │  │ (WebSockets)    │  │ │
│  │  └──────────┘  └──────────┘  └─────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │            TYPESENSE (Product Search)                │ │
│  │  - Unlimited free text search                       │ │
│  │  - Field weighting for e-commerce                   │ │
│  │  - Typo tolerance, facets, filters                  │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │        MONITORING (Grafana + Prometheus)             │ │
│  │        ANALYTICS (Plausible - Self-Hosted)           │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────┬───────────────┬───────────────────────┘
                     │               │
         ┌───────────┘               └──────────┐
         │                                      │
         ▼                                      ▼
┌──────────────────┐                  ┌───────────────────┐
│  EXTERNAL APIs   │                  │  PAYMENT GATEWAYS │
│                  │                  │                   │
│ Phase 1:         │                  │ - Stripe          │
│ - OpenAI GPT-4V  │                  │ - Flutterwave     │
│   (Capped 100/day)│                 │                   │
│                  │                  └───────────────────┘
│ Phase 2:         │
│ - Self-Host CLIP │
│   (on same server)│
└──────────────────┘

Optional (Growth Phase):
┌──────────────────────────────────┐
│   GPU Server (RunPod/Vast.ai)    │
│   - LLaVA 1.5 or CLIP            │
│   - On-demand GPU rental         │
│   - ~$50-100/month (paused)      │
└──────────────────────────────────┘
```

---

## 10. Cost Comparison

### Self-Hosted (Hetzner) vs Cloud (Vercel + Supabase)

#### **MVP Phase (First 3 Months)**

| Service | Cloud Cost | Self-Hosted Cost | Savings |
|---------|-----------|------------------|---------|
| **Frontend Hosting** | Vercel Pro: $20/mo | Hetzner CX42: €16/mo | ~$3/mo |
| **Database + Backend** | Supabase Pro: $25/mo | Included in Hetzner | **$25/mo** |
| **Product Search** | Algolia: $50+/mo | Typesense: €0 | **$50/mo** |
| **Vector DB** | Pinecone: $70/mo | pgvector: €0 | **$70/mo** |
| **CDN** | Cloudflare: $0 | Cloudflare: €0 | $0 |
| **AI Image Search** | OpenAI: $100/mo | OpenAI: $100/mo (capped) | $0 |
| **Monitoring** | Sentry + PostHog: $0 (free tier) | Self-hosted: €0 | $0 |
| **Backups** | Included | €10/mo | -€10/mo |
| | | | |
| **TOTAL** | **~$265/month** | **~€26/month (~$28)** | **~$237/mo (89% cheaper)** |

---

#### **Growth Phase (10K+ Users, 100K Products)**

| Service | Cloud Cost | Self-Hosted Cost | Savings |
|---------|-----------|------------------|---------|
| **Frontend** | Vercel Pro: $100/mo | Hetzner CCX32: €60/mo | ~$35/mo |
| **Database** | Supabase: $150/mo | Included | **$150/mo** |
| **Search** | Algolia: $200/mo | Typesense: €0 | **$200/mo** |
| **Vector DB** | Pinecone: $200/mo | Qdrant: €0 (same server) | **$200/mo** |
| **AI (Self-Hosted CLIP)** | N/A | €0 (on main server) | N/A |
| **CDN** | Cloudflare: $20/mo | Cloudflare: $20/mo | $0 |
| **GPU (Optional)** | N/A | RunPod: $50/mo (on-demand) | N/A |
| **Backups** | Included | €20/mo | -€20/mo |
| | | | |
| **TOTAL** | **~$670/month** | **~€150/month (~$165)** | **~$505/mo (75% cheaper)** |

---

### **Annual Savings**

- **MVP Year**: $237/mo × 12 = **$2,844/year saved**
- **Growth Year**: $505/mo × 12 = **$6,060/year saved**

---

### Key Takeaways

1. **Self-hosting saves 75-89% on infrastructure costs**
2. **Hetzner CX42 (€16/mo) can run entire MVP stack** (Next.js, Supabase, Typesense, monitoring)
3. **Product search is FREE and unlimited** (self-hosted Typesense)
4. **AI image search starts capped** (OpenAI, $100/mo), **migrates to free** (self-hosted CLIP)
5. **Scales cost-effectively**: Add servers as needed (~€60/mo per additional server vs $500+ cloud)

---

## Decision Points

Please confirm final architecture choices:

### **Confirmed Decisions** ✅
1. **Frontend**: Next.js 15 with App Router
2. **Product Search**: Typesense (self-hosted, unlimited free search)
3. **Payments**: Stripe + Flutterwave
4. **CDN**: Cloudflare

### **Pending Decisions** ❓

1. **Self-Hosting Platform**:
   - [ ] Coolify (more mature, easier)
   - [ ] Dokploy (better monitoring)
   - **Recommendation**: Coolify

2. **Backend/Database**:
   - [ ] Self-hosted Supabase (full control, zero cost)
   - [ ] Managed Supabase Cloud (less DevOps, $25-150/mo)
   - **Recommendation**: Self-hosted Supabase

3. **Vector Database**:
   - [ ] pgvector (simpler, included in PostgreSQL)
   - [ ] Qdrant (better performance)
   - **Recommendation**: pgvector (since image search is capped)

4. **AI Image Search**:
   - **Phase 1**: OpenAI GPT-4 Vision (capped at 100/day/user) - Confirmed? ✅
   - **Phase 2**: Self-hosted CLIP model (free, unlimited) - Confirmed? ✅

5. **Hetzner Server**:
   - [ ] CX42 (8 shared vCPU, 16GB RAM, €16/mo) - MVP
   - [ ] CCX22 (4 dedicated vCPU, 16GB RAM, ~€30/mo) - Better performance
   - **Recommendation**: Start with CX42, upgrade if needed

---

## Next Steps

Once architecture is confirmed:

1. ✅ Purchase Hetzner server (CX42 or CCX22)
2. ✅ Deploy Coolify on Hetzner
3. ✅ Deploy self-hosted Supabase stack via Coolify
4. ✅ Set up Next.js 15 project, connect to Supabase
5. ✅ Deploy Typesense for product search
6. ✅ Configure Cloudflare CDN
7. ✅ Design database schema (next document)
8. ✅ Begin Phase 1 development

---

## References

- [Coolify Documentation](https://coolify.io/docs)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [Typesense Documentation](https://typesense.org/docs/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [LLaVA GitHub](https://github.com/haotian-liu/LLaVA)
- [CLIP Model](https://github.com/openai/CLIP)
- [Hetzner Cloud](https://www.hetzner.com/cloud)
