import { PrismaClient, Vendor } from '@prisma/client';

export interface VendorWithMenuCount {
  id: string;
  restaurantName: string;
  description: string | null;
  menuItemCount: number;
  createdAt: Date;
}

export interface IVendorRepository {
  findById(id: string): Promise<Vendor | null>;
  findByUserId(userId: string): Promise<Vendor | null>;
  findAll(): Promise<Vendor[]>;
  findAllWithMenuCount(): Promise<VendorWithMenuCount[]>;
  create(data: { userId: string; restaurantName: string; description?: string }): Promise<Vendor>;
}

export class VendorRepository implements IVendorRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string): Promise<Vendor | null> {
    return this.prisma.vendor.findUnique({ where: { id } });
  }

  async findByUserId(userId: string): Promise<Vendor | null> {
    return this.prisma.vendor.findUnique({ where: { userId } });
  }

  async findAll(): Promise<Vendor[]> {
    return this.prisma.vendor.findMany({ orderBy: { restaurantName: 'asc' } });
  }

  async findAllWithMenuCount(): Promise<VendorWithMenuCount[]> {
    const vendors = await this.prisma.vendor.findMany({
      include: {
        _count: { select: { menuItems: true } },
      },
      orderBy: { restaurantName: 'asc' },
    });

    return vendors.map((v) => ({
      id: v.id,
      restaurantName: v.restaurantName,
      description: v.description,
      menuItemCount: v._count.menuItems,
      createdAt: v.createdAt,
    }));
  }

  async create(data: { userId: string; restaurantName: string; description?: string }): Promise<Vendor> {
    return this.prisma.vendor.create({ data });
  }
}
