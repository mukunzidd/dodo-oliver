# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CBATechno Mobile App - Cross-platform e-commerce application (Android & iOS) for selling technology products, with a specialized focus on Hybrid & EV auto parts. The app connects to an existing web platform backend (gura.cbatechno.com - "Gura platform").

## Technical Stack

### Mobile App
- **Framework**: React Native (Expo)
- **Language**: TypeScript
- **State Management**: Zustand (global), React Query (server state)
- **Navigation**: Expo Router (file-based)
- **Secure Storage**: react-native-secure-storage

### Backend (Independent)
- **Platform**: Supabase
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **Authentication**: Supabase Auth (email, phone OTP, OAuth)
- **Storage**: Supabase Storage (images, files, media)
- **Real-Time**: Supabase Realtime (WebSocket subscriptions)
- **Serverless Functions**: Supabase Edge Functions (Deno)
- **Push Notifications**: FCM (Android) + APNs (iOS) via Edge Functions

### Future Web Client
- **Framework**: Next.js 14+ (shares same Supabase backend)

### Legacy Integration
- Minimal integration with gura.cbatechno.com only for one-time data migration
- Backend is fully independent to support both mobile and future web clients

## Database Architecture

See `REQUIREMENTS.md` for full schema. Key tables:

- `users`, `user_profiles` - Authentication and profile data
- `products`, `categories` - Product catalog
- `vehicle_compatibility` - EV/Hybrid parts matching (critical feature)
- `orders`, `order_items` - Order management
- `conversations`, `messages` - Real-time chat
- `wishlists`, `reviews` - User engagement
- `content_library` - Educational content
- `notifications` - Push notification queue

**RLS Policies**: All tables have Row-Level Security enabled. Users can only access their own data, sellers manage their products, admins have elevated permissions.

## Core Application Architecture

### 1. Authentication (Supabase Auth)
- Providers: Email/password, phone OTP, Google OAuth, Apple OAuth
- Guest mode: Anonymous JWT with limited RLS permissions
- Session management: JWT tokens with 1-hour expiry, 7-day refresh tokens

### 2. Product Catalog
- Full-text search via PostgreSQL ts_vector
- Filters: market_origin (enum), category_id, price range, stock status
- Infinite scroll pagination (50 items/page)
- React Query for caching (5min stale time)
- Product detail: Images carousel, specs (JSONB), seller info, action buttons

### 3. Vehicle Compatibility Tool (High Priority)
- Database function: `find_compatible_parts(make, model, year)`
- Pre-populated dropdowns from `vehicle_compatibility` table
- Fuzzy matching for model names
- This is the critical business differentiator for EV/Hybrid parts

### 4. Shopping Cart & Checkout
- Cart state: Zustand (local) + Supabase (persisted for logged-in users)
- Checkout flow:
  1. Cart review with real-time price validation
  2. Shipping address selection/creation
  3. Shipping method → Edge Function calculates cost
  4. Payment method selection
  5. Order creation via `create_order` RPC
  6. Payment processing via `process-payment` Edge Function (Stripe, Flutterwave)
  7. Order confirmation + invoice PDF generation

### 5. Messaging System
- Real-time 1:1 conversations (Supabase Realtime subscriptions)
- Message types: text, image, voice note, structured offers (JSONB metadata)
- Typing indicators via Realtime presence
- Media storage: Supabase Storage with signed URLs
- VIP users get priority response SLAs

### 6. Push Notifications
- Triggered by database events or Edge Functions
- Types: Order updates, new messages, price drops, promos
- User preferences stored in `user_profiles.notification_preferences`
- Sent via FCM/APNs through Edge Function

### 7. Content Library
- Educational videos (YouTube embeds), webinars, tech demos
- Categorized by topic tags (JSONB array)
- Live sessions with scheduled_at timestamp
- Q&A chat during live sessions (reuses messaging infrastructure)

### 8. Seller Dashboard (Mobile)
- Manage products (CRUD with image uploads to Storage)
- Order management with realtime updates
- Customer messages inbox
- Basic analytics (orders, revenue)

