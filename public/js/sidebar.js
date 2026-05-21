/**
 * Reusable sidebar / topbar component สำหรับหน้า Admin
 * เรียกใช้: <script src="js/sidebar.js"></script> แล้ว setupAdminLayout(activePage)
 */
function renderAdminTopbar(activePage = '') {
  const navItems = [
    { id: 'dashboard',   icon: '📊', label: 'Dashboard',  href: 'dashboard.html' },
    { id: 'approve',     icon: '✅', label: 'อนุมัติ',     href: 'approve.html' },
    { id: 'receive',     icon: '📥', label: 'รับเข้า',     href: 'receive.html' },
    { id: 'products',    icon: '📦', label: 'สินค้า',      href: 'products.html' },
    { id: 'report',      icon: '📈', label: 'รายงาน',      href: 'report.html' },
    { id: 'requisition', icon: '🛒', label: 'หน้าผู้เบิก',  href: 'requisition.html' },
  ];

  const navHTML = navItems.map(n => `
    <a href="${n.href}" class="px-3 py-2 rounded-lg text-sm font-medium flex items-center gap-1.5 transition ${activePage === n.id ? 'bg-slate-900 text-white' : 'text-slate-600 hover:bg-slate-100'}">
      <span>${n.icon}</span><span class="hidden sm:inline">${n.label}</span>
    </a>`).join('');

  const topbar = document.createElement('header');
  topbar.className = 'sticky top-0 z-30 bg-white shadow-sm border-b';
  topbar.innerHTML = `
    <div class="max-w-7xl mx-auto px-4 py-3 flex items-center gap-3">
      <a href="dashboard.html" class="flex items-center gap-2 mr-3">
        <span class="text-2xl">📦</span>
        <div class="hidden sm:block">
          <div class="font-bold text-slate-900 leading-tight">Inspiration Stock</div>
          <div class="text-[10px] text-slate-500">Admin Console</div>
        </div>
      </a>
      <nav class="flex-1 flex items-center gap-1 overflow-x-auto">${navHTML}</nav>
      <div id="userBadge" class="flex items-center gap-2 ml-2">
        <div id="userInfo" class="text-right hidden md:block">
          <div id="topUserName" class="text-sm font-medium">-</div>
          <div id="topUserRole" class="text-[10px] text-slate-500">-</div>
        </div>
        <button onclick="logout()" class="px-3 py-1.5 text-xs rounded-lg bg-slate-100 hover:bg-slate-200">ออก</button>
      </div>
    </div>`;
  document.body.insertBefore(topbar, document.body.firstChild);
}

async function setupAdminLayout(activePage) {
  const profile = await requireAdmin();
  if (!profile) return null;
  renderAdminTopbar(activePage);
  document.getElementById('topUserName').textContent = profile.full_name;
  document.getElementById('topUserRole').textContent = (profile.role || 'staff').toUpperCase();
  return profile;
}
