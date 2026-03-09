import { Router } from 'express';
import { AdminController } from './admin.controller';
import { authenticate, requireRole } from '../../middleware/auth.middleware';
import { Role } from '@prisma/client';

export function createAdminRoutes(controller: AdminController): Router {
  const router = Router();

  router.use(authenticate);
  router.use(requireRole(Role.ADMIN));

  // SDUI endpoints
  router.get('/dashboard', controller.getDashboardSdui);
  router.get('/dashboard/vendors', controller.getVendorsSdui);
  router.get('/dashboard/students', controller.getStudentsSdui);
  router.get('/dashboard/orders', controller.getOrdersSdui);

  // Data endpoints
  router.get('/stats', controller.getStats);
  router.get('/vendors', controller.getVendors);
  router.get('/students', controller.getStudents);
  router.get('/orders', controller.getOrders);
  router.delete('/vendors/:vendorId', controller.deleteVendor);
  router.delete('/students/:studentId', controller.deleteStudent);

  // Bulk upload
  router.post('/vendors/bulk', controller.bulkUploadVendors);

  return router;
}
