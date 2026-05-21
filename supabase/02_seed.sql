-- =====================================================================
-- SEED DATA — สินค้าตัวอย่างสำหรับ Inspiration Design
-- รันหลังจาก 01_schema.sql เรียบร้อย
-- =====================================================================

-- 1. CATEGORIES
INSERT INTO categories (code, name, description, icon, display_order) VALUES
  ('STA', 'เครื่องเขียน',        'ปากกา ดินสอ สมุด ยางลบ',                 '✏️', 1),
  ('PAP', 'กระดาษ/วัสดุพิมพ์',  'กระดาษ A4 หมึกพิมพ์ ตลับหมึก',           '📄', 2),
  ('IT',  'อุปกรณ์ IT',          'เม้าส์ คีย์บอร์ด สาย Adapter',           '💻', 3),
  ('EMP', 'ของใช้พนักงาน',      'น้ำดื่ม ทิชชู่ ของใช้สิ้นเปลือง',          '🧻', 4)
ON CONFLICT (code) DO UPDATE
  SET name = EXCLUDED.name,
      icon = EXCLUDED.icon,
      description = EXCLUDED.description;

-- 2. SUPPLIERS (ตัวอย่าง — แก้ไขให้ตรงกับ supplier จริงของบริษัทได้)
INSERT INTO suppliers (code, name, contact_person, phone, email) VALUES
  ('SUP001', 'บริษัท ออฟฟิศเมท จำกัด',   'คุณสมชาย', '02-739-5555', 'sales@officemate.co.th'),
  ('SUP002', 'บริษัท บีทูเอส จำกัด',        'คุณนภา',    '02-655-7777', 'office@b2s.co.th'),
  ('SUP003', 'ร้านเอ็ม โอเอ',               'คุณเอ็ม',    '02-111-2222', NULL),
  ('SUP004', 'น้ำดื่มสปริงเคิล',             'คุณวี',      '02-333-4444', NULL)
ON CONFLICT (code) DO NOTHING;

-- 3. PRODUCTS

