import { PrismaClient, RevenueEntry, RevenueSummary } from '@prisma/client';
import { DateRange } from './revenue.types';

export interface IRevenueRepository {
  createEntry(data: {
    vendorId: string;
    orderId: string;
    grossAmountInPaise: number;
    commissionInPaise: number;
    netAmountInPaise: number;
  }): Promise<RevenueEntry>;

  upsertDailySummary(
    vendorId: string,
    date: Date,
    grossAmount: number,
    commission: number,
    netAmount: number,
  ): Promise<RevenueSummary>;

  findSummaryByDate(vendorId: string, date: Date): Promise<RevenueSummary | null>;
  findSummariesByDateRange(vendorId: string, range: DateRange): Promise<RevenueSummary[]>;

  getOverallSummary(vendorId: string): Promise<{
    totalOrderCount: number;
    grossRevenueInPaise: number;
    totalCommissionInPaise: number;
    netRevenueInPaise: number;
  }>;

  findEntries(
    vendorId: string,
    page: number,
    limit: number,
  ): Promise<{ entries: RevenueEntry[]; total: number }>;
}

export class RevenueRepository implements IRevenueRepository {
  constructor(private prisma: PrismaClient) {}

  async createEntry(data: {
    vendorId: string;
    orderId: string;
    grossAmountInPaise: number;
    commissionInPaise: number;
    netAmountInPaise: number;
  }): Promise<RevenueEntry> {
    return this.prisma.revenueEntry.create({ data });
  }

  async upsertDailySummary(
    vendorId: string,
    date: Date,
    grossAmount: number,
    commission: number,
    netAmount: number,
  ): Promise<RevenueSummary> {
    const normalizedDate = new Date(date);
    normalizedDate.setHours(0, 0, 0, 0);

    return this.prisma.revenueSummary.upsert({
      where: { vendorId_date: { vendorId, date: normalizedDate } },
      update: {
        totalOrderCount: { increment: 1 },
        grossRevenueInPaise: { increment: grossAmount },
        totalCommissionInPaise: { increment: commission },
        netRevenueInPaise: { increment: netAmount },
      },
      create: {
        vendorId,
        date: normalizedDate,
        totalOrderCount: 1,
        grossRevenueInPaise: grossAmount,
        totalCommissionInPaise: commission,
        netRevenueInPaise: netAmount,
      },
    });
  }

  async findSummaryByDate(vendorId: string, date: Date): Promise<RevenueSummary | null> {
    const normalizedDate = new Date(date);
    normalizedDate.setHours(0, 0, 0, 0);

    return this.prisma.revenueSummary.findUnique({
      where: { vendorId_date: { vendorId, date: normalizedDate } },
    });
  }

  async findSummariesByDateRange(vendorId: string, range: DateRange): Promise<RevenueSummary[]> {
    return this.prisma.revenueSummary.findMany({
      where: {
        vendorId,
        date: { gte: range.from, lte: range.to },
      },
      orderBy: { date: 'desc' },
    });
  }

  async getOverallSummary(vendorId: string): Promise<{
    totalOrderCount: number;
    grossRevenueInPaise: number;
    totalCommissionInPaise: number;
    netRevenueInPaise: number;
  }> {
    const result = await this.prisma.revenueSummary.aggregate({
      where: { vendorId },
      _sum: {
        totalOrderCount: true,
        grossRevenueInPaise: true,
        totalCommissionInPaise: true,
        netRevenueInPaise: true,
      },
    });

    return {
      totalOrderCount: result._sum.totalOrderCount ?? 0,
      grossRevenueInPaise: result._sum.grossRevenueInPaise ?? 0,
      totalCommissionInPaise: result._sum.totalCommissionInPaise ?? 0,
      netRevenueInPaise: result._sum.netRevenueInPaise ?? 0,
    };
  }

  async findEntries(
    vendorId: string,
    page: number,
    limit: number,
  ): Promise<{ entries: RevenueEntry[]; total: number }> {
    const [entries, total] = await Promise.all([
      this.prisma.revenueEntry.findMany({
        where: { vendorId },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.revenueEntry.count({ where: { vendorId } }),
    ]);

    return { entries, total };
  }
}
