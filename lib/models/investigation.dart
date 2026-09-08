/// Represents an auditor's investigation into a flagged project.
/// Used across investigation_form.dart, review_decision.dart,
/// and case_status.dart.
class Investigation {
  final String id;
  final String projectId;
  final String auditorName;
  final String findings;
  final List<String> evidenceFiles; // file names/paths of uploaded evidence
  final String status; // e.g. "Draft", "Submitted", "Under Review", "Approved", "Rejected", "Escalated"
  final String? reviewComment; // added by Senior/Independent Reviewer
  final String? reviewerDecision; // "Approve" | "Reject" | "Escalate"
  final DateTime submittedAt;

  Investigation({
    required this.id,
    required this.projectId,
    required this.auditorName,
    required this.findings,
    required this.evidenceFiles,
    required this.status,
    this.reviewComment,
    this.reviewerDecision,
    required this.submittedAt,
  });

  factory Investigation.fromJson(Map<String, dynamic> json) {
    return Investigation(
      id: json['investigation_id'] as String? ?? json['id'] as String? ?? 'Unknown ID',
      projectId: json['project_id'] as String? ?? 'Unknown',
      auditorName: json['assigned_to'] as String? ?? json['auditor_name'] as String? ?? 'Unknown Auditor',
      findings: json['findings'] as String? ?? '',
      evidenceFiles: List<String>.from(json['evidence_files'] ?? []),
      status: json['status'] as String? ?? 'Unknown',
      reviewComment: json['remarks'] as String? ?? json['review_comment'] as String?,
      reviewerDecision: json['reviewer_decision'] as String?,
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : (json['started_at'] != null ? DateTime.parse(json['started_at']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'auditor_name': auditorName,
        'findings': findings,
        'evidence_files': evidenceFiles,
        'status': status,
        'review_comment': reviewComment,
        'reviewer_decision': reviewerDecision,
        'submitted_at': submittedAt.toIso8601String(),
      };
}