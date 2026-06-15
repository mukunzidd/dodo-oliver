# CBATechno Discovery Platform - Final Architecture

**Version**: 1.0 LOCKED
**Date Finalized**: 2025-10-18
**Status**: ✅ APPROVED - Ready for Implementation

---

## Architecture Overview

**Self-Hosted, Cost-Optimized Stack on Hetzner Infrastructure**

This document represents the final, approved technical architecture for the CBATechno Discovery Platform. All decisions have been locked and implementation should proceed based on these specifications.

---

## Tech Stack (Locked ✅)

### **Frontend**
- **Framework**: Next.js 15 (App Router, React Server Components)
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS + shadcn/ui components
- **State Management**:
  - TanStack Query (server state)
  - Zustand (client UI state)
- **Forms**: React Hook Form + Zod validation
- **Deployment**: Coolify (self-hosted on Hetzner)

### **Backend & Database**
- **Platform**: Self-hosted Supabase
  - PostgreSQL 16+ (database)
  - PostgREST (auto-generated REST API)
  - GoTrue (authentication)
  - Supabase Storage (file uploads)
  - Supabase Realtime (WebSocket subscriptions)
- **Vector Search**: pgvector extension (Supabase Vector DB)
- **Security**: Row-Level Security (RLS) policies

### **Search & Discovery**
- **Product Search**: Typesense (self-hosted)
  - Unlimited free text search
  - Field weighting for e-commerce
  - Typo tolerance, faceted search
  - Real-time indexing
- **Vector Database**: pgvector (built into PostgreSQL)
  - Image embeddings storage
  - Similarity search for visual discovery

### **AI Image Search (Phased)**
- **Phase 1 (MVP)**: OpenAI GPT-4 Vision API
  - Capped at 100 searches/day/user
  - Cost: ~$100/month
  - Implementation: 1 week
- **Phase 2 (Post-Launch)**: Self-hosted CLIP model
  - Unlimited free searches
  - Zero ongoing costs
  - Runs on Hetzner server (CPU inference)
  - Implementation: 2-3 weeks after launch

### **Payments** (External Services)
- **International**: Stripe
  - Cards (Visa, Mastercard, Amex)
  - Apple Pay, Google Pay
  - 2.9% + $0.30 per transaction
- **Africa**: Flutterwave
  - Mobile Money (M-PESA, MTN, Airtel, etc.)
  - Local cards, bank transfers
  - 1.4% + local fees
- **Multi-Currency**: Open Exchange Rates API
  - Base currency: USD
  - Support: NGN, KES, GHS, etc.
  - Cache rates for 1 hour

### **Infrastructure**
- **Hosting**: Hetzner Cloud
  - **MVP Server**: CX42 (8 vCPU, 16GB RAM, 160GB SSD, €16.40/mo)
  - **Growth Server**: CCX32 (8 dedicated vCPU, 32GB RAM, €60/mo)
  - **Location**: EU (Germany/Finland) - 20TB bandwidth included
