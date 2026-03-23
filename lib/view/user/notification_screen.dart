import 'package:flutter/material.dart';

import '../../service/notification_service.dart';
import '../../entity/notification.dart';


class NotificationScreen extends StatelessWidget {
  final int userId;
  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NotificationService.instance.getAllNotifications(userId: userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!
              .map((e) => NotificationEntity.fromMap(e))
              .toList();
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: const Icon(Icons.notifications, color: Colors.blue),
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: Text(n.createdAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}
