import { MenuItem } from '@prisma/client';
import { ScreenBuilder } from './screen.builder';
import { COMPONENT_TYPES } from '../components';
import { SduiScreen, SduiComponent } from '../types';
import { formatPaiseToINR } from '../../utils/currency';

export class VendorMenuScreenBuilder {
  build(menuItems: MenuItem[], uploadBaseUrl: string): SduiScreen {
    const builder = new ScreenBuilder('vendor_menu')
      .setVersion(1)
      .addAppBar('Menu Management', [
        { type: COMPONENT_TYPES.iconButton, props: { icon: 'add', actionKey: 'addItem' } },
      ])
      .addAction('addItem', { type: 'navigate', route: '/vendor/menu/add' });

    if (menuItems.length === 0) {
      builder.addEmptyState('No menu items yet. Tap + to add your first item.', 'restaurant_menu');
      return builder.build();
    }

    const grouped = this.groupByCategory(menuItems);

    for (const [category, items] of Object.entries(grouped)) {
      builder.addSectionHeader(category || 'Uncategorized');

      const tiles: SduiComponent[] = items.map((item) => ({
        type: COMPONENT_TYPES.menuItemTile,
        props: {
          id: item.id,
          name: item.name,
          description: item.description,
          price: formatPaiseToINR(item.priceInPaise),
          priceInPaise: item.priceInPaise,
          imageUrl: item.imageUrl ? `${uploadBaseUrl}/${item.imageUrl}` : null,
          isAvailable: item.isAvailable,
          category: item.category,
        },
      }));

      builder.addList(tiles);
    }

    builder
      .addAction('onItemTap', { type: 'navigate', route: '/vendor/menu/edit/:id' })
      .addAction('toggleAvailability', {
        type: 'api_call',
        method: 'PATCH',
        url: '/api/vendor/menu/items/:id/availability',
      })
      .addAction('deleteItem', {
        type: 'api_call',
        method: 'DELETE',
        url: '/api/vendor/menu/items/:id',
        confirmMessage: 'Are you sure you want to delete this item?',
      });

    return builder.build();
  }

  private groupByCategory(items: MenuItem[]): Record<string, MenuItem[]> {
    return items.reduce(
      (acc, item) => {
        const cat = item.category || 'Uncategorized';
        if (!acc[cat]) acc[cat] = [];
        acc[cat].push(item);
        return acc;
      },
      {} as Record<string, MenuItem[]>,
    );
  }
}
