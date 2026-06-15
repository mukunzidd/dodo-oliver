# Database Schema Design

**Version**: 1.0 FINALIZED
**Last Updated**: 2025-10-18
**Database**: PostgreSQL 16+ (Self-hosted Supabase)
**Status**: ✅ APPROVED - Ready for Implementation

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Core Entities](#core-entities)
3. [Table Definitions](#table-definitions)
4. [Relationships](#relationships)
5. [Indexes](#indexes)
6. [RLS Policies](#rls-policies)
7. [Enums & Types](#enums--types)
8. [Design Decisions](#design-decisions-finalized)

---

## Schema Overview

### Design Principles

1. **Normalized Structure**: 3NF where appropriate, denormalized for performance-critical queries
2. **Row-Level Security**: Every table has RLS policies enforcing authorization
3. **Audit Trails**: `created_at`, `updated_at` timestamps on all tables
4. **Soft Deletes**: Critical data uses `deleted_at` instead of hard deletes
5. **JSONB for Flexibility**: Product specs, metadata use JSONB for schema-less data
6. **Full-Text Search**: `ts_vector` columns for searchable text
7. **Vector Embeddings**: `vector` type (pgvector) for AI image search

### Database Features Used

- **pgvector**: Vector similarity search (image embeddings)
- **pg_trgm**: Fuzzy text matching (typo tolerance)
- **uuid-ossp**: UUID generation for primary keys
- **PostGIS** (optional): Geospatial queries for shipping
- **pg_cron**: Scheduled jobs (currency updates, cleanup)

---

## Core Entities

### User Management
- `users` - Authentication (Supabase Auth manages this)
- `user_profiles` - Extended user data
- `user_roles` - Role assignments (buyer, supplier, admin)
- `user_addresses` - Shipping/billing addresses

### Supplier Management
- `suppliers` - Supplier business information
- `supplier_certifications` - Quality certifications, documents

### Product Catalog
- `categories` - Product categories (hierarchical)
- `products` - Core product data (includes simple inventory tracking)
- `product_images` - Product photos
- `product_specifications` - Flexible JSONB specs (handles variants via metadata)
- `product_embeddings` - Vector embeddings for image search
- `inventory_logs` - Stock change audit trail

### Orders & Payments
- `orders` - Order headers
- `order_items` - Line items
- `payments` - Payment transactions
- `order_status_history` - Audit trail
- `shipping_methods` - Available shipping options with rates

### Shopping
- `carts` - Shopping cart headers
- `cart_items` - Cart line items
- `wishlists` - Saved products

### Communication
- `conversations` - Buyer-supplier chat threads
- `messages` - Individual messages
- `notifications` - Push/email notifications

### Reviews & Feedback
- `reviews` - Product reviews
- `supplier_reviews` - Supplier ratings

### Search & Analytics
- `search_logs` - Search history for optimization
- `product_views` - View tracking for recommendations

### System
- `currency_rates` - Exchange rate cache
- `app_settings` - Configuration key-value store

---

## Table Definitions

### 1. `users` (Managed by Supabase Auth)

```sql
-- Supabase Auth manages this table
-- Reference: auth.users
-- Contains: id (UUID), email, phone, encrypted_password, etc.
```

---

### 2. `user_profiles`

Extended user information beyond authentication.

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  phone_number TEXT,
  phone_verified BOOLEAN DEFAULT false,
  language_preference TEXT DEFAULT 'en',
  currency_preference TEXT DEFAULT 'USD',
  notification_preferences JSONB DEFAULT '{
    "email": true,
    "sms": false,
    "push": true,
    "marketing": false
  }'::jsonb,
  is_guest BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_user_profiles_phone ON user_profiles(phone_number);
```

---

### 3. `user_roles`

Multi-role support (user can be both buyer and supplier).

```sql
CREATE TYPE user_role_enum AS ENUM ('buyer', 'supplier', 'admin');

CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role_enum NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);
```

**Indexes**:
```sql
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
```

---

### 4. `user_addresses`

Shipping and billing addresses.

```sql
CREATE TYPE address_type_enum AS ENUM ('shipping', 'billing');

CREATE TABLE user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  address_type address_type_enum NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state_province TEXT,
  postal_code TEXT,
  country_code TEXT NOT NULL, -- ISO 3166-1 alpha-2
  is_default BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = true;
```

---

### 5. `suppliers`

Supplier business profiles.

```sql
CREATE TYPE supplier_status_enum AS ENUM ('pending', 'approved', 'suspended', 'rejected');

CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  business_name TEXT NOT NULL,
  business_registration_number TEXT,
  business_email TEXT NOT NULL,
  business_phone TEXT NOT NULL,
  business_address TEXT,
  country TEXT NOT NULL,
  logo_url TEXT,
  description TEXT,
  status supplier_status_enum DEFAULT 'pending',
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES auth.users(id),
  min_order_value DECIMAL(10,2),
  payment_terms TEXT, -- e.g., "Net 30", "50% upfront"
  shipping_policy TEXT,
  return_policy TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_suppliers_user_id ON suppliers(user_id);
CREATE INDEX idx_suppliers_status ON suppliers(status);
CREATE INDEX idx_suppliers_business_name ON suppliers USING gin(to_tsvector('english', business_name));
```

---

### 6. `supplier_certifications`

Quality certifications and documents.

```sql
CREATE TABLE supplier_certifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID REFERENCES suppliers(id) ON DELETE CASCADE,
  certification_name TEXT NOT NULL,
  certification_number TEXT,
  issuing_body TEXT,
  issue_date DATE,
  expiry_date DATE,
  document_url TEXT, -- Stored in Supabase Storage
  verified BOOLEAN DEFAULT false,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_supplier_certifications_supplier_id ON supplier_certifications(supplier_id);
```

---

### 7. `categories`

Hierarchical product categories.

```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  image_url TEXT,
  icon TEXT, -- Icon name for UI
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_active ON categories(is_active) WHERE is_active = true;
```

---

### 8. `products`

Core product catalog.

```sql
CREATE TYPE market_origin_enum AS ENUM ('china', 'korea', 'africa', 'malaysia', 'other');
CREATE TYPE product_status_enum AS ENUM ('draft', 'active', 'out_of_stock', 'discontinued');

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID REFERENCES suppliers(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  short_description TEXT,
  description TEXT,
  market_origin market_origin_enum NOT NULL,

  -- Pricing
  base_price DECIMAL(10,2) NOT NULL, -- Base price in USD
  compare_at_price DECIMAL(10,2), -- Original price for discount display
  currency TEXT DEFAULT 'USD',

  -- Inventory
  stock_quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  allow_backorder BOOLEAN DEFAULT false,

  -- MOQ (Minimum Order Quantity)
  moq INTEGER DEFAULT 1,

  -- Shipping
  weight_grams INTEGER,
  requires_shipping BOOLEAN DEFAULT true,

  -- SEO
  meta_title TEXT,
  meta_description TEXT,

  -- Status
  status product_status_enum DEFAULT 'draft',
  published_at TIMESTAMPTZ,

  -- Search
  search_vector tsvector, -- Full-text search

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ -- Soft delete
);
```

**Indexes**:
```sql
CREATE INDEX idx_products_supplier_id ON products(supplier_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_status ON products(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_market_origin ON products(market_origin);
CREATE INDEX idx_products_price ON products(base_price);
CREATE INDEX idx_products_search_vector ON products USING gin(search_vector);
CREATE INDEX idx_products_created_at ON products(created_at DESC);
```

**Full-Text Search Trigger**:
```sql
CREATE TRIGGER products_search_vector_update
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(search_vector, 'pg_catalog.english', name, description, short_description);
```

---

### 9. `product_images`

Product photos with ordering.

```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL, -- Supabase Storage URL
  alt_text TEXT,
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT false,
  width INTEGER,
  height INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_product_images_product_id ON product_images(product_id);
CREATE INDEX idx_product_images_primary ON product_images(product_id, is_primary) WHERE is_primary = true;
```

---

### 10. `product_specifications`

Flexible JSONB for product specs.

```sql
CREATE TABLE product_specifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  spec_key TEXT NOT NULL, -- e.g., "voltage", "material", "color"
  spec_value TEXT NOT NULL, -- e.g., "220V", "Aluminum", "Red"
  spec_unit TEXT, -- e.g., "V", "kg", "mm"
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, spec_key)
);
```

**Indexes**:
```sql
CREATE INDEX idx_product_specifications_product_id ON product_specifications(product_id);
CREATE INDEX idx_product_specifications_key ON product_specifications(spec_key);
```

---

### 11. `product_embeddings`

Vector embeddings for image search (pgvector).

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE product_embeddings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE UNIQUE,
  image_id UUID REFERENCES product_images(id) ON DELETE CASCADE,
  embedding vector(1536), -- OpenAI ada-002 = 1536 dimensions, CLIP = 512
  model_version TEXT DEFAULT 'openai-ada-002',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_product_embeddings_product_id ON product_embeddings(product_id);
-- Vector similarity index (HNSW for fast approximate search)
CREATE INDEX idx_product_embeddings_vector ON product_embeddings
  USING hnsw (embedding vector_cosine_ops);
```

---

### 12. `inventory_logs`

Audit trail for stock changes.

```sql
CREATE TYPE inventory_action_enum AS ENUM (
  'restock',        -- Adding new stock
  'sale',           -- Sold via order
  'adjustment',     -- Manual adjustment (damaged, lost, etc.)
  'reserved',       -- Reserved during checkout
  'released'        -- Reservation released (cart abandoned, order cancelled)
);

CREATE TABLE inventory_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  action inventory_action_enum NOT NULL,
  quantity_change INTEGER NOT NULL, -- Positive for increase, negative for decrease
  quantity_after INTEGER NOT NULL, -- Stock after this change
  reference_id UUID, -- order_id, cart_id, etc.
  reference_type TEXT, -- 'order', 'cart', 'manual'
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_inventory_logs_product_id ON inventory_logs(product_id, created_at DESC);
CREATE INDEX idx_inventory_logs_reference ON inventory_logs(reference_id, reference_type);
```

---

### 13. `shipping_methods`

Available shipping options with rates.

```sql
CREATE TABLE shipping_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL, -- e.g., "Standard Shipping", "Express", "Economy"
  description TEXT,
  carrier TEXT, -- e.g., "DHL", "FedEx", "Local Courier"

  -- Pricing
  base_rate DECIMAL(10,2) NOT NULL, -- Base cost in USD
  per_kg_rate DECIMAL(10,2) DEFAULT 0, -- Additional cost per kg

  -- Service level
  estimated_days_min INTEGER, -- Minimum delivery days
  estimated_days_max INTEGER, -- Maximum delivery days

  -- Availability
  available_countries TEXT[], -- Array of country codes (ISO 3166-1 alpha-2)
  min_order_value DECIMAL(10,2), -- Minimum order value to qualify
  max_weight_kg DECIMAL(10,2), -- Max weight this method supports

  -- Status
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,

  -- Tracking
  supports_tracking BOOLEAN DEFAULT true,

  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_shipping_methods_active ON shipping_methods(is_active, display_order) WHERE is_active = true;
CREATE INDEX idx_shipping_methods_countries ON shipping_methods USING gin(available_countries);
```

---

### 14. `orders`

Order headers.

```sql
CREATE TYPE order_status_enum AS ENUM (
  'pending',        -- Awaiting payment
  'paid',           -- Payment confirmed
  'processing',     -- Supplier is processing
  'shipped',        -- Shipped to buyer
  'delivered',      -- Delivered
  'cancelled',      -- Cancelled by buyer/supplier
  'refunded'        -- Refunded
);

CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number TEXT UNIQUE NOT NULL, -- Human-readable: ORD-20251018-001

  -- Parties
  buyer_id UUID REFERENCES auth.users(id),
  supplier_id UUID REFERENCES suppliers(id),

  -- Status
  order_status order_status_enum DEFAULT 'pending',
  payment_status payment_status_enum DEFAULT 'pending',

  -- Pricing
  subtotal DECIMAL(10,2) NOT NULL,
  shipping_cost DECIMAL(10,2) DEFAULT 0,
  tax DECIMAL(10,2) DEFAULT 0,
  discount DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',

  -- Shipping
  shipping_address_id UUID REFERENCES user_addresses(id),
  billing_address_id UUID REFERENCES user_addresses(id),
  shipping_method_id UUID REFERENCES shipping_methods(id),
  tracking_number TEXT,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  -- Payment
  payment_method TEXT, -- 'stripe', 'flutterwave'
  payment_intent_id TEXT, -- External payment ID

  -- Notes
  buyer_notes TEXT,
  supplier_notes TEXT,
  admin_notes TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ
);
```

**Indexes**:
```sql
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
```

---

### 13. `order_items`

Line items within orders.

```sql
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),

  -- Snapshot of product at time of order
  product_name TEXT NOT NULL,
  product_sku TEXT NOT NULL,
  product_image_url TEXT,

  -- Pricing
  unit_price DECIMAL(10,2) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  subtotal DECIMAL(10,2) NOT NULL,

  -- Specifications at time of order
  specifications JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

---

### 14. `payments`

Payment transaction records.

```sql
CREATE TYPE payment_provider_enum AS ENUM ('stripe', 'flutterwave');

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),

  provider payment_provider_enum NOT NULL,
  provider_payment_id TEXT NOT NULL, -- External payment ID

  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL,

  status payment_status_enum DEFAULT 'pending',

  -- Payment method details
  payment_method_type TEXT, -- 'card', 'mobile_money', 'bank_transfer'
  payment_method_details JSONB DEFAULT '{}'::jsonb,

  -- Timestamps
  paid_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,

  error_message TEXT,

  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_provider_payment_id ON payments(provider, provider_payment_id);
```

---

### 15. `order_status_history`

Audit trail for order status changes.

```sql
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  old_status order_status_enum,
  new_status order_status_enum NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_order_status_history_order_id ON order_status_history(order_id, created_at DESC);
```

---

### 16. `carts`

Shopping cart headers.

```sql
CREATE TABLE carts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  session_id TEXT, -- For guest users
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_carts_user_id ON carts(user_id);
CREATE INDEX idx_carts_session_id ON carts(session_id);
```

---

### 17. `cart_items`

Items in shopping carts.

```sql
CREATE TABLE cart_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id UUID REFERENCES carts(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  added_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cart_id, product_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_cart_items_cart_id ON cart_items(cart_id);
CREATE INDEX idx_cart_items_product_id ON cart_items(product_id);
```

---

### 18. `wishlists`

Saved products for later.

```sql
CREATE TABLE wishlists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX idx_wishlists_product_id ON wishlists(product_id);
```

---

### 19. `conversations`

Buyer-supplier messaging threads.

```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  supplier_id UUID REFERENCES suppliers(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id), -- Optional: conversation about specific product
  subject TEXT,
  last_message_at TIMESTAMPTZ,
  buyer_unread_count INTEGER DEFAULT 0,
  supplier_unread_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(buyer_id, supplier_id, product_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_conversations_buyer_id ON conversations(buyer_id, last_message_at DESC);
CREATE INDEX idx_conversations_supplier_id ON conversations(supplier_id, last_message_at DESC);
```

---

### 20. `messages`

Individual messages in conversations.

```sql
CREATE TYPE message_type_enum AS ENUM ('text', 'image', 'file', 'quote', 'order_update');

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id),
  message_type message_type_enum DEFAULT 'text',
  content TEXT,
  attachments JSONB DEFAULT '[]'::jsonb, -- Array of file URLs
  metadata JSONB DEFAULT '{}'::jsonb, -- For structured data (quotes, etc.)
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id, created_at ASC);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
```

---

### 21. `reviews`

Product reviews.

```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id), -- Verified purchase
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  images JSONB DEFAULT '[]'::jsonb, -- Array of review image URLs
  verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, user_id, order_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_reviews_product_id ON reviews(product_id, created_at DESC);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
```

---

### 22. `supplier_reviews`

Supplier ratings.

```sql
CREATE TABLE supplier_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supplier_id UUID REFERENCES suppliers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  -- Detailed ratings
  communication_rating INTEGER CHECK (communication_rating >= 1 AND communication_rating <= 5),
  shipping_speed_rating INTEGER CHECK (shipping_speed_rating >= 1 AND shipping_speed_rating <= 5),
  product_quality_rating INTEGER CHECK (product_quality_rating >= 1 AND product_quality_rating <= 5),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(supplier_id, user_id, order_id)
);
```

**Indexes**:
```sql
CREATE INDEX idx_supplier_reviews_supplier_id ON supplier_reviews(supplier_id);
CREATE INDEX idx_supplier_reviews_user_id ON supplier_reviews(user_id);
```

---

### 23. `notifications`

Push/email notification queue.

```sql
CREATE TYPE notification_type_enum AS ENUM (
  'order_update',
  'new_message',
  'price_drop',
  'back_in_stock',
  'review_reminder',
  'supplier_approval',
  'promotion'
);

CREATE TYPE notification_channel_enum AS ENUM ('push', 'email', 'sms', 'in_app');

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type notification_type_enum NOT NULL,
  channel notification_channel_enum NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb, -- Extra data (order_id, product_id, etc.)
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_notifications_user_id ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_unsent ON notifications(sent_at) WHERE sent_at IS NULL;
```

---

### 24. `search_logs`

Search analytics for optimization.

```sql
CREATE TABLE search_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  session_id TEXT,
  query TEXT NOT NULL,
  filters JSONB DEFAULT '{}'::jsonb,
  results_count INTEGER,
  clicked_product_id UUID REFERENCES products(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_search_logs_query ON search_logs USING gin(to_tsvector('english', query));
CREATE INDEX idx_search_logs_created_at ON search_logs(created_at DESC);
```

---

### 25. `product_views`

Product view tracking for recommendations.

```sql
CREATE TABLE product_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  session_id TEXT,
  viewed_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes**:
```sql
CREATE INDEX idx_product_views_product_id ON product_views(product_id, viewed_at DESC);
CREATE INDEX idx_product_views_user_id ON product_views(user_id, viewed_at DESC);
```

---

### 26. `currency_rates`

Cached exchange rates.

```sql
CREATE TABLE currency_rates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  base_currency TEXT NOT NULL DEFAULT 'USD',
  target_currency TEXT NOT NULL,
  rate DECIMAL(10,6) NOT NULL,
  source TEXT, -- 'openexchangerates', 'manual'
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(base_currency, target_currency, valid_from)
);
```

**Indexes**:
```sql
CREATE INDEX idx_currency_rates_target ON currency_rates(target_currency, valid_from DESC);
```

---

### 27. `app_settings`

Configuration key-value store.

```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);
```

**Example Settings**:
- `image_search_daily_limit`: `{"value": 100}`
- `maintenance_mode`: `{"enabled": false}`
- `featured_categories`: `{"category_ids": ["uuid1", "uuid2"]}`

---

## Relationships

### Entity Relationship Diagram

```
users (auth.users)
  ├─ 1:1 ─ user_profiles
  ├─ 1:N ─ user_roles
  ├─ 1:N ─ user_addresses
  ├─ 1:1 ─ suppliers
  ├─ 1:N ─ orders (as buyer)
  ├─ 1:1 ─ carts
  ├─ 1:N ─ wishlists
  ├─ 1:N ─ conversations (as buyer)
  ├─ 1:N ─ messages (as sender)
  ├─ 1:N ─ reviews
  └─ 1:N ─ notifications

suppliers
  ├─ 1:N ─ supplier_certifications
  ├─ 1:N ─ products
  ├─ 1:N ─ orders (as supplier)
  ├─ 1:N ─ conversations (as supplier)
  └─ 1:N ─ supplier_reviews

categories
  ├─ 1:N ─ categories (self-referencing, parent-child)
  └─ 1:N ─ products

products
  ├─ 1:N ─ product_images
  ├─ 1:N ─ product_specifications
  ├─ 1:1 ─ product_embeddings
  ├─ 1:N ─ order_items
  ├─ 1:N ─ cart_items
  ├─ 1:N ─ wishlists
  ├─ 1:N ─ reviews
  ├─ 1:N ─ conversations
  └─ 1:N ─ product_views

orders
  ├─ 1:N ─ order_items
  ├─ 1:N ─ payments
  ├─ 1:N ─ order_status_history
  └─ 1:N ─ reviews

conversations
  └─ 1:N ─ messages
```

---

## Indexes

See individual table definitions for specific indexes. Key index strategies:

### Performance Indexes
- **Foreign Keys**: All FKs have indexes (automatic query optimization)
- **Timestamps**: `created_at DESC` for chronological listings
- **Status Fields**: Filtered indexes on active records
- **User Lookups**: Fast user_id queries across all tables

### Search Indexes
- **Full-Text Search**: GIN indexes on `tsvector` columns
- **Vector Search**: HNSW indexes for pgvector similarity
- **Text Fuzzy**: pg_trgm for typo-tolerant search

### Composite Indexes
- `(user_id, is_default)` for default addresses
- `(user_id, created_at DESC)` for user-scoped chronological queries

---

## RLS Policies

Row-Level Security policies enforce authorization at the database level.

### General Principles
- **Buyers** can read public products, manage their own data
- **Suppliers** can manage their own products and orders
- **Admins** have elevated permissions
- **Guests** have limited read-only access

### Example RLS Policies

#### `products` Table

```sql
-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Public can read active products
CREATE POLICY "Public can view active products"
ON products FOR SELECT
USING (status = 'active' AND deleted_at IS NULL);

-- Suppliers can manage their own products
CREATE POLICY "Suppliers can manage own products"
ON products FOR ALL
USING (
  supplier_id IN (
    SELECT id FROM suppliers WHERE user_id = auth.uid()
  )
);

-- Admins can manage all products
CREATE POLICY "Admins can manage all products"
ON products FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
```

#### `orders` Table

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Buyers can view their own orders
CREATE POLICY "Buyers can view own orders"
ON orders FOR SELECT
USING (buyer_id = auth.uid());

-- Suppliers can view orders for their products
CREATE POLICY "Suppliers can view own orders"
ON orders FOR SELECT
USING (
  supplier_id IN (
    SELECT id FROM suppliers WHERE user_id = auth.uid()
  )
);

-- Admins can view all orders
CREATE POLICY "Admins can view all orders"
ON orders FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  )
);
```

#### `conversations` Table

```sql
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Users can view conversations they're part of
CREATE POLICY "Users can view own conversations"
ON conversations FOR SELECT
USING (
  buyer_id = auth.uid() OR
  supplier_id IN (
    SELECT id FROM suppliers WHERE user_id = auth.uid()
  )
);

-- Users can create conversations
CREATE POLICY "Users can create conversations"
ON conversations FOR INSERT
WITH CHECK (buyer_id = auth.uid());
```

**Full RLS policy definitions will be in a separate migration file.**

---

## Enums & Types

### Defined Enums

```sql
-- User roles
CREATE TYPE user_role_enum AS ENUM ('buyer', 'supplier', 'admin');

-- Address types
CREATE TYPE address_type_enum AS ENUM ('shipping', 'billing');

-- Supplier status
CREATE TYPE supplier_status_enum AS ENUM ('pending', 'approved', 'suspended', 'rejected');

-- Market origin
CREATE TYPE market_origin_enum AS ENUM ('china', 'korea', 'africa', 'malaysia', 'other');

-- Product status
CREATE TYPE product_status_enum AS ENUM ('draft', 'active', 'out_of_stock', 'discontinued');

-- Inventory action
CREATE TYPE inventory_action_enum AS ENUM (
  'restock', 'sale', 'adjustment', 'reserved', 'released'
);

-- Order status
CREATE TYPE order_status_enum AS ENUM (
  'pending', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded'
);

-- Payment status
CREATE TYPE payment_status_enum AS ENUM ('pending', 'paid', 'failed', 'refunded');

-- Payment provider
CREATE TYPE payment_provider_enum AS ENUM ('stripe', 'flutterwave');

-- Message type
CREATE TYPE message_type_enum AS ENUM ('text', 'image', 'file', 'quote', 'order_update');

-- Notification type
CREATE TYPE notification_type_enum AS ENUM (
  'order_update', 'new_message', 'price_drop', 'back_in_stock',
  'review_reminder', 'supplier_approval', 'promotion'
);

-- Notification channel
CREATE TYPE notification_channel_enum AS ENUM ('push', 'email', 'sms', 'in_app');
```

---

## Design Decisions (Finalized)

### ✅ **Product Variants**
- **Decision**: Use JSONB metadata in `product_specifications` table
- **Rationale**: Flexible for MVP, can add dedicated variants table later if needed

### ✅ **Inventory Tracking**
- **Decision**: Simple tracking in `products` table + `inventory_logs` for audit trail
- **Fields**: `stock_quantity`, `low_stock_threshold`, `allow_backorder`
- **Future**: Reserved stock during checkout, multi-warehouse support (Phase 2+)

### ✅ **Shipping Methods**
- **Decision**: Dedicated `shipping_methods` table with rates
- **Rationale**: Different carriers have different rates, need structured data for calculations
- **Orders**: Reference `shipping_method_id` instead of text field

### ✅ **Currency**
- **Decision**: Store all prices in USD base, convert on display
- **Implementation**: `currency_rates` table with cached exchange rates
- **Update Frequency**: Hourly via cron job

### ✅ **Image Embeddings**
- **Decision**: Start with 1536 dimensions (OpenAI ada-002), migrate to 512 (CLIP) in Phase 2
- **Rationale**: Faster MVP implementation, documented migration path

### ✅ **Soft Deletes**
- **Decision**: Add `deleted_at` to `products`, `orders`, `suppliers`
- **Rationale**: Preserve historical data for order references and analytics

---

## Implementation Notes

**Database Setup**:
- Use Supabase CLI for schema management
- Enable extensions: `uuid-ossp`, `pgvector`, `pg_trgm`
- All tables have RLS enabled from day 1
- Generate TypeScript types: `supabase gen types typescript`

**Development Workflow**:
- Create schema in local Supabase instance
- Test with seed data
- Push to production when ready
- Monitor with Grafana + Prometheus

---

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Database Guide](https://supabase.com/docs/guides/database)
- [pgvector Extension](https://github.com/pgvector/pgvector)
- [Row-Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

**Status**: ✅ FINALIZED - Approved for implementation
**Tables**: 29 tables covering all core functionality
**Next Document**: Feature Specifications (with API contracts)
