# Inspiration Stock — ระบบเบิกสินค้าออนไลน์

ระบบเบิก-รับสินค้าสำนักงาน สำหรับ **อินสไปเรชั่น ดีไซน์** ใช้งานผ่านมือถือได้เหมือนแอป (PWA) เก็บข้อมูลบน Supabase ฟรี

## ฟีเจอร์

**สำหรับผู้เบิก (มือถือ)**
- ดูสินค้าทั้งหมดพร้อมรูป รหัส คงเหลือ
- เบิกของแบบตะกร้า เลือกได้หลายรายการในใบเดียว
- ค้นหา/กรองตามหมวด
- เห็นสินค้าใช้บ่อยขึ้นด้านบน (Quick Add)
- ดูประวัติการเบิกของตัวเอง
- ติดตั้งบนหน้าโฮมเหมือนแอปได้ (PWA)

**สำหรับ Admin/Manager**
- Dashboard สรุปยอดสต๊อก/มูลค่า/รายการรออนุมัติ
- กราฟรับ-จ่าย 14 วันล่าสุด
- รับสินค้าเข้า (Stock In) + คำนวณต้นทุนเฉลี่ยถ่วงน้ำหนัก (Weighted Average Cost)
- อนุมัติ/ไม่อนุมัติใบเบิก + ปรับจำนวนได้
- จ่ายของออก (Issue) — ระบบหักสต๊อกอัตโนมัติ
- จัดการสินค้า เพิ่ม/แก้ไข/อัปโหลดรูป รหัส auto-gen
- รายงาน Top สินค้าใช้บ่อย, Reorder List, ประวัติการเคลื่อนไหว — Export CSV ได้

**ระบบช่วยตัดสินใจ**
- เตือนสินค้าใกล้หมด/หมด (ตาม Min Stock)
- คำนวณจำนวนแนะนำสั่ง (Suggested Reorder)
- Auto-flag สินค้าใช้บ่อย (Top 20% ใน 60 วัน)

---

## โครงสร้างโฟลเดอร์

```
inspiration-stock/
├── README.md                  คู่มือนี้
├── supabase/
│   ├── 01_schema.sql          โครงสร้าง Database + RLS + Functions
│   └── 02_seed.sql            สินค้าตัวอย่าง 45+ รายการ
├── public/                    ไฟล์ที่ deploy ขึ้น web
│   ├── index.html             หน้า Login/Register
│   ├── requisition.html       หน้าเบิกของ (มือถือ)
│   ├── dashboard.html         Dashboard
│   ├── approve.html           อนุมัติใบเบิก
│   ├── receive.html           รับสินค้าเข้า
│   ├── products.html          จัดการสินค้า
│   ├── report.html            รายงาน
│   ├── manifest.json          PWA manifest
│   ├── sw.js                  Service Worker
│   └── js/
│       ├── config.js          Supabase config + helpers
│       └── sidebar.js         Topbar component
└── .github/workflows/
    └── deploy.yml             Auto deploy to GitHub Pages
```

---

## วิธี Setup (ทีละขั้น)

### ขั้นที่ 1: สร้าง Database ใน Supabase

