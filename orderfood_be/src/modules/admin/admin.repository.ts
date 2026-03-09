import { PrismaClient, OrderStatus, Role } from '@prisma/client';
import bcrypt from 'bcrypt';
import {
  PlatformStats,
  VendorWithStats,
  StudentWithStats,
  OrderWithDetails,
  BulkVendorInput,
} from './admin.types';
import { rupeesToPaise } from '../../utils/currency';

export interface CreatedVendor {
  id: string;
  email: string;
  restaurantName: string;
}

export interface IAdminRepository {
  getPlatformStats(): Promise<PlatformStats>;
  getAllVendors(): Promise<VendorWithStats[]>;
  getAllStudents(): Promise<StudentWithStats[]>;
  getAllOrders(filters?: { status?: OrderStatus; vendorId?: string }): Promise<OrderWithDetails[]>;
  deleteVendor(vendorId: string): Promise<void>;
  deleteStudent(studentId: string): Promise<void>;
  createVendorWithMenu(input: BulkVendorInput): Promise<CreatedVendor>;
  emailExists(email: string): Promise<boolean>;
}

export class AdminRepository implements IAdminRepository {
  constructor(private prisma: PrismaClient) {}

  async getPlatformStats(): Promise<PlatformStats> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalVendors,
      totalStudents,
      totalOrders,
      revenueAgg,
      ordersToday,
      revenueTodayAgg,
    ] = await Promise.all([
      this.prisma.vendor.count(),
      this.prisma.student.count(),
      this.prisma.order.count(),
      this.prisma.revenueEntry.aggregate({
        _sum: { netAmountInPaise: true },
      }),
      this.prisma.order.count({
        where: { createdAt: { gte: today } },
      }),
      this.prisma.revenueEntry.aggregate({
        where: { createdAt: { gte: today } },
        _sum: { netAmountInPaise: true },
      }),
    ]);

    return {
      totalVendors,
      totalStudents,
      totalOrders,
      totalRevenueInPaise: revenueAgg._sum.netAmountInPaise || 0,
      ordersToday,
      revenueToday: revenueTodayAgg._sum.netAmountInPaise || 0,
    };
  }

  async getAllVendors(): Promise<VendorWithStats[]> {
    const vendors = await this.prisma.vendor.findMany({
      include: {
        user: { select: { email: true } },
        orders: { select: { id: true, totalAmountInPaise: true } },
        revenueEntries: { select: { netAmountInPaise: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return vendors.map((v) => ({
      id: v.id,
      restaurantName: v.restaurantName,
      description: v.description,
      email: v.user.email,
      totalOrders: v.orders.length,
      totalRevenue: v.revenueEntries.reduce((sum, r) => sum + r.netAmountInPaise, 0),
      createdAt: v.createdAt,
    }));
  }

  async getAllStudents(): Promise<StudentWithStats[]> {
    const students = await this.prisma.student.findMany({
      include: {
        user: { select: { email: true } },
        orders: { select: { totalAmountInPaise: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return students.map((s) => ({
      id: s.id,
      name: s.name,
      email: s.user.email,
      totalOrders: s.orders.length,
      totalSpent: s.orders.reduce((sum, o) => sum + o.totalAmountInPaise, 0),
      createdAt: s.createdAt,
    }));
  }

  async getAllOrders(filters?: { status?: OrderStatus; vendorId?: string }): Promise<OrderWithDetails[]> {
    const where: Record<string, unknown> = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.vendorId) where.vendorId = filters.vendorId;

    const orders = await this.prisma.order.findMany({
      where,
      include: {
        student: {
          include: { user: { select: { email: true } } },
        },
        vendor: { select: { restaurantName: true } },
        items: { select: { id: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return orders.map((o) => ({
      id: o.id,
      studentName: o.student.name,
      studentEmail: o.student.user.email,
      vendorName: o.vendor.restaurantName,
      status: o.status,
      totalAmountInPaise: o.totalAmountInPaise,
      itemCount: o.items.length,
      createdAt: o.createdAt,
    }));
  }

  async deleteVendor(vendorId: string): Promise<void> {
    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      select: { userId: true },
    });

    if (!vendor) return;

    await this.prisma.$transaction([
      this.prisma.orderItem.deleteMany({
        where: { order: { vendorId } },
      }),
      this.prisma.revenueEntry.deleteMany({ where: { vendorId } }),
      this.prisma.revenueSummary.deleteMany({ where: { vendorId } }),
      this.prisma.order.deleteMany({ where: { vendorId } }),
      this.prisma.menuItem.deleteMany({ where: { vendorId } }),
      this.prisma.vendor.delete({ where: { id: vendorId } }),
      this.prisma.user.delete({ where: { id: vendor.userId } }),
    ]);
  }

  async deleteStudent(studentId: string): Promise<void> {
    const student = await this.prisma.student.findUnique({
      where: { id: studentId },
      select: { userId: true },
    });

    if (!student) return;

    await this.prisma.$transaction([
      this.prisma.orderItem.deleteMany({
        where: { order: { studentId } },
      }),
      this.prisma.order.deleteMany({ where: { studentId } }),
      this.prisma.student.delete({ where: { id: studentId } }),
      this.prisma.user.delete({ where: { id: student.userId } }),
    ]);
  }

  async emailExists(email: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { email } });
    return !!user;
  }

  async createVendorWithMenu(input: BulkVendorInput): Promise<CreatedVendor> {
    const passwordHash = await bcrypt.hash(input.password, 12);

    const result = await this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: input.email,
          passwordHash,
          role: Role.VENDOR,
        },
      });

      const vendor = await tx.vendor.create({
        data: {
          userId: user.id,
          restaurantName: input.restaurantName,
          description: input.description,
        },
      });

      if (input.menuItems && input.menuItems.length > 0) {
        await tx.menuItem.createMany({
          data: input.menuItems.map((item, index) => ({
            vendorId: vendor.id,
            name: item.name,
            description: item.description,
            priceInPaise: rupeesToPaise(item.priceInRupees),
            category: item.category,
            isAvailable: item.isAvailable ?? true,
            sortOrder: index + 1,
          })),
        });
      }

      return { id: vendor.id, email: user.email, restaurantName: vendor.restaurantName };
    });

    return result;
  }
}
