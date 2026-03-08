import { PrismaClient, MenuItem } from '@prisma/client';

export interface IMenuItemRepository {
  findById(id: string): Promise<MenuItem | null>;
  findByVendorId(vendorId: string): Promise<MenuItem[]>;
  findAvailableByVendorId(vendorId: string): Promise<MenuItem[]>;
  create(data: {
    vendorId: string;
    name: string;
    description?: string;
    priceInPaise: number;
    imageUrl?: string;
    category?: string;
    sortOrder?: number;
  }): Promise<MenuItem>;
  update(id: string, data: Partial<Omit<MenuItem, 'id' | 'vendorId' | 'createdAt'>>): Promise<MenuItem>;
  delete(id: string): Promise<void>;
}

export class MenuItemRepository implements IMenuItemRepository {
  constructor(private prisma: PrismaClient) {}

  async findById(id: string): Promise<MenuItem | null> {
    return this.prisma.menuItem.findUnique({ where: { id } });
  }

  async findByVendorId(vendorId: string): Promise<MenuItem[]> {
    return this.prisma.menuItem.findMany({
      where: { vendorId },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async findAvailableByVendorId(vendorId: string): Promise<MenuItem[]> {
    return this.prisma.menuItem.findMany({
      where: { vendorId, isAvailable: true },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async create(data: {
    vendorId: string;
    name: string;
    description?: string;
    priceInPaise: number;
    imageUrl?: string;
    category?: string;
    sortOrder?: number;
  }): Promise<MenuItem> {
    return this.prisma.menuItem.create({ data });
  }

  async update(id: string, data: Partial<Omit<MenuItem, 'id' | 'vendorId' | 'createdAt'>>): Promise<MenuItem> {
    return this.prisma.menuItem.update({ where: { id }, data });
  }

  async delete(id: string): Promise<void> {
    await this.prisma.menuItem.delete({ where: { id } });
  }
}
