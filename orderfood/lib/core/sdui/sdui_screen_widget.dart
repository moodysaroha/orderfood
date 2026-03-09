import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sdui_models.dart';
import 'sdui_registry.dart';

/// Generic SDUI screen renderer.
/// Fetches a screen definition from the API (or accepts one directly),
/// parses the JSON, and renders all components using the widget factory.
class SduiScreenWidget extends ConsumerStatefulWidget {
  final Future<Map<String, dynamic>> Function() fetchScreen;
  final void Function(SduiAction action, Map<String, dynamic>? context)? onAction;
  final String? title;
  final bool showAppBar;

  const SduiScreenWidget({
    super.key,
    required this.fetchScreen,
    this.onAction,
    this.title,
    this.showAppBar = true,
  });

  @override
  ConsumerState<SduiScreenWidget> createState() => _SduiScreenWidgetState();
}

class _SduiScreenWidgetState extends ConsumerState<SduiScreenWidget> {
  SduiScreen? _screen;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadScreen() async {
    try {
      setState(() { _loading = true; _error = null; });
      final json = await widget.fetchScreen();
      final data = json['data'] as Map<String, dynamic>? ?? json;
      final screen = SduiScreen.fromJson(data);

      if (mounted) {
        setState(() { _screen = screen; _loading = false; });
        _setupPolling(screen.pollingIntervalMs);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  void _setupPolling(int? intervalMs) {
    _pollTimer?.cancel();
    if (intervalMs != null && intervalMs > 0) {
      _pollTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
        _loadScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _screen == null) {
      if (!widget.showAppBar) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: widget.title != null ? AppBar(title: Text(widget.title!)) : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _screen == null) {
      final errorBody = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadScreen, child: const Text('Retry')),
          ],
        ),
      );
      if (!widget.showAppBar) {
        return errorBody;
      }
      return Scaffold(
        appBar: widget.title != null ? AppBar(title: Text(widget.title!)) : null,
        body: errorBody,
      );
    }

    final screen = _screen!;
    final factory = SduiWidgetFactory(
      actions: screen.actions,
      onAction: widget.onAction,
    );

    // Extract appBar component if present
    final appBarComponent = screen.components
        .where((c) => c.type == 'appBar')
        .firstOrNull;
    final bodyComponents = screen.components
        .where((c) => c.type != 'appBar' && c.type != 'fab')
        .toList();
    final fabComponent = screen.components
        .where((c) => c.type == 'fab')
        .firstOrNull;

    final body = RefreshIndicator(
      onRefresh: _loadScreen,
      child: ListView(
        children: bodyComponents.map((c) => factory.build(c)).toList(),
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarComponent?.prop('title') ?? widget.title ?? screen.screen),
        actions: appBarComponent?.children
            ?.map((c) => factory.build(c))
            .toList(),
      ),
      body: body,
      floatingActionButton: fabComponent != null
          ? FloatingActionButton(
              onPressed: () => factory.triggerAction(fabComponent.prop('actionKey') ?? ''),
              child: Icon(_resolveIcon(fabComponent.prop('icon') ?? 'add')),
            )
          : null,
    );
  }
}

IconData _resolveIcon(String name) {
  const map = <String, IconData>{
    'shopping_cart': Icons.shopping_cart,
    'add': Icons.add,
  };
  return map[name] ?? Icons.add;
}
