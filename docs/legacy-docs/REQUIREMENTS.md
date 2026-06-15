# CBATechno Platform - Technical Requirements

## Architecture Overview

**Backend-First Approach**: Build an independent backend that serves both mobile apps (iOS/Android) and future web clients. Minimal integration with existing gura.cbatechno.com only for legacy data migration if needed.

**Client Applications**:
- Mobile: React Native (iOS + Android)
- Web: Next.js 14+ (future)

**Backend**: Supabase
- PostgreSQL database
- Built-in authentication
- Real-time subscriptions
- Row-level security (RLS)
- Storage for images/files
- Edge Functions (Deno) for business logic

## Backend Infrastructure

### Database (PostgreSQL via Supabase)

**Core Tables**:

```sql
users
  - id (uuid, pk)
  - email (unique)
  - phone (unique)
  - full_name
  - avatar_url
  - user_type (enum: buyer, seller, admin)
  - vip_status (boolean)
  - created_at, updated_at

user_profiles
  - user_id (fk users.id)
  - shipping_addresses (jsonb[])
  - payment_methods (jsonb[])
  - notification_preferences (jsonb)

products
  - id (uuid, pk)
  - seller_id (fk users.id)
  - title, description
  - price (numeric)
  - market_origin (enum: china, korea, africa, malaysia, other)
  - category_id (fk categories.id)
  - images (text[])
  - specifications (jsonb)
  - stock_quantity (integer)
  - is_active (boolean)
  - created_at, updated_at

categories
  - id (uuid, pk)
  - name, slug
  - parent_id (fk categories.id, nullable for nested categories)
  - icon_url

vehicle_compatibility (for EV/Hybrid parts)
  - id (uuid, pk)
  - product_id (fk products.id)
  - make (text)
  - model (text)
  - year_start, year_end (integer)
  - notes (text)

orders
  - id (uuid, pk)
  - buyer_id (fk users.id)
  - status (enum: pending, confirmed, shipped, delivered, cancelled)
  - subtotal, tax, shipping_cost, total (numeric)
  - shipping_address (jsonb)
  - shipping_method (enum: standard, express, pickup)
  - payment_method (text)
  - payment_status (enum: pending, completed, failed, refunded)
  - created_at, updated_at

order_items
  - id (uuid, pk)
  - order_id (fk orders.id)
  - product_id (fk products.id)
  - seller_id (fk users.id)
  - quantity (integer)
  - price_at_purchase (numeric)

messages
  - id (uuid, pk)
  - conversation_id (fk conversations.id)
  - sender_id (fk users.id)
  - content_type (enum: text, image, voice, offer)
  - content (text)
  - media_url (text, nullable)
  - metadata (jsonb, for offers/quotes)
  - read_at (timestamp, nullable)
  - created_at

conversations
  - id (uuid, pk)
  - buyer_id (fk users.id)
  - seller_id (fk users.id)
  - product_id (fk products.id, nullable)
  - last_message_at
  - created_at

wishlists
  - user_id (fk users.id)
  - product_id (fk products.id)
  - created_at
  - PRIMARY KEY (user_id, product_id)

reviews
  - id (uuid, pk)
  - product_id (fk products.id)
  - user_id (fk users.id)
  - order_id (fk orders.id)
  - rating (integer, 1-5)
  - comment (text)
  - created_at

content_library (for educational content)
  - id (uuid, pk)
  - title, description
  - content_type (enum: video, article, webinar)
  - video_url (text, YouTube embed)
  - topic_tags (text[])
  - is_live (boolean)
  - scheduled_at (timestamp, nullable)
  - created_at

notifications
  - id (uuid, pk)
  - user_id (fk users.id)
  - type (enum: order_update, message, price_drop, promo)
  - title, body
  - data (jsonb)
  - read_at (timestamp, nullable)
  - created_at
```

**Indexes**:
- products: (market_origin, category_id, is_active)
- products: Full-text search on title + description
- vehicle_compatibility: (make, model, year_start, year_end)
- messages: (conversation_id, created_at DESC)
- orders: (buyer_id, status, created_at DESC)

