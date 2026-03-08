import 'package:flutter/material.dart';
import 'sdui_models.dart';
import 'widgets/sdui_widgets.dart';

/// Maps SDUI component type strings to Flutter widget builder functions.
/// New component types are registered here -- no app update needed to render
/// new server-driven layouts, as long as the type is registered.
typedef SduiWidgetBuilder = Widget Function(
  SduiComponent component,
  SduiWidgetFactory factory,
);

class SduiWidgetFactory {
  final Map<String, SduiWidgetBuilder> _builders = {};
  final Map<String, SduiAction> _actions;
  final void Function(SduiAction action, Map<String, dynamic>? context)? onAction;

  SduiWidgetFactory({
    Map<String, SduiAction>? actions,
    this.onAction,
  }) : _actions = actions ?? {} {
    _registerDefaults();
  }

  void _registerDefaults() {
    register('appBar', buildAppBar);
    register('statsRow', buildStatsRow);
    register('statCard', buildStatCard);
    register('sectionHeader', buildSectionHeader);
    register('list', buildList);
    register('orderTile', buildOrderTile);
    register('menuItemTile', buildMenuItemTile);
    register('menuItemCard', buildMenuItemCard);
    register('button', buildButton);
    register('fab', buildFab);
    register('emptyState', buildEmptyState);
    register('text', buildText);
    register('image', buildImage);
    register('icon', buildSduiIcon);
    register('divider', buildDivider);
    register('spacer', buildSpacer);
    register('switchToggle', buildSwitchToggle);
    register('iconButton', buildIconButton);
    register('column', buildColumn);
    register('row', buildRow);
    register('card', buildCard);
    register('container', buildContainer);
  }

  void register(String type, SduiWidgetBuilder builder) {
    _builders[type] = builder;
  }

  Widget build(SduiComponent component) {
    final builder = _builders[component.type];
    if (builder == null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Unknown component: ${component.type}',
            style: const TextStyle(color: Colors.red)),
      );
    }
    return builder(component, this);
  }

  List<Widget> buildChildren(SduiComponent component) {
    return component.children?.map((c) => build(c)).toList() ?? [];
  }

  void triggerAction(String actionKey, {Map<String, dynamic>? context}) {
    final action = _actions[actionKey];
    if (action != null && onAction != null) {
      onAction!(action, context);
    }
  }
}
