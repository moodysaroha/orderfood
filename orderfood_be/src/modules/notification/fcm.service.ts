import admin from 'firebase-admin';
import { env } from '../../config/env';

export interface FcmMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface IFcmService {
  sendToDevice(token: string, message: FcmMessage): Promise<boolean>;
  sendToDevices(tokens: string[], message: FcmMessage): Promise<{ success: number; failure: number }>;
}

export class FcmService implements IFcmService {
  private initialized = false;

  private initialize(): void {
    if (this.initialized) return;

    if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_PRIVATE_KEY || !env.FIREBASE_CLIENT_EMAIL) {
      console.warn('Firebase credentials not configured. Push notifications disabled.');
      return;
    }

    try {
      if (admin.apps.length === 0) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId: env.FIREBASE_PROJECT_ID,
            privateKey: env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            clientEmail: env.FIREBASE_CLIENT_EMAIL,
          }),
        });
      }
      this.initialized = true;
      console.log('Firebase Admin initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Firebase Admin:', error);
    }
  }

  async sendToDevice(token: string, message: FcmMessage): Promise<boolean> {
    this.initialize();
    if (!this.initialized) return false;

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'orderfood_notifications',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: message.title,
                body: message.body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      return true;
    } catch (error) {
      console.error('FCM send error:', error);
      return false;
    }
  }

  async sendToDevices(tokens: string[], message: FcmMessage): Promise<{ success: number; failure: number }> {
    this.initialize();
    if (!this.initialized || tokens.length === 0) {
      return { success: 0, failure: tokens.length };
    }

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'orderfood_notifications',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: message.title,
                body: message.body,
              },
              sound: 'default',
            },
          },
        },
      });

      return {
        success: response.successCount,
        failure: response.failureCount,
      };
    } catch (error) {
      console.error('FCM multicast error:', error);
      return { success: 0, failure: tokens.length };
    }
  }
}

export class MockFcmService implements IFcmService {
  async sendToDevice(token: string, message: FcmMessage): Promise<boolean> {
    console.log(`[MockFCM] Would send to ${token}:`, message);
    return true;
  }

  async sendToDevices(tokens: string[], message: FcmMessage): Promise<{ success: number; failure: number }> {
    console.log(`[MockFCM] Would send to ${tokens.length} devices:`, message);
    return { success: tokens.length, failure: 0 };
  }
}
