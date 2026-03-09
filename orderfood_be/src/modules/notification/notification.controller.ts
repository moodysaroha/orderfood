import { Request, Response } from 'express';
import { INotificationService } from './notification.service';
import { AuthenticatedRequest } from '../../types';

export class NotificationController {
  constructor(private service: INotificationService) {}

  registerDevice = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const { token, platform } = req.body;
      const userId = req.user!.userId;

      if (!token) {
        res.status(400).json({ error: 'Device token is required' });
        return;
      }

      await this.service.registerDevice({
        userId,
        token,
        platform: platform || 'android',
      });

      res.json({ success: true, message: 'Device registered for notifications' });
    } catch (error) {
      console.error('Register device error:', error);
      res.status(500).json({ error: 'Failed to register device' });
    }
  };

  unregisterDevice = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const { token } = req.body;
      const userId = req.user!.userId;

      if (!token) {
        res.status(400).json({ error: 'Device token is required' });
        return;
      }

      await this.service.unregisterDevice(userId, token);
      res.json({ success: true, message: 'Device unregistered' });
    } catch (error) {
      console.error('Unregister device error:', error);
      res.status(500).json({ error: 'Failed to unregister device' });
    }
  };

  getNotifications = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const page = parseInt(req.query.page as string) || 1;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

      const result = await this.service.getNotifications(userId, page, limit);
      res.json(result);
    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json({ error: 'Failed to get notifications' });
    }
  };

  markAsRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const userId = req.user!.userId;

      await this.service.markAsRead(id, userId);
      res.json({ success: true });
    } catch (error) {
      console.error('Mark as read error:', error);
      res.status(500).json({ error: 'Failed to mark notification as read' });
    }
  };

  markAllAsRead = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user!.userId;
      await this.service.markAllAsRead(userId);
      res.json({ success: true });
    } catch (error) {
      console.error('Mark all as read error:', error);
      res.status(500).json({ error: 'Failed to mark all notifications as read' });
    }
  };

  getUnreadCount = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
    try {
      const userId = req.user!.userId;
      const count = await this.service.getUnreadCount(userId);
      res.json({ unreadCount: count });
    } catch (error) {
      console.error('Get unread count error:', error);
      res.status(500).json({ error: 'Failed to get unread count' });
    }
  };
}
