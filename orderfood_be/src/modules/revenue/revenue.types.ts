export interface RecordRevenueInput {
  vendorId: string;
  orderId: string;
  grossAmountInPaise: number;
  commissionInPaise?: number;
}

export interface RevenueSummaryData {
  totalOrderCount: number;
  grossRevenueInPaise: number;
  totalCommissionInPaise: number;
  netRevenueInPaise: number;
  currency: string;
}

export interface RevenueSummaryFormatted extends RevenueSummaryData {
  grossRevenueFormatted: string;
  totalCommissionFormatted: string;
  netRevenueFormatted: string;
}

export interface RevenueEntryData {
  id: string;
  vendorId: string;
  orderId: string;
  grossAmountInPaise: number;
  commissionInPaise: number;
  netAmountInPaise: number;
  currency: string;
  createdAt: Date;
}

export interface DateRange {
  from: Date;
  to: Date;
}
