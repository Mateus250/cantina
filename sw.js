// Service worker simples: permite instalar como app. Os dados sempre vêm do Supabase.
self.addEventListener("install", e => self.skipWaiting());
self.addEventListener("activate", e => e.waitUntil(self.clients.claim()));
self.addEventListener("fetch", () => {});
