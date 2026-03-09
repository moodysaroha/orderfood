import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_vendors_screen.dart';
import 'admin_students_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_settlements_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminHomeScreen({super.key, required this.onLogout});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  void _navigateToScreen(String route) {
    Widget? screen;
    if (route == '/admin/vendors') {
      screen = const AdminVendorsScreen();
    } else if (route == '/admin/students') {
      screen = const AdminStudentsScreen();
    }
    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(
        onLogout: widget.onLogout,
        onNavigateToScreen: _navigateToScreen,
      ),
      const AdminOrdersScreen(),
      const AdminSettlementsScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Payouts'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
