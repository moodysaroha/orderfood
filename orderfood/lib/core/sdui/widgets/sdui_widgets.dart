import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../sdui_models.dart';
import '../sdui_registry.dart';

// --- Layout ---

Widget buildColumn(SduiComponent c, SduiWidgetFactory f) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: f.buildChildren(c),
  );
}

Widget buildRow(SduiComponent c, SduiWidgetFactory f) {
  return Row(children: f.buildChildren(c));
}

Widget buildCard(SduiComponent c, SduiWidgetFactory f) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: f.buildChildren(c),
      ),
    ),
  );
}

Widget buildContainer(SduiComponent c, SduiWidgetFactory f) {
  return Container(
    padding: const EdgeInsets.all(8),
    child: Column(children: f.buildChildren(c)),
  );
}

// --- Navigation ---

Widget buildAppBar(SduiComponent c, SduiWidgetFactory f) {
  // AppBar is handled at the screen level, not as a child widget.
  // This returns a placeholder; actual AppBar is set in SduiScreenWidget.
  return const SizedBox.shrink();
}

// --- Content ---

Widget buildText(SduiComponent c, SduiWidgetFactory f) {
  final value = c.prop('value') ?? '';
  final style = c.prop('style');
  TextStyle textStyle = const TextStyle();
  if (style == 'headline') textStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  if (style == 'subtitle') textStyle = const TextStyle(fontSize: 16, color: Colors.grey);
  return Text(value, style: textStyle);
}

Widget buildImage(SduiComponent c, SduiWidgetFactory f) {
  final url = c.prop('url') ?? '';
  if (url.isEmpty) return const SizedBox.shrink();
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
      imageUrl: url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
    ),
  );
}

Widget buildSduiIcon(SduiComponent c, SduiWidgetFactory f) {
  return Icon(_resolveIcon(c.prop('name') ?? 'help'));
}

Widget buildDivider(SduiComponent c, SduiWidgetFactory f) => const Divider();
Widget buildSpacer(SduiComponent c, SduiWidgetFactory f) => const SizedBox(height: 16);

// --- Dashboard ---

Widget buildStatsRow(SduiComponent c, SduiWidgetFactory f) {
  final children = f.buildChildren(c);
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: children.map((w) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(width: 150, child: w),
      )).toList(),
    ),
  );
}

Widget buildStatCard(SduiComponent c, SduiWidgetFactory f) {
  return Builder(
    builder: (context) {
      final primaryColor = Theme.of(context).colorScheme.primary;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_resolveIcon(c.prop('icon') ?? 'info'), size: 28, color: primaryColor),
              const SizedBox(height: 8),
              Text(c.prop('value') ?? '0',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(c.prop('label') ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildSectionHeader(SduiComponent c, SduiWidgetFactory f) {
  final actionLabel = c.prop('actionLabel');
  final actionKey = c.prop('actionKey');
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(c.prop('title') ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (actionLabel != null && actionKey != null)
          TextButton(
            onPressed: () => f.triggerAction(actionKey),
            child: Text(actionLabel),
          ),
      ],
    ),
  );
}

// --- Lists ---

Widget buildList(SduiComponent c, SduiWidgetFactory f) {
  return Column(children: f.buildChildren(c));
}

Widget buildOrderTile(SduiComponent c, SduiWidgetFactory f) {
  final status = c.prop('status') ?? 'pending';
  return ListTile(
    leading: CircleAvatar(child: Text(c.prop('student')?.substring(0, 1) ?? '?')),
    title: Text(c.prop('student') ?? 'Unknown'),
    subtitle: Text('${c.prop('total')} · $status'),
    trailing: _statusChip(status),
    onTap: () => f.triggerAction('onOrderTap', context: {'id': c.prop('id')}),
  );
}

Widget buildMenuItemTile(SduiComponent c, SduiWidgetFactory f) {
  final isAvailable = c.propBool('isAvailable');
  return ListTile(
    leading: c.prop('imageUrl') != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: c.prop('imageUrl')!,
              width: 56, height: 56, fit: BoxFit.cover,
            ),
          )
        : Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.grey),
          ),
    title: Text(c.prop('name') ?? '',
        style: TextStyle(decoration: isAvailable ? null : TextDecoration.lineThrough)),
    subtitle: Text(c.prop('price') ?? ''),
    trailing: Switch(
      value: isAvailable,
      onChanged: (_) => f.triggerAction('toggleAvailability', context: {'id': c.prop('id')}),
    ),
    onTap: () => f.triggerAction('onItemTap', context: {'id': c.prop('id')}),
  );
}

Widget buildMenuItemCard(SduiComponent c, SduiWidgetFactory f) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.prop('imageUrl') != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: c.prop('imageUrl')!,
              height: 150, width: double.infinity, fit: BoxFit.cover,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.prop('name') ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (c.prop('description') != null) ...[
                const SizedBox(height: 4),
                Text(c.prop('description')!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => Text(c.prop('price') ?? '',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => f.triggerAction('addToCart', context: {'id': c.prop('id')}),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// --- Interactive ---

Widget buildButton(SduiComponent c, SduiWidgetFactory f) {
  final actionKey = c.prop('actionKey') ?? '';
  final variant = c.prop('variant') ?? 'primary';
  if (variant == 'outlined') {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton(
        onPressed: () => f.triggerAction(actionKey),
        child: Text(c.prop('label') ?? ''),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ElevatedButton(
      onPressed: () => f.triggerAction(actionKey),
      child: Text(c.prop('label') ?? ''),
    ),
  );
}

Widget buildIconButton(SduiComponent c, SduiWidgetFactory f) {
  return IconButton(
    icon: Icon(_resolveIcon(c.prop('icon') ?? 'add')),
    onPressed: () => f.triggerAction(c.prop('actionKey') ?? ''),
  );
}

Widget buildFab(SduiComponent c, SduiWidgetFactory f) {
  // FAB is handled at screen level, this returns a placeholder
  return const SizedBox.shrink();
}

Widget buildSwitchToggle(SduiComponent c, SduiWidgetFactory f) {
  return SwitchListTile(
    title: Text(c.prop('label') ?? ''),
    value: c.propBool('value'),
    onChanged: (_) => f.triggerAction(c.prop('actionKey') ?? ''),
  );
}

// --- Feedback ---

Widget buildEmptyState(SduiComponent c, SduiWidgetFactory f) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_resolveIcon(c.prop('icon') ?? 'inbox'),
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(c.prop('message') ?? 'Nothing here yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    ),
  );
}

// --- Helpers ---

Widget _statusChip(String status) {
  Color color;
  switch (status.toUpperCase()) {
    case 'PENDING':    color = Colors.orange; break;
    case 'CONFIRMED':  color = Colors.blue;   break;
    case 'PREPARING':  color = Colors.purple;  break;
    case 'READY':      color = Colors.green;   break;
    case 'CANCELLED':  color = Colors.red;     break;
    default:           color = Colors.grey;    break;
  }
  return Chip(
    label: Text(status, style: const TextStyle(fontSize: 11, color: Colors.white)),
    backgroundColor: color,
    padding: EdgeInsets.zero,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

IconData _resolveIcon(String name) {
  const iconMap = <String, IconData>{
    'shopping_cart': Icons.shopping_cart,
    'currency_rupee': Icons.currency_rupee,
    'account_balance': Icons.account_balance,
    'receipt_long': Icons.receipt_long,
    'restaurant_menu': Icons.restaurant_menu,
    'restaurant': Icons.restaurant,
    'add': Icons.add,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'info': Icons.info,
    'help': Icons.help,
    'inbox': Icons.inbox,
    'search': Icons.search,
    'refresh': Icons.refresh,
    'settings': Icons.settings,
    'person': Icons.person,
    'star': Icons.star,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'list': Icons.list,
    'list_alt': Icons.list_alt,
    'check': Icons.check,
    'close': Icons.close,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'store': Icons.store,
    'school': Icons.school,
    'today': Icons.today,
    'dashboard': Icons.dashboard,
    'logout': Icons.logout,
    'receipt': Icons.receipt,
  };
  return iconMap[name] ?? Icons.help_outline;
}
