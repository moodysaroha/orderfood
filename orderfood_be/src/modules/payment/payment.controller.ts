import { Request, Response, NextFunction } from 'express';
import { IPaymentService } from './payment.service';
import { AppError } from '../../middleware';

function paramStr(val: string | string[] | undefined): string {
  return Array.isArray(val) ? val[0] : val ?? '';
}

export class PaymentController {
  constructor(private paymentService: IPaymentService) {}

  createPayment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const studentId = req.user?.studentId;
      if (!studentId) throw new AppError(403, 'Student access required');

      const { orderId } = req.body;
      if (!orderId) throw new AppError(400, 'orderId is required');

      const payment = await this.paymentService.createPayment({
        orderId,
        amountInPaise: req.body.amountInPaise,
      });

      res.status(201).json({ success: true, data: payment });
    } catch (err) {
      next(err);
    }
  };

  getPayment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const payment = await this.paymentService.getPayment(paramStr(req.params.paymentId));
      res.json({ success: true, data: payment });
    } catch (err) {
      next(err);
    }
  };

  getPaymentByOrder = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const payment = await this.paymentService.getPaymentByOrder(paramStr(req.params.orderId));
      if (!payment) {
        res.json({ success: true, data: null });
        return;
      }
      res.json({ success: true, data: payment });
    } catch (err) {
      next(err);
    }
  };

  confirmPayment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { transactionId } = req.body;
      if (!transactionId) throw new AppError(400, 'transactionId is required');

      const payment = await this.paymentService.confirmPayment({
        paymentId: paramStr(req.params.paymentId),
        transactionId,
      });

      res.json({ success: true, data: payment, message: 'Payment confirmed' });
    } catch (err) {
      next(err);
    }
  };

  checkStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const status = await this.paymentService.checkPaymentStatus(paramStr(req.params.paymentId));
      res.json({ success: true, data: status });
    } catch (err) {
      next(err);
    }
  };
}
