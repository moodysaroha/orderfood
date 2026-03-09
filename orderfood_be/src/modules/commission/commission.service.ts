import { ICommissionRepository } from './commission.repository';
import {
  PlatformConfigData,
  VendorBalanceData,
  VendorSettlementData,
  CommissionCalculation,
  CreateSettlementInput,
  ProcessSettlementInput,
} from './commission.types';
import { AppError } from '../../middleware';

const CONFIG_KEYS = {
  COMMISSION_PERCENTAGE: 'commission_percentage',
  PLATFORM_UPI_ID: 'platform_upi_id',
  PLATFORM_NAME: 'platform_name',
  MIN_SETTLEMENT_AMOUNT: 'min_settlement_amount',
};

const DEFAULT_CONFIG: PlatformConfigData = {
  commissionPercentage: 10,
  platformUpiId: 'orderfood@upi',
  platformName: 'OrderFood',
  minSettlementAmount: 50000,
};

export interface ICommissionService {
  getConfig(): Promise<PlatformConfigData>;
  updateConfig(config: Partial<PlatformConfigData>): Promise<PlatformConfigData>;
  calculateCommission(grossAmountInPaise: number): Promise<CommissionCalculation>;
  
  recordPaymentForVendor(vendorId: string, vendorAmountInPaise: number): Promise<void>;
  getVendorBalance(vendorId: string): Promise<VendorBalanceData | null>;
  getAllVendorBalances(): Promise<VendorBalanceData[]>;
  
  createSettlement(input: CreateSettlementInput): Promise<VendorSettlementData>;
  processSettlement(input: ProcessSettlementInput): Promise<VendorSettlementData>;
  failSettlement(settlementId: string, notes?: string): Promise<VendorSettlementData>;
  getPendingSettlements(): Promise<VendorSettlementData[]>;
  getVendorSettlements(vendorId: string): Promise<VendorSettlementData[]>;
}

export class CommissionService implements ICommissionService {
  constructor(private repository: ICommissionRepository) {}

  async getConfig(): Promise<PlatformConfigData> {
    const [commissionPct, platformUpiId, platformName, minSettlement] = await Promise.all([
      this.repository.getConfig(CONFIG_KEYS.COMMISSION_PERCENTAGE),
      this.repository.getConfig(CONFIG_KEYS.PLATFORM_UPI_ID),
      this.repository.getConfig(CONFIG_KEYS.PLATFORM_NAME),
      this.repository.getConfig(CONFIG_KEYS.MIN_SETTLEMENT_AMOUNT),
    ]);

    return {
      commissionPercentage: commissionPct ? parseFloat(commissionPct) : DEFAULT_CONFIG.commissionPercentage,
      platformUpiId: platformUpiId ?? DEFAULT_CONFIG.platformUpiId,
      platformName: platformName ?? DEFAULT_CONFIG.platformName,
      minSettlementAmount: minSettlement ? parseInt(minSettlement) : DEFAULT_CONFIG.minSettlementAmount,
    };
  }

  async updateConfig(config: Partial<PlatformConfigData>): Promise<PlatformConfigData> {
    const updates: Promise<void>[] = [];

    if (config.commissionPercentage !== undefined) {
      if (config.commissionPercentage < 0 || config.commissionPercentage > 100) {
        throw new AppError(400, 'Commission percentage must be between 0 and 100');
      }
      updates.push(
        this.repository.setConfig(
          CONFIG_KEYS.COMMISSION_PERCENTAGE,
          config.commissionPercentage.toString(),
          'Platform commission percentage (0-100)'
        )
      );
    }

    if (config.platformUpiId !== undefined) {
      updates.push(
        this.repository.setConfig(
          CONFIG_KEYS.PLATFORM_UPI_ID,
          config.platformUpiId,
          'Platform UPI ID for receiving payments'
        )
      );
    }

    if (config.platformName !== undefined) {
      updates.push(
        this.repository.setConfig(
          CONFIG_KEYS.PLATFORM_NAME,
          config.platformName,
          'Platform name shown in UPI'
        )
      );
    }

    if (config.minSettlementAmount !== undefined) {
      updates.push(
        this.repository.setConfig(
          CONFIG_KEYS.MIN_SETTLEMENT_AMOUNT,
          config.minSettlementAmount.toString(),
          'Minimum amount in paise for vendor settlement'
        )
      );
    }

    await Promise.all(updates);
    return this.getConfig();
  }

  async calculateCommission(grossAmountInPaise: number): Promise<CommissionCalculation> {
    const config = await this.getConfig();
    const commissionInPaise = Math.round((grossAmountInPaise * config.commissionPercentage) / 100);
    const vendorAmountInPaise = grossAmountInPaise - commissionInPaise;

    return {
      grossAmountInPaise,
      commissionInPaise,
      vendorAmountInPaise,
      commissionPercentage: config.commissionPercentage,
    };
  }

  async recordPaymentForVendor(vendorId: string, vendorAmountInPaise: number): Promise<void> {
    await this.repository.createOrUpdateVendorBalance(vendorId, vendorAmountInPaise);
  }

  async getVendorBalance(vendorId: string): Promise<VendorBalanceData | null> {
    const balance = await this.repository.getVendorBalance(vendorId);
    if (!balance) return null;

    return {
      vendorId: balance.vendorId,
      vendorName: '',
      pendingAmountInPaise: balance.pendingAmountInPaise,
      settledAmountInPaise: balance.settledAmountInPaise,
      lastSettlementAt: balance.lastSettlementAt,
    };
  }

  async getAllVendorBalances(): Promise<VendorBalanceData[]> {
    return this.repository.getAllVendorBalances();
  }

  async createSettlement(input: CreateSettlementInput): Promise<VendorSettlementData> {
    const config = await this.getConfig();
    
    if (input.amountInPaise < config.minSettlementAmount) {
      throw new AppError(
        400,
        `Minimum settlement amount is ₹${(config.minSettlementAmount / 100).toFixed(2)}`
      );
    }

    const settlement = await this.repository.createSettlement(
      input.vendorId,
      input.amountInPaise,
      input.notes
    );

    const result = await this.repository.getSettlement(settlement.id);
    if (!result) throw new AppError(500, 'Failed to create settlement');
    return result;
  }

  async processSettlement(input: ProcessSettlementInput): Promise<VendorSettlementData> {
    await this.repository.processSettlement(
      input.settlementId,
      input.referenceId,
      input.notes
    );

    const result = await this.repository.getSettlement(input.settlementId);
    if (!result) throw new AppError(500, 'Settlement not found after processing');
    return result;
  }

  async failSettlement(settlementId: string, notes?: string): Promise<VendorSettlementData> {
    await this.repository.failSettlement(settlementId, notes);
    
    const result = await this.repository.getSettlement(settlementId);
    if (!result) throw new AppError(500, 'Settlement not found after failing');
    return result;
  }

  async getPendingSettlements(): Promise<VendorSettlementData[]> {
    return this.repository.getAllPendingSettlements();
  }

  async getVendorSettlements(vendorId: string): Promise<VendorSettlementData[]> {
    return this.repository.getVendorSettlements(vendorId);
  }
}
