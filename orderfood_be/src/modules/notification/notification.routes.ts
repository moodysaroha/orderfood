import { Router } from 'express';
import { NotificationController } from './notification.controller';
import { authenticate } from '../../middleware/auth.middleware';

export function createNotificationRoutes(controller: NotificationController): Router {
  const router = Router();

  router.post('/device/register', authenticate, controller.registerDevice);
  router.post('/device/unregister', authenticate, controller.unregisterDevice);
  router.get('/', authenticate, controller.getNotifications);
  router.get('/unread-count', authenticate, controller.getUnreadCount);
  router.patch('/:id/read', authenticate, controller.markAsRead);
  router.patch('/read-all', authenticate, controller.markAllAsRead);

  return router;
}
