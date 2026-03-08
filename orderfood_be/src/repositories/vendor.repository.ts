import { PrismaClient, Vendor } from '@prisma/client';

export interface IVendorRepository {
  findById(id: string): Promise<Vendor | null>;
  findByUserId(userId: string): Promise<Vendor | null>;
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

  async create(data: { userId: string; restaurantName: string; description?: string }): Promise<Vendor> {
    return this.prisma.vendor.create({ data });
  }
}
