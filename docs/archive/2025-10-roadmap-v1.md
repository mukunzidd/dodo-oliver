> ⚠️ **SUPERSEDED 2026-06-15.** This is the original (Oct 2025) V1 plan for the
> abandoned stack — Next.js 15 + Typesense + self-hosted Supabase on Hetzner/Coolify.
> The project pivoted to TanStack + Expo + Supabase. Current plan:
> [`docs/05-development/roadmap.md`](../05-development/roadmap.md). Kept for history.

---

# Development Roadmap - CBATechno Discovery Platform

**Version**: 1.0
**Last Updated**: 2025-10-18
**Timeline**: 12 weeks to V1 launch
**Status**: ✅ Approved

---

## Overview

This roadmap outlines the 12-week development plan to launch CBATechno Discovery Platform V1. The project is divided into 3 major phases, each with clear deliverables and milestones.

### **Success Criteria for V1 Launch**
- ✅ Buyers can browse, search (text + image), and purchase products
- ✅ Suppliers can manage products, view orders, message buyers
- ✅ Admins can approve suppliers, moderate content, view analytics
- ✅ All core workflows functional and tested
- ✅ Platform deployed on Hetzner with Coolify
- ✅ Payment gateways (Stripe + Flutterwave) integrated

---

## Timeline Overview

```
Phase 1: Foundation & Core Discovery (Weeks 1-6)
  ├─ Sprint 1-2: Infrastructure + Auth + Basic UI
  ├─ Sprint 3-4: Product Catalog + Search
  └─ Sprint 5-6: Product Details + Cart + AI Image Search

Phase 2: Commerce & Communication (Weeks 7-9)
  ├─ Sprint 7: Checkout + Payments
  ├─ Sprint 8: Messaging + Notifications
  └─ Sprint 9: Dashboards (Supplier + Admin basics)

Phase 3: Polish & Launch (Weeks 10-12)
  ├─ Sprint 10: Full Dashboards + Reviews
  ├─ Sprint 11: Testing + Bug Fixes
  └─ Sprint 12: Deployment + Launch Prep
```

---

## Phase 1: Foundation & Core Discovery (Weeks 1-6)

**Goal**: Build the discovery platform - users can browse, search, and view products.

---

### **Sprint 1-2: Infrastructure + Authentication (Weeks 1-2)**

#### Week 1: Infrastructure Setup

**Tasks**:
- [ ] Provision Hetzner server (CX42)
- [ ] Deploy Coolify on Hetzner
- [ ] Set up self-hosted Supabase stack (PostgreSQL, Auth, Storage, Realtime)
- [ ] Configure Cloudflare CDN
- [ ] Create database schema (run SQL migrations)
- [ ] Generate TypeScript types from schema
- [ ] Initialize Next.js 15 project (App Router, TypeScript, Tailwind)
- [ ] Set up ESLint, Prettier, Husky (pre-commit hooks)
- [ ] Configure Supabase client SDK
- [ ] Deploy Typesense search engine

**Deliverables**:
- ✅ Hetzner + Coolify operational
- ✅ Supabase self-hosted and accessible
- ✅ Next.js app deployed via Coolify
- ✅ Database schema created
- ✅ Typesense running

---

#### Week 2: Authentication & Base UI

**Tasks**:
- [ ] Implement user registration (email/password)
- [ ] Implement user login
- [ ] Phone OTP verification (Twilio integration)
- [ ] Password reset flow
- [ ] Guest checkout setup (anonymous users)
- [ ] User profile page (view/edit)
- [ ] Address management (CRUD)
- [ ] Set up shadcn/ui component library
- [ ] Create base layout (header, footer, navigation)
- [ ] Responsive mobile menu
- [ ] Currency selector component
- [ ] Language selector skeleton (hardcode English for now)

**Deliverables**:
- ✅ Users can register, login, manage profile
- ✅ Base UI components ready
- ✅ Responsive layout complete

---

### **Sprint 3-4: Product Catalog + Search (Weeks 3-4)**

#### Week 3: Product Catalog

**Tasks**:
- [ ] Homepage design + implementation
  - [ ] Hero section with featured products
  - [ ] Category grid
  - [ ] Recently added products