**Row-Level Security (RLS) Policies**:
- Users can only read/update their own profile
- Sellers can CRUD their own products
- Buyers can read all active products
- Messages: users can only read conversations they're part of
- Orders: buyers see their purchases, sellers see their sales

### Authentication (Supabase Auth)

**Providers**:
- Email + Password
- Phone (OTP via Twilio)
- OAuth: Google, Apple
- Magic Link (email)
- Guest mode: anonymous JWT with limited permissions

**User Roles**: Managed via custom claims in JWT
- `user_type`: buyer, seller, admin
- `vip_status`: boolean

### Storage (Supabase Storage)

**Buckets**:
- `products`: Product images (public read, seller write)
- `avatars`: User profile pictures (public read, owner write)
- `messages`: Media attachments (conversation participants read)
- `documents`: Invoices, receipts (owner read only)

**Image Optimization**:
- Supabase Image Transformations for thumbnails
- WebP format, multiple sizes (thumb, medium, large)

### Real-Time (Supabase Realtime)

**Subscriptions**:
- `messages`: WHERE conversation_id = ? (for chat)
- `orders`: WHERE buyer_id = ? OR seller_id = ? (order status updates)
- `notifications`: WHERE user_id = ? (push notifications)

### Edge Functions (Deno)

**Critical Functions**:
```
/process-payment
  - Payment gateway integration (Stripe, Flutterwave for Africa)
  - Create order, update inventory
  - Send confirmation emails

/send-notification
  - Push notifications via FCM/APNs
  - Email notifications
  - SMS for order updates

/calculate-shipping
  - Calculate shipping cost based on address, weight
  - Integration with shipping APIs

/generate-invoice
  - PDF generation for orders
  - Store in documents bucket

/search-products
  - Full-text search with filters
  - Elasticsearch integration (optional, later)

/vehicle-compatibility-search
  - Complex queries for EV/hybrid parts matching

/analytics-webhook
  - Receive events from clients
  - Store in analytics table for dashboard
```

## API Design

**REST API** (Supabase PostgREST):
- Auto-generated from database schema
- Standard CRUD operations
- Complex queries via RPC functions

**GraphQL** (Optional, via pg_graphql):
- For complex nested queries
- Mobile apps can use for data fetching

**Real-time** (Supabase Realtime):
- WebSocket subscriptions for live updates

**Example Endpoints**:
```
GET    /products?market_origin=eq.china&category_id=eq.{uuid}
GET    /products?id=eq.{uuid}&select=*,categories(*),vehicle_compatibility(*)
POST   /rpc/search_products (body: { query, filters, limit, offset })
POST   /rpc/find_compatible_parts (body: { make, model, year })
GET    /orders?buyer_id=eq.{uuid}&order=created_at.desc
POST   /rpc/create_order (body: { items[], shipping, payment })
GET    /conversations?or=(buyer_id.eq.{uuid},seller_id.eq.{uuid})
POST   /messages
LISTEN conversations:{id} (realtime)
```

## Mobile App Stack

**Framework**: React Native (Expo)
- TypeScript
- Expo Router (file-based navigation)
- Expo dev client for custom native modules

**State Management**:
- Zustand (global state)
- React Query / TanStack Query (server state, caching)

**Supabase Client**:
- `@supabase/supabase-js`
- React hooks for auth, data fetching, subscriptions

**UI Components**:
- React Native Paper or NativeBase
- Custom design system matching brand

**Key Libraries**:
- `@react-navigation/native` (navigation)
- `react-hook-form` + `zod` (forms, validation)
- `react-native-fast-image` (image caching)
- `react-native-video` (YouTube player alternative or WebView)
- `@react-native-firebase/messaging` (push notifications)
- `react-native-secure-storage` (tokens)
- `stripe-react-native` (payments)

## Feature Requirements (Technical)

### 1. Authentication & User Management

**Features**:
- Sign up: email/phone verification required
- Login: email/password, phone OTP, Google/Apple OAuth
- Guest checkout: create order without account, prompt to register after
- Password reset via email
- Session management: JWT tokens, refresh token rotation

**Implementation**:
- Supabase Auth handles all flows
- Custom metadata for `user_type` and `vip_status`
- RLS policies enforce access control

### 2. Product Catalog

