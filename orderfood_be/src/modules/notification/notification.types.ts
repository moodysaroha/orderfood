import { NotificationType } from '@prisma/client';

export interface RegisterDeviceInput {
  userId: string;
  token: string;
  platform?: string;
}

export interface SendNotificationInput {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface SendMulticastInput {
  userIds: string[];
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface NotificationData {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data: Record<string, unknown> | null;
  isRead: boolean;
  createdAt: Date;
}

export interface PaginatedNotifications {
  notifications: NotificationData[];
  total: number;
  unreadCount: number;
}

export interface OrderNotificationContext {
  orderId: string;
  orderTotal: string;
  studentName: string;
  vendorName: string;
  itemCount: number;
}

export interface StockNotificationContext {
  menuItemId: string;
  itemName: string;
  vendorName: string;
}
