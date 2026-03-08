import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { z } from 'zod';
import { VendorController } from '../controllers/vendor.controller';
import { authenticate, requireRole, validate } from '../middleware';
import { env } from '../config/env';

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, path.resolve(env.UPLOAD_DIR)),
  filename: (_req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname);
    cb(null, `menu-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: env.MAX_FILE_SIZE_MB * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, WebP, and GIF images are allowed'));
    }
  },
});

const createItemSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  price: z.coerce.number().positive(),
  category: z.string().max(50).optional(),
  sortOrder: z.coerce.number().int().optional(),
});

const updateItemSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().max(500).optional(),
  price: z.coerce.number().positive().optional(),
  category: z.string().max(50).optional(),
  sortOrder: z.coerce.number().int().optional(),
});

const updateStatusSchema = z.object({
  status: z.enum(['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'DELIVERED', 'CANCELLED']),
});

export function createVendorRoutes(controller: VendorController): Router {
  const router = Router();

  router.use(authenticate);
  router.use(requireRole('VENDOR'));

  router.get('/dashboard', controller.getDashboard);
  router.get('/menu', controller.getMenu);
  router.post('/menu/items', validate(createItemSchema), controller.createMenuItem);
  router.put('/menu/items/:id', validate(updateItemSchema), controller.updateMenuItem);
  router.patch('/menu/items/:id/availability', controller.toggleAvailability);
  router.post('/menu/items/:id/image', upload.single('image'), controller.uploadImage);
  router.delete('/menu/items/:id', controller.deleteMenuItem);
  router.get('/orders', controller.getOrders);
  router.patch('/orders/:id/status', validate(updateStatusSchema), controller.updateOrderStatus);

  return router;
}
