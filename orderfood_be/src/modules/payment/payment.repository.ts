import { PrismaClient, Payment, PaymentStatus } from '@prisma/client';
import { PaymentData, PaymentWithOrder } from './payment.types';

export interface IPaymentRepository {
  create(data: {
    orderId: string;
    amountInPaise: number;
    commissionInPaise?: number;
    vendorAmountInPaise?: number;
    qrCodeData: string;
    upiId?: string;
    expiresAt: Date;
  }): Promise<Payment>;
  findById(id: string): Promise<Payment | null>;
  findByOrderId(orderId: string): Promise<Payment | null>;
  findByIdWithOrder(id: string): Promise<PaymentWithOrder | null>;
  updateStatus(id: string, status: PaymentStatus, transactionId?: string): Promise<Payment>;
  updateOrderPaymentStatus(orderId: string, status: PaymentStatus): Promise<void>;
}

export class PaymentRepository implements IPaymentRepository {
  constructor(private prisma: PrismaClient) {}

  async create(data: {
    orderId: string;
    amountInPaise: number;
    commissionInPaise?: number;
    vendorAmountInPaise?: number;
    qrCodeData: string;
    upiId?: string;
    expiresAt: Date;
  }): Promise<Payment> {
    return this.prisma.payment.create({ 
      data: {
        orderId: data.orderId,
        amountInPaise: data.amountInPaise,
        commissionInPaise: data.commissionInPaise ?? 0,
        vendorAmountInPaise: data.vendorAmountInPaise ?? data.amountInPaise,
        qrCodeData: data.qrCodeData,
        upiId: data.upiId,
        expiresAt: data.expiresAt,
      },
    });
  }

  async findById(id: string): Promise<Payment | null> {
    return this.prisma.payment.findUnique({ where: { id } });
  }

  async findByOrderId(orderId: string): Promise<Payment | null> {
    return this.prisma.payment.findUnique({ where: { orderId } });
  }

  async findByIdWithOrder(id: string): Promise<PaymentWithOrder | null> {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: {
        order: {
          include: {
            vendor: { select: { id: true, restaurantName: true, userId: true } },
            student: { select: { name: true, userId: true } },
            items: true,
          },
        },
      },
    });

    if (!payment) return null;

    return {
      id: payment.id,
      orderId: payment.orderId,
      amountInPaise: payment.amountInPaise,
      commissionInPaise: payment.commissionInPaise,
      vendorAmountInPaise: payment.vendorAmountInPaise,
      status: payment.status,
      qrCodeData: payment.qrCodeData,
      upiId: payment.upiId,
      transactionId: payment.transactionId,
      paidAt: payment.paidAt,
      expiresAt: payment.expiresAt,
      createdAt: payment.createdAt,
      order: {
        id: payment.order.id,
        status: payment.order.status,
        vendorName: payment.order.vendor.restaurantName,
        studentName: payment.order.student.name,
        vendor: payment.order.vendor,
        student: payment.order.student,
        items: payment.order.items,
      },
    };
  }

  async updateStatus(id: string, status: PaymentStatus, transactionId?: string): Promise<Payment> {
    const data: { status: PaymentStatus; transactionId?: string; paidAt?: Date } = { status };
    if (transactionId) data.transactionId = transactionId;
    if (status === PaymentStatus.COMPLETED) data.paidAt = new Date();

    return this.prisma.payment.update({
      where: { id },
      data,
    });
  }

  async updateOrderPaymentStatus(orderId: string, status: PaymentStatus): Promise<void> {
    await this.prisma.order.update({
      where: { id: orderId },
      data: { paymentStatus: status },
    });
  }
}
