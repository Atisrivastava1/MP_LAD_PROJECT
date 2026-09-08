/// Represents a single MPLADS project, including financial and
/// timeline data needed for project_details.dart and risk_analysis.dart.
class Project {
  final String id; // e.g. "PRJ-10452"
  final String name; // scheme/work name, e.g. "Community Hall"
  final String location; // e.g. "Kolkata, West Bengal"
  final String status; // e.g. "Ongoing", "Completed", "Delayed"

  final double estimatedCost;
  // final double actualExpenditure;
  final DateTime startDate;
  final DateTime? endDate; // null if still ongoing

  final int riskScore; // 0-100
  final List<String> riskTags; // e.g. ["Cost Anomaly", "Duplicate", "Delay"]
  final String lastUpdated; // display string
  final String? mpName;
  final int? completionDelayDays;
  final bool? hasImages;
  final bool? completionDateInconsistent;
  final bool? completionDelayMissing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.estimatedCost,
    // required this.actualExpenditure,
    required this.startDate,
    this.endDate,
    required this.riskScore,
    required this.riskTags,
    required this.lastUpdated,
    this.mpName,
    this.completionDelayDays,
    this.hasImages,
    this.completionDateInconsistent,
    this.completionDelayMissing,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // We fall back to old mock keys if the backend keys aren't present.
    // E.g., 'work_id' (backend) vs 'id' (mock)
    
    // Fallback for actual expenditure (mocking it to 75% of estimated cost if not present)
    double estCost = (json['recommended_amount'] as num?)?.toDouble() ?? (json['estimated_cost'] as num?)?.toDouble() ?? 0.0;
    // double actExp = (json['actual_expenditure'] as num?)?.toDouble() ?? (estCost * 0.75);

    return Project(
      id: json['work_id'] as String? ?? json['id'] as String? ?? 'Unknown',
      name: json['description'] as String? ?? json['name'] as String? ?? 'Unknown Project',
      location: json['state'] != null && json['constituency'] != null 
          ? '${json['constituency']}, ${json['state']}'
          : json['location'] as String? ?? 'Unknown Location',
      status: json['project_status'] as String? ?? json['status'] as String? ?? 'Unknown',
      estimatedCost: estCost,
      // actualExpenditure: actExp,
      startDate: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now()),
      endDate: json['completion_date'] != null 
          ? DateTime.parse(json['completion_date']) 
          : (json['end_date'] != null ? DateTime.parse(json['end_date']) : null),
      riskScore: json['risk_score'] as int? ?? 0,
      riskTags: json['why_flagged'] != null 
          ? List<String>.from(json['why_flagged']) 
          : List<String>.from(json['risk_tags'] ?? []),
      lastUpdated: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']).toLocal().toString().split(' ')[0] 
          : (json['last_updated'] as String? ?? 'Unknown'),
      mpName: json['mp_name'] as String?,
      completionDelayDays: json['completion_delay_days'] as int?,
      hasImages: json['has_images'] as bool?,
      completionDateInconsistent: json['completion_date_inconsistent'] as bool?,
      completionDelayMissing: json['completion_delay_missing'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// Risk band used for colour-coded UI (chips, badges).
  /// Thresholds match the backend spec exactly:
  ///   0–<50   → Low
  ///   50–<75  → Medium
  ///   75–<90  → High
  ///   90–100  → Critical
  String get riskLevel {
    if (riskScore >= 90) return 'Critical';
    if (riskScore >= 75) return 'High';
    if (riskScore >= 50) return 'Medium';
    return 'Low';
  }

  // /// How much of the estimated cost has actually been spent, as a %.
  // double get fundUtilizationPercent {
  //   if (estimatedCost == 0) return 0;
  //   return (actualExpenditure / estimatedCost) * 100;
  // }
}