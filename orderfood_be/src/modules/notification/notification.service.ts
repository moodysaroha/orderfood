import { NotificationType } from '@prisma/client';
import { INotificationRepository } from './notification.repository';
import { IFcmService, FcmMessage } from './fcm.service';
import {
  RegisterDeviceInput,
  SendNotificationInput,
  SendMulticastInput,
  PaginatedNotifications,
  OrderNotificationContext,
  StockNotificationContext,
} from './notification.types';

export interface INotificationService {
  registerDevice(input: RegisterDeviceInput): Promise<void>;
  unregisterDevice(userId: string, token: string): Promise<void>;
  sendNotification(input: SendNotificationInput): Promise<void>;
  sendMulticast(input: SendMulticastInput): Promise<void>;
  getNotifications(userId: string, page: number, limit: number): Promise<PaginatedNotifications>;
  markAsRead(notificationId: string, userId: string): Promise<void>;
  markAllAsRead(userId: string): Promise<void>;
  getUnreadCount(userId: string): Promise<number>;
  notifyOrderPlaced(vendorUserId: string, context: OrderNotificationContext): Promise<void>;
  notifyOrderStatusChange(studentUserId: string, status: string, context: OrderNotificationContext): Promise<void>;
  notifyItemOutOfStock(studentUserIds: string[], context: StockNotificationContext): Promise<void>;
  notifyItemBackInStock(studentUserIds: string[], context: StockNotificationContext): Promise<void>;
  notifyPaymentReceived(studentUserId: string, vendorUserId: string, context: OrderNotificationContext): Promise<void>;
  notifyPaymentFailed(studentUserId: string, context: OrderNotificationContext): Promise<void>;
}

export class NotificationService implements INotificationService {
  constructor(
    private repository: INotificationRepository,
    private fcmService: IFcmService
  ) {}

  async registerDevice(input: RegisterDeviceInput): Promise<void> {
    await this.repository.registerDevice(input.userId, input.token, input.platform || 'android');
  }

  async unregisterDevice(userId: string, token: string): Promise<void> {
    await this.repository.removeDevice(userId, token);
  }

  async sendNotification(input: SendNotificationInput): Promise<void> {
    await this.repository.createNotification({
      userId: input.userId,
      type: input.type,
      title: input.title,
      body: input.body,
      data: input.data,
    });

    const tokens = await this.repository.getActiveDeviceTokens(input.userId);
    if (tokens.length > 0) {
      const message: FcmMessage = {
        title: input.title,
        body: input.body,
        data: input.data,
      };
      await this.fcmService.sendToDevices(tokens, message);
    }
  }

  async sendMulticast(input: SendMulticastInput): Promise<void> {
    for (const userId of input.userIds) {
      await this.repository.createNotification({
        userId,
        type: input.type,
        title: input.title,
        body: input.body,
        data: input.data,
      });
    }

    const tokenMap = await this.repository.getActiveDeviceTokensForUsers(input.userIds);
    const allTokens: string[] = [];
    tokenMap.forEach((tokens) => allTokens.push(...tokens));

    if (allTokens.length > 0) {
      const message: FcmMessage = {
        title: input.title,
        body: input.body,
        data: input.data,
      };
      await this.fcmService.sendToDevices(allTokens, message);
    }
  }

  async getNotifications(userId: string, page: number, limit: number): Promise<PaginatedNotifications> {
    return this.repository.getNotifications(userId, page, limit);
  }

  async markAsRead(notificationId: string, userId: string): Promise<void> {
    await this.repository.markAsRead(notificationId, userId);
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.repository.markAllAsRead(userId);
  }

  async getUnreadCount(userId: string): Promise<number> {
    return this.repository.getUnreadCount(userId);
  }

