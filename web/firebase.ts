// Import the functions you need from the SDKs you need
import { initializeApp  } from "firebase/app";
import{getMessaging} from "firebase/messaging"
import { getAnalytics, isSupported } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDZaNpdV7GZn_nXcl14eezsW3SmSWa7HoI",
  authDomain: "uscitylink-adb9f.firebaseapp.com",
  projectId: "uscitylink-adb9f",
  storageBucket: "uscitylink-adb9f.firebasestorage.app",
  messagingSenderId: "786206543025",
  appId: "1:786206543025:web:b06287a409202b66716690",
  measurementId: "G-M460H4DLS0"
};

// Initialize Firebase
export const app = initializeApp(firebaseConfig);
export const message = async () =>{
  const supported = await isSupported();
  return supported ? getMessaging(app) : null
}
