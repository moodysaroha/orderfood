import { Router } from 'express';
import { SduiController } from '../controllers/sdui.controller';

export function createSduiRoutes(controller: SduiController): Router {
  const router = Router();

  router.get('/layouts', controller.getLayouts);
  router.put('/layouts/:screenName', controller.updateLayout);
  router.get('/components', controller.getComponents);

  return router;
}
