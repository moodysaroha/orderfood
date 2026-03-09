import { Request, Response, NextFunction } from 'express';
import { ICommissionService } from './commission.service';
import { formatINR, paiseToRupees } from '../../utils/currency';
import { AppError } from '../../middleware';

function paramStr(val: string | string[] | undefined): string {
  return Array.isArray(val) ? val[0] : val ?? '';
}

export class CommissionController {
  constructor(private commissionService: ICommissionService) {}

  getConfig = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const config = await this.commissionService.getConfig();
      res.json({
        success: true,
        data: {
          ...config,
          minSettlementAmountFormatted: formatINR(paiseToRupees(config.minSettlementAmount)),
        },
      });
    } catch (err) {
      next(err);
    }
  };

  updateConfig = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { commissionPercentage, platformUpiId, platformName, minSettlementAmount } = req.body;

      const config = await this.commissionService.updateConfig({
        commissionPercentage,
        platformUpiId,
        platformName,
        minSettlementAmount,
      });

      res.json({
        success: true,
        data: config,
        message: 'Platform configuration updated',
      });
    } catch (err) {
      next(err);
    }
  };

  getVendorBalances = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const balances = await this.commissionService.getAllVendorBalances();
      
      const formatted = balances.map((b) => ({
        ...b,
        pendingAmountFormatted: formatINR(paiseToRupees(b.pendingAmountInPaise)),
        settledAmountFormatted: formatINR(paiseToRupees(b.settledAmountInPaise)),
      }));

      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };

  getVendorBalance = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const vendorId = paramStr(req.params.vendorId);
      const balance = await this.commissionService.getVendorBalance(vendorId);

      if (!balance) {
        res.json({
          success: true,
          data: {
            vendorId,
            pendingAmountInPaise: 0,
            settledAmountInPaise: 0,
            pendingAmountFormatted: formatINR(0),
            settledAmountFormatted: formatINR(0),
            lastSettlementAt: null,
          },
        });
        return;
      }

      res.json({
        success: true,
        data: {
          ...balance,
          pendingAmountFormatted: formatINR(paiseToRupees(balance.pendingAmountInPaise)),
          settledAmountFormatted: formatINR(paiseToRupees(balance.settledAmountInPaise)),
        },
      });
    } catch (err) {
      next(err);
    }
  };

  createSettlement = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { vendorId, amountInPaise, notes } = req.body;

      if (!vendorId || !amountInPaise) {
        throw new AppError(400, 'vendorId and amountInPaise are required');
      }

      const settlement = await this.commissionService.createSettlement({
        vendorId,
        amountInPaise,
        notes,
      });

      res.status(201).json({
        success: true,
        data: {
          ...settlement,
          amountFormatted: formatINR(paiseToRupees(settlement.amountInPaise)),
        },
        message: 'Settlement created',
      });
    } catch (err) {
      next(err);
    }
  };

  processSettlement = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const settlementId = paramStr(req.params.settlementId);
      const { referenceId, notes } = req.body;

      if (!referenceId) {
        throw new AppError(400, 'referenceId is required');
      }

      const settlement = await this.commissionService.processSettlement({
        settlementId,
        referenceId,
        notes,
      });

      res.json({
        success: true,
        data: {
          ...settlement,
          amountFormatted: formatINR(paiseToRupees(settlement.amountInPaise)),
        },
        message: 'Settlement processed successfully',
      });
    } catch (err) {
      next(err);
    }
  };

  failSettlement = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const settlementId = paramStr(req.params.settlementId);
      const { notes } = req.body;

      const settlement = await this.commissionService.failSettlement(settlementId, notes);

      res.json({
        success: true,
        data: {
          ...settlement,
          amountFormatted: formatINR(paiseToRupees(settlement.amountInPaise)),
        },
        message: 'Settlement marked as failed, amount returned to vendor balance',
      });
    } catch (err) {
      next(err);
    }
  };

  getPendingSettlements = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const settlements = await this.commissionService.getPendingSettlements();
      
      const formatted = settlements.map((s) => ({
        ...s,
        amountFormatted: formatINR(paiseToRupees(s.amountInPaise)),
      }));

      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };

  getVendorSettlements = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const vendorId = paramStr(req.params.vendorId);
      const settlements = await this.commissionService.getVendorSettlements(vendorId);
      
      const formatted = settlements.map((s) => ({
        ...s,
        amountFormatted: formatINR(paiseToRupees(s.amountInPaise)),
      }));

      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };
}