- [ ] Category pages (list products by category)
- [ ] Product card component (image, name, price, supplier badge)
- [ ] Product list/grid view toggle
- [ ] Pagination component (infinite scroll)
- [ ] Seed database with test products (50-100 products)
- [ ] Sync products to Typesense index
- [ ] Product image upload to Supabase Storage
- [ ] Supplier profile page (basic)

**Deliverables**:
- ✅ Homepage with categories and products
- ✅ Product browsing by category
- ✅ Product cards displaying correctly

---

#### Week 4: Product Search

**Tasks**:
- [ ] Typesense integration for product search
- [ ] Search bar with autocomplete
- [ ] Search results page
- [ ] Filters sidebar:
  - [ ] Price range slider
  - [ ] Market origin checkboxes
  - [ ] Category filter
  - [ ] In-stock toggle
- [ ] Sort dropdown (relevance, price, newest)
- [ ] Active filters pills (removable)
- [ ] No results state with suggestions
- [ ] Search analytics logging (save queries to `search_logs`)
- [ ] Recent searches (localStorage)

**Deliverables**:
- ✅ Full-text search working with typo tolerance
- ✅ Filters and sorting functional
- ✅ Search experience polished

**Milestone 1**: 🎯 **Product Discovery Complete** - Users can browse and search products

---

### **Sprint 5-6: Product Details + Cart + AI Search (Weeks 5-6)**

#### Week 5: Product Detail Page + Cart

**Tasks**:
- [ ] Product detail page layout
  - [ ] Image carousel with zoom
  - [ ] Product info (name, price, description, specs)
  - [ ] Stock status badge
  - [ ] Supplier card
  - [ ] Shipping estimate
  - [ ] Related products (based on category)
- [ ] Add to cart functionality
- [ ] Shopping cart sidebar (slide-in)
- [ ] Cart page (full view)
- [ ] Update quantity (with MOQ validation)
- [ ] Remove item from cart
- [ ] Cart persistence (DB for logged-in, localStorage for guests)
- [ ] Stock validation before cart operations
- [ ] Wishlist functionality (add/remove)
- [ ] Wishlist page

**Deliverables**:
- ✅ Product detail page complete
- ✅ Shopping cart fully functional
- ✅ Wishlist working

---

#### Week 6: AI Image Search + Polish

**Tasks**:
- [ ] Image upload component (dropzone)
- [ ] Camera capture (mobile)
- [ ] OpenAI GPT-4 Vision API integration
  - [ ] Send image → get product description
  - [ ] Generate embeddings via OpenAI Embeddings API
- [ ] Vector similarity search (pgvector)
- [ ] Pre-generate embeddings for existing products
- [ ] Image search results page (with similarity scores)
- [ ] Daily quota system (100 searches/day/user)
- [ ] Quota indicator in UI
- [ ] Error handling (quota exceeded, API failures)
- [ ] Polish homepage, navigation, mobile UX
- [ ] Add loading states, skeleton loaders
- [ ] Error boundaries and fallbacks

**Deliverables**:
- ✅ AI image search functional (capped at 100/day/user)
- ✅ Core web client polished and responsive

**Milestone 2**: 🎯 **Discovery + Shopping Complete** - Users can search (text + image) and add to cart

---

## Phase 2: Commerce & Communication (Weeks 7-9)

**Goal**: Complete the buying journey - checkout, payments, messaging.

---

### **Sprint 7: Checkout + Payments (Week 7)**

**Tasks**:
- [ ] Multi-step checkout wizard
  - [ ] Step 1: Cart review
  - [ ] Step 2: Shipping address (select existing or add new)
  - [ ] Step 3: Shipping method selection
  - [ ] Step 4: Payment method selection
  - [ ] Step 5: Order review
- [ ] Shipping cost calculation (based on weight + destination + method)
- [ ] Inventory reservation during checkout (15-min hold)
- [ ] Stripe integration
  - [ ] Create payment intent
  - [ ] Stripe Elements UI
  - [ ] Payment confirmation webhook
- [ ] Flutterwave integration
  - [ ] Payment gateway widget
  - [ ] Mobile Money support
  - [ ] Payment confirmation webhook
