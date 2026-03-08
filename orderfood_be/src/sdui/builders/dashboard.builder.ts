import { ScreenBuilder } from './screen.builder';
import { COMPONENT_TYPES } from '../components';
import { SduiScreen, SduiComponent } from '../types';
import { IRevenueService } from '../../modules/revenue';
import { formatPaiseToINR } from '../../utils/currency';

export class DashboardScreenBuilder {
  constructor(private revenueService: IRevenueService) {}

  async build(vendorId: string, recentOrders: any[]): Promise<SduiScreen> {
    const [todaySummary, overallSummary] = await Promise.all([
      this.revenueService.getTodaySummary(vendorId),
      this.revenueService.getOverallSummary(vendorId),
    ]);

    const builder = new ScreenBuilder('vendor_dashboard')
      .setVersion(1)
      .addAppBar('Dashboard')
      .addStatsRow([
        { label: 'Orders Today', value: String(todaySummary.totalOrderCount), icon: 'shopping_cart' },
        { label: 'Revenue Today', value: todaySummary.netRevenueFormatted, icon: 'currency_rupee' },
        { label: 'Total Revenue', value: overallSummary.netRevenueFormatted, icon: 'account_balance' },
      ])
      .addSectionHeader('Recent Orders', 'View All', 'viewAllOrders')
      .addAction('viewAllOrders', { type: 'navigate', route: '/vendor/orders' });

    if (recentOrders.length === 0) {
      builder.addEmptyState('No orders yet today', 'receipt_long');
    } else {
      const orderTiles: SduiComponent[] = recentOrders.slice(0, 10).map((order) => ({
        type: COMPONENT_TYPES.orderTile,
        props: {
          id: order.id,
          student: order.student?.name ?? 'Unknown',
          total: formatPaiseToINR(order.totalAmountInPaise),
          status: order.status,
          itemCount: order.items?.length ?? 0,
          createdAt: order.createdAt,
        },
      }));
      builder.addList(orderTiles);
    }

    builder.addAction('onOrderTap', { type: 'navigate', route: '/vendor/orders/:id' });

    return builder.build();
  }
}
