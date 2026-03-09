import { PrismaClient, OrderStatus } from '@prisma/client';
import {
  PlatformStats,
  VendorWithStats,
  StudentWithStats,
  OrderWithDetails,
} from './admin.types';

export interface IAdminRepository {
  getPlatformStats(): Promise<PlatformStats>;
  getAllVendors(): Promise<VendorWithStats[]>;
  getAllStudents(): Promise<StudentWithStats[]>;
  getAllOrders(filters?: { status?: OrderStatus; vendorId?: string }): Promise<OrderWithDetails[]>;
  deleteVendor(vendorId: string): Promise<void>;
  deleteStudent(studentId: string): Promise<void>;
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
}
