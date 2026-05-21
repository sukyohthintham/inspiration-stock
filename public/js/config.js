/**
 * Supabase Configuration
 * แก้ไข URL และ ANON_KEY ให้ตรงกับ Supabase Project ของพี่หนึ่ง
 * ค่าทั้งสองหาได้ที่: Supabase Dashboard > Project Settings > API
 */
const SUPABASE_CONFIG = {
  URL: 'https://qhnvxgfmdquqvgrwuufh.supabase.co',
  ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFobnZ4Z2ZtZHF1cXZncnd1dWZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNTM1OTUsImV4cCI6MjA5NDkyOTU5NX0.qCU3DRK-eAjxU9-Nts6Bxh6yFt4lNS1zyJtNNojeixk',
};

// App-wide constants
const APP = {
  NAME: 'Inspiration Stock',
  COMPANY: 'อินสไปเรชั่น ดีไซน์',
  VERSION: '1.0.0',
  CURRENCY: 'บาท',
};

// Initialize Supabase client (ต้อง load supabase-js ก่อน)
const supabase = window.supabase.createClient(SUPABASE_CONFIG.URL, SUPABASE_CONFIG.ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
});

// Helper: Get current user profile (cached)
let _currentProfile = null;
async function getCurrentProfile(force = false) {
  if (_currentProfile && !force) return _currentProfile;
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();
  if (error) {
    console.error('Profile load error:', error);
    return null;
  }
  _currentProfile = { ...data, email: user.email };
  return _currentProfile;
}

// Helper: Require login (redirect to login page if not authenticated)
async function requireAuth() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    window.location.href = 'index.html';
    return null;
  }
  return await getCurrentProfile();
}

// Helper: Require admin/manager role
async function requireAdmin() {
  const profile = await requireAuth();
  if (!profile) return null;
  if (!['admin', 'manager'].includes(profile.role)) {
    alert('คุณไม่มีสิทธิเข้าถึงหน้านี้ (เฉพาะ Admin/Manager)');
    window.location.href = 'requisition.html';
    return null;
  }
  return profile;
}

// Helper: Logout
async function logout() {
  await supabase.auth.signOut();
  _currentProfile = null;
  window.location.href = 'index.html';
}

// Helper: Format currency
function fmtCurrency(n) {
  if (n == null) return '-';
  return Number(n).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

// Helper: Format datetime
function fmtDate(d) {
  if (!d) return '-';
  return new Date(d).toLocaleString('th-TH', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit'
  });
}

function fmtDateOnly(d) {
  if (!d) return '-';
  return new Date(d).toLocaleDateString('th-TH', {
    year: 'numeric', month: 'short', day: 'numeric'
  });
}

// Helper: Toast notification
function toast(message, type = 'info') {
  const colors = {
    info:    'bg-blue-600',
    success: 'bg-green-600',
    error:   'bg-red-600',
    warning: 'bg-amber-600',
  };
  const el = document.createElement('div');
  el.className = `fixed bottom-6 left-1/2 -translate-x-1/2 ${colors[type]} text-white px-5 py-3 rounded-full shadow-2xl z-50 text-sm font-medium animate-fade-in`;
  el.textContent = message;
  document.body.appendChild(el);
  setTimeout(() => {
    el.style.transition = 'opacity 0.3s';
    el.style.opacity = '0';
    setTimeout(() => el.remove(), 300);
  }, 2800);
}

// Helper: Confirm dialog
function confirmDialog(message) {
  return window.confirm(message);
}

// Register service worker (PWA)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('sw.js').catch(err => console.warn('SW failed:', err));
  });
}
