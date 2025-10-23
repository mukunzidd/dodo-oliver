# CBATechno Discovery Platform - Product Context

**Version**: 1.0
**Last Updated**: 2025-10-18
**Status**: Planning Phase

---

## Project Overview

**CBATechno Discovery Platform** - A discovery-first, multi-category B2B/B2C marketplace connecting buyers with premium products from vetted East Asian manufacturers (primarily China). The platform emphasizes intelligent product discovery, supplier transparency, and seamless buyer-supplier communication across diverse categories.

---

## Business Model & Value Proposition

### Revenue Streams

1. **Primary**: Commission on curated product listings (we source, list, coordinate fulfillment)
2. **Secondary**: Approved supplier marketplace (vetted suppliers list products, we take commission)

### Differentiator

**Trust through curation** - buyers discover quality products from verified manufacturers without the risk, uncertainty, or quality issues of typical Chinese marketplaces. We are the trusted intermediary ensuring product quality, supplier reliability, and transaction security.

---

## Product Categories

Research-validated, non-perishable focus:

- **Electronics & Tech Accessories**
- **Fashion & Apparel**
- **Kids & Moms** (toys, baby products, maternity)
- **Home Improvements & Finishing** (fixtures, fittings, decor)
- **Construction Materials & Supplies**
- **Tools** (power tools, hand tools, industrial)
- *Additional categories to be validated through market research*

---

## Platform Components

Priority order for development:

### 1. Web Client (Primary Launch Vehicle)
- Next.js 14+ progressive web app
- Discovery-optimized, mobile-responsive
- SEO-friendly for organic traffic
- Target: Desktop & mobile web users

### 2. Mobile Apps (Secondary, Post-V1)
- React Native (Expo) - iOS & Android
- On-the-go discovery, push notifications
- Camera-based image search

### 3. Buyer Dashboard (Integrated into Web/Mobile)
- Order tracking & history
- Supplier communication hub
- Saved searches, favorites, alerts
- Quote request management

### 4. Supplier Dashboard (Web-Based)
- Product catalog management (CRUD)
- Order fulfillment workflow
- Buyer inquiry responses
- Basic analytics (sales, views, conversions)

### 5. Admin Dashboard (Web-Based, Internal Tool)
- Supplier approval workflow (1-by-1 manual vetting)
- Product curation & moderation
- Platform analytics & reporting
- Commission tracking
- Content management

---

## Core User Journeys

### 1. Discovery (The Killer Feature)

- **Spec-Based Search**: Advanced filters by product attributes (voltage, dimensions, material, compatibility, etc.)
- **Visual/Image Search** (Phase 1): Upload a product photo → AI finds similar products
- **Category Browsing**: Intuitive navigation with faceted filters
- **Smart Matching**: Recommendations based on search history, viewed products
- **Supplier Transparency**: Factory certifications, MOQ, lead times, Incoterms, past performance

### 2. Communication

- **Real-Time Messaging**: Buyer ↔ Supplier chat (Supabase Realtime)
- **Quote Requests**: Structured forms with spec sheets, quantities, delivery requirements
- **Negotiation Tracking**: History of offers, counter-offers, terms
- **Bulk Inquiries**: Multi-product RFQs (Request for Quotation)

### 3. Purchasing

#### Guest Checkout
- Allowed but limited (no history, no saved suppliers, basic support)

#### Registered Benefits
- Order history, saved searches, supplier relationships, faster checkout, priority support

#### Payment Methods
- Mobile Money (MoMo) - Priority for African markets
- Cards (Visa/Mastercard via Stripe/Flutterwave)
- Bank transfer (for bulk orders)

#### Multi-Currency Support
- USD, local currencies (NGN, KES, GHS, etc.) with real-time conversion

#### Order Types
- Sample orders
- Bulk orders
- Recurring/subscription orders

---

## Technical Requirements

### Timeline
**3 months to V1 launch** (12 weeks)

### Key Features by Phase

