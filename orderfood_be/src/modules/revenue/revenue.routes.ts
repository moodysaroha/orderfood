import { Router } from 'express';
import { RevenueController } from './revenue.controller';
import { authenticate, requireRole } from '../../middleware';

export function createRevenueRoutes(controller: RevenueController): Router {
  const router = Router();

  router.use(authenticate);
  router.use(requireRole('VENDOR'));

  router.get('/today', controller.getToday);
  router.get('/overall', controller.getOverall);
  router.get('/summary', controller.getSummary);
  router.get('/entries', controller.getEntries);

  return router;
}
