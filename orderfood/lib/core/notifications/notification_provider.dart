import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import 'notification_service.dart';

class NotificationData {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationState {
  final List<NotificationData> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationData>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _api;
  final NotificationService _notificationService;
  bool _deviceRegistered = false;

  NotificationNotifier(this._api, this._notificationService) : super(NotificationState());

  Future<void> registerDevice() async {
    if (_deviceRegistered) return;
    
    final token = _notificationService.deviceToken;
    if (token == null) return;

    try {
      await _api.dio.post('/notifications/device/register', data: {
        'token': token,
        'platform': 'android',
      });
      _deviceRegistered = true;
    } catch (e) {
      // Silent fail - notifications are optional
    }
  }

  Future<void> unregisterDevice() async {
    final token = _notificationService.deviceToken;
    if (token == null) return;

    try {
      await _api.dio.post('/notifications/device/unregister', data: {
        'token': token,
      });
      _deviceRegistered = false;
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> loadNotifications({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      final data = response.data;
      final notifications = (data['notifications'] as List)
          .map((n) => NotificationData.fromJson(n as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: data['unreadCount'] as int,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['error'] ?? 'Failed to load notifications',
      );
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _api.dio.get('/notifications/unread-count');
      state = state.copyWith(unreadCount: response.data['unreadCount'] as int);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.dio.patch('/notifications/$notificationId/read');
      
      final updated = state.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          return NotificationData(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: (state.unreadCount - 1).clamp(0, state.unreadCount),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.dio.patch('/notifications/read-all');
      
      final updated = state.notifications.map((n) {
        return NotificationData(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();

      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      // Silent fail
    }
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(apiClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(api, notificationService);
});
