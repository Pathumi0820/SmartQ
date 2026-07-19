import "dotenv/config";

import {
  cert,
  getApps,
  initializeApp,
} from "firebase-admin/app";

import { getMessaging } from "firebase-admin/messaging";

const requiredVariables = [
  "FIREBASE_PROJECT_ID",
  "FIREBASE_CLIENT_EMAIL",
  "FIREBASE_PRIVATE_KEY",
];

for (const variable of requiredVariables) {
  if (!process.env[variable]?.trim()) {
    throw new Error(
      `Missing environment variable: ${variable}`,
    );
  }
}

const projectId =
  process.env.FIREBASE_PROJECT_ID.trim();

const clientEmail =
  process.env.FIREBASE_CLIENT_EMAIL.trim();

const privateKey =
  process.env.FIREBASE_PRIVATE_KEY
    .replace(/\\n/g, "\n")
    .trim();

const firebaseAdminApp =
  getApps().length > 0
    ? getApps()[0]
    : initializeApp({
        credential: cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        projectId,
      });

const firebaseMessaging = getMessaging(
  firebaseAdminApp,
);

console.log(
  `Firebase Admin initialized for project: ${projectId}`,
);

export {
  firebaseAdminApp,
  firebaseMessaging,
};

export default firebaseAdminApp;