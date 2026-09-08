/// ML prediction result from the backend Isolation Forest model.
/// Maps directly to the `predictions` table schema.
///
/// The frontend MUST NOT calculate any of these values itself —
/// every field is received from the FastAPI backend as-is.
class MlPrediction {
  final String predictionId;
  final String projectId;
  final String modelName;
  final String modelVersion;

  /// Raw anomaly score from Isolation Forest (negative = more anomalous).
  /// Display as-is; do NOT re-interpret as a probability.
  final double rawAnomalyScore;

  /// Normalised 0–100 risk score computed by the backend.
  /// Thresholds:
  ///   0–<50   → Low
  ///   50–<75  → Medium
  ///   75–<90  → High
  ///   90–100  → Critical
  final double riskScore;

  /// "Low" | "Medium" | "High" | "Critical"
  final String riskLevel;

  /// List of human-readable reasons why this project was flagged.
  final List<String> whyFlagged;

  /// Dictionary of rule/condition names that fired and their values.
  final Map<String, dynamic> rulesTriggered;

  /// The seven frozen ML features used during inference.
  /// Keys match the backend column names exactly.
  final Map<String, dynamic> processedFeatures;

  final DateTime predictionCreatedAt;

  MlPrediction({
    required this.predictionId,
    required this.projectId,
    required this.modelName,
    required this.modelVersion,
    required this.rawAnomalyScore,
    required this.riskScore,
    required this.riskLevel,
    required this.whyFlagged,
    required this.rulesTriggered,
    required this.processedFeatures,
    required this.predictionCreatedAt,
  });

  factory MlPrediction.fromJson(Map<String, dynamic> json) {
    return MlPrediction(
      predictionId: json['prediction_id'] as String,
      projectId: json['project_id'] as String,
      modelName: json['model_name'] as String? ?? 'IsolationForest',
      modelVersion: json['model_version'] as String? ?? '1.0',
      rawAnomalyScore: (json['raw_anomaly_score'] as num).toDouble(),
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      whyFlagged: List<String>.from(json['why_flagged'] ?? []),
      rulesTriggered: Map<String, dynamic>.from(json['rules_triggered'] ?? {}),
      processedFeatures: Map<String, dynamic>.from(json['processed_features'] ?? {}),
      predictionCreatedAt: DateTime.parse(json['prediction_created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'prediction_id': predictionId,
        'project_id': projectId,
        'model_name': modelName,
        'model_version': modelVersion,
        'raw_anomaly_score': rawAnomalyScore,
        'risk_score': riskScore,
        'risk_level': riskLevel,
        'why_flagged': whyFlagged,
        'rules_triggered': rulesTriggered,
        'processed_features': processedFeatures,
        'prediction_created_at': predictionCreatedAt.toIso8601String(),
      };

  /// UI helper: color for risk level badge.
  /// Defined here so every screen uses the same colour logic.
  static const Map<String, int> _riskColors = {
    'Critical': 0xFFD32F2F, // deep red
    'High': 0xFFF57C00, // deep orange
    'Medium': 0xFFF9A825, // amber
    'Low': 0xFF388E3C, // green
  };

  int get riskColorValue => _riskColors[riskLevel] ?? 0xFF757575;

  /// Formatted risk score for display, e.g. "91.7"
  String get riskScoreDisplay => riskScore.toStringAsFixed(1);
}
