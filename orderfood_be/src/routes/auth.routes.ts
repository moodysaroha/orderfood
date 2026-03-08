import { Router } from 'express';
import { z } from 'zod';
import { AuthController } from '../controllers/auth.controller';
import { validate, authenticate } from '../middleware';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  role: z.enum(['VENDOR', 'STUDENT']),
  name: z.string().min(1).optional(),
  restaurantName: z.string().min(1).optional(),
  description: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export function createAuthRoutes(controller: AuthController): Router {
  const router = Router();

  router.post('/register', validate(registerSchema), controller.register);
  router.post('/login', validate(loginSchema), controller.login);
  router.get('/me', authenticate, controller.me);

  return router;
}
