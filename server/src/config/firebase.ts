// /src/config/firebase.ts
import * as admin from 'firebase-admin';
import * as path from 'path';

// Path to your service account key file
const serviceAccountPath = path.join(__dirname, './firebase.json');

let initialized = false;

if (!initialized) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
  initialized = true;
  console.log('Firebase Admin SDK initialized');
}

export default admin;
