import { Request, Response, NextFunction } from 'express';
import { Role } from '@prisma/client';
import { ISduiLayoutRepository } from '../repositories/sdui-layout.repository';
import { sduiRegistry, getComponentTypesList } from '../sdui';
import { ApiResponse } from '../types';
import { AppError } from '../middleware';

export class SduiController {
  constructor(private layoutRepo: ISduiLayoutRepository) {}

  getLayouts = async (_req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const layouts = await this.layoutRepo.findAll();
      const registeredScreens = sduiRegistry.getRegisteredScreens();
      res.json({
        success: true,
        data: { layouts, registeredScreens },
      });
    } catch (err) {
      next(err);
    }
  };

  updateLayout = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const screenName = Array.isArray(req.params.screenName) ? req.params.screenName[0] : req.params.screenName;
      const { layoutJson, role } = req.body;

      if (!layoutJson || !role) {
        throw new AppError(400, 'layoutJson and role are required');
      }

      if (!Object.values(Role).includes(role)) {
        throw new AppError(400, `Invalid role. Must be one of: ${Object.values(Role).join(', ')}`);
      }

      const layout = await this.layoutRepo.upsert({
        screenName,
        role,
        layoutJson,
        version: 1,
      });

      res.json({ success: true, data: layout });
    } catch (err) {
      next(err);
    }
  };

  getComponents = async (_req: Request, res: Response<ApiResponse>, _next: NextFunction): Promise<void> => {
    const components = getComponentTypesList();
    res.json({ success: true, data: components });
  };
}
