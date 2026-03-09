import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_provider.dart';
import '../../features/notifications/notifications_screen.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationNotifierProvider.notifier).fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);

    return IconButton(
      icon: Badge(
        isLabelVisible: state.unreadCount > 0,
        label: Text(
          state.unreadCount > 99 ? '99+' : state.unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        );
      },
      tooltip: 'Notifications',
    );
  }
}
