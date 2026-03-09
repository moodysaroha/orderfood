import { OrderStatus } from '@prisma/client';
import { IAdminRepository } from './admin.repository';
import {
  PlatformStats,
  PlatformStatsFormatted,
  VendorWithStats,
  StudentWithStats,
  OrderWithDetails,
} from './admin.types';
import { paiseToRupees, formatINR } from '../../utils/currency';

export interface IAdminService {
  getPlatformStats(): Promise<PlatformStatsFormatted>;
  getPlatformStatsRaw(): Promise<PlatformStats>;
  getAllVendors(): Promise<VendorWithStats[]>;
  getAllStudents(): Promise<StudentWithStats[]>;
  getAllOrders(filters?: { status?: string; vendorId?: string }): Promise<OrderWithDetails[]>;
  deleteVendor(vendorId: string): Promise<void>;
  deleteStudent(studentId: string): Promise<void>;
}

export class AdminService implements IAdminService {
  constructor(private adminRepo: IAdminRepository) {}

  async getPlatformStats(): Promise<PlatformStatsFormatted> {
    const stats = await this.adminRepo.getPlatformStats();
    return {
      totalVendors: stats.totalVendors,
      totalStudents: stats.totalStudents,
      totalOrders: stats.totalOrders,
      totalRevenue: formatINR(paiseToRupees(stats.totalRevenueInPaise)),
      ordersToday: stats.ordersToday,
      revenueToday: formatINR(paiseToRupees(stats.revenueToday)),
    };
  }

  async getPlatformStatsRaw(): Promise<PlatformStats> {
    return this.adminRepo.getPlatformStats();
  }

  async getAllVendors(): Promise<VendorWithStats[]> {
    return this.adminRepo.getAllVendors();
  }

  async getAllStudents(): Promise<StudentWithStats[]> {
    return this.adminRepo.getAllStudents();
  }

  async getAllOrders(filters?: { status?: string; vendorId?: string }): Promise<OrderWithDetails[]> {
    const orderFilters: { status?: OrderStatus; vendorId?: string } = {};
    if (filters?.status) orderFilters.status = filters.status as OrderStatus;
    if (filters?.vendorId) orderFilters.vendorId = filters.vendorId;
    return this.adminRepo.getAllOrders(orderFilters);
  }

  async deleteVendor(vendorId: string): Promise<void> {
    await this.adminRepo.deleteVendor(vendorId);
  }

  async deleteStudent(studentId: string): Promise<void> {
    await this.adminRepo.deleteStudent(studentId);
  }
}
