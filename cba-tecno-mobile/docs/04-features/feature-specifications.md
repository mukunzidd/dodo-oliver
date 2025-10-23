# Feature Specifications - CBATechno Discovery Platform

**Version**: 1.0
**Last Updated**: 2025-10-18
**Status**: Draft - Under Development

---

## Table of Contents

1. [Overview](#overview)
2. [Web Client (Public Platform)](#web-client-public-platform)
3. [Supplier Dashboard](#supplier-dashboard)
4. [Admin Dashboard](#admin-dashboard)
5. [Shared Features](#shared-features)
6. [API Contracts](#api-contracts)

---

## Overview

This document defines all features for the CBATechno Discovery Platform across three main applications:

### **Platform Matrix**

| Platform | Users | Primary Goal | Priority |
|----------|-------|--------------|----------|
| **Web Client** | Buyers (public) | Product discovery & purchase | ⭐⭐⭐ MVP |
| **Supplier Dashboard** | Suppliers (registered) | Manage products & orders | ⭐⭐ MVP |
| **Admin Dashboard** | Admins (internal) | Platform moderation & analytics | ⭐ MVP |

### **Development Phases**

- **Phase 1 (Weeks 1-6)**: Web Client core discovery + basic dashboards
- **Phase 2 (Weeks 7-9)**: Enhanced features + communication
- **Phase 3 (Weeks 10-12)**: Full dashboards + launch prep

---

## Web Client (Public Platform)

**Target Users**: Buyers (registered + guest)
**Tech Stack**: Next.js 15, TanStack Query, Zustand, Typesense

---

### 1. Authentication & User Management

#### 1.1 User Registration

**User Story**: As a new user, I want to create an account so I can save my preferences and track orders.

**Acceptance Criteria**:
- Email/password registration with validation
- Phone number registration with OTP verification (via Twilio)
- Guest checkout option (no registration required)
- Email verification link sent via SendGrid
- Redirect to onboarding after successful registration

**Database Tables**: `auth.users`, `user_profiles`, `user_roles`

**API Endpoints**:
```typescript
POST /api/auth/signup
Body: { email: string, password: string, full_name: string, phone_number?: string }
Response: { user: User, session: Session }

POST /api/auth/verify-phone
Body: { phone_number: string, otp: string }
Response: { success: boolean }
```

**UI Components**:
- Registration form with real-time validation
- Password strength indicator
- OTP input for phone verification
- Success modal with next steps

---

#### 1.2 User Login

**User Story**: As a returning user, I want to log in to access my account.

**Acceptance Criteria**:
- Email/password login
- Phone OTP login
- "Remember me" option (7-day session)
- Password reset via email
- Social OAuth (Google, Apple) - Phase 2

**Database Tables**: `auth.users`, `user_profiles`

**API Endpoints**:
```typescript
POST /api/auth/login
Body: { email: string, password: string, remember_me?: boolean }
Response: { user: User, session: Session }

POST /api/auth/forgot-password
Body: { email: string }
Response: { success: boolean, message: string }
```

---

#### 1.3 User Profile Management

**User Story**: As a logged-in user, I want to manage my profile and preferences.

**Features**:
- Edit profile (name, avatar, phone)
- Language preference (English, French, Swahili, etc.)
- Currency preference (USD, NGN, KES, GHS, etc.)
- Notification settings (email, SMS, push)
- Address book management

**Database Tables**: `user_profiles`, `user_addresses`

**API Endpoints**:
```typescript
GET /api/user/profile
Response: { profile: UserProfile }

PATCH /api/user/profile
Body: Partial<UserProfile>
Response: { profile: UserProfile }

// Addresses
POST /api/user/addresses
Body: { address_line1, city, country_code, is_default, ... }
Response: { address: UserAddress }

GET /api/user/addresses
Response: { addresses: UserAddress[] }

PATCH /api/user/addresses/:id
DELETE /api/user/addresses/:id
```

---

### 2. Product Discovery (The Core Feature)

#### 2.1 Homepage / Browse

**User Story**: As a visitor, I want to see featured products and categories when I land on the site.

**Features**:
- Hero section with featured products/categories
- Category grid with icons
- Recently added products
- Popular products (based on views/orders)
- Market origin filters (China, Korea, Africa, Malaysia)

**Database Tables**: `products`, `categories`, `product_images`, `product_views`

**API Endpoints**:
```typescript
GET /api/products/featured
Query: { limit?: number }
Response: { products: Product[] }

GET /api/categories
Query: { parent_id?: string, include_children?: boolean }
Response: { categories: Category[] }

GET /api/products/recent
Query: { limit?: number, market_origin?: string }
Response: { products: Product[] }
```

**UI Components**:
- Hero carousel
- Category grid with hover effects
- Product card (image, name, price, supplier badge, origin flag)

---

#### 2.2 Product Search (Text-Based)

**User Story**: As a buyer, I want to search for products by keywords so I can quickly find what I need.

**Features**:
- Real-time search with typo tolerance (Typesense)
- Search suggestions/autocomplete
- Recent searches (saved in localStorage or DB)
- Advanced filters:
  - Price range
  - Market origin
  - Category
  - Supplier
  - Stock status (in stock, out of stock, backorder)
  - MOQ (minimum order quantity)
- Sort options: Relevance, Price (low-high, high-low), Newest, Popular
- Infinite scroll pagination (50 products per page)

**Database Tables**: `products`, `product_specifications`, `search_logs`

**Search Engine**: Typesense (self-hosted)

**API Endpoints**:
```typescript
GET /api/search
Query: {
  q: string,
  filters?: {
    category_id?: string,
    market_origin?: string[],
    price_min?: number,
    price_max?: number,
    in_stock?: boolean
  },
  sort?: 'relevance' | 'price_asc' | 'price_desc' | 'newest',
  page?: number,
  limit?: number
}
Response: {
  hits: Product[],
  found: number,
  page: number,
  total_pages: number
}

GET /api/search/suggestions
Query: { q: string }
Response: { suggestions: string[] }
```

**UI Components**:
- Search bar with autocomplete dropdown
- Filter sidebar (collapsible on mobile)
- Active filters pills with remove option
- Product grid with skeleton loaders
- No results state with suggestions

---

#### 2.3 Visual/Image Search (AI-Powered)

**User Story**: As a buyer, I want to upload a product photo and find similar products.

**Features**:
- Upload image or paste URL
- Camera capture (mobile)
- AI analyzes image → finds similar products
- Capped at 100 searches/day/user (to control costs)
- Progress indicator during processing

**Database Tables**: `product_embeddings`, `search_logs`

**AI Service**: OpenAI GPT-4 Vision API (Phase 1) → Self-hosted CLIP (Phase 2)

**API Endpoints**:
```typescript
POST /api/search/visual
Body: { image: File } or { image_url: string }
Response: {
  products: Product[],
  confidence_scores: number[],
  searches_remaining: number
}

GET /api/search/visual/quota
Response: { daily_limit: number, searches_today: number, remaining: number }
```

**UI Components**:
- Image upload dropzone
- Camera button (mobile)
- Processing modal with progress
- Results grid with similarity scores
- Quota indicator (X/100 searches left today)

---

#### 2.4 Product Detail Page

**User Story**: As a buyer, I want to see detailed product information to make an informed purchase.

**Features**:
- Image gallery (carousel with thumbnails)
- Product name, SKU, price (multi-currency)
- Short description + full description (markdown)
- Specifications table (from `product_specifications`)
- Market origin badge
- Stock status & availability
- MOQ (minimum order quantity)
- Supplier information card (name, rating, country, badge)
- Shipping estimate (based on buyer location + shipping methods)
- Related products (based on category or embeddings)
- Reviews & ratings
- Add to cart / Add to wishlist buttons
- Share button (social media, copy link)

**Database Tables**: `products`, `product_images`, `product_specifications`, `product_embeddings`, `suppliers`, `reviews`, `shipping_methods`

**API Endpoints**:
```typescript
GET /api/products/:slug
Response: {
  product: Product,
  images: ProductImage[],
  specifications: ProductSpecification[],
  supplier: Supplier,
  related_products: Product[]
}

GET /api/products/:id/shipping-estimate
Query: { country_code: string, weight_grams: number }
Response: {
  methods: ShippingMethod[],
  estimates: { method_id: string, cost: number, days_min: number, days_max: number }[]
}
```

**UI Components**:
- Image carousel with zoom
- Specs table (responsive)
- Supplier card (clickable → supplier page)
- Stock badge (In Stock, Low Stock, Out of Stock)
- CTA buttons (primary: Add to Cart, secondary: Wishlist)

---

### 3. Shopping Experience

#### 3.1 Shopping Cart

**User Story**: As a buyer, I want to add products to a cart and review before checkout.

**Features**:
- Add/remove products
- Update quantities (with MOQ validation)
- Real-time price updates (if currency changes)
- Cart persists for logged-in users (DB), expires after 7 days for guests (localStorage)
- Stock validation before checkout
- Estimated shipping cost (based on selected address)
- Coupon/discount code input (Phase 2)

**Database Tables**: `carts`, `cart_items`, `products`, `shipping_methods`

**API Endpoints**:
```typescript
POST /api/cart/items
Body: { product_id: string, quantity: number }
Response: { cart: Cart, items: CartItem[] }

PATCH /api/cart/items/:id
Body: { quantity: number }
Response: { cart: Cart, items: CartItem[] }

DELETE /api/cart/items/:id
Response: { cart: Cart, items: CartItem[] }

GET /api/cart
Response: { cart: Cart, items: CartItemWithProduct[] }
```

**UI Components**:
- Cart sidebar (slide-in)
- Cart page (full breakdown)
- Empty cart state with CTA
- Quantity stepper (respects MOQ)
- Remove item confirmation

---

#### 3.2 Wishlist

**User Story**: As a logged-in user, I want to save products for later.

**Features**:
- Add/remove products from wishlist
- View all wishlist items
- Move to cart directly
- Share wishlist (Phase 2)
- Price drop notifications (Phase 2)

**Database Tables**: `wishlists`, `products`

**API Endpoints**:
```typescript
POST /api/wishlist
Body: { product_id: string }
Response: { wishlist_item: WishlistItem }

DELETE /api/wishlist/:product_id
Response: { success: boolean }

GET /api/wishlist
Response: { items: WishlistItemWithProduct[] }
```

---

#### 3.3 Checkout Flow

**User Story**: As a buyer, I want a smooth checkout process to complete my purchase.

**Steps**:
1. **Cart Review**: Final check of items, quantities, prices
2. **Shipping Address**: Select existing or add new address
3. **Shipping Method**: Choose from available methods (filtered by destination)
4. **Payment Method**: Select Stripe (cards) or Flutterwave (MoMo, local cards)
5. **Order Review**: Summary of order, shipping, total
6. **Payment**: Process payment via selected gateway
7. **Confirmation**: Order number, tracking link, email sent

**Features**:
- Guest checkout (collects email + shipping address, creates guest account)
- Address autocomplete (Google Places API - Phase 2)
- Shipping cost calculation based on weight + destination
- Multi-currency support (convert at checkout time)
- Tax calculation (if applicable)
- Order notes field
- Payment processing via Stripe or Flutterwave
- Real-time stock validation before payment
- Inventory reservation during checkout (15-minute hold)

**Database Tables**: `orders`, `order_items`, `payments`, `shipping_methods`, `inventory_logs`

**API Endpoints**:
```typescript
// Step 1: Create checkout session (reserves inventory)
POST /api/checkout/create
Body: { cart_id: string }
Response: { checkout_session: CheckoutSession, expires_at: timestamp }

// Step 2: Update shipping address
PATCH /api/checkout/:session_id/shipping
Body: { address_id: string } or { address: NewAddress }
Response: { checkout_session: CheckoutSession }

// Step 3: Select shipping method & get updated totals
PATCH /api/checkout/:session_id/shipping-method
Body: { shipping_method_id: string }
Response: {
  checkout_session: CheckoutSession,
  totals: { subtotal, shipping, tax, total }
}

// Step 4: Create payment intent
POST /api/checkout/:session_id/payment-intent
Body: { payment_method: 'stripe' | 'flutterwave', currency: string }
Response: {
  payment_intent_id: string,
  client_secret: string,
  amount: number
}

// Step 5: Confirm order (after payment success)
POST /api/checkout/:session_id/confirm
Body: { payment_intent_id: string }
Response: {
  order: Order,
  order_number: string
}
```

**UI Components**:
- Multi-step wizard with progress indicator
- Address selector + "Add new address" form
- Shipping method selector (radio buttons with cost + delivery estimate)
- Payment method selector (Stripe Elements or Flutterwave widget)
- Order summary sidebar (sticky, updates in real-time)
- Success page with confetti animation

---

### 4. Order Management

#### 4.1 Order History

**User Story**: As a logged-in buyer, I want to see my past orders.

**Features**:
- List all orders with status
- Filter by status (pending, paid, shipped, delivered, cancelled)
- Search by order number
- Pagination

**Database Tables**: `orders`, `order_items`, `suppliers`

**API Endpoints**:
```typescript
GET /api/orders
Query: { status?: string, page?: number, limit?: number }
Response: { orders: OrderWithItems[], total: number, page: number }
```

---

#### 4.2 Order Details

**User Story**: As a buyer, I want to see full details of a specific order.

**Features**:
- Order number, status, dates
- Items purchased (snapshot at time of order)
- Shipping address
- Shipping method & tracking number (if shipped)
- Payment details (status, method, amount)
- Invoice download (PDF) - Phase 2
- Contact supplier button → opens conversation
- Cancel order (if status = 'pending' or 'paid')
- Status history timeline

**Database Tables**: `orders`, `order_items`, `order_status_history`, `payments`

**API Endpoints**:
```typescript
GET /api/orders/:order_number
Response: {
  order: Order,
  items: OrderItem[],
  status_history: OrderStatusHistory[],
  payment: Payment
}

POST /api/orders/:order_number/cancel
Response: { order: Order }

GET /api/orders/:order_number/invoice.pdf
Response: PDF file
```

---

### 5. Supplier Interaction

#### 5.1 Supplier Profile Page

**User Story**: As a buyer, I want to learn more about a supplier before purchasing.

**Features**:
- Supplier name, logo, description
- Country, business registration
- Certifications (with verification badges)
- Average rating from buyer reviews
- Product catalog (all products from this supplier)
- Contact button → opens conversation

**Database Tables**: `suppliers`, `supplier_certifications`, `supplier_reviews`, `products`

**API Endpoints**:
```typescript
GET /api/suppliers/:id
Response: {
  supplier: Supplier,
  certifications: SupplierCertification[],
  rating: { average: number, count: number },
  products: Product[]
}
```

---

#### 5.2 Real-Time Messaging

**User Story**: As a buyer, I want to message a supplier about a product or order.

**Features**:
- 1:1 conversations (buyer ↔ supplier)
- Message types: text, images, files
- Typing indicators (Supabase Realtime presence)
- Read receipts
- Attach product to conversation (context)
- Send quote request (structured message)
- Unread count badge

**Database Tables**: `conversations`, `messages`

**Realtime**: Supabase Realtime WebSocket subscriptions

**API Endpoints**:
```typescript
// Create or get conversation
POST /api/conversations
Body: { supplier_id: string, product_id?: string, initial_message: string }
Response: { conversation: Conversation }

// Get all conversations for current user
GET /api/conversations
Response: { conversations: ConversationWithLastMessage[] }

// Get messages in conversation
GET /api/conversations/:id/messages
Query: { limit?: number, before?: timestamp }
Response: { messages: Message[] }

// Send message
POST /api/conversations/:id/messages
Body: { content: string, attachments?: string[], type: 'text' | 'image' | 'file' }
Response: { message: Message }

// Mark as read
POST /api/conversations/:id/mark-read
Response: { success: boolean }
```

**Realtime Subscriptions**:
```typescript
// Subscribe to new messages
supabase
  .channel(`conversation:${conversationId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'messages',
    filter: `conversation_id=eq.${conversationId}`
  }, (payload) => {
    // Handle new message
  })
  .subscribe()
```

**UI Components**:
- Inbox page (list of conversations)
- Conversation thread (WhatsApp-style)
- Message input with attachment button
- Typing indicator
- Unread badge

---

### 6. Reviews & Ratings

#### 6.1 Write Product Review

**User Story**: As a buyer who received an order, I want to review the product.

**Features**:
- 1-5 star rating
- Review title + comment
- Upload images (optional)
- Verified purchase badge (if reviewed from order)
- Email reminder sent 7 days after delivery

**Database Tables**: `reviews`, `orders`

**API Endpoints**:
```typescript
POST /api/reviews
Body: {
  product_id: string,
  order_id: string,
  rating: number,
  title?: string,
  comment?: string,
  images?: string[]
}
Response: { review: Review }
```

---

#### 6.2 Write Supplier Review

**User Story**: As a buyer, I want to rate my experience with a supplier.

**Features**:
- Overall rating (1-5)
- Sub-ratings: Communication, Shipping Speed, Product Quality
- Comment

**Database Tables**: `supplier_reviews`, `orders`

**API Endpoints**:
```typescript
POST /api/supplier-reviews
Body: {
  supplier_id: string,
  order_id: string,
  rating: number,
  communication_rating: number,
  shipping_speed_rating: number,
  product_quality_rating: number,
  comment?: string
}
Response: { review: SupplierReview }
```

---

### 7. Notifications

**User Story**: As a user, I want to be notified about important events.

**Notification Types**:
- Order status updates (paid, shipped, delivered)
- New messages from suppliers
- Price drops on wishlist items (Phase 2)
- Back in stock alerts (Phase 2)
- Review reminders

**Channels**: Email, SMS, Push (mobile app - Phase 2), In-app

**Database Tables**: `notifications`, `user_profiles` (notification preferences)

**API Endpoints**:
```typescript
GET /api/notifications
Query: { unread_only?: boolean, limit?: number }
Response: { notifications: Notification[], unread_count: number }

POST /api/notifications/:id/mark-read
Response: { success: boolean }

PATCH /api/user/notification-preferences
Body: { email: boolean, sms: boolean, push: boolean, marketing: boolean }
Response: { preferences: NotificationPreferences }
```

---

## Supplier Dashboard

**Target Users**: Approved suppliers
**Access**: Web-based (Next.js app, separate route `/supplier`)

---

### 1. Supplier Onboarding

#### 1.1 Apply to Become Supplier

**User Story**: As a regular user, I want to apply to become a supplier.

**Features**:
- Application form:
  - Business name, registration number
  - Business email, phone
  - Business address, country
  - Description
  - Logo upload
  - Upload certifications (PDFs/images)
  - Payment terms, shipping policy, return policy
- Submission triggers admin review
- Email confirmation sent ("Application received, under review")

**Database Tables**: `suppliers`, `supplier_certifications`

**API Endpoints**:
```typescript
POST /api/supplier/apply
Body: {
  business_name: string,
  business_email: string,
  // ... other fields
  certifications: { name: string, document_url: string }[]
}
Response: { supplier: Supplier, status: 'pending' }
```

---

#### 1.2 Approval Status

**User Story**: As an applicant, I want to know the status of my application.

**Statuses**: Pending, Approved, Rejected, Suspended

**Features**:
- Dashboard shows current status
- Email notification on approval/rejection
- If rejected, show reason + option to reapply

---

### 2. Product Management

#### 2.1 Add New Product

**User Story**: As a supplier, I want to list a new product.

**Features**:
- Product form:
  - Name, SKU, slug (auto-generated from name)
  - Short description, full description (markdown editor)
  - Category selection (hierarchical dropdown)
  - Market origin
  - Base price (USD)
  - Compare-at price (for showing discounts)
  - Stock quantity, low stock threshold
  - Allow backorder toggle
  - MOQ
  - Weight (grams)
  - Meta title, meta description (SEO)
  - Status: Draft or Active
- Upload multiple images (drag-and-drop, set primary image)
- Add specifications (key-value pairs)
- Save as draft or publish immediately

**Database Tables**: `products`, `product_images`, `product_specifications`

**API Endpoints**:
```typescript
POST /api/supplier/products
Body: { product: ProductInput, images: File[], specifications: SpecInput[] }
Response: { product: Product }

// Upload images to Supabase Storage
POST /api/supplier/products/images/upload
Body: FormData with images
Response: { urls: string[] }
```

**UI Components**:
- Rich text editor (TipTap or similar)
- Image uploader with preview
- Specification builder (add/remove rows)
- Preview button (see how product looks on web client)

---

#### 2.2 Manage Products

**User Story**: As a supplier, I want to see all my products and manage them.

**Features**:
- Product list table (name, SKU, price, stock, status, actions)
- Search by name/SKU
- Filter by status, category, market origin
- Bulk actions: Activate, Deactivate, Delete
- Edit product (same form as add)
- Duplicate product (copy all fields, change SKU)
- Delete product (soft delete if has orders, hard delete otherwise)

**Database Tables**: `products`

**API Endpoints**:
```typescript
GET /api/supplier/products
Query: { status?: string, category_id?: string, page?: number }
Response: { products: Product[], total: number }

PATCH /api/supplier/products/:id
Body: Partial<ProductInput>
Response: { product: Product }

DELETE /api/supplier/products/:id
Response: { success: boolean }
```

---

#### 2.3 Inventory Management

**User Story**: As a supplier, I want to track and update stock levels.

**Features**:
- View current stock for all products
- Low stock alerts (products below threshold)
- Bulk stock update (CSV import)
- Manual stock adjustment with reason
- Inventory log history per product

**Database Tables**: `products`, `inventory_logs`

**API Endpoints**:
```typescript
GET /api/supplier/inventory
Response: { products: ProductWithStock[] }

POST /api/supplier/inventory/adjust
Body: { product_id: string, quantity_change: number, notes: string }
Response: { product: Product, log: InventoryLog }

GET /api/supplier/inventory/:product_id/logs
Response: { logs: InventoryLog[] }
```

---

### 3. Order Management

#### 3.1 View Orders

**User Story**: As a supplier, I want to see all orders for my products.

**Features**:
- Order list (order number, buyer, items count, total, status, date)
- Filter by status (pending, paid, processing, shipped, delivered)
- Search by order number or buyer email
- Sort by date, total
- Real-time updates when new orders arrive (Supabase Realtime)

**Database Tables**: `orders`, `order_items`

**API Endpoints**:
```typescript
GET /api/supplier/orders
Query: { status?: string, page?: number }
Response: { orders: OrderWithItems[], total: number }
```

---

#### 3.2 Process Order

**User Story**: As a supplier, I want to update order status and add tracking info.

**Features**:
- View full order details
- Update status: Processing → Shipped
- Add tracking number
- Add supplier notes (not visible to buyer)
- Send notification to buyer when status changes
- Print packing slip (Phase 2)

**Database Tables**: `orders`, `order_status_history`

**API Endpoints**:
```typescript
PATCH /api/supplier/orders/:order_number/status
Body: { status: 'processing' | 'shipped', tracking_number?: string, notes?: string }
Response: { order: Order }
```

---

### 4. Messaging

**User Story**: As a supplier, I want to respond to buyer inquiries.

**Features**: Same as buyer messaging, but supplier-side view
- Inbox with all conversations
- Unread count
- Send quotes/offers (structured messages with price, MOQ, delivery time)
- Attach products to conversation

---

### 5. Analytics (Basic)

**User Story**: As a supplier, I want to see my performance metrics.

**Metrics**:
- Total sales (current month, all-time)
- Total orders (current month, all-time)
- Top-selling products
- Product views (from `product_views` table)
- Average order value
- Customer satisfaction (average supplier rating)

**Database Tables**: `orders`, `order_items`, `product_views`, `supplier_reviews`

**API Endpoints**:
```typescript
GET /api/supplier/analytics/overview
Response: {
  total_sales: number,
  total_orders: number,
  avg_order_value: number,
  avg_rating: number
}

GET /api/supplier/analytics/top-products
Query: { limit?: number }
Response: { products: ProductWithSales[] }
```

**UI Components**:
- Dashboard with cards (total sales, orders, AOV, rating)
- Top products table
- Simple chart (sales over time - Phase 2)

---

## Admin Dashboard

**Target Users**: Platform administrators (internal team)
**Access**: Web-based (Next.js app, separate route `/admin`)

---

### 1. Supplier Management

#### 1.1 Approve Suppliers

**User Story**: As an admin, I want to review and approve supplier applications.

**Features**:
- List of pending suppliers
- View full application details
- View uploaded certifications (PDFs, images)
- Approve or Reject with reason
- Email notification sent to applicant
- Option to request more information

**Database Tables**: `suppliers`, `supplier_certifications`

**API Endpoints**:
```typescript
GET /api/admin/suppliers/pending
Response: { suppliers: SupplierWithCertifications[] }

POST /api/admin/suppliers/:id/approve
Response: { supplier: Supplier }

POST /api/admin/suppliers/:id/reject
Body: { reason: string }
Response: { supplier: Supplier }
```

---

#### 1.2 Manage Suppliers

**Features**:
- List all suppliers (with search, filters)
- View supplier details + performance
- Suspend supplier (disables all products)
- Unsuspend supplier
- Delete supplier (if no orders)

---

### 2. Product Moderation

**User Story**: As an admin, I want to review products and remove policy violations.

**Features**:
- Recently added products queue
- Flagged products (from user reports - Phase 2)
- Approve, Reject, or Request changes
- Bulk actions

**Database Tables**: `products`

**API Endpoints**:
```typescript
GET /api/admin/products/recent
Query: { limit?: number }
Response: { products: Product[] }

POST /api/admin/products/:id/deactivate
Body: { reason: string }
Response: { product: Product }
```

---

### 3. Order Management

**Features**:
- View all orders across platform
- Search by order number, buyer email, supplier name
- Manually cancel/refund orders (with reason)
- Resolve disputes (Phase 2)

---

### 4. Platform Analytics

**User Story**: As an admin, I want to see platform-wide metrics.

**Metrics**:
- Total users, suppliers, products
- Total orders, revenue
- Commission earned
- Top suppliers by revenue
- Top products by sales
- Search analytics (most searched terms, zero-result searches)
- User growth over time

**Database Tables**: All tables

**API Endpoints**:
```typescript
GET /api/admin/analytics/overview
Response: {
  total_users: number,
  total_suppliers: number,
  total_products: number,
  total_orders: number,
  total_revenue: number,
  commission_earned: number
}

GET /api/admin/analytics/top-suppliers
GET /api/admin/analytics/search-terms
```

**UI Components**:
- Dashboard with metric cards
- Charts (revenue over time, user growth)
- Tables (top suppliers, top products, search terms)
- Export to CSV

---

### 5. Content Management

#### 5.1 Manage Categories

**Features**:
- Add, edit, delete categories
- Set parent-child relationships (hierarchical)
- Upload category icons/images
- Reorder categories (display_order)
- Activate/deactivate

**Database Tables**: `categories`

---

#### 5.2 Shipping Methods

**Features**:
- Add, edit, delete shipping methods
- Set base rate, per-kg rate
- Set available countries
- Set delivery estimate (min/max days)
- Activate/deactivate

**Database Tables**: `shipping_methods`

---

#### 5.3 App Settings

**Features**:
- Global settings (maintenance mode, featured categories, etc.)
- Image search daily limit
- Currency exchange rate manual override
- Email templates (Phase 2)

**Database Tables**: `app_settings`, `currency_rates`

---

## Shared Features

### 1. Multi-Currency Display

**Implementation**:
- Detect user currency preference (from profile or IP geolocation)
- Fetch latest exchange rates from `currency_rates` table
- Display all prices in user's currency
- Show original USD price on hover/tooltip
- Currency selector in header

### 2. Multi-Language (Phase 2)

**Implementation**:
- i18n library (next-intl or react-i18next)
- Language selector in header
- Translations for UI strings
- RTL support for Arabic (Phase 2+)

### 3. Responsive Design

**Breakpoints**:
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

**Mobile-First Components**:
- Hamburger menu
- Bottom navigation (Phase 2)
- Swipeable carousels
- Sticky CTAs

---

## API Contracts

### Authentication

All authenticated endpoints require `Authorization: Bearer <token>` header.

**Supabase Auth** manages sessions via JWT tokens (1-hour access, 7-day refresh).

### Error Handling

All API endpoints follow standard error format:

```typescript
{
  error: {
    code: string,  // e.g., 'VALIDATION_ERROR', 'NOT_FOUND', 'UNAUTHORIZED'
    message: string,
    details?: any
  }
}
```

**HTTP Status Codes**:
- 200: Success
- 201: Created
- 400: Bad Request (validation error)
- 401: Unauthorized
- 403: Forbidden (lacks permission)
- 404: Not Found
- 409: Conflict (e.g., duplicate SKU)
- 500: Internal Server Error

### Pagination

Paginated endpoints use:

**Query**:
```typescript
{ page?: number, limit?: number }
```

**Response**:
```typescript
{
  data: T[],
  pagination: {
    page: number,
    limit: number,
    total: number,
    total_pages: number
  }
}
```

### Real-Time Updates

**Supabase Realtime** channels for:
- New messages in conversations
- Order status changes
- Stock updates (for suppliers)

**Example**:
```typescript
const channel = supabase.channel('orders')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'orders',
    filter: `supplier_id=eq.${supplierId}`
  }, (payload) => {
    // Handle order update
  })
  .subscribe()
```

---

## Next Steps

1. ✅ Review feature specifications
2. ✅ Confirm API contracts align with database schema
3. ✅ Create development roadmap with sprints
4. ✅ Begin UI/UX wireframes (Figma or similar)
5. ✅ Set up project structure and begin implementation

---

**Status**: Draft - Awaiting review
**Next Document**: Development Roadmap (Sprint Planning)
