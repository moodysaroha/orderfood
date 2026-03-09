import { Router } from 'express';
import { Container } from '../container';
import { createAuthRoutes } from './auth.routes';
import { createSduiRoutes } from './sdui.routes';
import { createVendorRoutes } from './vendor.routes';
import { createStudentRoutes } from './student.routes';
import { createRevenueRoutes } from '../modules/revenue';
import { createAdminRoutes } from '../modules/admin';
import { createPaymentRoutes } from '../modules/payment';
import { createNotificationRoutes } from '../modules/notification';
import { createCommissionRoutes } from '../modules/commission';

export function createRouter(container: Container): Router {
  const router = Router();

  router.use('/auth', createAuthRoutes(container.authController));
  router.use('/revenue', createRevenueRoutes(container.revenueController));
  router.use('/sdui', createSduiRoutes(container.sduiController));
  router.use('/vendor', createVendorRoutes(container.vendorController));
  router.use('/student', createStudentRoutes(container.studentController));
  router.use('/admin', createAdminRoutes(container.adminController));
  router.use('/payment', createPaymentRoutes(container.paymentController));
  router.use('/notifications', createNotificationRoutes(container.notificationController));
  router.use('/commission', createCommissionRoutes(container.commissionController));

  return router;
}