1. เข้า **[supabase.com](https://supabase.com)** → เปิด Project ที่มีอยู่
2. ไปที่ `SQL Editor` (เมนูซ้าย ไอคอนคล้ายโน้ตบุ๊ก)
3. กด `+ New query`
4. เปิดไฟล์ `supabase/01_schema.sql` → คัดลอกทั้งหมด → วางแล้วกด **RUN**
5. รอจน success — จะได้ tables, functions, RLS policies, storage bucket
6. กด `+ New query` อีกครั้ง → เปิด `supabase/02_seed.sql` → คัดลอก → RUN
7. ตอนนี้จะมีสินค้าตัวอย่าง 45 รายการ + Stock เริ่มต้น

### ขั้นที่ 2: ตั้งค่า Authentication

1. ไปที่ `Authentication` → `Providers` ตรวจสอบว่า **Email** เปิดอยู่
2. ปิด `Confirm email` ถ้าไม่ต้องการให้รอยืนยันอีเมล (`Authentication > Settings > Auth Providers > Email`)
3. ไปที่ `URL Configuration` → กรอก Site URL ของ web ที่จะ deploy (เช่น `https://yourname.github.io` หรือ `https://your-app.vercel.app`)

### ขั้นที่ 3: สร้าง Admin คนแรก (พี่หนึ่ง)

1. สมัครผ่านหน้า web (`index.html`) ด้วยอีเมล `isrd01headoffice@gmail.com`
2. กลับมาที่ Supabase → `SQL Editor` รัน
   ```sql
   UPDATE profiles SET role = 'admin' WHERE id = (
     SELECT id FROM auth.users WHERE email = 'isrd01headoffice@gmail.com'
   );
   ```

### ขั้นที่ 4: เอา Supabase URL + Anon Key

1. ใน Supabase ไปที่ `Project Settings` → `API`
2. คัดลอก **Project URL** (เช่น `https://xxxx.supabase.co`)
3. คัดลอก **anon public key**
4. เปิดไฟล์ `public/js/config.js` แก้ 2 บรรทัด

   ```javascript
   const SUPABASE_CONFIG = {
     URL: 'https://YOUR-PROJECT-REF.supabase.co',     ← ใส่ URL ที่คัดลอกมา
     ANON_KEY: 'YOUR-ANON-KEY-HERE',                  ← ใส่ anon key
   };
   ```

### ขั้นที่ 5: Deploy ไปที่ GitHub

1. สร้าง repo ใหม่ใน GitHub (เช่น `inspiration-stock`)
2. ในเครื่อง:
   ```bash
   cd inspiration-stock
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOURUSER/inspiration-stock.git
   git push -u origin main
   ```

### ขั้นที่ 6: เปิด GitHub Pages

1. ใน GitHub repo → `Settings` → `Pages`
2. **Source:** Deploy from a branch
3. **Branch:** `main` / Folder: `/public`
4. กด `Save` รอ 1-2 นาที จะได้ URL เช่น `https://yourname.github.io/inspiration-stock/`

> **ทางเลือก: ใช้ Vercel แทน** (เร็วและเสถียรกว่า)
> 1. เข้า [vercel.com](https://vercel.com) → Import Project จาก GitHub
> 2. Root Directory: `public`
> 3. Build Command: เว้นว่าง
> 4. กด Deploy เสร็จในไม่กี่วินาที

### ขั้นที่ 7: ติดตั้งเป็น App บนมือถือ

1. เปิด URL ของระบบในมือถือ (Safari บน iPhone, Chrome บน Android)
2. กดปุ่ม Share → **Add to Home Screen**
3. จะมีไอคอนแอป Inspiration Stock บนหน้าโฮม

---

## วิธีใช้งานประจำวัน

### พนักงานทั่วไป (ผู้เบิก)
1. เปิดแอป → Login
2. เลือกสินค้าที่ต้องการ กดปุ่ม `+` เพิ่มในตะกร้า
3. กดปุ่มตะกร้าด้านล่างขวา → ใส่วัตถุประสงค์ → ส่งใบเบิก
4. รอ admin อนุมัติ → มารับของที่คลัง
5. ดูประวัติได้จากไอคอนนาฬิกาด้านบน

### พี่หนึ่ง / Admin
- **Dashboard:** เห็นภาพรวมทุกเช้า รออนุมัติเท่าไหร่ ใกล้หมดเท่าไหร่
- **อนุมัติ:** กด tab "รออนุมัติ" → เลือกใบ → ตรวจจำนวน → อนุมัติ
- **จ่ายของ:** หลังอนุมัติแล้ว เปิดใบเดิม → กด "จ่ายของออกจากคลัง" → สต๊อกหักให้
- **รับเข้า:** เมื่อ supplier ส่งของ → เลือก supplier → เพิ่มรายการ → บันทึก
- **รายงาน:** ใช้ Export CSV ไป Excel ตอนปลายเดือนเพื่อทำรายงาน

---

## ฟีเจอร์ที่เพิ่มในอนาคต (Roadmap)

| ฟีเจอร์ | ความสำคัญ | หมายเหตุ |
|---------|-----------|----------|
| Barcode scanner เบิกเร็วขึ้น | สูง | ใช้กล้องมือถือ scan รหัสสินค้า |
| Auto-create PO ส่ง supplier | สูง | กดแล้วระบบทำ PO เป็น PDF ส่งเมล |
| LINE Notify เตือนใกล้หมด | กลาง | ตั้ง webhook ส่งเข้ากลุ่ม LINE คลัง |
| ตั้งโควต้าแผนกต่อเดือน | กลาง | เช่นฝ่ายการตลาดเบิก HighlighterไดŠ้ไม่เกิน 5 ด้าม/เดือน |
| Multi-warehouse | ต่ำ | ถ้ามีหลายคลัง |
| รายงาน ABC Analysis | กลาง | จัดสินค้าเป็น A/B/C ตามมูลค่า |

---

## คำถามที่พบบ่อย

**Q: ทำไมต้องใช้ Supabase ไม่ใช้ Google Sheet?**
A: เร็วกว่า ปลอดภัยกว่า มี RLS (Row Level Security) ป้องกันคนนอกแก้ข้อมูล รองรับ realtime — ถ้า admin อนุมัติ ฝั่งผู้เบิกเห็นทันที

**Q: ราคาเท่าไหร่?**
A: Supabase Free Tier — DB 500MB + Storage 1GB + Auth ไม่จำกัด ใช้ได้สบายๆ สำหรับบริษัท 50-100 คน

**Q: ถ้าจะแก้ไขสินค้าที่ seed เข้าไป?**
A: เข้าหน้า `products.html` → เลือกสินค้า → กดแก้ไข หรือ delete จาก Supabase Table Editor

**Q: ลืม password?**
A: ไป Supabase → Authentication → Users → คลิกผู้ใช้ → Send password recovery email

---

## ติดต่อ

พี่หนึ่ง · Warehouse Manager · อินสไปเรชั่น ดีไซน์
สร้างโดย Jarvis 🤖 — Built with ❤️ for Inspiration Design
