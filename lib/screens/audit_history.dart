import 'package:flutter/material.dart';

import '../models/audit_log.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';

/// Audit History — project/case activity history, actions,
/// timestamps, responsible users.
class AuditHistoryScreen extends StatefulWidget {
  final String? projectId;

  const AuditHistoryScreen({super.key, this.projectId});

  @override
  State<AuditHistoryScreen> createState() => _AuditHistoryScreenState();
}

class _AuditHistoryScreenState extends State<AuditHistoryScreen> {
  late Future<List<AuditLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = ApiService.fetchAuditHistory(widget.projectId ?? '175556');
  }



  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    return AppShell(
      title: 'Audit History',
      selectedIndex: 3, // History tab is index 3 for Auditor
      body: FutureBuilder<List<AuditLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load audit history: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No activity recorded yet.'));
          }

          return isDesktop
              ? _buildDesktopLayout(logs)
              : _buildMobileLayout(logs);
        },
      ),
    );
  }

  Widget _buildMobileLayout(List<AuditLog> logs) {
    return _buildTimeline(logs);
  }

  Widget _buildTimeline(List<AuditLog> logs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final entry = logs[index];
        final isFirst = index == 0;
        final isLast = index == logs.length - 1;
        
        // Define colors and icons based on the action/status
        Color iconColor = Colors.blue;
        IconData iconData = Icons.info_outline;
        
        if (entry.action.toLowerCase().contains('created')) {
          iconColor = const Color(0xFF1976D2);
          iconData = Icons.assignment_outlined;
        } else if (entry.action.toLowerCase().contains('evidence')) {
          iconColor = const Color(0xFF1976D2);
          iconData = Icons.upload_file_outlined;
        } else if (entry.action.toLowerCase().contains('review')) {
          iconColor = Colors.purple;
          iconData = Icons.person_outline;
        } else if (entry.action.toLowerCase().contains('decision') || entry.action.toLowerCase().contains('escalated')) {
          iconColor = Colors.green;
          iconData = Icons.gavel_outlined;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column: Timeline line and icon
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Container(
                      width: 2, 
                      height: 20, 
                      color: isFirst ? Colors.transparent : Colors.grey.shade300,
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(iconData, color: iconColor, size: 24),
                    ),
                    Expanded(
                      child: Container(
                        width: 2, 
                        color: isLast ? Colors.transparent : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 0, top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.formattedDate, 
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.action, 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: Color(0xFF0B1F3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${entry.who}', 
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isLast) Divider(color: Colors.grey.shade200, height: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<AuditLog> logs) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildTimeline(logs),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
