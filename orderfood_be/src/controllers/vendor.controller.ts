import { Request, Response, NextFunction } from 'express';
import { IVendorService } from '../services/vendor.service';
import { IRevenueService } from '../modules/revenue';
import { DashboardScreenBuilder } from '../sdui/builders/dashboard.builder';
import { VendorMenuScreenBuilder } from '../sdui/builders/vendor-menu.builder';
import { IOrderRepository } from '../repositories/order.repository';
import { ApiResponse } from '../types';
import { AppError } from '../middleware';

function paramId(req: Request): string {
  const id = req.params.id;
  return Array.isArray(id) ? id[0] : id;
}

export class VendorController {
  private dashboardBuilder: DashboardScreenBuilder;
  private menuScreenBuilder: VendorMenuScreenBuilder;

  constructor(
    private vendorService: IVendorService,
    private orderRepo: IOrderRepository,
    revenueService: IRevenueService,
  ) {
    this.dashboardBuilder = new DashboardScreenBuilder(revenueService);
    this.menuScreenBuilder = new VendorMenuScreenBuilder();
  }

  getDashboard = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const recentOrders = await this.orderRepo.findByVendorId(vendorId, { date: new Date() });
      const screen = await this.dashboardBuilder.build(vendorId, recentOrders);
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  getMenu = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const items = await this.vendorService.getMenuItems(vendorId);
      const baseUrl = `${req.protocol}://${req.get('host') ?? 'localhost'}/uploads`;
      const screen = this.menuScreenBuilder.build(items, baseUrl);
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  createMenuItem = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const item = await this.vendorService.createMenuItem({
        vendorId,
        name: req.body.name,
        description: req.body.description,
        priceInRupees: req.body.price,
        category: req.body.category,
        sortOrder: req.body.sortOrder,
      });
      res.status(201).json({ success: true, data: item });
    } catch (err) {
      next(err);
    }
  };

  updateMenuItem = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const item = await this.vendorService.updateMenuItem(vendorId, paramId(req), {
        name: req.body.name,
        description: req.body.description,
        priceInRupees: req.body.price,
        category: req.body.category,
        sortOrder: req.body.sortOrder,
      });
      res.json({ success: true, data: item });
    } catch (err) {
      next(err);
    }
  };

  toggleAvailability = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const item = await this.vendorService.toggleAvailability(vendorId, paramId(req));
      res.json({ success: true, data: item, message: item.isAvailable ? 'Back in stock' : 'Marked as sold out' });
    } catch (err) {
      next(err);
    }
  };

  uploadImage = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      if (!req.file) throw new AppError(400, 'No image file provided');

      const imageUrl = req.file.filename;
      const item = await this.vendorService.setMenuItemImage(vendorId, paramId(req), imageUrl);
      res.json({ success: true, data: item });
    } catch (err) {
      next(err);
    }
  };

  deleteMenuItem = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      await this.vendorService.deleteMenuItem(vendorId, paramId(req));
      res.json({ success: true, message: 'Menu item deleted' });
    } catch (err) {
      next(err);
    }
  };

  getOrders = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const orders = await this.vendorService.getOrders(vendorId, {
        status: req.query.status as string | undefined,
        date: req.query.date as string | undefined,
      });
      res.json({ success: true, data: orders });
    } catch (err) {
      next(err);
    }
  };

  updateOrderStatus = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = req.user?.vendorId;
      if (!vendorId) throw new AppError(403, 'Vendor access required');

      const order = await this.vendorService.updateOrderStatus(vendorId, paramId(req), req.body.status);
      res.json({ success: true, data: order });
    } catch (err) {
      next(err);
    }
  };
}
