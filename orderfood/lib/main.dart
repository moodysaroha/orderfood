import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_screen.dart';
import 'features/vendor/vendor_home_screen.dart';
import 'features/student/student_home_screen.dart';
import 'features/admin/admin_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: OrderFoodApp()));
}

class OrderFoodApp extends ConsumerStatefulWidget {
  const OrderFoodApp({super.key});

  @override
  ConsumerState<OrderFoodApp> createState() => _OrderFoodAppState();
}

class _OrderFoodAppState extends ConsumerState<OrderFoodApp> {
  String? _authenticatedRole;

  void _onAuthenticated(String role) {
    setState(() => _authenticatedRole = role);
  }

  Future<void> _onLogout() async {
    final api = ref.read(apiClientProvider);
    await api.clearToken();
    setState(() => _authenticatedRole = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderFood',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_authenticatedRole == null) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }
    if (_authenticatedRole == 'VENDOR') {
      return VendorHomeScreen(onLogout: _onLogout);
    }
    if (_authenticatedRole == 'ADMIN') {
      return AdminHomeScreen(onLogout: _onLogout);
    }
    return StudentHomeScreen(onLogout: _onLogout);
  }
}
