import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

const firebaseConfig = {
  apiKey: "AIzaSyCd4D6fXPAdbOYdwfytXXwfBv9-kchM48g",
  authDomain: "ivory-hub.firebaseapp.com",
  projectId: "ivory-hub",
  storageBucket: "ivory-hub.firebasestorage.app",
  messagingSenderId: "85845669756",
  appId: "1:85845669756:web:ea6b64b81981b48ac356f9",
  measurementId: "G-FCW4ERMR64"
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };
