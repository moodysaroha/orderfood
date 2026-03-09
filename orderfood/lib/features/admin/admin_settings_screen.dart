import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _config;

  final _commissionController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _platformNameController = TextEditingController();
  final _minSettlementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _upiIdController.dispose();
    _platformNameController.dispose();
    _minSettlementController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/commission/config');
      final data = res.data['data'] as Map<String, dynamic>;

      setState(() {
        _config = data;
        _commissionController.text = data['commissionPercentage'].toString();
        _upiIdController.text = data['platformUpiId'] ?? '';
        _platformNameController.text = data['platformName'] ?? '';
        _minSettlementController.text = ((data['minSettlementAmount'] ?? 0) / 100).toStringAsFixed(0);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    final commission = double.tryParse(_commissionController.text);
    if (commission == null || commission < 0 || commission > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commission must be between 0 and 100')),
      );
      return;
    }

    final minSettlement = double.tryParse(_minSettlementController.text);
    if (minSettlement == null || minSettlement < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum settlement must be a positive number')),
      );
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/commission/config', data: {
        'commissionPercentage': commission,
        'platformUpiId': _upiIdController.text,
        'platformName': _platformNameController.text,
        'minSettlementAmount': (minSettlement * 100).round(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Settings')),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadConfig, child: const Text('Retry')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commission Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commissionController,
                    decoration: const InputDecoration(
                      labelText: 'Commission Percentage',
                      suffixText: '%',
                      helperText: 'Percentage deducted from each order (0-100)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _upiIdController,
                    decoration: const InputDecoration(
                      labelText: 'Platform UPI ID',
                      helperText: 'UPI ID where students will pay',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _platformNameController,
                    decoration: const InputDecoration(
                      labelText: 'Platform Name',
                      helperText: 'Name shown in UPI payment apps',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settlement Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minSettlementController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Settlement Amount',
                      prefixText: '₹ ',
                      helperText: 'Minimum amount required for vendor payout',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
