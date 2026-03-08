import { IRevenueRepository } from './revenue.repository';
import {
  RecordRevenueInput,
  RevenueSummaryData,
  RevenueSummaryFormatted,
  RevenueEntryData,
  DateRange,
} from './revenue.types';
import { formatPaiseToINR } from '../../utils/currency';
import { PaginatedResult } from '../../types';

export interface IRevenueService {
  recordRevenue(input: RecordRevenueInput): Promise<RevenueEntryData>;
  getTodaySummary(vendorId: string): Promise<RevenueSummaryFormatted>;
  getOverallSummary(vendorId: string): Promise<RevenueSummaryFormatted>;
  getSummaryByDateRange(vendorId: string, range: DateRange): Promise<RevenueSummaryFormatted>;
  getEntries(vendorId: string, page: number, limit: number): Promise<PaginatedResult<RevenueEntryData>>;
}

const EMPTY_SUMMARY: RevenueSummaryData = {
  totalOrderCount: 0,
  grossRevenueInPaise: 0,
  totalCommissionInPaise: 0,
  netRevenueInPaise: 0,
  currency: 'INR',
};

function formatSummary(data: RevenueSummaryData): RevenueSummaryFormatted {
  return {
    ...data,
    grossRevenueFormatted: formatPaiseToINR(data.grossRevenueInPaise),
    totalCommissionFormatted: formatPaiseToINR(data.totalCommissionInPaise),
    netRevenueFormatted: formatPaiseToINR(data.netRevenueInPaise),
  };
}

export class RevenueService implements IRevenueService {
  constructor(private revenueRepo: IRevenueRepository) {}

  async recordRevenue(input: RecordRevenueInput): Promise<RevenueEntryData> {
    const commission = input.commissionInPaise ?? 0;
    const net = input.grossAmountInPaise - commission;

    const entry = await this.revenueRepo.createEntry({
      vendorId: input.vendorId,
      orderId: input.orderId,
      grossAmountInPaise: input.grossAmountInPaise,
      commissionInPaise: commission,
      netAmountInPaise: net,
    });

    await this.revenueRepo.upsertDailySummary(
      input.vendorId,
      new Date(),
      input.grossAmountInPaise,
      commission,
      net,
    );

    return {
      id: entry.id,
      vendorId: entry.vendorId,
      orderId: entry.orderId,
      grossAmountInPaise: entry.grossAmountInPaise,
      commissionInPaise: entry.commissionInPaise,
      netAmountInPaise: entry.netAmountInPaise,
      currency: entry.currency,
      createdAt: entry.createdAt,
    };
  }

  async getTodaySummary(vendorId: string): Promise<RevenueSummaryFormatted> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const summary = await this.revenueRepo.findSummaryByDate(vendorId, today);
    if (!summary) return formatSummary(EMPTY_SUMMARY);

    return formatSummary({
      totalOrderCount: summary.totalOrderCount,
      grossRevenueInPaise: summary.grossRevenueInPaise,
      totalCommissionInPaise: summary.totalCommissionInPaise,
      netRevenueInPaise: summary.netRevenueInPaise,
      currency: summary.currency,
    });
  }

  async getOverallSummary(vendorId: string): Promise<RevenueSummaryFormatted> {
    const overall = await this.revenueRepo.getOverallSummary(vendorId);
    return formatSummary({ ...overall, currency: 'INR' });
  }

  async getSummaryByDateRange(vendorId: string, range: DateRange): Promise<RevenueSummaryFormatted> {
    const summaries = await this.revenueRepo.findSummariesByDateRange(vendorId, range);

    if (summaries.length === 0) return formatSummary(EMPTY_SUMMARY);

    const aggregated = summaries.reduce(
      (acc, s) => ({
        totalOrderCount: acc.totalOrderCount + s.totalOrderCount,
        grossRevenueInPaise: acc.grossRevenueInPaise + s.grossRevenueInPaise,
        totalCommissionInPaise: acc.totalCommissionInPaise + s.totalCommissionInPaise,
        netRevenueInPaise: acc.netRevenueInPaise + s.netRevenueInPaise,
        currency: 'INR' as const,
      }),
      { ...EMPTY_SUMMARY },
    );

    return formatSummary(aggregated);
  }

  async getEntries(vendorId: string, page: number, limit: number): Promise<PaginatedResult<RevenueEntryData>> {
    const { entries, total } = await this.revenueRepo.findEntries(vendorId, page, limit);

    return {
      data: entries.map((e) => ({
        id: e.id,
        vendorId: e.vendorId,
        orderId: e.orderId,
        grossAmountInPaise: e.grossAmountInPaise,
        commissionInPaise: e.commissionInPaise,
        netAmountInPaise: e.netAmountInPaise,
        currency: e.currency,
        createdAt: e.createdAt,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
