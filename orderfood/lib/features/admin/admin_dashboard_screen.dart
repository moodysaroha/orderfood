import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/sdui/sdui_screen_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final VoidCallback onLogout;

  const AdminDashboardScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SduiScreenWidget(
        title: 'Admin Dashboard',
        showAppBar: false,
        fetchScreen: () async {
          final res = await api.get('/admin/dashboard');
          return res.data as Map<String, dynamic>;
        },
        onAction: (action, ctx) {
          if (action.type == 'navigate' && action.route != null) {
            _handleNavigation(context, action.route!);
          }
        },
      ),
    );
  }

  void _handleNavigation(BuildContext context, String route) {
    // Admin dashboard navigation is handled by the bottom nav
    // The SDUI actions are mainly for in-screen interactions
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onLogout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
