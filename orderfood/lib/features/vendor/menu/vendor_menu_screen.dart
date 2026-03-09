import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sdui/sdui_screen_widget.dart';
import 'add_menu_item_screen.dart';

class VendorMenuScreen extends ConsumerStatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  ConsumerState<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends ConsumerState<VendorMenuScreen> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiClientProvider);

    return SduiScreenWidget(
      key: ValueKey(_refreshKey),
      title: 'Menu Management',
      fetchScreen: () async {
        final res = await api.get('/vendor/menu');
        return res.data as Map<String, dynamic>;
      },
      onAction: (action, ctx) async {
        if (action.type == 'navigate') {
          if (action.route == '/vendor/menu/add') {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddMenuItemScreen()),
            );
            if (result == true) _refresh();
          }
        } else if (action.type == 'api_call') {
          final url = action.url!.replaceAll(':id', ctx?['id'] ?? '');
          try {
            if (action.method == 'PATCH') {
              await api.patch(url);
            } else if (action.method == 'DELETE') {
              if (action.confirmMessage != null) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm'),
                    content: Text(action.confirmMessage!),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed != true) return;
              }
              await api.delete(url);
            }
            _refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated successfully')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        }
      },
    );
  }
}