### 9. Admin Dashboard (Future Web App)
- Seller approval workflow
- Content moderation
- Analytics dashboard (PostgreSQL views + Edge Functions)
- Push notification campaigns

## Development Phases

**Phase 1 (Weeks 1-4)**: Foundation
- Supabase setup (database schema, RLS policies, auth, storage)
- React Native app boilerplate (Expo, navigation, Supabase client)
- Authentication flows, basic UI components

**Phase 2 (Weeks 5-8)**: Core E-Commerce
- Product catalog with filters and full-text search
- Product detail pages, wishlist, cart

**Phase 3 (Weeks 9-12)**: Checkout & Orders
- Shipping address management
- Payment integration (Stripe, Flutterwave)
- Order creation, history, invoice PDFs

**Phase 4 (Weeks 13-16)**: Vehicle Compatibility & Messaging
- EV/Hybrid parts compatibility tool (make/model/year search)
- Real-time messaging (text, images, voice)
- Push notifications

**Phase 5 (Weeks 17-20)**: Seller & Content
- Seller dashboard (product/order management)
- Content library with YouTube integration
- Advanced chat features (offers, quotes)

**Phase 6 (Weeks 21-24)**: Polish & Launch
- Performance optimization, offline mode
- Beta testing, bug fixes
- App Store and Play Store submission

**Phase 7 (Post-Launch)**: Admin & Advanced
- Admin web dashboard (Next.js)
- Advanced analytics, additional payment methods
- Multi-language support, loyalty program

## Key Technical Considerations

### API & Data Layer
- All data access via Supabase PostgREST (auto-generated REST API)
- Complex queries use PostgreSQL RPC functions
- Realtime subscriptions for chat and order updates
- React Query handles caching, optimistic updates, retry logic

### Performance
- Image optimization: WebP format, multiple sizes, CDN (Cloudflare)
- Lazy loading: Products (infinite scroll), images (progressive)
- Offline mode: Cache product catalog in AsyncStorage, queue mutations
- Database indexes on frequently queried columns

### Security
- Row-Level Security (RLS) on all tables - enforces user/seller/admin permissions
- JWT tokens (1-hour access, 7-day refresh) managed by Supabase Auth
- Input sanitization on Edge Functions
- PCI DSS compliance via Stripe (never store card details)
- Rate limiting on public Edge Functions

### Code Organization
- Monorepo structure (optional): `/mobile`, `/web`, `/shared`
- Shared TypeScript types generated from Supabase schema
- Reusable business logic in `/shared/utils`, `/shared/api`
- Component library for consistent UI across mobile/web

### Testing
- Unit tests: Vitest for utilities and business logic
- Integration tests: React Native Testing Library
- E2E tests: Detox (iOS/Android)
- Supabase local development: Docker compose for testing

## Critical Features Priority

1. **Vehicle Compatibility Tool**: The killer feature - car make/model/year → compatible parts
2. **Real-time Messaging**: Buyer-seller communication is core to trust and sales
3. **Multi-Market Filtering**: Products by origin (China, Korea, Africa, Malaysia) - essential for business model
4. **Payment Flexibility**: Support local payment methods (Mobile Money, Flutterwave) for African markets
5. **Seller Tools**: Easy product upload, order management drives seller adoption

## Common Commands

### Supabase CLI
```bash
# Start local Supabase (Docker required)
supabase start

# Generate TypeScript types from schema
supabase gen types typescript --local > lib/database.types.ts

# Run migrations
supabase db push

# Reset database (development)
supabase db reset
```

### Mobile App (React Native/Expo)
```bash
# Install dependencies
npm install

# Start development server
npx expo start

# Run on iOS simulator
npx expo run:ios

# Run on Android emulator
npx expo run:android

# Build for production
eas build --platform ios
eas build --platform android

# Submit to stores
eas submit -p ios
eas submit -p android
```

### Database Migrations
```bash
# Create new migration
supabase migration new <migration_name>

# Apply migrations
supabase db push

# Generate migration from schema diff
supabase db diff -f <migration_name>
```

### Testing
```bash
# Run unit tests
npm test

# Run E2E tests
npm run test:e2e

# Type checking
npx tsc --noEmit
```
