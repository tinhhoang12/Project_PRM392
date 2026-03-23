import 'package:flutter/material.dart';

import '../../entity/notification.dart';
import '../../service/notification_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  List<NotificationEntity> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final rows =
        await _notificationService.getAllNotifications(userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _notifications = rows.map(NotificationEntity.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _openDetail(NotificationEntity item) async {
    if (item.id != null && !item.isRead) {
      await _notificationService.markAsRead(item.id!);
      await _loadNotifications();
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.body,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Time: ${_formatTime(item.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard Notifications'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return ListTile(
                        onTap: () => _openDetail(item),
                        leading: Icon(
                          item.isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: item.isRead
                              ? const Color(0xFF64748B)
                              : const Color(0xFF135BEC),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatTime(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
