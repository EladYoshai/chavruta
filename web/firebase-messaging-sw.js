importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCBn-LugNq3tlzHi-W-maIfMylK-lKDBuk',
  authDomain: 'chavroota-6c454.firebaseapp.com',
  projectId: 'chavroota-6c454',
  storageBucket: 'chavroota-6c454.firebasestorage.app',
  messagingSenderId: '547246231621',
  appId: '1:547246231621:web:48edf32de0acac1e90532c',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  const title = payload.notification?.title || 'חברותא';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    dir: 'rtl',
    lang: 'he',
  };
  return self.registration.showNotification(title, options);
});
