import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/notification_bell.dart';
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

class _VendorListScreen extends ConsumerStatefulWidget {
  final void Function(String vendorId) onVendorTap;
  final VoidCallback onLogout;

  const _VendorListScreen({required this.onVendorTap, required this.onLogout});

  @override
  ConsumerState<_VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<_VendorListScreen> {
  List<dynamic> _vendors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/student/vendors');
      setState(() {
        _vendors = res.data['data'] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
              widget.onLogout();
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
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadVendors, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('No restaurants available yet'),
            const SizedBox(height: 8),
            const Text(
              'Check back later!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: ListView.builder(
        itemCount: _vendors.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final vendor = _vendors[index];
          final menuCount = vendor['menuItemCount'] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                vendor['restaurantName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vendor['description'] != null)
                    Text(
                      vendor['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '$menuCount items on menu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onVendorTap(vendor['id']),
            ),
          );
        },
      ),
    );
  }
}
