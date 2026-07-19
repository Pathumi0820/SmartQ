import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyByPZ3mcKSyIz6lGdG1dJTE4v8dDv3YmEA",
  authDomain: "smartq-hospital.firebaseapp.com",
  projectId: "smartq-hospital",
  storageBucket: "smartq-hospital.firebasestorage.app",
  messagingSenderId: "384712045387",
  appId: "1:384712045387:web:7699bccfb64adb0cabeece"
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
export const auth = getAuth(app);