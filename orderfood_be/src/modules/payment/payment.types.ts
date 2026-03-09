import { PaymentStatus } from '@prisma/client';

export interface CreatePaymentInput {
  orderId: string;
  amountInPaise: number;
  vendorUpiId?: string;
}

export interface PaymentData {
  id: string;
  orderId: string;
  amountInPaise: number;
  status: PaymentStatus;
  qrCodeData: string;
  upiId: string | null;
  transactionId: string | null;
  paidAt: Date | null;
  expiresAt: Date;
  createdAt: Date;
}

export interface PaymentWithOrder extends PaymentData {
  order: {
    id: string;
    status: string;
    vendorName: string;
    studentName: string;
    vendor?: { restaurantName: string; userId: string };
    student?: { name: string; userId: string };
    items?: unknown[];
  };
}

export interface QrPaymentData {
  paymentId: string;
  orderId: string;
  amount: number;
  amountFormatted: string;
  qrCodeData: string;
  upiDeepLink: string;
  expiresAt: Date;
  status: PaymentStatus;
}

export interface ConfirmPaymentInput {
  paymentId: string;
  transactionId: string;
}
