// Service worker: permite instalar como app e abrir sem internet.
// Os dados sempre vÃªm do Supabase; aqui sÃ³ guardamos os arquivos do app (rede primeiro, cÃ³pia se cair).
const CACHE = "cantina-app-v3";
const SHELL = ["./", "./index.html", "./manifest.json", "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.2/dist/umd/supabase.js"];
const KEEP = /^https:\/\/(cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com)\//;

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => Promise.allSettled(SHELL.map(u => c.add(u)))).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const req = e.request, url = new URL(req.url);
  if (req.method !== "GET") return;
  const mine = url.origin === location.origin;
  if (!mine && !KEEP.test(req.url)) return;          // Supabase e o resto: sempre direto na rede
  e.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const net = fetch(req).then(res => { if (res && (res.ok || res.type === "opaque")) cache.put(req, res.clone()); return res; });
    try {
      // internet lenta: depois de 5 s usa a cÃ³pia, se tiver
      return await Promise.race([net, new Promise((_, no) => setTimeout(() => no(new Error("timeout")), 5000))]);
    } catch (err) {
      const hit = await cache.match(req, { ignoreSearch: true }) || (req.mode === "navigate" && await cache.match("./index.html"));
      return hit || net;
    }
  })());
});
