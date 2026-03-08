import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sdui/sdui_screen_widget.dart';
import '../../../core/sdui/sdui_models.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiClientProvider);

    return SduiScreenWidget(
      title: 'Dashboard',
      fetchScreen: () async {
        final res = await api.get('/vendor/dashboard');
        return res.data as Map<String, dynamic>;
      },
      onAction: (action, ctx) {
        if (action.type == 'navigate' && action.route != null) {
          final route = action.route!.replaceAll(':id', ctx?['id'] ?? '');
          Navigator.of(context).pushNamed(route);
        }
      },
    );
  }
}
