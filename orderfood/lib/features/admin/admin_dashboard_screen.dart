import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  final void Function(String route) onNavigateToScreen;

  const AdminDashboardScreen({
    super.key,
    required this.onLogout,
    required this.onNavigateToScreen,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/admin/stats');
      setState(() {
        _stats = res.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Logout',
                  onPressed: () => _confirmLogout(context),
                ),
              ],
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats Cards
                    _buildStatsGrid(colorScheme),
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildQuickActions(colorScheme),
                    const SizedBox(height: 24),
                    
                    // Today's Summary
                    _buildTodaySummary(colorScheme),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.store_rounded,
          label: 'Vendors',
          value: '${_stats?['totalVendors'] ?? 0}',
          color: Colors.orange,
          onTap: () => widget.onNavigateToScreen('/admin/vendors'),
        ),
        _StatCard(
          icon: Icons.school_rounded,
          label: 'Students',
          value: '${_stats?['totalStudents'] ?? 0}',
          color: Colors.blue,
          onTap: () => widget.onNavigateToScreen('/admin/students'),
        ),
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          label: 'Total Orders',
          value: '${_stats?['totalOrders'] ?? 0}',
          color: Colors.green,
        ),
        _StatCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Total Revenue',
          value: _stats?['totalRevenue'] ?? '₹0',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.store_rounded,
            label: 'Manage\nVendors',
            color: Colors.orange,
            onTap: () => widget.onNavigateToScreen('/admin/vendors'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.people_rounded,
            label: 'Manage\nStudents',
            color: Colors.blue,
            onTap: () => widget.onNavigateToScreen('/admin/students'),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummary(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.primary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Today's Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Orders',
                  value: '${_stats?['ordersToday'] ?? 0}',
                  icon: Icons.receipt_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: colorScheme.outline.withOpacity(0.3)),
              Expanded(
                child: _SummaryItem(
                  label: 'Revenue',
                  value: _stats?['revenueToday'] ?? '₹0',
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
