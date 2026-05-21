-- =====================================================================
-- INSPIRATION DESIGN - Office Supply Requisition System
-- Database Schema for Supabase (PostgreSQL)
-- Version: 1.0
-- Author: Jarvis for พี่หนึ่ง
-- =====================================================================

-- =====================================================================
-- 1. EXTENSIONS
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================================
-- 2. ENUMS
-- =====================================================================
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'manager', 'staff');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE movement_type AS ENUM ('IN', 'OUT', 'ADJUST');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE requisition_status AS ENUM ('pending', 'approved', 'rejected', 'issued', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- =====================================================================
-- 3. PROFILES (linked to auth.users)
-- =====================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  nickname TEXT,
  department TEXT,
  phone TEXT,
  role user_role DEFAULT 'staff' NOT NULL,
  avatar_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto create profile when new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'staff'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================================
-- 4. CATEGORIES
-- =====================================================================
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,           -- e.g. STA, PAP, IT, EMP
  name TEXT NOT NULL,                  -- ชื่อหมวด
  description TEXT,
  icon TEXT,                           -- emoji or icon name
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 5. SUPPLIERS
-- =====================================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================================
-- 6. PRODUCTS (สินค้าหลัก)
-- =====================================================================
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,            -- รหัสสินค้า เช่น OFF-STA-001
  name TEXT NOT NULL,                  -- ชื่อสินค้า
  description TEXT,
  category_id INT REFERENCES categories(id) ON DELETE SET NULL,
  unit TEXT NOT NULL DEFAULT 'ชิ้น',   -- หน่วยนับ
  image_url TEXT,                      -- รูปสินค้า (Supabase Storage)
  current_stock NUMERIC(12,2) DEFAULT 0 NOT NULL,
  min_stock NUMERIC(12,2) DEFAULT 0,   -- Reorder Point จุดสั่งซื้อ
  max_stock NUMERIC(12,2) DEFAULT 0,   -- จำนวนสต๊อกสูงสุด
  unit_cost NUMERIC(12,2) DEFAULT 0,   -- ต้นทุนเฉลี่ย
  preferred_supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
  is_frequent BOOLEAN DEFAULT FALSE,   -- สินค้าใช้บ่อย (Auto-flag จาก trigger)
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active) WHERE is_active = TRUE;

-- Auto-generate SKU function
CREATE OR REPLACE FUNCTION generate_sku(cat_code TEXT)
RETURNS TEXT AS $$
DECLARE
  next_num INT;
  new_sku TEXT;
BEGIN
  SELECT COALESCE(MAX(CAST(SPLIT_PART(sku, '-', 3) AS INT)), 0) + 1
  INTO next_num
  FROM products
  WHERE sku LIKE 'OFF-' || cat_code || '-%';
  new_sku := 'OFF-' || cat_code || '-' || LPAD(next_num::TEXT, 3, '0');
  RETURN new_sku;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 7. STOCK MOVEMENTS (Ledger - บันทึกการเคลื่อนไหวทุกครั้ง)
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id BIGSERIAL PRIMARY KEY,
  product_id INT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  movement_type movement_type NOT NULL,
  quantity NUMERIC(12,2) NOT NULL,     -- + สำหรับ IN, - สำหรับ OUT
  unit_cost NUMERIC(12,2),
  balance_after NUMERIC(12,2),         -- สต๊อกคงเหลือหลังการเคลื่อนไหว
  reference_type TEXT,                 -- 'requisition', 'receive', 'adjust', 'init'
  reference_id BIGINT,                 -- ID ของเอกสารอ้างอิง
  reference_no TEXT,                   -- เลขที่เอกสาร เช่น PO-001, REQ-001
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_movements_product ON stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_movements_date ON stock_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_movements_type ON stock_movements(movement_type);

