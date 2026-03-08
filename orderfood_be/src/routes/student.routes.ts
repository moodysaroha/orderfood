import { Router } from 'express';
import { z } from 'zod';
import { StudentController } from '../controllers/student.controller';
import { authenticate, requireRole, validate } from '../middleware';

const placeOrderSchema = z.object({
  vendorId: z.string().uuid(),
  items: z.array(
    z.object({
      menuItemId: z.string().uuid(),
      quantity: z.number().int().positive(),
    }),
  ).min(1),
});

export function createStudentRoutes(controller: StudentController): Router {
  const router = Router();

  // Menu browsing (SDUI) -- authenticated students
  router.get('/menu/:vendorId', authenticate, controller.getMenu);

  // Order management
  router.post('/orders', authenticate, requireRole('STUDENT'), validate(placeOrderSchema), controller.placeOrder);
  router.get('/orders', authenticate, requireRole('STUDENT'), controller.getOrders);
  router.get('/orders/:id', authenticate, requireRole('STUDENT'), controller.getOrderDetail);

  return router;
}
