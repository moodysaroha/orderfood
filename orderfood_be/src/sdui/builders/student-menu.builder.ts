import { MenuItem } from '@prisma/client';
import { ScreenBuilder } from './screen.builder';
import { COMPONENT_TYPES } from '../components';
import { SduiScreen, SduiComponent } from '../types';
import { formatPaiseToINR } from '../../utils/currency';
import { env } from '../../config/env';

export class StudentMenuScreenBuilder {
  build(menuItems: MenuItem[], vendorName: string, uploadBaseUrl: string): SduiScreen {
    const builder = new ScreenBuilder('student_menu')
      .setVersion(1)
      .setPollingInterval(env.POLLING_INTERVAL_MS)
      .addAppBar(vendorName);

    const available = menuItems.filter((i) => i.isAvailable);

    if (available.length === 0) {
      builder.addEmptyState('No items available right now. Check back later!', 'restaurant');
      return builder.build();
    }

    const grouped = this.groupByCategory(available);

    for (const [category, items] of Object.entries(grouped)) {
      builder.addSectionHeader(category || 'Menu');

      const cards: SduiComponent[] = items.map((item) => ({
        type: COMPONENT_TYPES.menuItemCard,
        props: {
          id: item.id,
          name: item.name,
          description: item.description,
          price: formatPaiseToINR(item.priceInPaise),
          priceInPaise: item.priceInPaise,
          imageUrl: item.imageUrl ? `${uploadBaseUrl}/${item.imageUrl}` : null,
          isAvailable: item.isAvailable,
        },
      }));

      builder.addList(cards);
    }

    builder
      .addAction('addToCart', {
        type: 'api_call',
        method: 'POST',
        url: '/api/student/cart/add',
      })
      .addFab('shopping_cart', 'viewCart')
      .addAction('viewCart', { type: 'navigate', route: '/student/cart' });

    return builder.build();
  }

  private groupByCategory(items: MenuItem[]): Record<string, MenuItem[]> {
    return items.reduce(
      (acc, item) => {
        const cat = item.category || 'Menu';
        if (!acc[cat]) acc[cat] = [];
        acc[cat].push(item);
        return acc;
      },
      {} as Record<string, MenuItem[]>,
    );
  }
}
