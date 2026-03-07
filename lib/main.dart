import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:food/app_state.dart';
import 'package:food/models.dart';
import 'package:food/pages/getpro_page.dart';
import 'package:food/pages/login/login_page.dart';
import 'package:food/services/auth_service.dart';
import 'package:food/services/loading_service.dart';
import 'package:food/widget/authcheck_widget.dart';
import 'package:food/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize App Check
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LoadingService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Lock & Key',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/pro': (context) => const GetProPage(),
      },
    );
  }
}

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final authService = Provider.of<AuthService>(context);

    if (appState.user.role == UserRole.student && !appState.user.isSubscribed) {
      return const SubscriptionGate();
    }

    Widget body;
    String title;

    switch (appState.user.role) {
      case UserRole.vendor:
        body = const VendorDashboard();
        title = "Vendor Dashboard";
        break;
      case UserRole.admin:
        body = const AdminPanel();
        title = "Admin Panel";
        break;
      case UserRole.student:
      default:
        body = const StudentHomeScreen();
        title = "Student Home";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () => _showTimeTravelDialog(context, appState),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          )
        ],
      ),
      body: body,
    );
  }

  void _showTimeTravelDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug: Set Time"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("7:30 AM (Lock-in Window)"),
              onTap: () {
                appState.setSimulatedTime(7, 30);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("11:05 AM (Auto-Deduction Check)"),
              onTap: () {
                appState.setSimulatedTime(11, 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("1:30 PM (Pickup Window)"),
              onTap: () {
                appState.setSimulatedTime(13, 30);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("5:30 PM (Closed)"),
              onTap: () {
                appState.setSimulatedTime(17, 30);
                Navigator.pop(context);
              },
            ),
            TextButton(
              onPressed: () {
                appState.resetToRealTime();
                Navigator.pop(context);
              },
              child: const Text("Reset to Real Time"),
            )
          ],
        ),
      ),
    );
  }
}

