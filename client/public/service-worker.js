// Austin Food Club Service Worker
// Handles push notifications and offline functionality

const CACHE_NAME = 'austin-food-club-v1';
const urlsToCache = [
  '/',
  '/static/js/bundle.js',
  '/static/css/main.css',
  '/icon-192x192.png',
  '/badge-72x72.png'
];

// Install event - cache resources
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('📦 Service Worker: Caching app shell');
        return cache.addAll(urlsToCache);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ Service Worker: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      })
  );
});

// Push event - handle incoming push notifications
self.addEventListener('push', event => {
  console.log('📱 Push notification received:', event);
  
  if (!event.data) {
    console.log('📭 Push event but no data');
    return;
  }

  const data = event.data.json();
  console.log('📱 Push data:', data);

  const options = {
    body: data.body,
    icon: data.icon || '/icon-192x192.png',
    badge: data.badge || '/badge-72x72.png',
    vibrate: [100, 50, 100],
    data: data.data || {},
    actions: data.actions || [],
    tag: data.data?.type || 'default',
    requireInteraction: data.data?.type === 'rsvp_reminder',
    timestamp: Date.now()
  };

  // Customize notification based on type
  if (data.data?.type === 'weekly_announcement') {
    options.icon = '/icon-192x192.png';
    options.badge = '/badge-72x72.png';
    options.vibrate = [200, 100, 200];
  } else if (data.data?.type === 'rsvp_reminder') {
    options.icon = '/icon-192x192.png';
    options.vibrate = [300, 100, 300, 100, 300];
    options.requireInteraction = true;
  } else if (data.data?.type === 'friend_activity') {
    options.icon = '/icon-192x192.png';
    options.vibrate = [100, 50, 100];
  }

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

// Notification click event - handle user interactions
self.addEventListener('notificationclick', event => {
  console.log('🖱️ Notification clicked:', event);
  
  event.notification.close();

  const action = event.action;
  const data = event.notification.data;
  
  let url = '/';
  
  // Handle different actions
  if (action === 'rsvp' || data.action === 'view_restaurant') {
    url = `/restaurant/${data.restaurantId}`;
  } else if (action === 'details') {
    url = `/restaurant/${data.restaurantId}`;
  } else if (action === 'directions' && data.address) {
    url = `https://maps.google.com/?q=${encodeURIComponent(data.address)}`;
  } else if (action === 'cancel' && data.rsvpId) {
    url = `/profile?cancel_rsvp=${data.rsvpId}`;
  } else if (action === 'verify') {
    url = `/verify-visit?restaurant=${data.restaurantId}`;
  } else if (data.type === 'friend_activity') {
    url = `/friends`;
  } else if (data.type === 'weekly_announcement') {
    url = `/`;
  }

  // Log click event
  event.waitUntil(
    Promise.all([
      // Open the URL
      clients.openWindow(url),
      
      // Log the click (if we have an API endpoint for it)
      fetch('/api/notifications/click', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          notificationId: data.notificationId,
          action: action || 'default',
          timestamp: Date.now()
        })
      }).catch(err => console.log('Failed to log click:', err))
    ])
  );
});

// Background sync for failed notifications
self.addEventListener('sync', event => {
  if (event.tag === 'background-sync') {
    console.log('🔄 Background sync triggered');
    event.waitUntil(
      // Retry failed notification sends
      fetch('/api/notifications/retry-failed', {
        method: 'POST'
      }).catch(err => console.log('Background sync failed:', err))
    );
  }
});

// Handle notification close event
self.addEventListener('notificationclose', event => {
  console.log('❌ Notification closed:', event.notification.tag);
  
  // Log dismissal (optional analytics)
  event.waitUntil(
    fetch('/api/notifications/dismiss', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        tag: event.notification.tag,
        timestamp: Date.now()
      })
    }).catch(err => console.log('Failed to log dismissal:', err))
  );
});

console.log('🔧 Austin Food Club Service Worker loaded');
