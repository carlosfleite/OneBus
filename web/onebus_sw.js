/* OneBus service worker.
 *
 * - Core files (page, loader, app code, manifest, version): NETWORK-FIRST.
 *   A new deploy is picked up on the next load; the cached copy is used
 *   only when the network fails or is too slow, so a stale cache can't
 *   stick.
 * - Static assets (CanvasKit, fonts, icons, assets/): STALE-WHILE-REVALIDATE
 *   for instant loads and resilience when the connection drops.
 * - Google Fonts: stale-while-revalidate in their own cache.
 * - Everything else (Supabase API, map tiles, …) goes straight to the
 *   network and is never cached here.
 *
 * Bump VERSION to drop every old cache.
 */
const VERSION = 'onebus-v1';
const CORE = `${VERSION}-core`;
const ASSETS = `${VERSION}-assets`;
const FONTS = `${VERSION}-fonts`;
const KEEP = [CORE, ASSETS, FONTS];

const NETWORK_TIMEOUT_MS = 4000;
const CORE_FILES = [
  'index.html',
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'main.dart.mjs',
  'main.dart.wasm',
  'version.json',
  'manifest.json',
];
const PRECACHE = ['./', 'index.html', 'manifest.json', 'favicon.png',
  'icons/Icon-192.png', 'icons/Icon-512.png', 'icons/apple-touch-icon.png'];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CORE).then((cache) =>
      Promise.all(PRECACHE.map((url) =>
        fetch(url, { cache: 'reload' })
          .then((res) => (res.ok ? cache.put(url, res) : null))
          .catch(() => null))))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((n) => !KEEP.includes(n)).map((n) => caches.delete(n)));
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});

function isCore(url, request) {
  if (request.mode === 'navigate') return true;
  const path = url.pathname;
  return CORE_FILES.some((f) => path.endsWith('/' + f) || path === '/' + f) ||
    path.endsWith('/');
}

function cacheable(res) {
  return res && res.ok && res.status === 200 &&
    (res.type === 'basic' || res.type === 'cors');
}

async function networkFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const res = await Promise.race([
      fetch(request),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), NETWORK_TIMEOUT_MS)),
    ]);
    if (cacheable(res)) cache.put(request, res.clone());
    return res;
  } catch (err) {
    const cached = await cache.match(request, { ignoreSearch: true });
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const shell = await cache.match('index.html') || await cache.match('./');
      if (shell) return shell;
    }
    // Slow network and nothing cached yet: wait for the real answer.
    return fetch(request);
  }
}

async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  const fresh = fetch(request).then((res) => {
    if (cacheable(res)) cache.put(request, res.clone());
    return res;
  }).catch(() => null);
  return cached || (await fresh) || Response.error();
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (url.origin === self.location.origin) {
    if (request.headers.has('range')) return; // media / partial requests
    event.respondWith(
      isCore(url, request)
        ? networkFirst(request, CORE)
        : staleWhileRevalidate(request, ASSETS));
    return;
  }

  if (url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com') {
    event.respondWith(staleWhileRevalidate(request, FONTS));
  }
  // Anything else: default browser behavior.
});
