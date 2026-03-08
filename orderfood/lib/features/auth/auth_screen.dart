import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

/// Placeholder auth screen. Full login/register flow to be implemented later.
class AuthScreen extends ConsumerStatefulWidget {
  final void Function(String role) onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isVendor = true;
  bool _loading = false;
  String? _error;

  // Only used for registration
  final _nameController = TextEditingController();
  final _restaurantController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _restaurantController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final api = ref.read(apiClientProvider);

    try {
      final Map<String, dynamic> body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      if (_isLogin) {
        final res = await api.post('/auth/login', data: body);
        final token = res.data['data']['token'] as String;
        final role = res.data['data']['user']['role'] as String;
        await api.saveToken(token);
        widget.onAuthenticated(role);
      } else {
        body['role'] = _isVendor ? 'VENDOR' : 'STUDENT';
        if (_isVendor) {
          body['restaurantName'] = _restaurantController.text.trim();
        } else {
          body['name'] = _nameController.text.trim();
        }
        final res = await api.post('/auth/register', data: body);
        final token = res.data['data']['token'] as String;
        final role = res.data['data']['user']['role'] as String;
        await api.saveToken(token);
        widget.onAuthenticated(role);
      }
    } catch (e) {
      setState(() { _error = 'Authentication failed. Please check your credentials.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant, size: 64, color: Colors.deepOrange),
                const SizedBox(height: 16),
                Text('OrderFood', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Vendor')),
                      ButtonSegment(value: false, label: Text('Student')),
                    ],
                    selected: {_isVendor},
                    onSelectionChanged: (s) => setState(() => _isVendor = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (_isVendor)
                    TextField(
                      controller: _restaurantController,
                      decoration: const InputDecoration(labelText: 'Restaurant Name', prefixIcon: Icon(Icons.store)),
                    )
                  else
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isLogin ? 'Login' : 'Register'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? "Don't have an account? Register" : 'Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
