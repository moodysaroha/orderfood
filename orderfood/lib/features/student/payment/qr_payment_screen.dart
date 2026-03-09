import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';

class QrPaymentScreen extends ConsumerStatefulWidget {
  final String orderId;
  final int amountInPaise;
  final VoidCallback? onPaymentComplete;

  const QrPaymentScreen({
    super.key,
    required this.orderId,
    required this.amountInPaise,
    this.onPaymentComplete,
  });

  @override
  ConsumerState<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends ConsumerState<QrPaymentScreen> {
  Map<String, dynamic>? _payment;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  bool _paymentComplete = false;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/payment', data: {
        'orderId': widget.orderId,
        'amountInPaise': widget.amountInPaise,
      });
      setState(() {
        _payment = res.data['data'] as Map<String, dynamic>;
        _loading = false;
      });
      _startPolling();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_payment == null || _paymentComplete) return;

      try {
        final api = ref.read(apiClientProvider);
        final res = await api.get('/payment/${_payment!['paymentId']}/status');
        final status = res.data['data']['status'];

        if (status == 'COMPLETED') {
          _pollTimer?.cancel();
          setState(() => _paymentComplete = true);
          widget.onPaymentComplete?.call();
        } else if (status == 'FAILED' || res.data['data']['isExpired'] == true) {
          _pollTimer?.cancel();
          setState(() => _error = 'Payment expired or failed');
        }
      } catch (_) {}
    });
  }

  Future<void> _openUpiApp() async {
    if (_payment == null) return;

    final upiLink = _payment!['upiDeepLink'] as String;
    final uri = Uri.parse(upiLink);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UPI app found')),
        );
      }
    }
  }

  Future<void> _confirmManually() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Transaction ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'UPI Transaction ID',
            helperText: 'Enter the transaction ID from your UPI app',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final api = ref.read(apiClientProvider);
        await api.post('/payment/${_payment!['paymentId']}/confirm', data: {
          'transactionId': result,
        });
        setState(() => _paymentComplete = true);
        widget.onPaymentComplete?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to confirm: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with UPI'),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createPayment,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paymentComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _payment!['amountFormatted'] ?? '',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Scan to Pay',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: _payment!['qrCodeData'] ?? '',
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _payment!['amountFormatted'] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${widget.orderId.substring(0, 8)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openUpiApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Pay with UPI App'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmManually,
              icon: const Icon(Icons.check),
              label: const Text('I\'ve Already Paid'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Payment expires in ${_getExpiryText()}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'UPI ID',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              Text(_payment!['upiDeepLink']?.split('pa=')[1]?.split('&')[0] ?? ''),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  final upiId = _payment!['upiDeepLink']?.split('pa=')[1]?.split('&')[0] ?? '';
                  Clipboard.setData(ClipboardData(text: upiId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI ID copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getExpiryText() {
    if (_payment == null) return '';
    try {
      final expiresAt = DateTime.parse(_payment!['expiresAt']);
      final diff = expiresAt.difference(DateTime.now());
      if (diff.isNegative) return 'Expired';
      return '${diff.inMinutes} minutes';
    } catch (_) {
      return '15 minutes';
    }
  }
}