- [ ] Multi-currency checkout (convert prices at checkout time)
- [ ] Order creation after successful payment
- [ ] Inventory deduction (create `inventory_logs` entry)
- [ ] Order confirmation page
- [ ] Order confirmation email (SendGrid)
- [ ] Guest checkout (create minimal user profile)

**Deliverables**:
- ✅ Full checkout flow working
- ✅ Stripe and Flutterwave payments functional
- ✅ Orders created successfully

**Milestone 3**: 🎯 **E-Commerce MVP** - Users can complete purchases end-to-end

---

### **Sprint 8: Messaging + Notifications (Week 8)**

**Tasks**:
- [ ] Conversations table setup
- [ ] Create/get conversation API
- [ ] Real-time messaging (Supabase Realtime)
- [ ] Inbox page (list conversations)
- [ ] Conversation thread page (chat UI)
- [ ] Send text messages
- [ ] Send images (upload to Supabase Storage)
- [ ] Typing indicators (Realtime presence)
- [ ] Read receipts
- [ ] Unread count badge
- [ ] Notification system
  - [ ] Create `notifications` table entries
  - [ ] Email notifications (order updates, new messages)
  - [ ] SMS notifications (optional, via Twilio)
  - [ ] In-app notifications (bell icon with dropdown)
- [ ] Notification preferences page

**Deliverables**:
- ✅ Real-time messaging between buyers and suppliers
- ✅ Email and in-app notifications working

---

### **Sprint 9: Basic Dashboards (Week 9)**

#### Supplier Dashboard

