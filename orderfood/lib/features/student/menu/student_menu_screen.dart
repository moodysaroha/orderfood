import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sdui/sdui_screen_widget.dart';
import '../../../core/sdui/sdui_models.dart';

class StudentMenuScreen extends ConsumerWidget {
  final String vendorId;

  const StudentMenuScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiClientProvider);

    return SduiScreenWidget(
      title: 'Menu',
      fetchScreen: () async {
        final res = await api.get('/student/menu/$vendorId');
        return res.data as Map<String, dynamic>;
      },
      onAction: (action, ctx) {
        if (action.type == 'navigate') {
          Navigator.of(context).pushNamed(
            action.route!.replaceAll(':id', ctx?['id'] ?? ''),
          );
        } else if (action.type == 'api_call') {
          // Cart actions handled here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to cart')),
          );
        }
      },
    );
  }
}