- **PaaS Platform**: Coolify (self-hosted)
  - One-click deployments
  - Auto SSL (Let's Encrypt)
  - Git integration
  - Multi-app management
- **CDN**: Cloudflare (Free tier)
  - Global edge caching
  - DDoS protection
  - SSL/TLS
- **Backups**:
  - Hetzner Snapshots (automated daily)
  - PostgreSQL dumps (pg_dump via cron)
  - Storage: Hetzner Object Storage or Backblaze B2

### **Monitoring & Analytics**
- **Server Monitoring**: Grafana + Prometheus (self-hosted)
- **Web Analytics**: Plausible Analytics (self-hosted, privacy-friendly)
- **Uptime Monitoring**: Uptime Kuma (self-hosted)
- **Error Tracking**: Sentry (free tier or self-hosted)

### **Communication**
- **Email**: SendGrid (free tier: 100 emails/day) or Resend
- **SMS**: Twilio or Africa's Talking
- **Real-time Chat**: Supabase Realtime (WebSockets)

---

## Cost Structure

### **MVP Phase (Months 1-3)**

| Component | Provider | Monthly Cost |
|-----------|----------|--------------|
| Server Hosting | Hetzner CX42 | €16.40 |
| AI Image Search | OpenAI (capped) | $100.00 |
| CDN | Cloudflare | €0.00 |
| Backups | Hetzner Snapshots | €10.00 |
| Email | SendGrid | €0.00 |
| Domain & DNS | Cloudflare | €10.00 |
| **TOTAL** | | **~€120/mo (~$132)** |

**Plus**: Transaction fees (2-4% of sales)

### **Post-Launch (CLIP Migration)**

| Component | Provider | Monthly Cost |
|-----------|----------|--------------|
| Server Hosting | Hetzner CCX32 | €60.00 |
| AI Image Search | Self-hosted CLIP | €0.00 |
| CDN | Cloudflare | €20.00 |
| Backups | Hetzner | €20.00 |
| **TOTAL** | | **~€100/mo (~$110)** |

### **Comparison to Cloud Alternative**

| Phase | Cloud (Vercel + Supabase + Algolia) | Self-Hosted | Savings |
|-------|--------------------------------------|-------------|---------|
| MVP | $265/month | $132/month | **50% ($133/mo)** |
| Growth | $670/month | $110/month | **84% ($560/mo)** |
| **Annual** | **$8,040/year** | **$1,320/year** | **$6,720/year** |

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│              USER DEVICES                        │
│    Desktop, Mobile Web, Native Apps (Future)    │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────┐
│          CLOUDFLARE CDN (Free Tier)             │
│   Global Edge | DDoS Protection | SSL           │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│      HETZNER CX42 (€16.40/mo)                   │
│      8 vCPU | 16GB RAM | 160GB SSD              │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         COOLIFY (PaaS Layer)              │ │
│  │                                           │ │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐ │ │
│  │  │ Next.js  │  │ Supplier │  │ Admin  │ │ │
│  │  │   Web    │  │Dashboard │  │Dashboard│ │ │
│  │  └──────────┘  └──────────┘  └────────┘ │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │      SELF-HOSTED SUPABASE STACK           │ │
│  │                                           │ │
│  │  PostgreSQL 16 + pgvector                │ │
│  │  Auth (GoTrue) | Storage | Realtime      │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │         TYPESENSE (Search Engine)         │ │
│  │    Unlimited Product Search (Free)        │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │  MONITORING (Grafana + Prometheus)        │ │
│  │  ANALYTICS (Plausible - Self-Hosted)      │ │
│  └───────────────────────────────────────────┘ │
└──────────────┬────────────┬───────────────────┘
               │            │
      ┌────────┘            └────────┐
      ▼                              ▼
┌──────────────┐              ┌──────────────┐
│ EXTERNAL APIs│              │   PAYMENTS   │
│              │              │              │
│ Phase 1:     │              │ - Stripe     │
│ OpenAI GPT-4V│              │ - Flutterwave│
│ (Capped)     │              │              │
│              │              └──────────────┘
│ Phase 2:     │
│ CLIP Model   │
│ (Self-Hosted)│
└──────────────┘
```

---

## Development Phases (3-Month Timeline)

### **Phase 1: Foundation & Core Discovery** (Weeks 1-6)
- Week 1-2: Infrastructure setup, Supabase schema, auth, UI components
- Week 3-4: Product catalog, Typesense search, category navigation
- Week 5-6: Product details, cart, checkout, OpenAI image search (capped)
- **Milestone**: Browse, search (text + image), purchase products

### **Phase 2: Enhanced Features** (Weeks 7-9)
- Week 7: Multi-currency, payment integrations (Stripe + Flutterwave)
- Week 8: Real-time messaging, quote requests
- Week 9: Buyer dashboard, order tracking, saved searches
- **Milestone**: Full discovery + supplier communication

### **Phase 3: Supplier Tools & Launch** (Weeks 10-12)
- Week 10: Supplier dashboard (products, orders)
- Week 11: Admin dashboard (approvals, moderation, analytics)
- Week 12: Testing, optimization, deployment, launch prep
- **Milestone**: V1 launch-ready

### **Post-Launch**
- CLIP migration (remove OpenAI dependency)
- Mobile apps (React Native)
- Advanced analytics & recommendations
- Legacy data migration from gura.cbatechno.com

---

## Security Architecture

### **Authentication**
- Email/password (bcrypt hashing)
- Phone OTP (SMS via Twilio)
- OAuth (Google, Apple - future)
- Guest checkout (anonymous JWT with limited RLS)

### **Authorization**
- Row-Level Security (RLS) on all tables
- Role-based access: `buyer`, `supplier`, `admin`
- JWT tokens (1-hour access, 7-day refresh)

### **Data Protection**
- HTTPS everywhere (TLS 1.3)
- Encrypted backups
- GDPR-compliant (EU hosting)
- PCI DSS via Stripe (no card storage)

### **Rate Limiting**
- API: 100 requests/minute/user
- Image search: 100 searches/day/user
- Login attempts: 5 failures → 15-minute lockout

---

## Key Technical Decisions & Rationale

### **Why Self-Hosted?**
- **Cost**: 50-84% cheaper than cloud ($6,720/year savings)
- **Control**: Full data ownership, no vendor lock-in
- **Performance**: Dedicated resources, no noisy neighbors
- **Privacy**: EU hosting, GDPR-compliant

### **Why Coolify over Dokploy?**
- **Maturity**: 5 years vs 1 year
- **Community**: 46K stars vs 25K stars
- **Ease of Use**: Simpler UI, faster learning curve
- **Stability**: Proven in production at scale

### **Why Typesense over Meilisearch?**
- **Field Weighting**: Boost title over description (higher conversions)
- **E-commerce Focus**: Built for product catalogs
- **Performance**: RAM-based, sub-50ms queries

### **Why pgvector over Qdrant?**
- **Simplicity**: No separate service (built into PostgreSQL)
- **Throughput**: 11.4x higher than Qdrant
- **Cost**: Free (included with database)
- **Rationale**: Image search is capped, so throughput > latency

### **Why OpenAI → CLIP Migration?**
- **MVP Speed**: OpenAI fastest to implement (1 week)
- **Cost Control**: Cap at 100/day prevents abuse
- **Future Optimization**: Migrate to CLIP for zero cost
- **Flexibility**: Keep OpenAI for premium tier

---

## Non-Functional Requirements

### **Performance**
- Page load: <2 seconds (3G connection)
- Search results: <200ms
- Image search: <3 seconds
- API response: <500ms (p95)

### **Availability**
- Uptime target: 99.5% (MVP), 99.9% (post-launch)
- Automated backups: Daily (retain 7 days)
- Disaster recovery: 4-hour RTO (Recovery Time Objective)

### **Scalability**
- MVP: 10K products, 1K concurrent users
- Growth: 100K products, 10K concurrent users
- Horizontal scaling: Add Hetzner servers as needed

### **SEO**
- Server-side rendering (Next.js SSR)
- Semantic HTML, meta tags
- Sitemap generation
- Structured data (JSON-LD)

---

## Next Steps

With architecture locked, proceed to:

1. ✅ **Database Schema Design** (next document)
   - Define all tables, relationships
   - RLS policies for security
   - Indexes for performance
   - Migration strategy

2. ✅ **Feature Specifications**
   - User stories per platform
   - Acceptance criteria
   - API contracts

3. ✅ **Development Roadmap**
   - Detailed task breakdown
   - Dependencies
   - Sprint planning

4. ✅ **Infrastructure Setup**
   - Provision Hetzner server
   - Deploy Coolify
   - Set up Supabase, Typesense
   - Configure Cloudflare

5. ✅ **Begin Development**
   - Sprint 1: Auth + basic UI
   - Sprint 2: Product catalog
   - Sprint 3: Search + discovery

---

## Architecture Governance

### **Change Policy**
This architecture is now **locked for MVP development**. Any changes require:
1. Written justification
2. Cost/benefit analysis
3. Timeline impact assessment
4. Approval from project stakeholders

### **Exceptions**
Minor changes allowed without approval:
- UI library choices (within Tailwind/shadcn ecosystem)
- Specific npm packages (as long as they fit architecture)
- Database field additions (that don't break migrations)

### **Review Points**
Re-evaluate architecture at:
- End of Phase 1 (6 weeks)
- Post-launch (after V1 release)
- 10K+ users milestone

---

## Document Status

**Status**: ✅ APPROVED & LOCKED
**Last Updated**: 2025-10-18
**Next Review**: End of Phase 1 (Week 6)
**Owner**: Development Team
**Approved By**: Project Stakeholders

---

## Quick Reference

**GitHub**: TBD
**Hetzner**: TBD (provision during setup)
**Cloudflare**: TBD (configure during setup)
**Domain**: TBD

**Documentation Structure**:
- `/docs/01-requirements/` - Product context
- `/docs/02-architecture/` - This document + alternatives
- `/docs/03-database/` - Schema (next)
- `/docs/04-features/` - Feature specs (upcoming)
- `/docs/05-development/` - Roadmap (upcoming)
- `/docs/06-integrations/` - API specs (upcoming)
