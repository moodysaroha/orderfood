import 'package:flutter/material.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'menu/vendor_menu_screen.dart';
import 'orders/vendor_orders_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const VendorHomeScreen({super.key, required this.onLogout});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    VendorDashboardScreen(onLogout: widget.onLogout),
    const VendorMenuScreen(),
    const VendorOrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_rounded), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
        ],
      ),
    );
  }
}
