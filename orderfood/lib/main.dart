import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/notification_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/vendor/vendor_home_screen.dart';
import 'features/student/student_home_screen.dart';
import 'features/admin/admin_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(const ProviderScope(child: OrderFoodApp()));
}

class OrderFoodApp extends ConsumerStatefulWidget {
  const OrderFoodApp({super.key});

  @override
  ConsumerState<OrderFoodApp> createState() => _OrderFoodAppState();
}

class _OrderFoodAppState extends ConsumerState<OrderFoodApp> {
  String? _authenticatedRole;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
  }

  void _onAuthenticated(String role) {
    setState(() => _authenticatedRole = role);
    _registerDevice();
  }

  Future<void> _registerDevice() async {
    final notifier = ref.read(notificationNotifierProvider.notifier);
    await notifier.registerDevice();
  }

  Future<void> _onLogout() async {
    final api = ref.read(apiClientProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    
    await notifier.unregisterDevice();
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
