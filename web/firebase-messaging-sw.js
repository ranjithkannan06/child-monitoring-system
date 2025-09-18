// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
  apiKey: 'AIzaSyA6V4YX8qABZEt3Hm_zS89frxUnSJ55pIM',
  authDomain: 'child-monitering-system.firebaseapp.com',
  projectId: 'child-monitering-system',
  storageBucket: 'child-monitering-system.firebasestorage.app',
  messagingSenderId: '217976487619',
  appId: '1:217976487619:web:71c35d59ee11f17ac22c76',
  measurementId: 'G-0JPZ16DQSK',
  databaseURL: 'https://child-monitering-system-default-rtdb.firebaseio.com/',
});

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Child Safety Alert';
  const notificationOptions = {
    body: payload.notification?.body || 'New alert from your device',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
