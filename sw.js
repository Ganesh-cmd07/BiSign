const CACHE_NAME = 'bisign-v2';
const CORE_ASSETS = [
  '/',
  '/index.html',
  '/src/style.css',
  '/src/main.js',
  '/src/model.js',
  '/src/nlp.js',
  '/src/tts.js',
  '/bisign-icon.svg',
  '/manifest.json',
];

// Install: cache only the app shell (local assets). Large CDN assets are cached at runtime.
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE_ASSETS);
    })
  );
});

// Activate: cleanup old caches if needed
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
        )
      )
  );
});

// Fetch handler: prefer cache for local assets; use network-first for CDN/large assets but cache them for subsequent requests.
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  // Serve core assets from cache first
  if (
    CORE_ASSETS.includes(url.pathname) ||
    url.origin === self.location.origin
  ) {
    event.respondWith(
      caches.match(request).then(
        (cached) =>
          cached ||
          fetch(request)
            .then((res) => {
              // Cache responses for future offline use
              const copy = res.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
              return res;
            })
            .catch(() => cached)
      )
    );
    return;
  }

  // For known CDN hosts (MediaPipe / TF / fonts), use network-first with a cache fallback
  if (
    url.hostname.includes('cdn.jsdelivr.net') ||
    url.hostname.includes('fonts.googleapis.com') ||
    url.hostname.includes('fonts.gstatic.com')
  ) {
    event.respondWith(
      fetch(request)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
          return res;
        })
        .catch(() => caches.match(request))
    );
    return;
  }

  // Default: try cache first, then network
  event.respondWith(
    caches.match(request).then((resp) => resp || fetch(request))
  );
});
