/// Represents a single MPLADS project, aligned with FastAPI ProjectOut schema.
class Project {
  final String id; // maps to work_id
  final String description; // maps to description
  final String location;
  final String state;
  final String district; // maps to constituency, state
  final String status; // maps to project_status

  final double estimatedCost; // maps to recommended_amount
  final DateTime startDate; // maps to created_at
  final DateTime? endDate; // maps to completion_date

  final double riskScore; // optional from ML prediction
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
    required this.description,
    required this.location,
    required this.state,
    required this.district,
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
    double score = (json['risk_score'] as num?)?.toDouble() ?? 0.0;
    List<String> tags = [];
    if (json['why_flagged'] != null) {
      tags = List<String>.from(json['why_flagged']);
    } else if (json['risk_tags'] != null) {
      tags = List<String>.from(json['risk_tags']);
    }

    return Project(
      id: json['work_id'] as String? ?? json['id'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? json['name'] as String? ?? 'Unknown Project',
      state: json['state'] as String? ?? 'Unknown',
      district: json['constituency'] as String? ?? 'Unknown',
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

  // The dynamically calculated penalty score!
  double get effectiveRiskScore {
    double finalScore = riskScore;
    
    if (daysUntilUpdate < 0) {
      int daysOverdue = daysUntilUpdate.abs();
      finalScore += 5 + daysOverdue; // +5 flat penalty, +1 per day
    }
    
    return finalScore > 100.0 ? 100.0 : finalScore;
  }

  // The dynamically injected warning message!
  List<String> get effectiveRiskTags {
    List<String> tags = List.from(riskTags);
    if (daysUntilUpdate < 0) {
      tags.add('Update overdue by ${daysUntilUpdate.abs()} days');
    }
    return tags;
  }

  String get riskLevel {
    if (effectiveRiskScore >= 90) return 'Critical';
    if (effectiveRiskScore >= 75) return 'High';
    if (effectiveRiskScore >= 50) return 'Medium';
    return 'Low';
  }

  int get daysUntilUpdate {
    if (nextUpdateDue == null) return 0;
    final now = DateTime.now();
    return nextUpdateDue!.difference(now).inDays;
  }

  /// Format amount in Indian numbering system (e.g., 6,00,00,000)
  String get formattedCost {
    if (estimatedCost == 0) return '0';
    int amount = estimatedCost.toInt();
    String numStr = amount.toString();
    if (numStr.length <= 3) return numStr;
    
    String result = numStr.substring(numStr.length - 3);
    String remaining = numStr.substring(0, numStr.length - 3);
    while (remaining.length > 2) {
      result = '${remaining.substring(remaining.length - 2)},$result';
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      result = '$remaining,$result';
    }
    return result;
  }
}
