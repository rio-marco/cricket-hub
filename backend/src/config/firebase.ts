import { App, cert, getApp, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';
import { env } from './env';

const placeholders = ['your_firebase_project_id', 'your_firebase_client_email', 'your_firebase_private_key'];

export const isFirebaseConfigured = (): boolean => {
  const values = [env.FIREBASE_PROJECT_ID, env.FIREBASE_CLIENT_EMAIL, env.FIREBASE_PRIVATE_KEY];
  return values.every((value) => value.trim().length > 0 && !placeholders.includes(value.trim()));
};

let app: App | null = null;
let initializationAttempted = false;

export const getFirebaseApp = (): App | null => {
  if (!isFirebaseConfigured()) return null;
  if (app) return app;
  if (initializationAttempted && getApps().length === 0) return null;

  initializationAttempted = true;
  try {
    app = getApps().length ? getApp() : initializeApp({
      credential: cert({
        projectId: env.FIREBASE_PROJECT_ID.trim(),
        clientEmail: env.FIREBASE_CLIENT_EMAIL.trim(),
        privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
      databaseURL: undefined,
    });
    return app;
  } catch {
    app = null;
    return null;
  }
};

export const getFirebaseMessaging = (): Messaging | null => {
  const firebaseApp = getFirebaseApp();
  if (!firebaseApp) return null;
  return getMessaging(firebaseApp);
};
