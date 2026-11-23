// Keeps the app working without a connection: the home screen, and every game that was opened once.
// scripts/build.sh replaces the version below with the commit the site was built from.
const VERSION = '__VERSION__';
const CACHE = 'shneyor-games-' + VERSION;
const SHELL = ['./', 'games.json', 'manifest.webmanifest', 'icon.svg', 'icon-192.png'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

async function store(request, response) {
  if (response.ok && response.status === 200) {
    const cache = await caches.open(CACHE);
    await cache.put(request, response.clone()).catch(() => {});
  }
  return response;
}

// A game's files live in a folder named after the build, so a saved copy can never be out of date.
async function cacheFirst(request) {
  return (await caches.match(request)) || store(request, await fetch(request));
}

// Everything else is fetched fresh, and the saved copy is only for when there is no connection.
async function networkFirst(request) {
  try {
    return await store(request, await fetch(request));
  } catch (err) {
    const saved = await caches.match(request, { ignoreSearch: true });
    if (saved) return saved;
    throw err;
  }
}

self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== location.origin) return;
  const versioned = url.pathname.includes('/' + VERSION + '/');
  event.respondWith(versioned ? cacheFirst(request) : networkFirst(request));
});
