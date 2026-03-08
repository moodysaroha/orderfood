import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/currency/currency_utils.dart';

class StudentOrdersScreen extends ConsumerStatefulWidget {
  const StudentOrdersScreen({super.key});

  @override
  ConsumerState<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends ConsumerState<StudentOrdersScreen> {
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
      final res = await api.get('/student/orders');
      setState(() {
        _orders = res.data['data'] as List;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
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
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.receipt)),
                            title: Text(CurrencyUtils.formatPaise(order['totalAmountInPaise'] as int)),
                            subtitle: Text('Status: ${order['status']}'),
                            trailing: Text(
                              (order['createdAt'] as String).split('T').first,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