-- หมวด STA: เครื่องเขียน
INSERT INTO products (sku, name, description, category_id, unit, min_stock, max_stock, unit_cost, preferred_supplier_id, image_url) VALUES
  ('OFF-STA-001', 'ปากกาลูกลื่น สีน้ำเงิน 0.5mm',  'ปากกาลูกลื่นใช้ทั่วไป', (SELECT id FROM categories WHERE code='STA'), 'ด้าม', 30, 100,  8.00,  (SELECT id FROM suppliers WHERE code='SUP001'), 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400'),
  ('OFF-STA-002', 'ปากกาลูกลื่น สีดำ 0.5mm',        NULL, (SELECT id FROM categories WHERE code='STA'), 'ด้าม', 30, 100,  8.00,  (SELECT id FROM suppliers WHERE code='SUP001'), 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400'),
  ('OFF-STA-003', 'ปากกาลูกลื่น สีแดง 0.5mm',       NULL, (SELECT id FROM categories WHERE code='STA'), 'ด้าม', 10, 30,   8.00,  (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-004', 'ดินสอกด 0.5mm Pentel',           NULL, (SELECT id FROM categories WHERE code='STA'), 'ด้าม', 10, 30,   45.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-005', 'ไส้ดินสอกด 0.5mm 2B',             NULL, (SELECT id FROM categories WHERE code='STA'), 'หลอด', 10, 30,   25.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-006', 'ปากกาเน้นข้อความ Highlighter',    'สีเหลือง สีชมพู สีเขียว', (SELECT id FROM categories WHERE code='STA'), 'ด้าม', 12, 36, 25.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-007', 'สมุดโน้ตปกแข็ง A5 100แผ่น',        NULL, (SELECT id FROM categories WHERE code='STA'), 'เล่ม', 10, 30,   65.00, (SELECT id FROM suppliers WHERE code='SUP002'), NULL),
  ('OFF-STA-008', 'ยางลบ Pentel',                     NULL, (SELECT id FROM categories WHERE code='STA'), 'ก้อน',  5, 20,   12.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-009', 'น้ำยาลบคำผิด Liquid Paper',         NULL, (SELECT id FROM categories WHERE code='STA'), 'ขวด',  5, 20,   35.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-010', 'กบเหลาดินสอแบบมือหมุน',           NULL, (SELECT id FROM categories WHERE code='STA'), 'อัน',  2, 6,    180.00, NULL, NULL),
  ('OFF-STA-011', 'ลวดเย็บกระดาษ Max No.10',         '1กล่อง=1000ตัว', (SELECT id FROM categories WHERE code='STA'), 'กล่อง', 10, 30, 18.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-012', 'เครื่องเย็บกระดาษ Max No.10',       NULL, (SELECT id FROM categories WHERE code='STA'), 'อัน',  3, 10, 75.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-013', 'คลิปดำหนีบกระดาษ ขนาด 32mm',     NULL, (SELECT id FROM categories WHERE code='STA'), 'กล่อง',  5, 15, 35.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-014', 'เทปกาวใส 1นิ้ว',                    NULL, (SELECT id FROM categories WHERE code='STA'), 'ม้วน',  6, 24, 22.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL),
  ('OFF-STA-015', 'กระดาษโน้ต Post-it 3x3',          NULL, (SELECT id FROM categories WHERE code='STA'), 'แพ็ก', 10, 30, 55.00, (SELECT id FROM suppliers WHERE code='SUP001'), NULL);

-- หมวด PAP: กระดาษ/วัสดุพิมพ์
INSERT INTO products (sku, name, description, category_id, unit, min_stock, max_stock, unit_cost, preferred_supplier_id, image_url) VALUES
  ('OFF-PAP-001', 'กระดาษ A4 80gsm Double A',     'รีม 500แผ่น',  (SELECT id FROM categories WHERE code='PAP'), 'รีม',  20, 80,  125.00, (SELECT id FROM suppliers WHERE code='SUP002'), 'https://images.unsplash.com/photo-1568871391849-d7a2bb1d8c54?w=400'),
  ('OFF-PAP-002', 'กระดาษ A3 80gsm Double A',     'รีม 500แผ่น',  (SELECT id FROM categories WHERE code='PAP'), 'รีม',   5, 20,  250.00, (SELECT id FROM suppliers WHERE code='SUP002'), NULL),
  ('OFF-PAP-003', 'กระดาษ A5 70gsm',                NULL,        (SELECT id FROM categories WHERE code='PAP'), 'รีม',   5, 15,  90.00,  NULL, NULL),
  ('OFF-PAP-004', 'หมึกพิมพ์ HP 305 สีดำ',           NULL,        (SELECT id FROM categories WHERE code='PAP'), 'ตลับ',  2, 8,  680.00, (SELECT id FROM suppliers WHERE code='SUP003'), NULL),
  ('OFF-PAP-005', 'หมึกพิมพ์ HP 305 สี',              NULL,        (SELECT id FROM categories WHERE code='PAP'), 'ตลับ',  2, 8,  780.00, (SELECT id FROM suppliers WHERE code='SUP003'), NULL),
  ('OFF-PAP-006', 'หมึก Canon PG-47 สีดำ',           NULL,        (SELECT id FROM categories WHERE code='PAP'), 'ตลับ',  2, 6,  450.00, (SELECT id FROM suppliers WHERE code='SUP003'), NULL),
  ('OFF-PAP-007', 'กระดาษถ่ายเอกสารสี A4',          'แพ็ก 100แผ่น คละสี', (SELECT id FROM categories WHERE code='PAP'), 'แพ็ก', 3, 10, 95.00, NULL, NULL),
  ('OFF-PAP-008', 'ซองจดหมาย C5 สีขาว',              NULL,        (SELECT id FROM categories WHERE code='PAP'), 'กล่อง',  3, 10, 120.00, (SELECT id FROM suppliers WHERE code='SUP002'), NULL),
  ('OFF-PAP-009', 'กระดาษคาร์บอน A4 น้ำเงิน',         '100แผ่น',  (SELECT id FROM categories WHERE code='PAP'), 'แพ็ก',  2, 6,  95.00, NULL, NULL),
  ('OFF-PAP-010', 'สติ๊กเกอร์ A4 100แผ่น',             NULL,        (SELECT id FROM categories WHERE code='PAP'), 'แพ็ก',  3, 10, 150.00, NULL, NULL);

-- หมวด IT: อุปกรณ์ IT
INSERT INTO products (sku, name, description, category_id, unit, min_stock, max_stock, unit_cost, preferred_supplier_id, image_url) VALUES
  ('OFF-IT-001',  'เม้าส์ Logitech M170 Wireless', NULL,        (SELECT id FROM categories WHERE code='IT'),  'ตัว',   3, 10, 450.00, (SELECT id FROM suppliers WHERE code='SUP003'), 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=400'),
  ('OFF-IT-002',  'คีย์บอร์ด Logitech K120 USB',    NULL,        (SELECT id FROM categories WHERE code='IT'),  'ตัว',   2, 8,  550.00, (SELECT id FROM suppliers WHERE code='SUP003'), NULL),
  ('OFF-IT-003',  'สาย HDMI 1.5m',                  NULL,        (SELECT id FROM categories WHERE code='IT'),  'เส้น',  3, 10, 220.00, NULL, NULL),
  ('OFF-IT-004',  'สาย LAN Cat6 3m',                NULL,        (SELECT id FROM categories WHERE code='IT'),  'เส้น',  3, 10, 180.00, NULL, NULL),
  ('OFF-IT-005',  'USB Flash Drive 32GB SanDisk',  NULL,        (SELECT id FROM categories WHERE code='IT'),  'อัน',   3, 10, 280.00, (SELECT id FROM suppliers WHERE code='SUP003'), NULL),
  ('OFF-IT-006',  'ปลั๊กไฟ 5ช่อง 3m',                NULL,        (SELECT id FROM categories WHERE code='IT'),  'อัน',   2, 8,  450.00, NULL, NULL),
  ('OFF-IT-007',  'ถ่าน AA Energizer 4ก้อน',         NULL,        (SELECT id FROM categories WHERE code='IT'),  'แพ็ก',  5, 20, 120.00, NULL, NULL),
  ('OFF-IT-008',  'ถ่าน AAA Energizer 4ก้อน',        NULL,        (SELECT id FROM categories WHERE code='IT'),  'แพ็ก',  5, 20, 120.00, NULL, NULL),
  ('OFF-IT-009',  'หูฟัง USB พร้อมไมโครโฟน',         NULL,        (SELECT id FROM categories WHERE code='IT'),  'ตัว',   2, 6,  650.00, NULL, NULL),
  ('OFF-IT-010',  'เม้าสแพด',                       NULL,        (SELECT id FROM categories WHERE code='IT'),  'แผ่น',  3, 10, 80.00,  NULL, NULL);

-- หมวด EMP: ของใช้พนักงาน
INSERT INTO products (sku, name, description, category_id, unit, min_stock, max_stock, unit_cost, preferred_supplier_id, image_url) VALUES
  ('OFF-EMP-001', 'น้ำดื่ม 600ml ขวด',                'แพ็ก 12ขวด', (SELECT id FROM categories WHERE code='EMP'), 'แพ็ก', 10, 40, 60.00,   (SELECT id FROM suppliers WHERE code='SUP004'), 'https://images.unsplash.com/photo-1564419320461-6870880221ad?w=400'),
  ('OFF-EMP-002', 'น้ำดื่มถังเล็ก 18.9L',              NULL,        (SELECT id FROM categories WHERE code='EMP'), 'ถัง',   5, 20, 75.00,   (SELECT id FROM suppliers WHERE code='SUP004'), NULL),
  ('OFF-EMP-003', 'ทิชชู่ม้วน Scott',                  '1แพ็ก=12ม้วน', (SELECT id FROM categories WHERE code='EMP'), 'แพ็ก', 5, 20, 180.00, NULL, 'https://images.unsplash.com/photo-1583947581924-860bda3afe39?w=400'),
  ('OFF-EMP-004', 'ทิชชู่กล่อง Cellox',                '1แพ็ก=6กล่อง',  (SELECT id FROM categories WHERE code='EMP'), 'แพ็ก', 5, 15, 120.00, NULL, NULL),
  ('OFF-EMP-005', 'แอลกอฮอล์เจล 500ml',              NULL,        (SELECT id FROM categories WHERE code='EMP'), 'ขวด',   5, 20, 95.00,  NULL, NULL),
  ('OFF-EMP-006', 'หน้ากากอนามัย กล่อง 50ชิ้น',       NULL,        (SELECT id FROM categories WHERE code='EMP'), 'กล่อง', 3, 12, 65.00, NULL, NULL),
  ('OFF-EMP-007', 'กาแฟสำเร็จรูป Nescafe 3in1',      'แพ็ก 27ซอง',  (SELECT id FROM categories WHERE code='EMP'), 'แพ็ก',  5, 15, 95.00, NULL, NULL),
  ('OFF-EMP-008', 'น้ำตาลทราย 1กก.',                  NULL,        (SELECT id FROM categories WHERE code='EMP'), 'ถุง',   3, 8,  30.00,  NULL, NULL),
  ('OFF-EMP-009', 'แก้วกระดาษใช้แล้วทิ้ง 50ใบ',       NULL,        (SELECT id FROM categories WHERE code='EMP'), 'แพ็ก',  3, 10, 35.00,  NULL, NULL),
  ('OFF-EMP-010', 'น้ำยาเช็ดกระจก Mr.Muscle 500ml', NULL,        (SELECT id FROM categories WHERE code='EMP'), 'ขวด',   2, 8,  85.00,  NULL, NULL);

-- 4. STOCK เริ่มต้น (รับเข้าครั้งแรก) — เติมให้ทุกสินค้าเริ่มต้นที่ ~80% ของ max_stock
DO $$
DECLARE
  v_product products%ROWTYPE;
  v_init_qty NUMERIC;
BEGIN
  FOR v_product IN SELECT * FROM products WHERE current_stock = 0 LOOP
    v_init_qty := GREATEST(FLOOR(v_product.max_stock * 0.8), v_product.min_stock + 5);

    UPDATE products SET current_stock = v_init_qty WHERE id = v_product.id;

    INSERT INTO stock_movements(
      product_id, movement_type, quantity, unit_cost, balance_after,
      reference_type, reference_no, notes
    ) VALUES (
      v_product.id, 'IN', v_init_qty, v_product.unit_cost, v_init_qty,
      'init', 'INIT-2026', 'Stock เริ่มต้นระบบ'
    );
  END LOOP;
END $$;

-- 5. จำลองการเบิกย้อนหลัง (เพื่อให้ dashboard มีข้อมูลแสดง) — สร้างเฉพาะถ้ายังไม่มี user จริง
-- พี่หนึ่ง: ส่วนนี้จะ run ก็ต่อเมื่อมี user ในระบบแล้ว
-- (skip ถ้าไม่มี profiles)

-- END SEED
