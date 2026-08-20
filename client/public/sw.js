/*
 * 睡眠良方 Service Worker
 * 修复：停用"缓存优先"策略 — 之前会把 / 永久缓存，导致页面锁死在旧快照（白屏）。
 * 现在改为"网络优先 + 立即接管 + 清理旧缓存"，保证始终加载最新版本，
 * 并为已注册的旧 Service Worker 提供升级清理路径。
 */
const CACHE_NAME = 'sleep-cbti-v2';

/* 安装时：先清理所有旧缓存，失败不阻塞安装 */
self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    ).catch(() => {})
  );
});

/* 激活时：立即接管所有页面，并再次清理旧缓存 */
self.addEventListener('activate', (e) => {
  e.waitUntil(
    (async () => {
      await self.clients.claim();
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
    })().catch(() => {})
  );
});

/*
 * 网络优先：始终尝试从网络加载最新资源；
 * 网络失败时才回退到缓存（离线兜底）。保证不会锁死在旧页面。
 */
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    fetch(e.request)
      .then((resp) => {
        // 仅缓存同源、成功的响应，用于离线兜底
        if (resp && resp.ok && e.request.url.startsWith(self.location.origin)) {
          const clone = resp.clone();
          caches.open(CACHE_NAME).then((c) => c.put(e.request, clone)).catch(() => {});
        }
        return resp;
      })
      .catch(() => caches.match(e.request).then((r) => r || Response.error()))
  );
});
