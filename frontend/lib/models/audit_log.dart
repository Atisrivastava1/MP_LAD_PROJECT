/// Represents a single entry in a project/case's permanent audit trail.
/// Used in audit_history.dart and audit_report.dart.
class AuditLog {
  final String id;
  final String who; // e.g. "Auditor 102"
  final String action; // e.g. "Submitted investigation"
  final String projectId;
  final DateTime timestamp;
  final String status; // e.g. "Under Review", "Flagged", "Closed", "Escalated"

  AuditLog({
    required this.id,
    required this.who,
    required this.action,
    required this.projectId,
    required this.timestamp,
    required this.status,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['log_id'] as String,
      who: json['user_id'] as String? ?? 'Unknown',
      action: json['action'] as String,
      projectId: json['project_id'] as String? ?? '',
      timestamp: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'Unknown',
    );
  }

  /// Display-friendly date, e.g. "28-08-2026"
  String get formattedDate =>
      '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
}