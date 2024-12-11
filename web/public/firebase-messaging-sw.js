importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js');

firebase.initializeApp({
  apiKey: "AIzaSyDZaNpdV7GZn_nXcl14eezsW3SmSWa7HoI",
  authDomain: "uscitylink-adb9f.firebaseapp.com",
  projectId: "uscitylink-adb9f",
  storageBucket: "uscitylink-adb9f.firebasestorage.app",
  messagingSenderId: "786206543025",
  appId: "1:786206543025:web:b06287a409202b66716690",
  measurementId: "G-M460H4DLS0"
});


const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function (payload) {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    // icon: '/icons/icon-192x192.png',
  };

  // Display the notification to the user
  self.registration.showNotification(notificationTitle, notificationOptions);
});
