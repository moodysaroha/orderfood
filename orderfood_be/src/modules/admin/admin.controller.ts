import { Request, Response, NextFunction } from 'express';
import { IAdminService } from './admin.service';
import { formatINR, paiseToRupees } from '../../utils/currency';
import {
  AdminDashboardScreenBuilder,
  AdminVendorsScreenBuilder,
  AdminStudentsScreenBuilder,
  AdminOrdersScreenBuilder,
} from '../../sdui/builders/admin-dashboard.builder';

export class AdminController {
  private dashboardBuilder: AdminDashboardScreenBuilder;
  private vendorsBuilder: AdminVendorsScreenBuilder;
  private studentsBuilder: AdminStudentsScreenBuilder;
  private ordersBuilder: AdminOrdersScreenBuilder;

  constructor(private adminService: IAdminService) {
    this.dashboardBuilder = new AdminDashboardScreenBuilder(adminService);
    this.vendorsBuilder = new AdminVendorsScreenBuilder(adminService);
    this.studentsBuilder = new AdminStudentsScreenBuilder(adminService);
    this.ordersBuilder = new AdminOrdersScreenBuilder(adminService);
  }

  getDashboardSdui = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const screen = await this.dashboardBuilder.build();
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  getVendorsSdui = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const screen = await this.vendorsBuilder.build();
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  getStudentsSdui = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const screen = await this.studentsBuilder.build();
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  getOrdersSdui = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const filters: { status?: string; vendorId?: string } = {};
      if (req.query.status) filters.status = req.query.status as string;
      if (req.query.vendorId) filters.vendorId = req.query.vendorId as string;
      const screen = await this.ordersBuilder.build(filters);
      res.json({ success: true, data: screen });
    } catch (err) {
      next(err);
    }
  };

  getStats = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const stats = await this.adminService.getPlatformStats();
      res.json({ success: true, data: stats });
    } catch (err) {
      next(err);
    }
  };

  getVendors = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const vendors = await this.adminService.getAllVendors();
      const formatted = vendors.map((v) => ({
        ...v,
        totalRevenueFormatted: formatINR(paiseToRupees(v.totalRevenue)),
      }));
      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };

  getStudents = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const students = await this.adminService.getAllStudents();
      const formatted = students.map((s) => ({
        ...s,
        totalSpentFormatted: formatINR(paiseToRupees(s.totalSpent)),
      }));
      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };

  getOrders = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const filters: { status?: string; vendorId?: string } = {};
      if (req.query.status) filters.status = req.query.status as string;
      if (req.query.vendorId) filters.vendorId = req.query.vendorId as string;

      const orders = await this.adminService.getAllOrders(filters);
      const formatted = orders.map((o) => ({
        ...o,
        totalAmountFormatted: formatINR(paiseToRupees(o.totalAmountInPaise)),
      }));
      res.json({ success: true, data: formatted });
    } catch (err) {
      next(err);
    }
  };

  deleteVendor = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await this.adminService.deleteVendor(req.params.vendorId);
      res.json({ success: true, message: 'Vendor deleted' });
    } catch (err) {
      next(err);
    }
  };

  deleteStudent = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await this.adminService.deleteStudent(req.params.studentId);
      res.json({ success: true, message: 'Student deleted' });
    } catch (err) {
      next(err);
    }
  };
}
