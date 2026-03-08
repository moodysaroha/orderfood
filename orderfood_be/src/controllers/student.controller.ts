import { Request, Response, NextFunction } from 'express';
import { IStudentService } from '../services/student.service';
import { IMenuItemRepository } from '../repositories/menu-item.repository';
import { IVendorRepository } from '../repositories/vendor.repository';
import { StudentMenuScreenBuilder } from '../sdui/builders/student-menu.builder';
import { ApiResponse } from '../types';
import { AppError } from '../middleware';

function param(req: Request, name: string): string {
  const val = req.params[name];
  return Array.isArray(val) ? val[0] : val;
}

export class StudentController {
  private menuScreenBuilder: StudentMenuScreenBuilder;

  constructor(
    private studentService: IStudentService,
    private menuItemRepo: IMenuItemRepository,
    private vendorRepo: IVendorRepository,
  ) {
    this.menuScreenBuilder = new StudentMenuScreenBuilder();
  }

  getMenu = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const vendorId = param(req, 'vendorId');
      const vendor = await this.vendorRepo.findById(vendorId);
      if (!vendor) throw new AppError(404, 'Vendor not found');

      const items = await this.menuItemRepo.findByVendorId(vendorId);
      const baseUrl = `${req.protocol}://${req.get('host') ?? 'localhost'}/uploads`;
      const screen = this.menuScreenBuilder.build(items, vendor.restaurantName, baseUrl);
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  placeOrder = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const studentId = req.user?.studentId;
      if (!studentId) throw new AppError(403, 'Student access required');

      const order = await this.studentService.placeOrder({
        studentId,
        vendorId: req.body.vendorId,
        items: req.body.items,
      });
      res.status(201).json({ success: true, data: order });
    } catch (err) {
      next(err);
    }
  };

  getOrders = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const studentId = req.user?.studentId;
      if (!studentId) throw new AppError(403, 'Student access required');

      const orders = await this.studentService.getOrders(studentId);
      res.json({ success: true, data: orders });
    } catch (err) {
      next(err);
    }
  };

  getOrderDetail = async (req: Request, res: Response<ApiResponse>, next: NextFunction): Promise<void> => {
    try {
      const studentId = req.user?.studentId;
      if (!studentId) throw new AppError(403, 'Student access required');

      const order = await this.studentService.getOrderDetail(studentId, param(req, 'id'));
      res.json({ success: true, data: order });
    } catch (err) {
      next(err);
    }
  };
}