-- =====================================================================
-- 8. REQUISITIONS (ใบเบิก - Header)
-- =====================================================================
CREATE TABLE IF NOT EXISTS requisitions (
  id BIGSERIAL PRIMARY KEY,
  req_no TEXT UNIQUE NOT NULL,         -- REQ-2026-0001
  requested_by UUID NOT NULL REFERENCES profiles(id),
  department TEXT,
  purpose TEXT,                        -- วัตถุประสงค์การเบิก
  status requisition_status DEFAULT 'pending' NOT NULL,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  issued_by UUID REFERENCES profiles(id),
  issued_at TIMESTAMPTZ,
  total_items INT DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_req_status ON requisitions(status);
CREATE INDEX IF NOT EXISTS idx_req_requester ON requisitions(requested_by);
CREATE INDEX IF NOT EXISTS idx_req_date ON requisitions(created_at DESC);

-- Auto-generate Requisition No.
CREATE OR REPLACE FUNCTION generate_req_no()
RETURNS TRIGGER AS $$
DECLARE
  year_part TEXT;
  next_num INT;
BEGIN
  IF NEW.req_no IS NULL OR NEW.req_no = '' THEN
    year_part := TO_CHAR(NOW(), 'YYYY');
    SELECT COALESCE(MAX(CAST(SPLIT_PART(req_no, '-', 3) AS INT)), 0) + 1
    INTO next_num
    FROM requisitions
    WHERE req_no LIKE 'REQ-' || year_part || '-%';
    NEW.req_no := 'REQ-' || year_part || '-' || LPAD(next_num::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gen_req_no ON requisitions;
CREATE TRIGGER trg_gen_req_no
  BEFORE INSERT ON requisitions
  FOR EACH ROW EXECUTE FUNCTION generate_req_no();

-- =====================================================================
-- 9. REQUISITION ITEMS (Line)
-- =====================================================================
CREATE TABLE IF NOT EXISTS requisition_items (
  id BIGSERIAL PRIMARY KEY,
  requisition_id BIGINT NOT NULL REFERENCES requisitions(id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(id),
  quantity_requested NUMERIC(12,2) NOT NULL CHECK (quantity_requested > 0),
  quantity_approved NUMERIC(12,2),
  quantity_issued NUMERIC(12,2),
  unit TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reqitems_req ON requisition_items(requisition_id);
CREATE INDEX IF NOT EXISTS idx_reqitems_prod ON requisition_items(product_id);

-- =====================================================================
-- 10. RECEIVING (รับสินค้าเข้า - Header)
-- =====================================================================
CREATE TABLE IF NOT EXISTS receivings (
  id BIGSERIAL PRIMARY KEY,
  receive_no TEXT UNIQUE NOT NULL,     -- RCV-2026-0001
  supplier_id INT REFERENCES suppliers(id),
  po_reference TEXT,                   -- เลข PO อ้างอิง
  received_by UUID REFERENCES profiles(id),
  received_at TIMESTAMPTZ DEFAULT NOW(),
  total_amount NUMERIC(14,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS receiving_items (
  id BIGSERIAL PRIMARY KEY,
  receiving_id BIGINT NOT NULL REFERENCES receivings(id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(id),
  quantity NUMERIC(12,2) NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
  notes TEXT
);

-- Auto-generate Receive No.
CREATE OR REPLACE FUNCTION generate_receive_no()
RETURNS TRIGGER AS $$
DECLARE
  year_part TEXT;
  next_num INT;
BEGIN
  IF NEW.receive_no IS NULL OR NEW.receive_no = '' THEN
    year_part := TO_CHAR(NOW(), 'YYYY');
    SELECT COALESCE(MAX(CAST(SPLIT_PART(receive_no, '-', 3) AS INT)), 0) + 1
    INTO next_num
    FROM receivings
    WHERE receive_no LIKE 'RCV-' || year_part || '-%';
    NEW.receive_no := 'RCV-' || year_part || '-' || LPAD(next_num::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gen_receive_no ON receivings;
CREATE TRIGGER trg_gen_receive_no
  BEFORE INSERT ON receivings
  FOR EACH ROW EXECUTE FUNCTION generate_receive_no();

-- =====================================================================
-- 11. CORE BUSINESS FUNCTIONS
-- =====================================================================

-- Function: Receive Stock (รับสินค้าเข้า)
CREATE OR REPLACE FUNCTION receive_stock(
  p_product_id INT,
  p_quantity NUMERIC,
  p_unit_cost NUMERIC,
  p_reference_id BIGINT,
  p_reference_no TEXT,
  p_user_id UUID,
  p_notes TEXT DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
  v_new_balance NUMERIC;
  v_current_stock NUMERIC;
  v_current_cost NUMERIC;
  v_new_cost NUMERIC;
BEGIN
  -- Get current stock and cost
  SELECT current_stock, unit_cost INTO v_current_stock, v_current_cost
  FROM products WHERE id = p_product_id FOR UPDATE;

  -- Weighted average cost calculation
  IF v_current_stock > 0 THEN
    v_new_cost := ROUND(
      ((v_current_stock * COALESCE(v_current_cost,0)) + (p_quantity * p_unit_cost))
      / (v_current_stock + p_quantity), 2);
  ELSE
    v_new_cost := p_unit_cost;
  END IF;

  v_new_balance := v_current_stock + p_quantity;

  -- Update product
  UPDATE products
  SET current_stock = v_new_balance,
      unit_cost = v_new_cost,
      updated_at = NOW()
  WHERE id = p_product_id;

  -- Insert movement
  INSERT INTO stock_movements(
    product_id, movement_type, quantity, unit_cost, balance_after,
    reference_type, reference_id, reference_no, created_by, notes
  ) VALUES (
    p_product_id, 'IN', p_quantity, p_unit_cost, v_new_balance,
    'receive', p_reference_id, p_reference_no, p_user_id, p_notes
  );

  RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Issue Stock (จ่ายออก)
CREATE OR REPLACE FUNCTION issue_stock(
  p_product_id INT,
  p_quantity NUMERIC,
  p_reference_id BIGINT,
  p_reference_no TEXT,
  p_user_id UUID,
  p_notes TEXT DEFAULT NULL
) RETURNS NUMERIC AS $$
DECLARE
  v_new_balance NUMERIC;
  v_current_stock NUMERIC;
  v_current_cost NUMERIC;
BEGIN
  SELECT current_stock, unit_cost INTO v_current_stock, v_current_cost
  FROM products WHERE id = p_product_id FOR UPDATE;

  IF v_current_stock < p_quantity THEN
    RAISE EXCEPTION 'สต๊อกไม่พอ — มีอยู่ % แต่จะเบิก %', v_current_stock, p_quantity;
  END IF;

  v_new_balance := v_current_stock - p_quantity;

  UPDATE products
  SET current_stock = v_new_balance,
      updated_at = NOW()
  WHERE id = p_product_id;

  INSERT INTO stock_movements(
    product_id, movement_type, quantity, unit_cost, balance_after,
    reference_type, reference_id, reference_no, created_by, notes
  ) VALUES (
    p_product_id, 'OUT', -p_quantity, v_current_cost, v_new_balance,
    'requisition', p_reference_id, p_reference_no, p_user_id, p_notes
  );

  RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Issue All Items of an Approved Requisition
CREATE OR REPLACE FUNCTION issue_requisition(p_req_id BIGINT, p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_req requisitions%ROWTYPE;
  v_item requisition_items%ROWTYPE;
BEGIN
  SELECT * INTO v_req FROM requisitions WHERE id = p_req_id FOR UPDATE;
  IF v_req.status <> 'approved' THEN
    RAISE EXCEPTION 'ใบเบิกนี้ยังไม่ได้รับการอนุมัติ (สถานะปัจจุบัน: %)', v_req.status;
  END IF;

  FOR v_item IN SELECT * FROM requisition_items WHERE requisition_id = p_req_id LOOP
    PERFORM issue_stock(
      v_item.product_id,
      COALESCE(v_item.quantity_approved, v_item.quantity_requested),
      p_req_id,
      v_req.req_no,
      p_user_id,
      'เบิกตามใบ ' || v_req.req_no
    );
    UPDATE requisition_items
    SET quantity_issued = COALESCE(quantity_approved, quantity_requested)
    WHERE id = v_item.id;
  END LOOP;

  UPDATE requisitions
  SET status = 'issued', issued_by = p_user_id, issued_at = NOW(), updated_at = NOW()
  WHERE id = p_req_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 12. VIEWS (สำหรับ Reporting)
-- =====================================================================

-- View: สินค้าใกล้หมด
CREATE OR REPLACE VIEW v_low_stock AS
SELECT
  p.id, p.sku, p.name, p.unit, p.current_stock, p.min_stock, p.max_stock,
  c.name AS category_name, c.icon AS category_icon,
  CASE
    WHEN p.current_stock <= 0 THEN 'out_of_stock'
    WHEN p.current_stock <= p.min_stock THEN 'low'
    ELSE 'ok'
  END AS stock_status,
  CASE
    WHEN p.max_stock > 0 THEN GREATEST(p.max_stock - p.current_stock, 0)
    ELSE GREATEST(p.min_stock * 2 - p.current_stock, 0)
  END AS suggested_reorder
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE p.is_active = TRUE
  AND (p.current_stock <= p.min_stock OR p.current_stock <= 0);

-- View: สรุปการเบิก
CREATE OR REPLACE VIEW v_requisition_summary AS
SELECT
  r.id, r.req_no, r.status,
  p.full_name AS requester, r.department, r.purpose,
  r.created_at, r.approved_at, r.issued_at,
  COUNT(ri.id) AS item_count,
  SUM(ri.quantity_requested) AS total_qty_requested,
  SUM(ri.quantity_issued) AS total_qty_issued
FROM requisitions r
LEFT JOIN profiles p ON p.id = r.requested_by
LEFT JOIN requisition_items ri ON ri.requisition_id = r.id
GROUP BY r.id, p.full_name;

-- View: Top Consumed Items (สินค้าใช้บ่อย 30 วันล่าสุด)
CREATE OR REPLACE VIEW v_top_consumed AS
SELECT
  p.id, p.sku, p.name, p.unit, p.image_url,
  c.name AS category_name,
  ABS(SUM(sm.quantity)) AS total_consumed,
  COUNT(DISTINCT sm.reference_id) AS times_requested,
  p.current_stock, p.min_stock
FROM products p
JOIN stock_movements sm ON sm.product_id = p.id
LEFT JOIN categories c ON c.id = p.category_id
WHERE sm.movement_type = 'OUT'
  AND sm.created_at >= NOW() - INTERVAL '30 days'
  AND p.is_active = TRUE
GROUP BY p.id, c.name
ORDER BY total_consumed DESC;

-- View: Movement History พร้อมรายละเอียด
CREATE OR REPLACE VIEW v_movement_history AS
SELECT
  sm.id, sm.created_at, sm.movement_type, sm.quantity, sm.balance_after,
  sm.reference_no, sm.notes,
  p.sku, p.name AS product_name, p.unit,
  pr.full_name AS user_name
FROM stock_movements sm
JOIN products p ON p.id = sm.product_id
LEFT JOIN profiles pr ON pr.id = sm.created_by
ORDER BY sm.created_at DESC;

-- =====================================================================
-- 13. AUTO-FLAG FREQUENT ITEMS (รัน trigger ทุกๆ requisition_item)
-- =====================================================================
CREATE OR REPLACE FUNCTION update_frequent_items()
RETURNS VOID AS $$
BEGIN
  -- รีเซ็ตทั้งหมด
  UPDATE products SET is_frequent = FALSE;
  -- ตั้งใหม่ตาม Top 20% ของสินค้าที่ถูกเบิกใน 60 วันล่าสุด
  WITH ranked AS (
    SELECT product_id,
           ABS(SUM(quantity)) AS total_qty,
           NTILE(5) OVER (ORDER BY ABS(SUM(quantity)) DESC) AS tile
    FROM stock_movements
    WHERE movement_type = 'OUT'
      AND created_at >= NOW() - INTERVAL '60 days'
    GROUP BY product_id
  )
  UPDATE products SET is_frequent = TRUE
  WHERE id IN (SELECT product_id FROM ranked WHERE tile = 1);
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 14. ROW LEVEL SECURITY (RLS)
-- =====================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE requisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE requisition_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE receivings ENABLE ROW LEVEL SECURITY;
ALTER TABLE receiving_items ENABLE ROW LEVEL SECURITY;

-- Helper function เช็ค role
CREATE OR REPLACE FUNCTION is_admin_or_manager()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND role IN ('admin', 'manager')
      AND is_active = TRUE
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin' AND is_active = TRUE
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Profiles: ทุกคนอ่านได้ (เพื่อแสดงชื่อ) แก้ไขเฉพาะของตัวเอง / admin แก้ของคนอื่นได้
DROP POLICY IF EXISTS p_profiles_read ON profiles;
CREATE POLICY p_profiles_read ON profiles FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS p_profiles_update_self ON profiles;
CREATE POLICY p_profiles_update_self ON profiles FOR UPDATE
  USING (id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS p_profiles_admin_all ON profiles;
CREATE POLICY p_profiles_admin_all ON profiles FOR ALL USING (is_admin());

-- Categories / Suppliers: ทุกคนอ่านได้ จัดการได้เฉพาะ admin/manager
DROP POLICY IF EXISTS p_cat_read ON categories;
CREATE POLICY p_cat_read ON categories FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS p_cat_mod ON categories;
CREATE POLICY p_cat_mod ON categories FOR ALL USING (is_admin_or_manager());

DROP POLICY IF EXISTS p_sup_read ON suppliers;
CREATE POLICY p_sup_read ON suppliers FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS p_sup_mod ON suppliers;
CREATE POLICY p_sup_mod ON suppliers FOR ALL USING (is_admin_or_manager());

-- Products: ทุกคนอ่านได้ จัดการได้เฉพาะ admin/manager
DROP POLICY IF EXISTS p_prod_read ON products;
CREATE POLICY p_prod_read ON products FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS p_prod_mod ON products;
CREATE POLICY p_prod_mod ON products FOR ALL USING (is_admin_or_manager());

-- Stock Movements: อ่านได้ทุกคน / system function เป็นคน insert
DROP POLICY IF EXISTS p_mov_read ON stock_movements;
CREATE POLICY p_mov_read ON stock_movements FOR SELECT USING (auth.role() = 'authenticated');
DROP POLICY IF EXISTS p_mov_mod ON stock_movements;
CREATE POLICY p_mov_mod ON stock_movements FOR ALL USING (is_admin_or_manager());

-- Requisitions: staff เห็นเฉพาะของตัวเอง, admin/manager เห็นทั้งหมด
DROP POLICY IF EXISTS p_req_read ON requisitions;
CREATE POLICY p_req_read ON requisitions FOR SELECT
  USING (requested_by = auth.uid() OR is_admin_or_manager());

DROP POLICY IF EXISTS p_req_insert ON requisitions;
CREATE POLICY p_req_insert ON requisitions FOR INSERT WITH CHECK (requested_by = auth.uid());

DROP POLICY IF EXISTS p_req_update ON requisitions;
CREATE POLICY p_req_update ON requisitions FOR UPDATE
  USING ((requested_by = auth.uid() AND status = 'pending') OR is_admin_or_manager());

DROP POLICY IF EXISTS p_req_delete ON requisitions;
CREATE POLICY p_req_delete ON requisitions FOR DELETE
  USING ((requested_by = auth.uid() AND status = 'pending') OR is_admin());

-- Requisition Items: ตามใบเบิกของมัน
DROP POLICY IF EXISTS p_ri_read ON requisition_items;
CREATE POLICY p_ri_read ON requisition_items FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM requisitions r WHERE r.id = requisition_id
      AND (r.requested_by = auth.uid() OR is_admin_or_manager())
  ));

DROP POLICY IF EXISTS p_ri_mod ON requisition_items;
CREATE POLICY p_ri_mod ON requisition_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM requisitions r WHERE r.id = requisition_id
      AND ((r.requested_by = auth.uid() AND r.status = 'pending') OR is_admin_or_manager())
  ));

-- Receivings: เฉพาะ admin/manager
DROP POLICY IF EXISTS p_rcv_all ON receivings;
CREATE POLICY p_rcv_all ON receivings FOR ALL USING (is_admin_or_manager());

DROP POLICY IF EXISTS p_rcvi_all ON receiving_items;
CREATE POLICY p_rcvi_all ON receiving_items FOR ALL USING (is_admin_or_manager());

-- =====================================================================
-- 15. STORAGE BUCKET FOR PRODUCT IMAGES
-- =====================================================================
-- รันคำสั่งนี้ใน Supabase Dashboard > Storage หรือใช้ SQL ด้านล่าง:
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: ทุกคนอ่านได้ / admin upload ได้
DO $$ BEGIN
  CREATE POLICY "public read product images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'product-images');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "admin upload product images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'product-images' AND is_admin_or_manager());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "admin update product images"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'product-images' AND is_admin_or_manager());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =====================================================================
-- END OF SCHEMA
-- =====================================================================
