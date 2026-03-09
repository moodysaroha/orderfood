import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu/student_menu_screen.dart';
import 'orders/student_orders_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const StudentHomeScreen({super.key, required this.onLogout});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _VendorListScreen(
              onVendorTap: (vendorId) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StudentMenuScreen(vendorId: vendorId),
                ));
              },
              onLogout: widget.onLogout,
            )
          : const StudentOrdersScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'My Orders'),
        ],
      ),
    );
  }
}

/// Placeholder vendor list -- in a full app, this would fetch available vendors.
class _VendorListScreen extends StatelessWidget {
  final void Function(String vendorId) onVendorTap;
  final VoidCallback onLogout;

  const _VendorListScreen({required this.onVendorTap, required this.onLogout});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Vendor list will be populated from the backend.\nFor now, use the vendor ID from seed data.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => onVendorTap('placeholder-vendor-id'),
                child: const Text('Browse Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
