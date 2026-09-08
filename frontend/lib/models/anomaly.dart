/// Represents a single detected anomaly/risk factor for a project.
/// Used in risk_analysis.dart to power the "Why Flagged?" explanation.
class Anomaly {
  final String id;
  final String projectId;
  final String type; // e.g. "Cost Anomaly", "Duplicate Work", "Delay"
  final String description; // human-readable explanation of why it was flagged
  final String source; // e.g. "Rule Check", "Isolation Forest", "Duplicate Detection"
  final double confidence; // 0.0 - 1.0, how confident the model is
  final String recommendation; // suggested next step for the auditor

  Anomaly({
    required this.id,
    required this.projectId,
    required this.type,
    required this.description,
    required this.source,
    required this.confidence,
    required this.recommendation,
  });

  factory Anomaly.fromJson(Map<String, dynamic> json) {
    return Anomaly(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      source: json['source'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
    );
  }

  /// Confidence shown as a whole-number percentage, e.g. "87%"
  String get confidencePercent => '${(confidence * 100).round()}%';
}