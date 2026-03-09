import { Router } from 'express';
import { CommissionController } from './commission.controller';
import { authenticate, requireRole } from '../../middleware/auth.middleware';
import { Role } from '@prisma/client';

export function createCommissionRoutes(controller: CommissionController): Router {
  const router = Router();

  router.get('/config', authenticate, requireRole(Role.ADMIN), controller.getConfig);
  router.patch('/config', authenticate, requireRole(Role.ADMIN), controller.updateConfig);

  router.get('/balances', authenticate, requireRole(Role.ADMIN), controller.getVendorBalances);
  router.get('/balances/:vendorId', authenticate, requireRole(Role.ADMIN, Role.VENDOR), controller.getVendorBalance);

  router.get('/settlements/pending', authenticate, requireRole(Role.ADMIN), controller.getPendingSettlements);
  router.get('/settlements/vendor/:vendorId', authenticate, requireRole(Role.ADMIN, Role.VENDOR), controller.getVendorSettlements);
  router.post('/settlements', authenticate, requireRole(Role.ADMIN), controller.createSettlement);
  router.post('/settlements/:settlementId/process', authenticate, requireRole(Role.ADMIN), controller.processSettlement);
  router.post('/settlements/:settlementId/fail', authenticate, requireRole(Role.ADMIN), controller.failSettlement);

  return router;
}
