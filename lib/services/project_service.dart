import '../models/project.dart';

/// Handles project-related data fetching (legacy service — now superseded
/// by ApiService for all new screens).
///
/// Kept for backward compatibility with any screen still referencing it.
/// All new screens should use ApiService directly.
class ProjectService {
  /// GET /projects/high-risk — returns the top high-risk projects.
  static Future<List<Project>> fetchHighRiskProjects() async {
    // TODO: replace with real API call, e.g.
    //   final response = await http.get(
    //     Uri.parse('$baseUrl/projects/high-risk'),
    //     headers: {'Authorization': 'Bearer $token'},
    //   );
    //   final data = jsonDecode(response.body) as List;
    //   return data.map((e) => Project.fromJson(e)).toList();

    await Future.delayed(const Duration(milliseconds: 500)); // simulate network

    return [
      Project(
        id: 'PRJ-10452',
        name: 'Community Hall',
        location: 'Kolkata, West Bengal',
        status: 'Ongoing',
        estimatedCost: 2500000,
        // actualExpenditure: 1800000,
        startDate: DateTime(2023, 1, 10),
        riskScore: 91,
        riskTags: ['Cost Anomaly', 'Duplicate', 'Delay'],
        lastUpdated: '12 May 2024',
        mpName: 'Shri A.K. Roy',
        completionDelayDays: 183,
        hasImages: false,
        completionDateInconsistent: false,
        completionDelayMissing: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 5, 12),
      ),
      Project(
        id: 'PRJ-10411',
        name: 'Drainage System',
        location: 'Burdwan, West Bengal',
        status: 'Delayed',
        estimatedCost: 1200000,
        // actualExpenditure: 900000,
        startDate: DateTime(2022, 8, 5),
        riskScore: 85,
        riskTags: ['Unusual Cost', 'Delay'],
        lastUpdated: '11 May 2024',
        mpName: 'Smt. S. Banerjee',
        completionDelayDays: 45,
        hasImages: true,
        completionDateInconsistent: true,
        completionDelayMissing: false,
        createdAt: DateTime(2023, 10, 1),
        updatedAt: DateTime(2024, 5, 11),
      ),
      Project(
        id: 'PRJ-10398',
        name: 'Road Construction Phase 2',
        location: 'Nadia, West Bengal',
        status: 'Completed',
        estimatedCost: 600000,
        // actualExpenditure: 620000,
        startDate: DateTime(2022, 3, 1),
        endDate: DateTime(2023, 11, 15),
        riskScore: 70,
        riskTags: ['Duplicate'],
        lastUpdated: '12 May 2024',
      ),
      Project(
        id: 'PRJ-10377',
        name: 'Street Light Installation',
        location: 'Howrah, West Bengal',
        status: 'Completed',
        estimatedCost: 300000,
        // actualExpenditure: 295000,
        startDate: DateTime(2022, 6, 1),
        endDate: DateTime(2023, 4, 10),
        riskScore: 72,
        riskTags: ['Duplicate'],
        lastUpdated: '12 May 2024',
        completionDelayMissing: true,
      ),
    ];
  }

  /// GET /projects/{id}
  static Future<Project> fetchProjectDetails(String projectId) async {
    // TODO: replace with a real API call using projectId.
    final all = await fetchHighRiskProjects();
    return all.firstWhere((p) => p.id == projectId);
  }
}