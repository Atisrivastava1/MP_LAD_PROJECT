/// Represents a single MPLADS project, aligned with FastAPI ProjectOut schema.
class Project {
  final String id; // maps to work_id
  final String name; // maps to description
  final String location; // maps to constituency, state
  final String status; // maps to project_status

  final double estimatedCost; // maps to recommended_amount
  final DateTime startDate; // maps to created_at
  final DateTime? endDate; // maps to completion_date

  final int riskScore; // optional from ML prediction
  final List<String> riskTags; // optional from ML prediction
  final String lastUpdated; // maps to updated_at
  
  final String? mpName;
  final int? completionDelayDays;
  final bool? hasImages;
  final bool? completionDateInconsistent;
  final bool? completionDelayMissing;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? nextUpdateDue; // NEW

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.estimatedCost,
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
    this.nextUpdateDue,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    double estCost = (json['recommended_amount'] as num?)?.toDouble() ?? (json['estimated_cost'] as num?)?.toDouble() ?? 0.0;
    
    // Fallback logic for nested ML Prediction data if the backend returns it joined
    int score = json['risk_score'] as int? ?? 0;
    List<String> tags = [];
    if (json['why_flagged'] != null) {
      tags = List<String>.from(json['why_flagged']);
    } else if (json['risk_tags'] != null) {
      tags = List<String>.from(json['risk_tags']);
    }

    return Project(
      id: json['work_id'] as String? ?? json['id'] as String? ?? 'Unknown',
      name: json['description'] as String? ?? json['name'] as String? ?? 'Unknown Project',
      location: (json['state'] != null && json['constituency'] != null) 
          ? '${json['constituency']}, ${json['state']}'
          : json['location'] as String? ?? 'Unknown Location',
      status: json['project_status'] as String? ?? json['status'] as String? ?? 'Unknown',
      estimatedCost: estCost,
      startDate: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['completion_date'] != null 
          ? DateTime.tryParse(json['completion_date']) 
          : null,
      riskScore: score,
      riskTags: tags,
      lastUpdated: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'])?.toLocal().toString().split(' ')[0] ?? 'Unknown'
          : 'Unknown',
      mpName: json['mp_name'] as String?,
      completionDelayDays: json['completion_delay_days'] as int?,
      hasImages: json['has_images'] as bool?,
      completionDateInconsistent: json['completion_date_inconsistent'] as bool?,
      completionDelayMissing: json['completion_delay_missing'] as bool?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      nextUpdateDue: json['next_update_due'] != null ? DateTime.tryParse(json['next_update_due']) : null,
    );
  }

  String get riskLevel {
    if (riskScore >= 90) return 'Critical';
    if (riskScore >= 75) return 'High';
    if (riskScore >= 50) return 'Medium';
    return 'Low';
  }
}
