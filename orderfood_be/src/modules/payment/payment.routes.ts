import { Router } from 'express';
import { PaymentController } from './payment.controller';
import { authenticate, requireRole } from '../../middleware/auth.middleware';
import { Role } from '@prisma/client';

export function createPaymentRoutes(controller: PaymentController): Router {
  const router = Router();

  router.use(authenticate);

  router.post('/', requireRole(Role.STUDENT), controller.createPayment);
  router.get('/:paymentId', controller.getPayment);
  router.get('/order/:orderId', controller.getPaymentByOrder);
  router.post('/:paymentId/confirm', controller.confirmPayment);
  router.get('/:paymentId/status', controller.checkStatus);

  return router;
}
