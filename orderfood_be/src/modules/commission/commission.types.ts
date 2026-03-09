import { SettlementStatus } from '@prisma/client';

export interface PlatformConfigData {
  commissionPercentage: number;
  platformUpiId: string;
  platformName: string;
  minSettlementAmount: number;
}

export interface VendorBalanceData {
  vendorId: string;
  vendorName: string;
  pendingAmountInPaise: number;
  settledAmountInPaise: number;
  lastSettlementAt: Date | null;
}

export interface VendorSettlementData {
  id: string;
  vendorId: string;
  vendorName: string;
  amountInPaise: number;
  status: SettlementStatus;
  referenceId: string | null;
  notes: string | null;
  processedAt: Date | null;
  createdAt: Date;
}

export interface CreateSettlementInput {
  vendorId: string;
  amountInPaise: number;
  notes?: string;
}

export interface ProcessSettlementInput {
  settlementId: string;
  referenceId: string;
  notes?: string;
}

export interface CommissionCalculation {
  grossAmountInPaise: number;
  commissionInPaise: number;
  vendorAmountInPaise: number;
  commissionPercentage: number;
}