#### Phase 1: Foundation, Discovery & Core Commerce (Weeks 1-6)
- Week 1-2: Project setup, Supabase schema, auth, basic UI components
- Week 3-4: Product catalog, search & filters, category navigation, **AI image search**
- Week 5-6: Product detail pages, cart, basic checkout (single currency)
- **Milestone**: Browse, search (including image search), and purchase products (MVP)

#### Phase 2: Enhanced Features & Communication (Weeks 7-9)
- Week 7: Multi-currency support, payment gateway integrations
- Week 8: Real-time supplier messaging, quote requests
- Week 9: Buyer dashboard, order tracking, saved searches
- **Milestone**: Full discovery experience + supplier communication

#### Phase 3: Supplier Tools & Launch Prep (Weeks 10-12)
- Week 10: Supplier dashboard (product management, orders)
- Week 11: Admin dashboard (supplier approval, moderation)
- Week 12: Testing, bug fixes, performance optimization, deployment
- **Milestone**: V1 launch-ready (all core workflows functional)

#### Post-Launch
- Mobile apps
- Advanced analytics
- Recommendation engine
- Loyalty program

### Supplier Onboarding
**Manual 1-by-1 approval** - Admin reviews certifications, samples, business documents before approving supplier accounts.

### Platform Integrations

#### Payment Gateways
- Stripe (cards, international)
- Flutterwave (MoMo, local cards, bank transfer)

#### AI Image Search
- OpenAI Vision API, Google Cloud Vision, or specialized product search APIs
- Vector embeddings for similarity matching

#### Analytics
- PostHog, Mixpanel, or custom via Supabase + Metabase

#### Communication
- Email/SMS: SendGrid, Twilio
- Real-time chat: Supabase Realtime

#### Other
- Currency Conversion: Open Exchange Rates API
- CDN: Cloudflare for global performance

---

## Migration from Legacy Platform

### Legacy System
gura.cbatechno.com (weak site to be deprecated)

### Migration Strategy

1. **Data Audit**: Export products, suppliers, orders, users from legacy DB
2. **Data Cleaning**: Normalize, validate, deduplicate
3. **Schema Mapping**: Map legacy schema to new Supabase schema
4. **Phased Migration**:
   - Migrate products & suppliers first (test new catalog)
   - Migrate users (send reactivation emails)
   - Migrate historical orders (read-only archive)
5. **Parallel Running**: Run both platforms briefly, redirect traffic gradually
6. **Legacy Shutdown**: Once new platform is stable (1-2 months post-launch)

---

## Success Metrics (V1)

### Discovery Effectiveness
- Search → Product View rate: >40%
- Product View → Inquiry rate: >10%
- Image search accuracy: >70% relevant results

### Engagement
- Supplier response time: <24 hours (median)
- Buyer return rate: >30% within 30 days
- Average session duration: >5 minutes

### Conversion
- Inquiry → Order conversion: >15%
- Guest checkout → Registration: >25%
- Average order value: Track & optimize

### Business
- Commission revenue per transaction: Track
- Approved suppliers onboarded: 50+ by V1 launch
- Product catalog size: 500+ products by launch

---

## Documentation Structure

This project uses a systematic documentation approach:

- **01-requirements/**: Product context, user stories, business requirements
- **02-architecture/**: Technical architecture, infrastructure, security
- **03-database/**: Schema design, migrations, data models
- **04-features/**: Feature specifications per platform
- **05-development/**: Roadmap, milestones, sprint planning
- **06-integrations/**: Third-party integration specifications

---

## Next Steps

1. ✅ Product context defined
2. 🔄 Research and design technical architecture
3. ⏳ Design database schema
4. ⏳ Specify features per platform
5. ⏳ Create development roadmap
6. ⏳ Set up project structure and begin development

---

## References

- Original requirements: See `/REQUIREMENTS.md` (baseline from original plan)
- Project instructions: See `/CLAUDE.md`
