import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';

/// Notifications Screen — lists all system notifications.
/// Used by both Auditor and Data Manager roles.
class NotificationsScreen extends StatelessWidget {
  final String role;
  final String userName;
  final String userId;

  const NotificationsScreen({
    super.key,
    this.role = 'Auditor',
    this.userName = 'User',
    this.userId = 'USR-001',
  });

  // Placeholder notification data — replace with API call
  static const List<_NotifItem> _mockNotifs = [
    _NotifItem(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFE53935),
      title: 'Critical Risk Detected',
      body: 'Work ID 175556 has been flagged with a risk score of 91/100.',
      time: '2 min ago',
    ),
    _NotifItem(
      icon: Icons.file_upload_outlined,
      color: Color(0xFF2F6FED),
      title: 'CSV Upload Complete',
      body: '120 projects imported successfully. 3 anomalies detected.',
      time: '15 min ago',
    ),
    _NotifItem(
      icon: Icons.check_circle_outline,
      color: Color(0xFF43A047),
      title: 'Investigation Submitted',
      body: 'Investigation INV-2024-045 submitted by Auditor Ramesh Kumar.',
      time: '1 hour ago',
    ),
    _NotifItem(
      icon: Icons.info_outline,
      color: Color(0xFFFF8F00),
      title: 'Data Quality Alert',
      body: '15 projects are missing Completion Date. Please review.',
      time: '3 hours ago',
    ),
    _NotifItem(
      icon: Icons.copy_all_outlined,
      color: Color(0xFF8E24AA),
      title: 'Duplicate Detected',
      body: 'Work ID 172001 may be a duplicate of Work ID 175556.',
      time: 'Yesterday',
    ),
    _NotifItem(
      icon: Icons.update_outlined,
      color: Color(0xFF00ACC1),
      title: 'ML Model Updated',
      body: 'ML model updated to version 1.1.0. Re-analysis scheduled.',
      time: '2 days ago',
    ),
  ];

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