**Features**:
- Infinite scroll with pagination (50 items/page)
- Filters: market_origin, category, price range, in-stock only
- Full-text search across title + description
- Product detail: images carousel, specs table, seller info
- "Add to Cart", "Add to Wishlist", "Chat Seller", "Request Quote"

**Implementation**:
- PostgreSQL full-text search (ts_vector)
- Cached queries with React Query (5min stale time)
- Optimistic UI updates for wishlist/cart

### 3. Vehicle Compatibility Tool (High Priority)

**User Flow**:
1. Select "Find Parts for My Car"
2. Enter: Make → Model → Year
3. Browse filtered products that fit

**Implementation**:
- Database function: `find_compatible_parts(make, model, year)`
- Pre-populate make/model dropdowns from `vehicle_compatibility` table
- Fuzzy matching for model names

### 4. Shopping Cart & Checkout

**Cart**:
- Local state (Zustand) + sync to DB for logged-in users
- Real-time price updates if product price changes
- Stock validation before checkout

**Checkout Flow**:
1. Review cart items
2. Select/add shipping address
3. Choose shipping method → calculate cost via Edge Function
4. Select payment method
5. Confirm order → `create_order` RPC function
6. Payment processing → `process-payment` Edge Function
7. Order confirmation screen + email

**Payment Gateways**:
- Stripe (cards, Apple/Google Pay)
- Flutterwave (Mobile Money, local African payments)
- PayPal
- Crypto: Coinbase Commerce (optional)

### 5. Messaging System

**Features**:
- 1:1 conversations between buyer and seller
- Message types: text, image, voice note, quote/offer
- Unread count badges
- Typing indicators (via Realtime presence)
- Message history pagination

**Implementation**:
- Supabase Realtime subscription to `messages` table
- Voice notes: record in-app, store in Storage, send URL
- Images: compress, upload to Storage, send URL
- Offers: structured data in `metadata` field (price, quantity, expiry)

### 6. Push Notifications

**Types**:
- Order updates (confirmed, shipped, delivered)
- New messages
- Price drops on wishlist items
- Promotional campaigns (admin-triggered)

**Implementation**:
- Supabase Edge Function sends to FCM/APNs
- Notification preferences stored in `user_profiles.notification_preferences`
- Client registers device token on login

### 7. Order Management

**Buyer View**:
- Order history with status
- Track shipment (integration with carrier APIs)
- Download invoice (PDF from Storage)
- Reorder button → add all items to cart
- Request return/refund

**Seller Dashboard**:
- New orders list (realtime updates)
- Update order status
- Print packing slips
- View customer messages

**Implementation**:
- Realtime subscription to `orders` table
- Status changes trigger notifications
- Invoice generation via Edge Function on order creation

### 8. Content Library (Educational)

**Features**:
- Browse videos by topic tags
- Embedded YouTube player
- Schedule live webinars (show countdown)
- Q&A chat during live sessions (separate realtime chat)

**Implementation**:
- `content_library` table
- YouTube IFrame API for embedded player
- Live Q&A uses same messaging infrastructure

### 9. Admin Dashboard (Mobile-Optimized Web View)

**Features**:
- Approve new seller registrations
- Manage products (remove violating listings)
- View analytics: sales by region, top products, GMV
- Send push notifications to user segments

**Implementation**:
- Next.js admin app (future web client)
- Supabase RLS policies for admin role
- Analytics aggregated via DB views or Edge Functions

### 10. Analytics & Monitoring

**Track**:
- User engagement: screen views, session duration
- Conversion funnel: browse → add-to-cart → checkout → purchase
- Product performance: views, add-to-cart rate, purchases
- Seller metrics: response time, order fulfillment rate

**Tools**:
- Supabase: custom `analytics_events` table
- PostHog (open-source, self-hosted or cloud)
- Sentry (error tracking)

## Non-Functional Requirements

### Performance
- App launch: < 3 seconds
- Search results: < 500ms
- Image loading: Progressive, cached
- Offline mode: cache product catalog, queue actions

### Security
- HTTPS only
- Supabase RLS for all tables
- JWT token expiry: 1 hour (access), 7 days (refresh)
- Rate limiting on Edge Functions
- Input validation (all user inputs sanitized)
- PCI DSS compliance via Stripe