class SubscriptionGate extends StatefulWidget {
  const SubscriptionGate({super.key});

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  bool _isSubscribing = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                "Welcome to Lock & Key",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Access to vendors is blocked until you have an active plan.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _isSubscribing 
                  ? null 
                  : () async {
                      setState(() => _isSubscribing = true);
                      // Simulate a small delay for better UX
                      await Future.delayed(const Duration(milliseconds: 800));
                      appState.subscribe();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Subscription Active! Enjoy your meals.")),
                        );
                      }
                    },
                child: _isSubscribing 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Text("Buy 30-Day Plan (90 Coins)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(user),
          const SizedBox(height: 20),
          _buildUrgencyTimer(appState),
          const SizedBox(height: 20),
          if (user.currentMealStatus == MealStatus.available)
            _buildVendorSelection(context, appState)
          else if (user.currentMealStatus == MealStatus.locked)
            _buildLockedStatus(context, appState)
          else if (user.currentMealStatus == MealStatus.consumed)
            const Card(
              color: Colors.greenAccent,
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text("Meal Consumed!"),
                subtitle: Text("Hope you enjoyed your bite."),
              ),
            )
          else if (user.currentMealStatus == MealStatus.expired)
            _buildExpiredStatus(context, appState),
        ],
      ),
    );
  }

  Widget _buildTopBar(UserProfile user) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello, ${user.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.role == UserRole.student ? "Student Profile" : "Vendor Profile"),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text("Balance: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${user.coins} 🪙", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text("Rescue Passes: ${user.rescuePasses} 🆘", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        )
      ],
    );
  }

  Widget _buildUrgencyTimer(AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Column(
        children: [
          const Text("Urgency Timer", style: TextStyle(color: Colors.grey)),
          Text(
            appState.getTimerMessage(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorSelection(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Available Vendors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...appState.vendors.map((vendor) => Card(
          child: ExpansionTile(
            title: Text(vendor.name),
            subtitle: const Text("Tap to see menu"),
            children: vendor.menu.map((meal) => ListTile(
              title: Text(meal.name),
              subtitle: Text(meal.description),
              trailing: meal.isSoldOut 
                ? const Text("SOLD OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                : ElevatedButton(
                    onPressed: () {
                      final error = appState.lockMeal(vendor.id, meal.id);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error),
                          action: SnackBarAction(
                            label: 'Change Time',
                            onPressed: () => _showTimeTravelDialog(context, appState),
                          ),
                        ));
                      }
                    },
                    child: const Text("🔒 LOCK"),
                  ),
            )).toList(),
          ),
        )),
      ],
    );
  }

  void _showTimeTravelDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug: Set Time"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("7:30 AM (Lock-in Window)"),
              onTap: () {
                appState.setSimulatedTime(7, 30);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("11:05 AM (Expired)"),
              onTap: () {
                appState.setSimulatedTime(11, 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("1:30 PM (Pickup Window)"),
              onTap: () {
                appState.setSimulatedTime(13, 30);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedStatus(BuildContext context, AppState appState) {
    final isPickup = appState.isPickupWindow();
    final mealId = appState.user.lockedMealId;
    final vendorId = appState.user.lockedVendorId;
    
    final vendor = appState.vendors.firstWhere((v) => v.id == vendorId);
    final meal = vendor.menu.firstWhere((m) => m.id == mealId);

    return Column(
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Meal Locked at ${vendor.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meal.name, style: const TextStyle(fontSize: 16)),
                const Divider(),
                if (!isPickup)
                   const Text("Kitchen is preparing your meal. Pickup starts at 12 PM.")
                else
                   Column(
                     children: [
                       const Text("Show this QR to the vendor for pickup:"),
                       const SizedBox(height: 20),
                       QrImageView(
                          data: "ORDER_${appState.user.id}_$mealId",
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                       const SizedBox(height: 10),
                       const Text("Valid for pickup until 4 PM", style: TextStyle(color: Colors.grey, fontSize: 12)),
                     ],
                   )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredStatus(BuildContext context, AppState appState) {
    return Card(
      color: Colors.redAccent.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.timer_off, color: Colors.white),
              title: Text("Daily Credit Deducted", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("You missed today's lock-in window.", style: TextStyle(color: Colors.white70)),
            ),
            if (appState.user.rescuePasses > 0 && appState.isLockWindow())
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: () => appState.useRescuePass(),
                  child: Text("Use Rescue Pass (${appState.user.rescuePasses} left)"),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final vendor = appState.vendors.isNotEmpty 
        ? appState.vendors.firstWhere((v) => v.id == 'v1', orElse: () => appState.vendors.first)
        : Vendor(id: 'unknown', name: 'Unknown Vendor', menu: []);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Overview"),
            Tab(icon: Icon(Icons.restaurant_menu), text: "Menu"),
            Tab(icon: Icon(Icons.history), text: "Orders"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(appState, vendor),
              _buildMenuTab(appState, vendor),
              _buildOrdersTab(appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(AppState appState, Vendor vendor) {
    final lockedMeals = appState.user.lockedVendorId == vendor.id ? 1 : 0; // Simulated count

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${vendor.name} Dashboard", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPreOrderManifest(lockedMeals),
          const SizedBox(height: 24),
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Simulated Scan
              if (appState.user.currentMealStatus == MealStatus.locked && appState.isPickupWindow()) {
                appState.consumeMeal();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Confirmed!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No active orders for pickup or window closed.")));
              }
            },
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: const Text("SCAN PICKUP QR", style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 24),
          _buildStatSummary(),
        ],
      ),
    );
  }

  Widget _buildMenuTab(AppState appState, Vendor vendor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendor.menu.length,
      itemBuilder: (context, index) {
        final meal = vendor.menu[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${meal.category} • ${meal.description}"),
            trailing: Switch(
              value: !meal.isSoldOut,
              activeColor: Colors.green,
              onChanged: (value) => appState.toggleItemStock(vendor.id, meal.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab(AppState appState) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No order history yet today", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPreOrderManifest(int count) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.inventory, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Today's Pre-Order Manifest", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _manifestItem("Total Prep Needed", count.toString(), Icons.restaurant),
                _manifestItem("Guaranteed Revenue", "${count * 0.9} 🪙", Icons.payments),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _manifestItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.deepPurple)),
      ],
    );
  }

  Widget _buildStatSummary() {
    return Row(
      children: [
        Expanded(child: _statCard("Total Scanned", "0", Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Pending", "1", Colors.orange)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("The Sweep Tool", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatCard("Total Auto-Deductions Today", "${appState.totalAutoDeductions}", Colors.red.shade100),
          const SizedBox(height: 8),
          _buildStatCard("Total Meals Consumed", "${appState.totalConsumed}", Colors.green.shade100),
          const SizedBox(height: 24),
          const Text("Payout Calculator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Card(
            child: ListTile(
              title: Text("Oven Express"),
              subtitle: Text("Pending Payout: 0.9 🪙"),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      color: color,
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
