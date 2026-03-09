import { PrismaClient, Notification, DeviceToken, NotificationType } from '@prisma/client';
import { NotificationData, PaginatedNotifications } from './notification.types';

export interface INotificationRepository {
  registerDevice(userId: string, token: string, platform: string): Promise<DeviceToken>;
  removeDevice(userId: string, token: string): Promise<void>;
  getActiveDeviceTokens(userId: string): Promise<string[]>;
  getActiveDeviceTokensForUsers(userIds: string[]): Promise<Map<string, string[]>>;
  createNotification(data: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }): Promise<Notification>;
  getNotifications(userId: string, page: number, limit: number): Promise<PaginatedNotifications>;
  markAsRead(notificationId: string, userId: string): Promise<void>;
  markAllAsRead(userId: string): Promise<void>;
  getUnreadCount(userId: string): Promise<number>;
}

export class NotificationRepository implements INotificationRepository {
  constructor(private prisma: PrismaClient) {}

  async registerDevice(userId: string, token: string, platform: string): Promise<DeviceToken> {
    return this.prisma.deviceToken.upsert({
      where: { userId_token: { userId, token } },
      update: { isActive: true, platform, updatedAt: new Date() },
      create: { userId, token, platform, isActive: true },
    });
  }

  async removeDevice(userId: string, token: string): Promise<void> {
    await this.prisma.deviceToken.updateMany({
      where: { userId, token },
      data: { isActive: false },
    });
  }

  async getActiveDeviceTokens(userId: string): Promise<string[]> {
    const devices = await this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { token: true },
    });
    return devices.map((d) => d.token);
  }

  async getActiveDeviceTokensForUsers(userIds: string[]): Promise<Map<string, string[]>> {
    const devices = await this.prisma.deviceToken.findMany({
      where: { userId: { in: userIds }, isActive: true },
      select: { userId: true, token: true },
    });

    const tokenMap = new Map<string, string[]>();
    for (const device of devices) {
      const tokens = tokenMap.get(device.userId) || [];
      tokens.push(device.token);
      tokenMap.set(device.userId, tokens);
    }
    return tokenMap;
  }

  async createNotification(data: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    data?: Record<string, unknown>;
  }): Promise<Notification> {
    return this.prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data ? JSON.parse(JSON.stringify(data.data)) : undefined,
      },
    });
  }

  async getNotifications(userId: string, page: number, limit: number): Promise<PaginatedNotifications> {
    const skip = (page - 1) * limit;

    const [notifications, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where: { userId } }),
      this.prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    return {
      notifications: notifications.map((n) => ({
        id: n.id,
        userId: n.userId,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data as Record<string, unknown> | null,
        isRead: n.isRead,
        createdAt: n.createdAt,
      })),
      total,
      unreadCount,
    };
  }

  async markAsRead(notificationId: string, userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }
}
