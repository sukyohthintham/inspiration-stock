/**
 * Service Worker - Inspiration Stock PWA
 * Strategy: Network-first สำหรับ API, Cache-first สำหรับ static files
 */
const CACHE_NAME = 'inspiration-stock-v1';
const STATIC_FILES = [
  './',
  './index.html',
  './requisition.html',
  './dashboard.html',
  './manifest.json',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_FILES).catch(() => {}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // API call: ไป network ก่อน
  if (url.hostname.includes('supabase.co')) {
    event.respondWith(fetch(event.request).catch(() => caches.match(event.request)));
    return;
  }
  // Static: cache ก่อน, fallback network
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request))
  );
});