  async notifyOrderPlaced(vendorUserId: string, context: OrderNotificationContext): Promise<void> {
    await this.sendNotification({
      userId: vendorUserId,
      type: NotificationType.ORDER_PLACED,
      title: 'New Order Received!',
      body: `${context.studentName} placed an order for ${context.orderTotal} (${context.itemCount} item${context.itemCount > 1 ? 's' : ''})`,
      data: {
        orderId: context.orderId,
        type: 'ORDER_PLACED',
      },
    });
  }

  async notifyOrderStatusChange(studentUserId: string, status: string, context: OrderNotificationContext): Promise<void> {
    const statusMessages: Record<string, { title: string; body: string; type: NotificationType }> = {
      CONFIRMED: {
        title: 'Order Confirmed!',
        body: `Your order at ${context.vendorName} has been confirmed`,
        type: NotificationType.ORDER_CONFIRMED,
      },
      PREPARING: {
        title: 'Order Being Prepared',
        body: `${context.vendorName} is now preparing your order`,
        type: NotificationType.ORDER_PREPARING,
      },
      READY: {
        title: 'Order Ready for Pickup!',
        body: `Your order at ${context.vendorName} is ready! Please pick it up.`,
        type: NotificationType.ORDER_READY,
      },
      CANCELLED: {
        title: 'Order Cancelled',
        body: `Your order at ${context.vendorName} has been cancelled`,
        type: NotificationType.ORDER_CANCELLED,
      },
    };

    const messageConfig = statusMessages[status];
    if (!messageConfig) return;

    await this.sendNotification({
      userId: studentUserId,
      type: messageConfig.type,
      title: messageConfig.title,
      body: messageConfig.body,
      data: {
        orderId: context.orderId,
        status,
        type: `ORDER_${status}`,
      },
    });
  }

  async notifyItemOutOfStock(studentUserIds: string[], context: StockNotificationContext): Promise<void> {
    if (studentUserIds.length === 0) return;

    await this.sendMulticast({
      userIds: studentUserIds,
      type: NotificationType.ITEM_OUT_OF_STOCK,
      title: 'Item Out of Stock',
      body: `${context.itemName} at ${context.vendorName} is now out of stock`,
      data: {
        menuItemId: context.menuItemId,
        type: 'ITEM_OUT_OF_STOCK',
      },
    });
  }

  async notifyItemBackInStock(studentUserIds: string[], context: StockNotificationContext): Promise<void> {
    if (studentUserIds.length === 0) return;

    await this.sendMulticast({
      userIds: studentUserIds,
      type: NotificationType.ITEM_BACK_IN_STOCK,
      title: 'Item Back in Stock!',
      body: `${context.itemName} at ${context.vendorName} is available again`,
      data: {
        menuItemId: context.menuItemId,
        type: 'ITEM_BACK_IN_STOCK',
      },
    });
  }

  async notifyPaymentReceived(studentUserId: string, vendorUserId: string, context: OrderNotificationContext): Promise<void> {
    await this.sendNotification({
      userId: studentUserId,
      type: NotificationType.PAYMENT_RECEIVED,
      title: 'Payment Successful!',
      body: `Your payment of ${context.orderTotal} for the order at ${context.vendorName} was successful`,
      data: {
        orderId: context.orderId,
        type: 'PAYMENT_RECEIVED',
      },
    });

    await this.sendNotification({
      userId: vendorUserId,
      type: NotificationType.PAYMENT_RECEIVED,
      title: 'Payment Received!',
      body: `Payment of ${context.orderTotal} received from ${context.studentName}`,
      data: {
        orderId: context.orderId,
        type: 'PAYMENT_RECEIVED',
      },
    });
  }

  async notifyPaymentFailed(studentUserId: string, context: OrderNotificationContext): Promise<void> {
    await this.sendNotification({
      userId: studentUserId,
      type: NotificationType.PAYMENT_FAILED,
      title: 'Payment Failed',
      body: `Your payment for the order at ${context.vendorName} failed. Please try again.`,
      data: {
        orderId: context.orderId,
        type: 'PAYMENT_FAILED',
      },
    });
  }
}
