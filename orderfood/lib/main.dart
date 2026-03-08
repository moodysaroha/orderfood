import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/vendor/vendor_home_screen.dart';
import 'features/student/student_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: OrderFoodApp()));
}

class OrderFoodApp extends StatefulWidget {
  const OrderFoodApp({super.key});

  @override
  State<OrderFoodApp> createState() => _OrderFoodAppState();
}

class _OrderFoodAppState extends State<OrderFoodApp> {
  String? _authenticatedRole;

  void _onAuthenticated(String role) {
    setState(() => _authenticatedRole = role);
  }

  void _onLogout() {
    setState(() => _authenticatedRole = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderFood',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_authenticatedRole == null) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }
    if (_authenticatedRole == 'VENDOR') {
      return const VendorHomeScreen();
    }
    return const StudentHomeScreen();
  }
}
