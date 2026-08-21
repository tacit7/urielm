// Retire service-worker registrations left behind by older browser sessions.
self.addEventListener("install", () => self.skipWaiting())

self.addEventListener("activate", event => {
  event.waitUntil(self.registration.unregister())
})
