import { PrismaClient, Order, OrderStatus, OrderItem } from '@prisma/client';

type OrderWithItems = Order & { items: (OrderItem & { menuItem: { name: string } })[] };
type OrderWithStudent = Order & { student: { name: string }; items: (OrderItem & { menuItem: { name: string } })[] };
type OrderWithFullDetails = Order & {
  student: { name: string; userId: string };
  vendor: { restaurantName: string; userId: string };
  items: (OrderItem & { menuItem: { name: string } })[];
};

export interface IOrderRepository {
  findById(id: string): Promise<OrderWithItems | null>;
  findByIdWithStudent(id: string): Promise<OrderWithStudent | null>;
  findByIdWithDetails(id: string): Promise<OrderWithFullDetails | null>;
  findByStudentId(studentId: string): Promise<Order[]>;
  findByVendorId(vendorId: string, filters?: { status?: OrderStatus; date?: Date }): Promise<OrderWithStudent[]>;
  create(data: {
    studentId: string;
    vendorId: string;
    totalAmountInPaise: number;
    items: { menuItemId: string; quantity: number; priceAtOrderInPaise: number }[];
  }): Promise<OrderWithItems>;
  updateStatus(id: string, status: OrderStatus): Promise<Order>;
  countByVendorAndDate(vendorId: string, date: Date): Promise<number>;
  getRecentStudentUserIdsByVendor(vendorId: string, days: number): Promise<string[]>;
}

export class OrderRepository implements IOrderRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string): Promise<OrderWithItems | null> {
    return this.prisma.order.findUnique({
      where: { id },
      include: { items: { include: { menuItem: { select: { name: true } } } } },
    });
  }

  async findByIdWithStudent(id: string): Promise<OrderWithStudent | null> {
    return this.prisma.order.findUnique({
      where: { id },
      include: {
        student: { select: { name: true } },
        items: { include: { menuItem: { select: { name: true } } } },
      },
    });
  }

  async findByIdWithDetails(id: string): Promise<OrderWithFullDetails | null> {
    return this.prisma.order.findUnique({
      where: { id },
      include: {
        student: { select: { name: true, userId: true } },
        vendor: { select: { restaurantName: true, userId: true } },
        items: { include: { menuItem: { select: { name: true } } } },
      },
    });
  }

  async findByStudentId(studentId: string): Promise<Order[]> {
    return this.prisma.order.findMany({
      where: { studentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByVendorId(
    vendorId: string,
    filters?: { status?: OrderStatus; date?: Date },
  ): Promise<OrderWithStudent[]> {
    const where: Record<string, unknown> = { vendorId };
    if (filters?.status) where.status = filters.status;
    if (filters?.date) {
      const start = new Date(filters.date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(filters.date);
      end.setHours(23, 59, 59, 999);
      where.createdAt = { gte: start, lte: end };
    }

    return this.prisma.order.findMany({
      where,
      include: {
        student: { select: { name: true } },
        items: { include: { menuItem: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: {
    studentId: string;
    vendorId: string;
    totalAmountInPaise: number;
    items: { menuItemId: string; quantity: number; priceAtOrderInPaise: number }[];
  }): Promise<OrderWithItems> {
    return this.prisma.order.create({
      data: {
        studentId: data.studentId,
        vendorId: data.vendorId,
        totalAmountInPaise: data.totalAmountInPaise,
        items: { create: data.items },
      },
      include: { items: { include: { menuItem: { select: { name: true } } } } },
    });
  }

  async updateStatus(id: string, status: OrderStatus): Promise<Order> {
    return this.prisma.order.update({ where: { id }, data: { status } });
  }

  async countByVendorAndDate(vendorId: string, date: Date): Promise<number> {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);
    return this.prisma.order.count({
      where: { vendorId, createdAt: { gte: start, lte: end } },
    });
  }

  async getRecentStudentUserIdsByVendor(vendorId: string, days: number): Promise<string[]> {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const orders = await this.prisma.order.findMany({
      where: {
        vendorId,
        createdAt: { gte: since },
      },
      include: {
        student: { select: { userId: true } },
      },
      distinct: ['studentId'],
    });

    return orders.map((o) => o.student.userId);
  }
}