### Scalability
- Supabase Pro: handles 100k+ concurrent connections
- Database connection pooling (pgBouncer)
- CDN for static assets (Cloudflare)
- Horizontal scaling via Supabase read replicas

### Localization
- Multi-language support: English, French (for Africa), Chinese
- i18n library: `react-i18next`
- Currency: USD, local currencies (via exchange rate API)

## Development Phases

### Phase 1: Foundation (Weeks 1-4)
- Supabase project setup (database, auth, storage, edge functions)
- Database schema implementation with RLS policies
- React Native app boilerplate (Expo, navigation, Supabase client)
- Authentication flows (email, phone, OAuth)
- Basic UI components and design system

**Deliverable**: Users can sign up, log in, browse products (static data)

### Phase 2: Core E-Commerce (Weeks 5-8)
- Product catalog with filters, search
- Product detail page
- Shopping cart (local + synced)
- Wishlist functionality
- Category browsing

**Deliverable**: Users can browse, search, add to cart/wishlist

### Phase 3: Checkout & Orders (Weeks 9-12)
- Shipping address management
- Payment integration (Stripe)
- Order creation and confirmation
- Order history and tracking
- Invoice generation (PDF)

**Deliverable**: End-to-end purchase flow working

### Phase 4: Vehicle Compatibility & Messaging (Weeks 13-16)
- Vehicle compatibility tool (make/model/year search)
- Messaging system (text, images)
- Conversation list and chat UI
- Real-time updates (Supabase Realtime)
- Push notifications (FCM/APNs)

**Deliverable**: Users can find compatible parts, chat with sellers

### Phase 5: Seller Features & Content (Weeks 17-20)
- Seller dashboard (manage products, orders)
- Product upload flow (sellers can add products)
- Content library (videos, webinars)
- YouTube player integration
- Voice messages in chat

**Deliverable**: Sellers can manage their business, educational content accessible

### Phase 6: Polish & Launch (Weeks 21-24)
- Performance optimization (image caching, lazy loading)
- Offline mode support
- Error handling and retry logic
- Analytics integration
- Beta testing (TestFlight, Google Play Beta)
- Bug fixes, UI polish
- App Store submissions

**Deliverable**: Production-ready apps on App Store and Play Store

### Phase 7: Admin & Advanced Features (Post-Launch)
- Admin dashboard (Next.js web app)
- Advanced analytics
- Additional payment methods (Flutterwave, crypto)
- Multi-language support
- Seller verification and ratings
- Loyalty program

## Integration with Existing gura.cbatechno.com

**Minimal Integration Points**:
1. **One-time data migration**: Export products, users, orders from old system
   - Script to transform and import into Supabase
2. **Optional API bridge** (if old system needs to stay active temporarily):
   - Edge Function proxies specific requests to gura API
   - Gradually deprecate as users migrate

**Goal**: New backend is fully independent within 3-6 months

## Future Web Client

**Next.js App** (shares same Supabase backend):
- Same database, authentication, APIs
- Server-side rendering for SEO
- Desktop-optimized UI
- Admin dashboard
- Seller portal (advanced product management)

**Code Sharing**:
- Business logic, API clients, utilities in shared npm packages
- Consistent data models (TypeScript types from Supabase)

## Risk Mitigation

**Technical Risks**:
- Supabase downtime → Use Supabase Enterprise with SLA, implement caching
- Payment gateway issues → Support multiple gateways, graceful fallback
- Real-time message failures → Queue messages locally, retry on reconnect

**Business Risks**:
- Low initial product data → Scrape/import from existing gura platform
- Seller adoption → Incentivize early sellers, provide onboarding support
- Payment fraud → Implement fraud detection, manual review for high-value orders

## Success Metrics

- **User Acquisition**: 10k users in first 3 months
- **Conversion Rate**: 3-5% (browse → purchase)
- **Seller Response Time**: < 2 hours average
- **Order Fulfillment**: 95% orders shipped within 48 hours
- **App Rating**: 4.5+ stars on App Store/Play Store
- **Retention**: 40% 30-day retention
