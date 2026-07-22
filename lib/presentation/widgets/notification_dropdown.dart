import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationDropdown extends ConsumerStatefulWidget {
  const NotificationDropdown({super.key});

  @override
  ConsumerState<NotificationDropdown> createState() =>
      _NotificationDropdownState();
}

class _NotificationDropdownState extends ConsumerState<NotificationDropdown> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  bool _isOpen = false;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadCountSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    _unreadCountSubscription = _notificationRepository.getUnreadCount().listen((
      count,
    ) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Stack(
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _isOpen = true;
        });
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              enabled: false,
              child: SizedBox(
                width: 300,
                height: 400,
                child: NotificationList(
                  onNotificationsViewed: () {
                    setState(() {
                      _isOpen = false;
                    });
                  },
                ),
              ),
            ),
          ],
    );
  }
}

class NotificationList extends ConsumerStatefulWidget {
  final VoidCallback onNotificationsViewed;

  const NotificationList({required this.onNotificationsViewed, super.key});

  @override
  ConsumerState<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<NotificationList> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  @override
  void initState() {
    super.initState();
    // Marcar todas como leídas cuando se abre el menú
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationRepository.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Notificaciones',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await _markAllAsRead();
                    },
                    child: const Text(
                      'Marcar todas como leídas',
                      style: TextStyle(fontSize: 11),
                      textAlign:
                          TextAlign
                              .right, // asegura que el texto se alinee bien
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<NotificationModel>>(
            stream: _notificationRepository.getUserNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No hay notificaciones',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () async {
                      await _notificationRepository.markAsRead(notification.id);
                      widget.onNotificationsViewed();
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _markAllAsRead() async {
    await _notificationRepository.markAllAsRead();
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight:
                          notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_course':
        return Colors.green;
      case 'reminder':
        return Colors.orange;
      case 'achievement':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_course':
        return Icons.school;
      case 'reminder':
        return Icons.alarm;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
