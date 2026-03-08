import express from 'express';
import cors from 'cors';
import path from 'path';
import { env } from './config/env';
import prisma from './config/database';
import { createContainer } from './container';
import { createRouter } from './routes';
import { errorHandler } from './middleware';

export function createApp() {
  const app = express();
  const container = createContainer(prisma);

  app.use(cors({ origin: env.CORS_ORIGIN }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  app.use('/uploads', express.static(path.resolve(env.UPLOAD_DIR)));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.use('/api', createRouter(container));

  app.use(errorHandler);

  return { app, container };
}

if (require.main === module) {
  const { app } = createApp();
  app.listen(env.PORT, () => {
    console.log(`Server running on http://localhost:${env.PORT}`);
    console.log(`Environment: ${env.NODE_ENV}`);
  });
}
