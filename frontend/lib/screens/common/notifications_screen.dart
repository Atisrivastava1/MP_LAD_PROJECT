import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/profile_header.dart';

/// Notifications Screen — lists all system notifications.
/// Used by both Auditor and Data Manager roles.
class NotificationsScreen extends StatefulWidget {
  final String role;
  final String userName;
  final String userId;

  const NotificationsScreen({
    super.key,
    this.role = 'Auditor',
    this.userName = 'User',
    this.userId = 'USR-001',
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_NotifItem> _mockNotifs = [];

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    final rawList = await ApiService.fetchNotifications();
    final notifs = rawList.map((m) => _NotifItem(
      icon: Icons.info_outline,
      color: m['type'] == 'alert' ? const Color(0xFFE53935) : const Color(0xFF2F6FED),
      title: m['title']?.toString() ?? 'Notification',
      body: m['message']?.toString() ?? '',
      time: m['time']?.toString() ?? '',
    )).toList();
    if (mounted) {
      setState(() {
        _mockNotifs = notifs;
      });
    }
  }

  // Placeholder notification data — replace with API call


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: buildProfileAppBarActions(context),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _mockNotifs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _mockNotifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = _mockNotifs[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: notif.color.withValues(alpha: 0.12),
                      child: Icon(notif.icon, color: notif.color, size: 20),
                    ),
                    title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(notif.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
  });
}
