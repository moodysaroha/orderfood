import { Request, Response, NextFunction } from 'express';
import { IAuthService } from '../services/auth.service';
import { ApiResponse } from '../types';

export class AuthController {
  constructor(private authService: IAuthService) {}

  register = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const result = await this.authService.register(req.body);
      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };

  login = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const result = await this.authService.login(req.body);
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };

  me = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const profile = await this.authService.getProfile(req.user!.userId);
      res.json({ success: true, data: profile });
    } catch (err) {
      next(err);
    }
  };
}
