import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_vendors_screen.dart';
import 'admin_students_screen.dart';
import 'admin_orders_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminHomeScreen({super.key, required this.onLogout});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    AdminDashboardScreen(onLogout: widget.onLogout),
    const AdminVendorsScreen(),
    const AdminStudentsScreen(),
    const AdminOrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Vendors'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Students'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Orders'),
        ],
      ),
    );
  }
}
