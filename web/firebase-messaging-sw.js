// ============================================
// Firebase Cloud Messaging Service Worker
// This file handles push notifications when the
// website/PWA is closed or in the background.
// Place this file in your web/ root directory.
// ============================================

// Import Firebase scripts (compat version for service workers)
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Your Firebase config - same as in your app
firebase.initializeApp({
  apiKey: 'AIzaSyCBn-LugNq3tlzHi-W-maIfMylK-lKDBuk',
  authDomain: 'chavroota-6c454.firebaseapp.com',
  projectId: 'chavroota-6c454',
  storageBucket: 'chavroota-6c454.firebasestorage.app',
  messagingSenderId: '547246231621',
  appId: '1:547246231621:web:48edf32de0acac1e90532c',
});

// Get messaging instance
const messaging = firebase.messaging();

// Handle background messages (when app is closed or in background)
messaging.onBackgroundMessage(function(payload) {
  console.log('[SW] Background message received:', payload);

  // Extract notification data
  const title = payload.notification?.title || 'חברותא';
  const options = {
    body: payload.notification?.body || 'יש לך הודעה חדשה',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    dir: 'rtl',
    lang: 'he',
    tag: 'chavruta-notification', // Prevents duplicate notifications
    renotify: true,
    data: payload.data || {},
  };

  return self.registration.showNotification(title, options);
});

// Handle notification click and actions
self.addEventListener('notificationclick', function(event) {
  const action = event.action;
  event.notification.close();

  if (action === 'omer_done') {
    // User read the omer - dismiss, no further action
    return;
  }

  if (action === 'omer_snooze') {
    // Snooze: show again in 30 minutes
    event.waitUntil(
      new Promise(resolve => {
        setTimeout(() => {
          self.registration.showNotification('חברותא - ספירת העומר 🌾', {
            body: 'תזכורת: לא לשכוח לספור ספירת העומר!',
            icon: '/icons/Icon-192.png',
            dir: 'rtl',
            lang: 'he',
            tag: 'chavruta-omer-snooze',
            actions: [
              { action: 'omer_done', title: 'קראתי ✓' },
            ],
          });
          resolve();
        }, 30 * 60 * 1000); // 30 minutes
      })
    );
    return;
  }

  // Default: open the app
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (const client of clientList) {
        if (client.url.includes('chavruta') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
