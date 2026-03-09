import { MenuItem, OrderStatus } from '@prisma/client';
import { IMenuItemRepository } from '../repositories/menu-item.repository';
import { IOrderRepository } from '../repositories/order.repository';
import { IRevenueService } from '../modules/revenue';
import { INotificationService } from '../modules/notification';
import { AppError } from '../middleware';
import { rupeesToPaise, paiseToRupees } from '../utils/currency';

interface CreateMenuItemInput {
  vendorId: string;
  name: string;
  description?: string;
  priceInPaise: number;
  category?: string;
  sortOrder?: number;
}

interface UpdateMenuItemInput {
  name?: string;
  description?: string;
  priceInPaise?: number;
  category?: string;
  sortOrder?: number;
}

export interface IVendorService {
  getMenuItems(vendorId: string): Promise<MenuItem[]>;
  createMenuItem(input: CreateMenuItemInput): Promise<MenuItem>;
  updateMenuItem(vendorId: string, itemId: string, input: UpdateMenuItemInput): Promise<MenuItem>;
  toggleAvailability(vendorId: string, itemId: string, vendorName?: string): Promise<MenuItem>;
  setMenuItemImage(vendorId: string, itemId: string, imageUrl: string): Promise<MenuItem>;
  deleteMenuItem(vendorId: string, itemId: string): Promise<void>;
  getOrders(vendorId: string, filters?: { status?: string; date?: string }): Promise<unknown[]>;
  updateOrderStatus(vendorId: string, orderId: string, status: string, vendorName?: string): Promise<unknown>;
}

export class VendorService implements IVendorService {
  constructor(
    private menuItemRepo: IMenuItemRepository,
    private orderRepo: IOrderRepository,
    private revenueService?: IRevenueService,
    private notificationService?: INotificationService,
  ) {}

  async getMenuItems(vendorId: string): Promise<MenuItem[]> {
    return this.menuItemRepo.findByVendorId(vendorId);
  }

  async createMenuItem(input: CreateMenuItemInput): Promise<MenuItem> {
    return this.menuItemRepo.create({
      vendorId: input.vendorId,
      name: input.name,
      description: input.description,
      priceInPaise: input.priceInPaise,
      category: input.category,
      sortOrder: input.sortOrder,
    });
  }

  async updateMenuItem(vendorId: string, itemId: string, input: UpdateMenuItemInput): Promise<MenuItem> {
    const item = await this.menuItemRepo.findById(itemId);
    if (!item || item.vendorId !== vendorId) {
      throw new AppError(404, 'Menu item not found');
    }

    const updateData: Record<string, unknown> = {};
    if (input.name !== undefined) updateData.name = input.name;
    if (input.description !== undefined) updateData.description = input.description;
    if (input.priceInPaise !== undefined) updateData.priceInPaise = input.priceInPaise;
    if (input.category !== undefined) updateData.category = input.category;
    if (input.sortOrder !== undefined) updateData.sortOrder = input.sortOrder;

    return this.menuItemRepo.update(itemId, updateData);
  }

  async toggleAvailability(vendorId: string, itemId: string, vendorName?: string): Promise<MenuItem> {
    const item = await this.menuItemRepo.findById(itemId);
    if (!item || item.vendorId !== vendorId) {
      throw new AppError(404, 'Menu item not found');
    }

    const wasAvailable = item.isAvailable;
    const updated = await this.menuItemRepo.update(itemId, { isAvailable: !item.isAvailable });

    if (this.notificationService && vendorName) {
      const recentStudentUserIds = await this.orderRepo.getRecentStudentUserIdsByVendor(vendorId, 30);
      
      if (recentStudentUserIds.length > 0) {
        const context = {
          menuItemId: itemId,
          itemName: item.name,
          vendorName,
        };

        if (wasAvailable) {
          await this.notificationService.notifyItemOutOfStock(recentStudentUserIds, context);
        } else {
          await this.notificationService.notifyItemBackInStock(recentStudentUserIds, context);
        }
      }
    }

    return updated;
  }

  async setMenuItemImage(vendorId: string, itemId: string, imageUrl: string): Promise<MenuItem> {
    const item = await this.menuItemRepo.findById(itemId);
    if (!item || item.vendorId !== vendorId) {
      throw new AppError(404, 'Menu item not found');
    }

    return this.menuItemRepo.update(itemId, { imageUrl });
  }

  async deleteMenuItem(vendorId: string, itemId: string): Promise<void> {
    const item = await this.menuItemRepo.findById(itemId);
    if (!item || item.vendorId !== vendorId) {
      throw new AppError(404, 'Menu item not found');
    }

    await this.menuItemRepo.delete(itemId);
  }

  async getOrders(vendorId: string, filters?: { status?: string; date?: string }): Promise<unknown[]> {
    const orderFilters: { status?: any; date?: Date } = {};
    if (filters?.status) orderFilters.status = filters.status;
    if (filters?.date) orderFilters.date = new Date(filters.date);

    return this.orderRepo.findByVendorId(vendorId, orderFilters);
  }

  async updateOrderStatus(vendorId: string, orderId: string, status: string, vendorName?: string): Promise<unknown> {
    const order = await this.orderRepo.findById(orderId);
    if (!order || order.vendorId !== vendorId) {
      throw new AppError(404, 'Order not found');
    }

    const updated = await this.orderRepo.updateStatus(orderId, status as OrderStatus);

    // Record revenue when order is READY (final status - students pick up from restaurant)
    if (status === OrderStatus.READY && this.revenueService) {
      await this.revenueService.recordRevenue({
        vendorId: order.vendorId,
        orderId: order.id,
        grossAmountInPaise: order.totalAmountInPaise,
      });
    }

    if (this.notificationService) {
      const orderWithDetails = await this.orderRepo.findByIdWithDetails(orderId);
      if (orderWithDetails) {
        const context = {
          orderId,
          orderTotal: `₹${paiseToRupees(order.totalAmountInPaise)}`,
          studentName: orderWithDetails.student?.name || 'Student',
          vendorName: vendorName || orderWithDetails.vendor?.restaurantName || 'Restaurant',
          itemCount: orderWithDetails.items?.length || 0,
        };

        const studentUserId = orderWithDetails.student?.userId;
        if (studentUserId) {
          await this.notificationService.notifyOrderStatusChange(studentUserId, status, context);
        }
      }
    }

    return updated;
  }
}
