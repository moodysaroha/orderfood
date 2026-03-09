import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';

class AdminSettlementsScreen extends ConsumerStatefulWidget {
  const AdminSettlementsScreen({super.key});

  @override
  ConsumerState<AdminSettlementsScreen> createState() => _AdminSettlementsScreenState();
}

class _AdminSettlementsScreenState extends ConsumerState<AdminSettlementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> _balances = [];
  List<dynamic> _pendingSettlements = [];
  bool _loadingBalances = true;
  bool _loadingSettlements = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadBalances(), _loadPendingSettlements()]);
  }

  Future<void> _loadBalances() async {
    setState(() => _loadingBalances = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/commission/balances');
      setState(() {
        _balances = res.data['data'] as List<dynamic>;
        _loadingBalances = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingBalances = false;
      });
    }
  }

  Future<void> _loadPendingSettlements() async {
    setState(() => _loadingSettlements = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/commission/settlements/pending');
      setState(() {
        _pendingSettlements = res.data['data'] as List<dynamic>;
        _loadingSettlements = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingSettlements = false;
      });
    }
  }

  Future<void> _createSettlement(String vendorId, String vendorName, int pendingAmount) async {
    final amountController = TextEditingController(text: (pendingAmount / 100).toStringAsFixed(0));
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Settlement for $vendorName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pending Balance: ₹${(pendingAmount / 100).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount to Settle',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid amount')),
          );
        }
        return;
      }

      try {
        final api = ref.read(apiClientProvider);
        await api.dio.post('/commission/settlements', data: {
          'vendorId': vendorId,
          'amountInPaise': (amount * 100).round(),
          'notes': notesController.text.isNotEmpty ? notesController.text : null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement created')),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _processSettlement(String settlementId, String vendorName, int amount) async {
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Process Settlement for $vendorName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Amount: ₹${(amount / 100).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference ID',
                hintText: 'UPI/Bank transaction ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (referenceController.text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reference ID is required')),
          );
        }
        return;
      }

      try {
        final api = ref.read(apiClientProvider);
        await api.dio.post('/commission/settlements/$settlementId/process', data: {
          'referenceId': referenceController.text,
          'notes': notesController.text.isNotEmpty ? notesController.text : null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement processed')),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Settlements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Balances'),
            Tab(text: 'Pending Payouts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBalancesTab(),
          _buildPendingTab(),
        ],
      ),
    );
  }

  Widget _buildBalancesTab() {
    if (_loadingBalances) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_balances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No vendor balances yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBalances,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _balances.length,
        itemBuilder: (context, index) {
          final balance = _balances[index];
          final pending = balance['pendingAmountInPaise'] as int;
          final settled = balance['settledAmountInPaise'] as int;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(balance['vendorName'] ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pending: ${balance['pendingAmountFormatted']}',
                      style: TextStyle(color: pending > 0 ? Colors.orange : Colors.grey)),
                  Text('Total Settled: ${balance['settledAmountFormatted']}',
                      style: const TextStyle(color: Colors.green)),
                ],
              ),
              trailing: pending > 0
                  ? FilledButton.tonal(
                      onPressed: () => _createSettlement(
                        balance['vendorId'],
                        balance['vendorName'],
                        pending,
                      ),
                      child: const Text('Settle'),
                    )
                  : null,
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_loadingSettlements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingSettlements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending settlements'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingSettlements,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingSettlements.length,
        itemBuilder: (context, index) {
          final settlement = _pendingSettlements[index];
          final status = settlement['status'] as String;
          final createdAt = DateTime.parse(settlement['createdAt']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          settlement['vendorName'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(status),
                        backgroundColor: status == 'PENDING'
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settlement['amountFormatted'] ?? '₹0.00',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created: ${DateFormat('MMM d, y h:mm a').format(createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (settlement['notes'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${settlement['notes']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        onPressed: () => _processSettlement(
                          settlement['id'],
                          settlement['vendorName'],
                          settlement['amountInPaise'],
                        ),
                        child: const Text('Mark as Paid'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
