import { Order, OrderStatus } from '@prisma/client';
import { IMenuItemRepository } from '../repositories/menu-item.repository';
import { IOrderRepository } from '../repositories/order.repository';
import { IVendorRepository } from '../repositories/vendor.repository';
import { IRevenueService } from '../modules/revenue';
import { INotificationService } from '../modules/notification';
import { AppError } from '../middleware';
import { paiseToRupees } from '../utils/currency';

interface OrderItemInput {
  menuItemId: string;
  quantity: number;
}

interface PlaceOrderInput {
  studentId: string;
  studentName: string;
  studentUserId: string;
  vendorId: string;
  items: OrderItemInput[];
}

export interface IStudentService {
  placeOrder(input: PlaceOrderInput): Promise<unknown>;
  getOrders(studentId: string): Promise<Order[]>;
  getOrderDetail(studentId: string, orderId: string): Promise<unknown>;
}

export class StudentService implements IStudentService {
  constructor(
    private menuItemRepo: IMenuItemRepository,
    private orderRepo: IOrderRepository,
    private vendorRepo: IVendorRepository,
    private revenueService: IRevenueService,
    private notificationService?: INotificationService,
  ) {}

  async placeOrder(input: PlaceOrderInput): Promise<unknown> {
    const vendor = await this.vendorRepo.findById(input.vendorId);
    if (!vendor) throw new AppError(404, 'Vendor not found');

    if (input.items.length === 0) throw new AppError(400, 'Order must have at least one item');

    const orderItems: { menuItemId: string; quantity: number; priceAtOrderInPaise: number }[] = [];
    let totalAmountInPaise = 0;

    for (const item of input.items) {
      const menuItem = await this.menuItemRepo.findById(item.menuItemId);
      if (!menuItem || menuItem.vendorId !== input.vendorId) {
        throw new AppError(404, `Menu item ${item.menuItemId} not found`);
      }
      if (!menuItem.isAvailable) {
        throw new AppError(400, `"${menuItem.name}" is currently unavailable`);
      }
      if (item.quantity < 1) {
        throw new AppError(400, 'Quantity must be at least 1');
      }

      const lineTotal = menuItem.priceInPaise * item.quantity;
      orderItems.push({
        menuItemId: menuItem.id,
        quantity: item.quantity,
        priceAtOrderInPaise: menuItem.priceInPaise,
      });
      totalAmountInPaise += lineTotal;
    }

    const order = await this.orderRepo.create({
      studentId: input.studentId,
      vendorId: input.vendorId,
      totalAmountInPaise,
      items: orderItems,
    });

    if (this.notificationService && vendor.userId) {
      const context = {
        orderId: order.id,
        orderTotal: `₹${paiseToRupees(totalAmountInPaise)}`,
        studentName: input.studentName,
        vendorName: vendor.restaurantName,
        itemCount: orderItems.length,
      };
      await this.notificationService.notifyOrderPlaced(vendor.userId, context);
    }

    return order;
  }

  async getOrders(studentId: string): Promise<Order[]> {
    return this.orderRepo.findByStudentId(studentId);
  }

  async getOrderDetail(studentId: string, orderId: string): Promise<unknown> {
    const order = await this.orderRepo.findById(orderId);
    if (!order || order.studentId !== studentId) {
      throw new AppError(404, 'Order not found');
    }
    return order;
  }

  /**
   * Called when vendor marks order as DELIVERED.
   * Triggers revenue recording through the isolated revenue module.
   */
  async onOrderDelivered(orderId: string): Promise<void> {
    const order = await this.orderRepo.findById(orderId);
    if (!order) return;

    await this.revenueService.recordRevenue({
      vendorId: order.vendorId,
      orderId: order.id,
      grossAmountInPaise: order.totalAmountInPaise,
    });
  }
}
