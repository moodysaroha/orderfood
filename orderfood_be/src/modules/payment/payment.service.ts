import { PaymentStatus } from '@prisma/client';
import { IPaymentRepository } from './payment.repository';
import { IRevenueService } from '../revenue';
import { INotificationService } from '../notification';
import {
  CreatePaymentInput,
  QrPaymentData,
  PaymentWithOrder,
  ConfirmPaymentInput,
} from './payment.types';
import { env } from '../../config/env';
import { paiseToRupees, formatINR } from '../../utils/currency';
import { AppError } from '../../middleware';

export interface IPaymentService {
  createPayment(input: CreatePaymentInput): Promise<QrPaymentData>;
  getPayment(paymentId: string): Promise<PaymentWithOrder>;
  getPaymentByOrder(orderId: string): Promise<PaymentWithOrder | null>;
  confirmPayment(input: ConfirmPaymentInput): Promise<PaymentWithOrder>;
  checkPaymentStatus(paymentId: string): Promise<{ status: PaymentStatus; isExpired: boolean }>;
}

export class PaymentService implements IPaymentService {
  constructor(
    private paymentRepo: IPaymentRepository,
    private revenueService?: IRevenueService,
    private notificationService?: INotificationService,
  ) {}

  async createPayment(input: CreatePaymentInput): Promise<QrPaymentData> {
    const existingPayment = await this.paymentRepo.findByOrderId(input.orderId);
    if (existingPayment) {
      if (existingPayment.status === PaymentStatus.COMPLETED) {
        throw new AppError(400, 'Order already paid');
      }
      if (existingPayment.status === PaymentStatus.PENDING && existingPayment.expiresAt > new Date()) {
        return this.formatQrPaymentData(existingPayment);
      }
    }

    const upiId = input.vendorUpiId || env.DEFAULT_UPI_ID;
    const amountInRupees = paiseToRupees(input.amountInPaise);
    const expiresAt = new Date(Date.now() + env.PAYMENT_EXPIRY_MINUTES * 60 * 1000);

    const qrCodeData = this.generateUpiQrData(upiId, amountInRupees, input.orderId);

    const payment = await this.paymentRepo.create({
      orderId: input.orderId,
      amountInPaise: input.amountInPaise,
      qrCodeData,
      upiId,
      expiresAt,
    });

    return this.formatQrPaymentData(payment);
  }

  async getPayment(paymentId: string): Promise<PaymentWithOrder> {
    const payment = await this.paymentRepo.findByIdWithOrder(paymentId);
    if (!payment) {
      throw new AppError(404, 'Payment not found');
    }
    return payment;
  }

  async getPaymentByOrder(orderId: string): Promise<PaymentWithOrder | null> {
    const payment = await this.paymentRepo.findByOrderId(orderId);
    if (!payment) return null;
    return this.paymentRepo.findByIdWithOrder(payment.id);
  }

  async confirmPayment(input: ConfirmPaymentInput): Promise<PaymentWithOrder> {
    const payment = await this.paymentRepo.findByIdWithOrder(input.paymentId);
    if (!payment) {
      throw new AppError(404, 'Payment not found');
    }

    if (payment.status === PaymentStatus.COMPLETED) {
      throw new AppError(400, 'Payment already confirmed');
    }

    if (payment.expiresAt < new Date()) {
      await this.paymentRepo.updateStatus(input.paymentId, PaymentStatus.FAILED);
      await this.paymentRepo.updateOrderPaymentStatus(payment.orderId, PaymentStatus.FAILED);

      if (this.notificationService && payment.order) {
        const context = {
          orderId: payment.orderId,
          orderTotal: formatINR(paiseToRupees(payment.amountInPaise)),
          studentName: (payment.order as any).student?.name || 'Student',
          vendorName: (payment.order as any).vendor?.restaurantName || 'Restaurant',
          itemCount: (payment.order as any).items?.length || 0,
        };
        const studentUserId = (payment.order as any).student?.userId;
        if (studentUserId) {
          await this.notificationService.notifyPaymentFailed(studentUserId, context);
        }
      }

      throw new AppError(400, 'Payment expired');
    }

    await this.paymentRepo.updateStatus(input.paymentId, PaymentStatus.COMPLETED, input.transactionId);
    await this.paymentRepo.updateOrderPaymentStatus(payment.orderId, PaymentStatus.COMPLETED);

    const confirmedPayment = await this.paymentRepo.findByIdWithOrder(input.paymentId) as PaymentWithOrder;

    if (this.notificationService && confirmedPayment.order) {
      const context = {
        orderId: confirmedPayment.orderId,
        orderTotal: formatINR(paiseToRupees(confirmedPayment.amountInPaise)),
        studentName: (confirmedPayment.order as any).student?.name || 'Student',
        vendorName: (confirmedPayment.order as any).vendor?.restaurantName || 'Restaurant',
        itemCount: (confirmedPayment.order as any).items?.length || 0,
      };
      const studentUserId = (confirmedPayment.order as any).student?.userId;
      const vendorUserId = (confirmedPayment.order as any).vendor?.userId;
      if (studentUserId && vendorUserId) {
        await this.notificationService.notifyPaymentReceived(studentUserId, vendorUserId, context);
      }
    }

    return confirmedPayment;
  }

  async checkPaymentStatus(paymentId: string): Promise<{ status: PaymentStatus; isExpired: boolean }> {
    const payment = await this.paymentRepo.findById(paymentId);
    if (!payment) {
      throw new AppError(404, 'Payment not found');
    }

    const isExpired = payment.expiresAt < new Date() && payment.status === PaymentStatus.PENDING;
    return { status: payment.status, isExpired };
  }

  private generateUpiQrData(upiId: string, amount: number, orderId: string): string {
    const params = new URLSearchParams({
      pa: upiId,
      pn: 'OrderFood',
      am: amount.toFixed(2),
      cu: 'INR',
      tn: `Order ${orderId.slice(0, 8)}`,
    });
    return `upi://pay?${params.toString()}`;
  }

  private formatQrPaymentData(payment: {
    id: string;
    orderId: string;
    amountInPaise: number;
    qrCodeData: string;
    upiId: string | null;
    expiresAt: Date;
    status: PaymentStatus;
  }): QrPaymentData {
    return {
      paymentId: payment.id,
      orderId: payment.orderId,
      amount: paiseToRupees(payment.amountInPaise),
      amountFormatted: formatINR(paiseToRupees(payment.amountInPaise)),
      qrCodeData: payment.qrCodeData,
      upiDeepLink: payment.qrCodeData,
      expiresAt: payment.expiresAt,
      status: payment.status,
    };
  }
}
