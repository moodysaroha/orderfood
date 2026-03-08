class SduiScreen {
  final String screen;
  final int version;
  final List<SduiComponent> components;
  final Map<String, SduiAction>? actions;
  final int? pollingIntervalMs;

  SduiScreen({
    required this.screen,
    required this.version,
    required this.components,
    this.actions,
    this.pollingIntervalMs,
  });

  factory SduiScreen.fromJson(Map<String, dynamic> json) {
    return SduiScreen(
      screen: json['screen'] as String,
      version: json['version'] as int,
      components: (json['components'] as List)
          .map((c) => SduiComponent.fromJson(c as Map<String, dynamic>))
          .toList(),
      actions: json['actions'] != null
          ? (json['actions'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, SduiAction.fromJson(v as Map<String, dynamic>)),
            )
          : null,
      pollingIntervalMs: json['pollingIntervalMs'] as int?,
    );
  }
}

class SduiComponent {
  final String type;
  final Map<String, dynamic>? props;
  final List<SduiComponent>? children;

  SduiComponent({
    required this.type,
    this.props,
    this.children,
  });

  factory SduiComponent.fromJson(Map<String, dynamic> json) {
    return SduiComponent(
      type: json['type'] as String,
      props: json['props'] as Map<String, dynamic>?,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => SduiComponent.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  String? prop(String key) => props?[key]?.toString();
  int? propInt(String key) => props?[key] is int ? props![key] as int : null;
  bool propBool(String key) => props?[key] == true;
}

class SduiAction {
  final String type;
  final String? route;
  final String? method;
  final String? url;
  final String? confirmMessage;

  SduiAction({
    required this.type,
    this.route,
    this.method,
    this.url,
    this.confirmMessage,
  });

  factory SduiAction.fromJson(Map<String, dynamic> json) {
    return SduiAction(
      type: json['type'] as String,
      route: json['route'] as String?,
      method: json['method'] as String?,
      url: json['url'] as String?,
      confirmMessage: json['confirmMessage'] as String?,
    );
  }
}
