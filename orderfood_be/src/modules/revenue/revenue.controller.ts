import { Request, Response, NextFunction } from 'express';
import { IRevenueService } from './revenue.service';
import { ApiResponse } from '../../types';
import { AppError } from '../../middleware';

export class RevenueController {
  constructor(private revenueService: IRevenueService) {}

  getToday = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const summary = await this.revenueService.getTodaySummary(vendorId);
      res.json({ success: true, data: summary });
    } catch (err) {
      next(err);
    }
  };

  getOverall = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const summary = await this.revenueService.getOverallSummary(vendorId);
      res.json({ success: true, data: summary });
    } catch (err) {
      next(err);
    }
  };

  getSummary = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const from = req.query.from ? new Date(req.query.from as string) : new Date();
      const to = req.query.to ? new Date(req.query.to as string) : new Date();

      if (isNaN(from.getTime()) || isNaN(to.getTime())) {
        throw new AppError(400, 'Invalid date format. Use ISO 8601 (YYYY-MM-DD).');
      }

      const summary = await this.revenueService.getSummaryByDateRange(vendorId, { from, to });
      res.json({ success: true, data: summary });
    } catch (err) {
      next(err);
    }
  };

  getEntries = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const page = Math.max(1, parseInt(req.query.page as string) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string) || 20));

      const result = await this.revenueService.getEntries(vendorId, page, limit);
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };
}