**Tasks**:
- [ ] Supplier application form (become a supplier)
- [ ] Supplier dashboard layout (sidebar navigation)
- [ ] Products page (list all supplier's products)
- [ ] Add product form (with image upload, specs)
- [ ] Edit product
- [ ] Delete product (soft delete)
- [ ] Inventory management page (view stock levels)
- [ ] Manual stock adjustment
- [ ] Orders page (list orders for supplier's products)
- [ ] Order detail page (view order, update status, add tracking)
- [ ] Messaging inbox (supplier-side)
- [ ] Basic analytics page (total sales, orders, top products)

#### Admin Dashboard

**Tasks**:
- [ ] Admin dashboard layout
- [ ] Supplier approval queue (list pending suppliers)
- [ ] Approve/reject supplier
- [ ] View all suppliers (with search, filters)
- [ ] Suspend/unsuspend supplier
- [ ] View all products (recently added, flagged)
- [ ] Deactivate product
- [ ] View all orders (platform-wide)
- [ ] Basic analytics page (users, suppliers, products, revenue)
- [ ] Category management (CRUD categories)
- [ ] Shipping methods management (CRUD shipping methods)
- [ ] App settings page (global settings)

**Deliverables**:
- ✅ Suppliers can manage products and orders
- ✅ Admins can approve suppliers, moderate content
- ✅ Basic analytics available

**Milestone 4**: 🎯 **Platform Complete** - All core workflows functional

---

## Phase 3: Polish & Launch (Weeks 10-12)

**Goal**: Complete remaining features, test thoroughly, deploy to production.

---

### **Sprint 10: Reviews + Order Management (Week 10)**

**Tasks**:
- [ ] Product reviews (write review, upload images)
- [ ] Supplier reviews (rate supplier)
- [ ] Display reviews on product page
- [ ] Display supplier rating on profile
- [ ] "Verified Purchase" badge
- [ ] Order history page (buyer)
- [ ] Order details page (buyer)
- [ ] Cancel order (if status allows)
- [ ] Order status timeline
- [ ] Invoice generation (basic - Phase 2 for PDF)
- [ ] Buyer dashboard (order history, wishlist, messages, reviews)
- [ ] Search analytics page (admin - most searched terms, zero results)
- [ ] Currency rates management (admin can manually update)
- [ ] Automated currency rate updates (pg_cron job via Open Exchange Rates API)

**Deliverables**:
- ✅ Reviews and ratings functional
- ✅ Order management complete
- ✅ Currency system working

---

### **Sprint 11: Testing + Bug Fixes (Week 11)**

**Tasks**:
- [ ] Unit tests for critical functions (auth, cart, checkout)
- [ ] Integration tests for API endpoints
- [ ] End-to-end tests (Playwright)
  - [ ] User registration → browse → add to cart → checkout → order
  - [ ] Supplier adds product → buyer purchases → supplier ships
  - [ ] Admin approves supplier
- [ ] Cross-browser testing (Chrome, Firefox, Safari)
- [ ] Mobile responsiveness testing (iOS, Android)
- [ ] Performance optimization
  - [ ] Image optimization (WebP format, multiple sizes)
  - [ ] Code splitting (Next.js automatic)
  - [ ] Lazy loading (images, components)
  - [ ] Database query optimization (check slow queries)
  - [ ] Add database indexes where missing
- [ ] Security audit
  - [ ] Review RLS policies
  - [ ] SQL injection prevention (Supabase handles)
  - [ ] XSS prevention (React escapes by default)
  - [ ] Rate limiting (API routes)
  - [ ] HTTPS everywhere (Cloudflare + Let's Encrypt)
- [ ] Bug fixes from testing
- [ ] User acceptance testing (UAT) with small group

**Deliverables**:
- ✅ Tests written and passing
- ✅ Major bugs fixed
- ✅ Performance optimized
- ✅ Security hardened

---

### **Sprint 12: Deployment + Launch Prep (Week 12)**

**Tasks**:
- [ ] Final production deployment to Hetzner
- [ ] Domain setup (DNS, SSL)
- [ ] Email templates finalized
- [ ] SMS templates finalized (if using)
- [ ] Seed production database with initial data
  - [ ] Categories
  - [ ] Shipping methods
  - [ ] Currency rates
  - [ ] Admin user
- [ ] Onboard 5-10 initial suppliers (manually approved)
- [ ] Onboard 50-100 initial products
- [ ] Set up monitoring (Grafana dashboards, alerts)
- [ ] Set up error tracking (Sentry)
- [ ] Set up analytics (Plausible)
- [ ] Create backup strategy (automated daily backups)
- [ ] Create runbook for common issues
- [ ] Launch checklist:
  - [ ] All critical paths tested
  - [ ] Payment gateways in production mode
  - [ ] Email/SMS working
  - [ ] Monitoring active
  - [ ] Backups configured
  - [ ] Team trained on admin dashboard
- [ ] Soft launch (announce to small audience)
- [ ] Monitor for issues
- [ ] Public launch announcement

**Deliverables**:
- ✅ Platform live in production
- ✅ Initial suppliers and products onboarded
- ✅ Monitoring and backups operational
- ✅ V1 launched! 🚀

**Milestone 5**: 🎯 **V1 LAUNCH** - Platform publicly available

---

## Post-Launch Roadmap (Phase 4+)

### Immediate Post-Launch (Weeks 13-16)

**Priority Fixes**:
- Bug fixes based on user feedback
- Performance improvements based on real traffic
- UX tweaks based on user behavior analytics

**Quick Wins**:
- CLIP model migration (remove OpenAI dependency for image search)
- Invoice PDF generation
- Advanced search filters
- Product import/export (CSV) for suppliers
- Email marketing campaigns
- Discount codes / promotions

### Medium-Term (Months 4-6)

**Major Features**:
- Mobile apps (React Native - iOS & Android)
- Social login (Google, Apple OAuth)
- Recommendation engine (collaborative filtering)
- Loyalty program
- Affiliate program
- Multi-language support (French, Swahili, etc.)
- Advanced analytics dashboards
- Warehouse management (multi-location inventory)

### Long-Term (Months 7-12)

**Strategic Initiatives**:
- B2B bulk ordering features
- Subscription/recurring orders
- Advanced shipping integrations (live rates, label printing)
- Live chat support
- Product comparison tool
- Augmented reality (AR) product preview
- Blockchain-based supply chain tracking (if relevant)

---

## Risk Management

### **Identified Risks**

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Hetzner server downtime | High | Low | Daily backups, disaster recovery plan |
| OpenAI API rate limits/costs | Medium | Medium | Cap at 100/day/user, migrate to CLIP in Phase 2 |
| Payment gateway issues | High | Low | Test thoroughly, have fallback gateway |
| Supplier onboarding slow | Medium | Medium | Manual outreach, incentives for early suppliers |
| Technical debt accumulation | Medium | High | Code reviews, refactoring sprints, automated tests |
| Scope creep | High | High | Stick to roadmap, defer non-critical features to Phase 4+ |

### **Mitigation Strategies**

**Weekly Check-ins**: Review progress, adjust timeline if needed
**Daily Standups**: Identify blockers early
**Test Early, Test Often**: Catch bugs before they compound
**User Feedback Loops**: Involve test users in Weeks 10-11
**Documentation**: Keep code documented for maintainability

---

## Team & Responsibilities

**Assuming Small Team** (1-3 developers):

### **Developer 1** (Full-Stack, Lead)
- Infrastructure setup
- Database schema
- Authentication
- Checkout + payments
- Deployment

### **Developer 2** (Frontend Focus)
- UI components (shadcn/ui)
- Product pages, search
- Dashboards
- Mobile responsiveness

### **Developer 3** (Backend Focus - Optional)
- API endpoints
- Typesense integration
- Real-time messaging
- Background jobs (currency updates, notifications)

**If Solo Developer**: Follow roadmap sequentially, prioritize ruthlessly.

---

## Key Metrics to Track

### **Development Metrics**
- Sprint velocity (features completed per week)
- Bug count (open vs closed)
- Code coverage (target: 70%+)
- Deployment frequency

### **Product Metrics** (Post-Launch)
- Daily active users (DAU)
- Product views
- Search → Product view conversion (target: >40%)
- Add to cart rate (target: >15%)
- Checkout completion rate (target: >60%)
- Order volume
- Average order value
- Supplier onboarding rate
- Customer satisfaction (NPS)

---

## Tools & Resources

**Project Management**: Linear, GitHub Projects, or Trello
**Design**: Figma (for wireframes, mockups)
**Documentation**: This `/docs` folder
**Communication**: Slack, Discord, or similar
**Code Repository**: GitHub (private repo)
**CI/CD**: Coolify (auto-deploy on git push)
**Monitoring**: Grafana + Prometheus
**Error Tracking**: Sentry
**Analytics**: Plausible

---

## Definition of Done (DoD)

A feature is considered "done" when:
- [ ] Code written and tested locally
- [ ] Unit tests written (for critical logic)
- [ ] Integration test written (if applicable)
- [ ] Code reviewed (if team > 1)
- [ ] Deployed to staging environment
- [ ] Manually tested in staging
- [ ] Product owner / stakeholder approves
- [ ] Deployed to production
- [ ] Documentation updated (if needed)
- [ ] Marked as completed in project tracker

---

## Launch Checklist (Week 12)

### **Pre-Launch**
- [ ] All critical features tested end-to-end
- [ ] Payment gateways in production mode (not test mode)
- [ ] SSL certificates valid
- [ ] Domain DNS configured
- [ ] Email/SMS sending working
- [ ] Backups running daily
- [ ] Monitoring dashboards configured
- [ ] Error tracking active (Sentry)
- [ ] Analytics tracking enabled (Plausible)
- [ ] Legal pages (Terms, Privacy Policy) published
- [ ] Support email set up (support@cbatechno.com or similar)
- [ ] Runbook created (for common issues)

### **Launch Day**
- [ ] Announce on social media
- [ ] Email initial users / suppliers
- [ ] Monitor server load, errors, user activity
- [ ] Be ready for hotfixes

### **Post-Launch**
- [ ] Collect user feedback
- [ ] Prioritize bug fixes
- [ ] Plan Phase 4 features based on feedback

---

## Conclusion

This roadmap is ambitious but achievable in 12 weeks with focus and discipline. The key is to:

1. **Stick to the plan**: Resist scope creep
2. **Test continuously**: Don't wait until Week 11
3. **Iterate quickly**: Deploy often, get feedback, improve
4. **Communicate**: Keep stakeholders informed of progress
5. **Celebrate milestones**: Recognize progress to maintain momentum

**Next Steps**:
1. ✅ Review and approve roadmap
2. ✅ Set up project tracking tool (Linear, GitHub Projects, etc.)
3. ✅ Kick off Sprint 1 (Week 1)
4. ✅ Let's build! 🚀

---

**Status**: ✅ APPROVED - Ready to begin development
**Start Date**: TBD
**Target Launch**: TBD (12 weeks from start)
