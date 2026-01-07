

importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// 1. Initialize Firebase (Replace with your credentials from Firebase Console)
const firebaseConfig = {
 apiKey: "AIzaSyDZaNpdV7GZn_nXcl14eezsW3SmSWa7HoI",
  authDomain: "uscitylink-adb9f.firebaseapp.com",
  projectId: "uscitylink-adb9f",
  storageBucket: "uscitylink-adb9f.firebasestorage.app",
  messagingSenderId: "786206543025",
  appId: "1:786206543025:web:b06287a409202b66716690",
  measurementId: "G-M460H4DLS0",
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// 2. Handle Background Messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png', // Ensure you have this icon in web/icons
    // 3. Set the Badge count from the data payload
  };

  // BADGE LOGIC: Check if browser supports badging
  if (navigator.setAppBadge) {
    // We expect the backend to send a data field named 'badgeCount'
    const badgeCount = payload.data && payload.data.badgeCount ? parseInt(payload.data.badgeCount) : 0;
    if (badgeCount > 0) {
      navigator.setAppBadge(badgeCount);
    } else {
      navigator.clearAppBadge();
    }
  }

  return self.registration.showNotification(notificationTitle, notificationOptions);
});