import { PrismaClient, SettlementStatus, VendorBalance, VendorSettlement, PlatformConfig } from '@prisma/client';
import { VendorBalanceData, VendorSettlementData } from './commission.types';

export interface ICommissionRepository {
  getConfig(key: string): Promise<string | null>;
  setConfig(key: string, value: string, description?: string): Promise<void>;
  getAllConfig(): Promise<PlatformConfig[]>;
  
  getVendorBalance(vendorId: string): Promise<VendorBalance | null>;
  getAllVendorBalances(): Promise<VendorBalanceData[]>;
  createOrUpdateVendorBalance(vendorId: string, pendingIncrease: number): Promise<VendorBalance>;
  
  createSettlement(vendorId: string, amountInPaise: number, notes?: string): Promise<VendorSettlement>;
  getSettlement(id: string): Promise<VendorSettlementData | null>;
  getVendorSettlements(vendorId: string): Promise<VendorSettlementData[]>;
  getAllPendingSettlements(): Promise<VendorSettlementData[]>;
  processSettlement(id: string, referenceId: string, notes?: string): Promise<VendorSettlement>;
  failSettlement(id: string, notes?: string): Promise<VendorSettlement>;
}

export class CommissionRepository implements ICommissionRepository {
  constructor(private prisma: PrismaClient) {}

  async getConfig(key: string): Promise<string | null> {
    const config = await this.prisma.platformConfig.findUnique({ where: { key } });
    return config?.value ?? null;
  }

  async setConfig(key: string, value: string, description?: string): Promise<void> {
    await this.prisma.platformConfig.upsert({
      where: { key },
      update: { value, description },
      create: { key, value, description },
    });
  }

  async getAllConfig(): Promise<PlatformConfig[]> {
    return this.prisma.platformConfig.findMany({ orderBy: { key: 'asc' } });
  }

  async getVendorBalance(vendorId: string): Promise<VendorBalance | null> {
    return this.prisma.vendorBalance.findUnique({ where: { vendorId } });
  }

  async getAllVendorBalances(): Promise<VendorBalanceData[]> {
    const balances = await this.prisma.vendorBalance.findMany({
      include: { vendor: { select: { restaurantName: true } } },
      orderBy: { pendingAmountInPaise: 'desc' },
    });

    return balances.map((b) => ({
      vendorId: b.vendorId,
      vendorName: b.vendor.restaurantName,
      pendingAmountInPaise: b.pendingAmountInPaise,
      settledAmountInPaise: b.settledAmountInPaise,
      lastSettlementAt: b.lastSettlementAt,
    }));
  }

  async createOrUpdateVendorBalance(vendorId: string, pendingIncrease: number): Promise<VendorBalance> {
    return this.prisma.vendorBalance.upsert({
      where: { vendorId },
      update: { pendingAmountInPaise: { increment: pendingIncrease } },
      create: { vendorId, pendingAmountInPaise: pendingIncrease, settledAmountInPaise: 0 },
    });
  }

  async createSettlement(vendorId: string, amountInPaise: number, notes?: string): Promise<VendorSettlement> {
    return this.prisma.$transaction(async (tx) => {
      const balance = await tx.vendorBalance.findUnique({ where: { vendorId } });
      if (!balance || balance.pendingAmountInPaise < amountInPaise) {
        throw new Error('Insufficient pending balance for settlement');
      }

      await tx.vendorBalance.update({
        where: { vendorId },
        data: { pendingAmountInPaise: { decrement: amountInPaise } },
      });

      return tx.vendorSettlement.create({
        data: { vendorId, amountInPaise, notes, status: SettlementStatus.PENDING },
      });
    });
  }

  async getSettlement(id: string): Promise<VendorSettlementData | null> {
    const settlement = await this.prisma.vendorSettlement.findUnique({
      where: { id },
      include: { vendor: { select: { restaurantName: true } } },
    });

    if (!settlement) return null;

    return {
      id: settlement.id,
      vendorId: settlement.vendorId,
      vendorName: settlement.vendor.restaurantName,
      amountInPaise: settlement.amountInPaise,
      status: settlement.status,
      referenceId: settlement.referenceId,
      notes: settlement.notes,
      processedAt: settlement.processedAt,
      createdAt: settlement.createdAt,
    };
  }

  async getVendorSettlements(vendorId: string): Promise<VendorSettlementData[]> {
    const settlements = await this.prisma.vendorSettlement.findMany({
      where: { vendorId },
      include: { vendor: { select: { restaurantName: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return settlements.map((s) => ({
      id: s.id,
      vendorId: s.vendorId,
      vendorName: s.vendor.restaurantName,
      amountInPaise: s.amountInPaise,
      status: s.status,
      referenceId: s.referenceId,
      notes: s.notes,
      processedAt: s.processedAt,
      createdAt: s.createdAt,
    }));
  }

  async getAllPendingSettlements(): Promise<VendorSettlementData[]> {
    const settlements = await this.prisma.vendorSettlement.findMany({
      where: { status: { in: [SettlementStatus.PENDING, SettlementStatus.PROCESSING] } },
      include: { vendor: { select: { restaurantName: true } } },
      orderBy: { createdAt: 'asc' },
    });

    return settlements.map((s) => ({
      id: s.id,
      vendorId: s.vendorId,
      vendorName: s.vendor.restaurantName,
      amountInPaise: s.amountInPaise,
      status: s.status,
      referenceId: s.referenceId,
      notes: s.notes,
      processedAt: s.processedAt,
      createdAt: s.createdAt,
    }));
  }

  async processSettlement(id: string, referenceId: string, notes?: string): Promise<VendorSettlement> {
    return this.prisma.$transaction(async (tx) => {
      const settlement = await tx.vendorSettlement.findUnique({ where: { id } });
      if (!settlement) throw new Error('Settlement not found');
      if (settlement.status === SettlementStatus.COMPLETED) {
        throw new Error('Settlement already completed');
      }

      const updated = await tx.vendorSettlement.update({
        where: { id },
        data: {
          status: SettlementStatus.COMPLETED,
          referenceId,
          notes: notes ?? settlement.notes,
          processedAt: new Date(),
        },
      });

      await tx.vendorBalance.update({
        where: { vendorId: settlement.vendorId },
        data: {
          settledAmountInPaise: { increment: settlement.amountInPaise },
          lastSettlementAt: new Date(),
        },
      });

      return updated;
    });
  }

  async failSettlement(id: string, notes?: string): Promise<VendorSettlement> {
    return this.prisma.$transaction(async (tx) => {
      const settlement = await tx.vendorSettlement.findUnique({ where: { id } });
      if (!settlement) throw new Error('Settlement not found');
      if (settlement.status === SettlementStatus.COMPLETED) {
        throw new Error('Cannot fail a completed settlement');
      }

      await tx.vendorBalance.update({
        where: { vendorId: settlement.vendorId },
        data: { pendingAmountInPaise: { increment: settlement.amountInPaise } },
      });

      return tx.vendorSettlement.update({
        where: { id },
        data: { status: SettlementStatus.FAILED, notes },
      });
    });
  }
}
