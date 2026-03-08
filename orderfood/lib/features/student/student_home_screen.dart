import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'menu/student_menu_screen.dart';
import 'orders/student_orders_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

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

  const _VendorListScreen({required this.onVendorTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant, size: 64, color: Colors.deepOrange),
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
