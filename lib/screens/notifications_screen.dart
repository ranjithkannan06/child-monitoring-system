import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    final items = service.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: service.markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: service.clearAll,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                final read = (n['read'] == true);
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).cardColor,
                  leading: Icon(
                    read ? Icons.notifications_none : Icons.notifications_active,
                    color: read ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text((n['title'] ?? '').toString()),
                  subtitle: Text((n['body'] ?? '').toString()),
                  trailing: read ? null : const Icon(Icons.fiber_new, color: Colors.redAccent),
                  onTap: () {
                    final id = (n['id'] ?? '').toString();
                    if (id.isNotEmpty) {
                      service.markAsRead(id);
                    }
                  },
                );
              },
            ),
    );
  }
}
