-- ==============================================================================
-- JNOVAMUSIC OFFICIAL DATABASE SCHEMA & MIGRATION (SUPABASE POSTGRESQL)
-- Salin dan jalankan seluruh isi file ini di SQL Editor pada Supabase Dashboard.
-- ==============================================================================

-- 1. Enable Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Drop existing types if recreating
DO $$ BEGIN
  CREATE TYPE user_tier_enum AS ENUM ('bronze', 'silver', 'gold', 'platinum');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE fulfillment_method_enum AS ENUM ('pickup', 'delivery');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE order_status_enum AS ENUM (
    'menunggu_pembayaran',
    'menunggu_verifikasi',
    'pembayaran_terverifikasi',
    'diproses_luthier',
    'dalam_pengiriman',
    'siap_diambil',
    'selesai',
    'dibatalkan'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE payment_method_enum AS ENUM ('bank_transfer_bca', 'bank_transfer_mandiri', 'qris');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE payment_status_enum AS ENUM ('pending', 'under_review', 'verified', 'rejected', 'expired');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE point_category_enum AS ENUM ('purchase', 'game_bonus', 'jackpot', 'daily_mission', 'level_up');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- 3. TABEL PROFIL PENGGUNA (Terikat ke auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name VARCHAR(150) NOT NULL,
  username VARCHAR(60) UNIQUE NOT NULL,
  email VARCHAR(150) NOT NULL,
  phone_number VARCHAR(30),
  birth_date DATE,
  photo_url TEXT,
  tier user_tier_enum DEFAULT 'silver',
  current_points INTEGER DEFAULT 2400 CHECK (current_points >= 0),
  is_email_verified BOOLEAN DEFAULT FALSE,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  is_biometric_enabled BOOLEAN DEFAULT FALSE,
  
  -- Alamat Pengiriman Utama
  address_label VARCHAR(60) DEFAULT 'Rumah Utama',
  street_address TEXT,
  rt_rw VARCHAR(30),
  courier_notes TEXT,
  kelurahan VARCHAR(100),
  kecamatan VARCHAR(100),
  city VARCHAR(100),
  province VARCHAR(100),
  postal_code VARCHAR(15),
  
  created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. TABEL CABANG TOKO (Store Branches)
CREATE TABLE IF NOT EXISTS public.store_branches (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  tag VARCHAR(50) NOT NULL,
  address TEXT NOT NULL,
  distance_label VARCHAR(30),
  operating_hours VARCHAR(100) NOT NULL,
  stock_status VARCHAR(50) DEFAULT 'Stok Ready di Toko',
  latitude NUMERIC(10, 7),
  longitude NUMERIC(10, 7),
  phone VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABEL KATALOG PRODUK
CREATE TABLE IF NOT EXISTS public.products (
  id VARCHAR(50) PRIMARY KEY,
  brand VARCHAR(100) NOT NULL,
  name VARCHAR(200) NOT NULL,
  price BIGINT NOT NULL CHECK (price >= 0),
  category VARCHAR(50) NOT NULL,
  variant VARCHAR(150),
  code VARCHAR(50) UNIQUE,
  stock INTEGER NOT NULL DEFAULT 5 CHECK (stock >= 0),
  rating NUMERIC(3, 1) DEFAULT 5.0,
  review_count INTEGER DEFAULT 0,
  is_original BOOLEAN DEFAULT TRUE,
  is_best_seller BOOLEAN DEFAULT FALSE,
  image_url TEXT NOT NULL,
  description TEXT NOT NULL,
  specs JSONB DEFAULT '{}'::jsonb,
  color_variants TEXT[] DEFAULT ARRAY['Standard'],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABEL PESANAN (ORDERS)
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  fulfillment_method fulfillment_method_enum NOT NULL,
  status order_status_enum DEFAULT 'menunggu_pembayaran' NOT NULL,
  subtotal BIGINT NOT NULL CHECK (subtotal >= 0),
  discount BIGINT DEFAULT 0 CHECK (discount >= 0),
  shipping_fee BIGINT DEFAULT 0 CHECK (shipping_fee >= 0),
  packing_fee BIGINT DEFAULT 0 CHECK (packing_fee >= 0),
  service_fee BIGINT DEFAULT 1000 CHECK (service_fee >= 0),
  total_payment BIGINT NOT NULL CHECK (total_payment >= 0),
  
  -- Info Pembayaran Transfer Bank
  payment_method payment_method_enum NOT NULL,
  payment_account_name VARCHAR(100) DEFAULT 'PT JNOVA MUSIK INDONESIA',
  payment_account_number VARCHAR(50) NOT NULL,
  payment_expiry_at TIMESTAMPTZ NOT NULL,
  payment_proof_url TEXT,
  payment_verified_at TIMESTAMPTZ,
  payment_verified_by UUID REFERENCES auth.users(id),
  
  -- Info Pengambilan di Toko
  pickup_store_id VARCHAR(50) REFERENCES public.store_branches(id),
  pickup_code VARCHAR(30),
  
  -- Info Pengiriman Kurir
  recipient_name VARCHAR(150),
  recipient_phone VARCHAR(50),
  recipient_address TEXT,
  courier_name VARCHAR(100),
  tracking_number VARCHAR(100),
  estimated_arrival VARCHAR(100),
  
  idempotency_key VARCHAR(100) UNIQUE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 7. TABEL ITEM PESANAN (ORDER ITEMS)
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id VARCHAR(50) NOT NULL REFERENCES public.products(id),
  product_name VARCHAR(200) NOT NULL,
  price_per_unit BIGINT NOT NULL CHECK (price_per_unit >= 0),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  item_total BIGINT NOT NULL CHECK (item_total >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABEL RIWAYAT TRANSAKSI POIN MEMBER
CREATE TABLE IF NOT EXISTS public.point_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  title VARCHAR(200) NOT NULL,
  category VARCHAR(100) NOT NULL,
  points INTEGER NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 9. TABEL FAVORIT PENGGUNA
CREATE TABLE IF NOT EXISTS public.user_favorites (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id VARCHAR(50) REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, product_id)
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- Profiles: User view & update own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Products & Branches: Public read
DROP POLICY IF EXISTS "Public read products" ON public.products;
CREATE POLICY "Public read products" ON public.products
  FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Public read branches" ON public.store_branches;
CREATE POLICY "Public read branches" ON public.store_branches
  FOR SELECT TO authenticated, anon USING (true);

-- Orders: User view & insert own orders
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
CREATE POLICY "Users can insert own orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Order Items
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()
    )
  );

-- Point Transactions
DROP POLICY IF EXISTS "Users can view own point history" ON public.point_transactions;
CREATE POLICY "Users can view own point history" ON public.point_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Favorites
DROP POLICY IF EXISTS "Users can manage favorites" ON public.user_favorites;
CREATE POLICY "Users can manage favorites" ON public.user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- ==============================================================================
-- STORED PROCEDURES (SERVER-AUTHORITATIVE)
-- ==============================================================================

-- Function 1: create_order_secure
CREATE OR REPLACE FUNCTION public.create_order_secure(
  p_idempotency_key VARCHAR,
  p_fulfillment fulfillment_method_enum,
  p_payment_method payment_method_enum,
  p_items JSONB,
  p_pickup_store_id VARCHAR DEFAULT NULL,
  p_shipping_fee BIGINT DEFAULT 0,
  p_packing_fee BIGINT DEFAULT 0,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_order_id UUID;
  v_order_number VARCHAR(50);
  v_subtotal BIGINT := 0;
  v_discount BIGINT := 0;
  v_service_fee BIGINT := 1000;
  v_total BIGINT := 0;
  v_item JSONB;
  v_prod RECORD;
  v_acc_num VARCHAR(50);
  v_pickup_code VARCHAR(30) := NULL;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Pengguna belum terautentikasi.';
  END IF;

  SELECT id INTO v_order_id FROM public.orders WHERE idempotency_key = p_idempotency_key;
  IF v_order_id IS NOT NULL THEN
    RETURN v_order_id;
  END IF;

  IF p_payment_method = 'bank_transfer_bca' THEN
    v_acc_num := '8841-0922-1100';
  ELSIF p_payment_method = 'bank_transfer_mandiri' THEN
    v_acc_num := '137-00-8841922-1';
  ELSE
    v_acc_num := 'QRIS-JNOVA-INSTANT';
  END IF;

  IF p_fulfillment = 'pickup' THEN
    v_pickup_code := 'PKP-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 4)) || '-JNV';
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT id, name, price, stock INTO v_prod
    FROM public.products
    WHERE id = (v_item->>'product_id')
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Produk dengan ID % tidak ditemukan.', (v_item->>'product_id');
    END IF;

    IF v_prod.stock < (v_item->>'quantity')::INT THEN
      RAISE EXCEPTION 'Stok produk % tidak mencukupi (sisa: %, diminta: %).', v_prod.name, v_prod.stock, (v_item->>'quantity');
    END IF;

    v_subtotal := v_subtotal + (v_prod.price * (v_item->>'quantity')::INT);
  END LOOP;

  v_discount := ROUND(v_subtotal * 0.10);
  v_total := v_subtotal - v_discount + p_shipping_fee + p_packing_fee + v_service_fee;
  v_order_number := '#JNV-' || TO_CHAR(NOW(), 'YYYYMM') || '-' || LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

  INSERT INTO public.orders (
    user_id,
    order_number,
    fulfillment_method,
    status,
    subtotal,
    discount,
    shipping_fee,
    packing_fee,
    service_fee,
    total_payment,
    payment_method,
    payment_account_number,
    payment_expiry_at,
    pickup_store_id,
    pickup_code,
    idempotency_key,
    notes
  ) VALUES (
    v_user_id,
    v_order_number,
    p_fulfillment,
    'menunggu_pembayaran',
    v_subtotal,
    v_discount,
    p_shipping_fee,
    p_packing_fee,
    v_service_fee,
    v_total,
    p_payment_method,
    v_acc_num,
    NOW() + INTERVAL '24 hours',
    p_pickup_store_id,
    v_pickup_code,
    p_idempotency_key,
    p_notes
  ) RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    SELECT price, name INTO v_prod FROM public.products WHERE id = (v_item->>'product_id');

    INSERT INTO public.order_items (
      order_id,
      product_id,
      product_name,
      price_per_unit,
      quantity,
      item_total
    ) VALUES (
      v_order_id,
      (v_item->>'product_id'),
      v_prod.name,
      v_prod.price,
      (v_item->>'quantity')::INT,
      v_prod.price * (v_item->>'quantity')::INT
    );

    UPDATE public.products
    SET stock = stock - (v_item->>'quantity')::INT
    WHERE id = (v_item->>'product_id');
  END LOOP;

  RETURN v_order_id;
END;
$$;

-- Function 2: verify_order_payment
CREATE OR REPLACE FUNCTION public.verify_order_payment(
  p_order_id UUID,
  p_verifier_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order RECORD;
  v_points_earned INT;
BEGIN
  SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pesanan tidak ditemukan.';
  END IF;

  IF v_order.status != 'menunggu_verifikasi' AND v_order.status != 'menunggu_pembayaran' THEN
    RAISE EXCEPTION 'Status pesanan tidak valid untuk verifikasi pembayaran.';
  END IF;

  v_points_earned := FLOOR(v_order.total_payment / 10000);

  UPDATE public.orders
  SET 
    status = CASE WHEN v_order.fulfillment_method = 'pickup' THEN 'siap_diambil'::order_status_enum ELSE 'diproses_luthier'::order_status_enum END,
    payment_verified_at = NOW(),
    payment_verified_by = p_verifier_id,
    updated_at = NOW()
  WHERE id = p_order_id;

  UPDATE public.profiles
  SET current_points = current_points + v_points_earned
  WHERE id = v_order.user_id;

  INSERT INTO public.point_transactions (
    user_id,
    order_id,
    title,
    category,
    points,
    transaction_type
  ) VALUES (
    v_order.user_id,
    v_order.id,
    'Pembelian ' || v_order.order_number,
    'Pembelian Produk',
    v_points_earned,
    'purchase'
  );

  RETURN TRUE;
END;
$$;
