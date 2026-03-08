import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/currency/currency_utils.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/vendor/orders');
      setState(() {
        _orders = res.data['data'] as List;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/vendor/orders/$orderId/status', data: {'status': status});
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (_, i) {
                        final order = _orders[i] as Map<String, dynamic>;
                        final status = order['status'] as String;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(order['student']?['name'] ?? 'Student'),
                            subtitle: Text(
                              '${CurrencyUtils.formatPaise(order['totalAmountInPaise'] as int)} · $status',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (s) => _updateStatus(order['id'], s),
                              itemBuilder: (_) => [
                                'CONFIRMED', 'PREPARING', 'READY', 'DELIVERED', 'CANCELLED',
                              ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
