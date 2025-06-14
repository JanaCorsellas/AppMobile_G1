importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAVGap3-2Tk9_Y_zW4gA-860n3z4f1i2qU",
  authDomain: "trazer-e4cb2.firebaseapp.com",
  projectId: "trazer-e4cb2",
  storageBucket: "trazer-e4cb2.firebasestorage.app",
  messagingSenderId: "782085531087",
  appId: "1:782085531087:web:fbc005500d06279a4f5eba",
  measurementId: "G-YKZ1SH85QD"
});

const messaging = firebase.messaging();

// Missatges en segon pla
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Nueva notificación';
  const notificationOptions = {
    body: payload.notification?.body || 'Tienes una nueva notificación',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: 'notification-tag'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Clics en les notificacions
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow('http://localhost:3000/')
  );
});