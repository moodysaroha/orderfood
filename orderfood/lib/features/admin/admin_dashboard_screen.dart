import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/sdui/sdui_screen_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final VoidCallback onLogout;
  final void Function(int tabIndex) onNavigateToTab;

  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    required this.onNavigateToTab,
  });

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
            _handleNavigation(action.route!);
          }
        },
      ),
    );
  }

  void _handleNavigation(String route) {
    // Map routes to tab indices
    // Tabs: 0=Dashboard, 1=Vendors, 2=Students, 3=Orders, 4=Settlements, 5=Settings
    switch (route) {
      case '/admin/vendors':
        onNavigateToTab(1);
        break;
      case '/admin/students':
        onNavigateToTab(2);
        break;
      case '/admin/orders':
        onNavigateToTab(3);
        break;
      case '/admin/settlements':
        onNavigateToTab(4);
        break;
      case '/admin/settings':
        onNavigateToTab(5);
        break;
    }
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
