import { ScreenBuilder } from './screen.builder';
import { COMPONENT_TYPES } from '../components';
import { SduiScreen, SduiComponent } from '../types';
import { IAdminService } from '../../modules/admin';
import { formatPaiseToINR } from '../../utils/currency';

export class AdminDashboardScreenBuilder {
  constructor(private adminService: IAdminService) {}

  async build(): Promise<SduiScreen> {
    const stats = await this.adminService.getPlatformStats();

    const builder = new ScreenBuilder('admin_dashboard')
      .setVersion(1)
      .addAppBar('Admin Dashboard')
      .addStatsRow([
        { label: 'Total Vendors', value: String(stats.totalVendors), icon: 'store' },
        { label: 'Total Students', value: String(stats.totalStudents), icon: 'school' },
        { label: 'Total Orders', value: String(stats.totalOrders), icon: 'shopping_cart' },
      ])
      .addStatsRow([
        { label: 'Orders Today', value: String(stats.ordersToday), icon: 'today' },
        { label: 'Revenue Today', value: stats.revenueToday, icon: 'currency_rupee' },
        { label: 'Total Revenue', value: stats.totalRevenue, icon: 'account_balance' },
      ])
      .addSectionHeader('Quick Actions')
      .addButton('View All Vendors', 'viewVendors', 'store')
      .addButton('View All Students', 'viewStudents', 'school')
      .addButton('View All Orders', 'viewOrders', 'list_alt')
      .addAction('viewVendors', { type: 'navigate', route: '/admin/vendors' })
      .addAction('viewStudents', { type: 'navigate', route: '/admin/students' })
      .addAction('viewOrders', { type: 'navigate', route: '/admin/orders' });

    return builder.build();
  }
}

export class AdminVendorsScreenBuilder {
  constructor(private adminService: IAdminService) {}

  async build(): Promise<SduiScreen> {
    const vendors = await this.adminService.getAllVendors();

    const builder = new ScreenBuilder('admin_vendors')
      .setVersion(1)
      .addAppBar('Manage Vendors', true)
      .addSectionHeader(`${vendors.length} Vendors`);

    if (vendors.length === 0) {
      builder.addEmptyState('No vendors registered', 'store');
    } else {
      const vendorTiles: SduiComponent[] = vendors.map((v) => ({
        type: COMPONENT_TYPES.listTile,
        props: {
          id: v.id,
          title: v.restaurantName,
          subtitle: `${v.email}\n${v.totalOrders} orders · ${formatPaiseToINR(v.totalRevenue)}`,
          icon: 'store',
          showDelete: true,
        },
      }));
      builder.addList(vendorTiles);
    }

    builder.addAction('onDeleteVendor', {
      type: 'api_call',
      method: 'DELETE',
      url: '/api/admin/vendors/:id',
      confirmMessage: 'Are you sure you want to delete this vendor? All their data will be lost.',
    });

    return builder.build();
  }
}

export class AdminStudentsScreenBuilder {
  constructor(private adminService: IAdminService) {}

  async build(): Promise<SduiScreen> {
    const students = await this.adminService.getAllStudents();

    const builder = new ScreenBuilder('admin_students')
      .setVersion(1)
      .addAppBar('Manage Students', true)
      .addSectionHeader(`${students.length} Students`);

    if (students.length === 0) {
      builder.addEmptyState('No students registered', 'school');
    } else {
      const studentTiles: SduiComponent[] = students.map((s) => ({
        type: COMPONENT_TYPES.listTile,
        props: {
          id: s.id,
          title: s.name,
          subtitle: `${s.email}\n${s.totalOrders} orders · Spent: ${formatPaiseToINR(s.totalSpent)}`,
          icon: 'person',
          showDelete: true,
        },
      }));
      builder.addList(studentTiles);
    }

    builder.addAction('onDeleteStudent', {
      type: 'api_call',
      method: 'DELETE',
      url: '/api/admin/students/:id',
      confirmMessage: 'Are you sure you want to delete this student? All their orders will be lost.',
    });

    return builder.build();
  }
}

export class AdminOrdersScreenBuilder {
  constructor(private adminService: IAdminService) {}

  async build(filters?: { status?: string; vendorId?: string }): Promise<SduiScreen> {
    const orders = await this.adminService.getAllOrders(filters);

    const builder = new ScreenBuilder('admin_orders')
      .setVersion(1)
      .addAppBar('All Orders', true)
      .addSectionHeader(`${orders.length} Orders`);

    if (orders.length === 0) {
      builder.addEmptyState('No orders found', 'receipt_long');
    } else {
      const orderTiles: SduiComponent[] = orders.map((o) => ({
        type: COMPONENT_TYPES.orderTile,
        props: {
          id: o.id,
          student: o.studentName,
          vendor: o.vendorName,
          total: formatPaiseToINR(o.totalAmountInPaise),
          status: o.status,
          itemCount: o.itemCount,
          createdAt: o.createdAt,
        },
      }));
      builder.addList(orderTiles);
    }

    return builder.build();
  }
}
