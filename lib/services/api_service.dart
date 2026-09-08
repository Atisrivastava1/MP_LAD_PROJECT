
import '../models/user.dart';
import '../models/project.dart';
import '../models/anomaly.dart';
import '../models/investigation.dart';
import '../models/audit_log.dart';
import '../models/ml_prediction.dart';

/// Central place for all backend calls (FastAPI).
///
/// Right now every method returns hardcoded mock data so every screen
/// is fully testable before the backend is ready. Each method has a
/// TODO showing the real `http` call to swap in once Soumyadip's
/// endpoints are live — just uncomment and remove the mock block.
class ApiService {
  // static const String baseUrl = 'https://api.mplads-sentinel.gov.in/api/v1';
  static const String baseUrl = 'http://localhost:8000/api/v1';

  static String? _authToken; // set after login, sent on every request



  static User? currentUser;
  
  // Mock database for the demo to persist users across sign-up and login
  static final Map<String, User> _mockUsersDb = {};

  // ---------------- AUTH ----------------

  /// POST /auth/login (form-data) -> access_token
  /// GET /auth/me -> UserOut
  static Future<User> login({
    required String username,
    required String password,
    required String role,
  }) async {
    // TODO: POST '$baseUrl/auth/login' to get token, then GET '$baseUrl/auth/me' to get user details
    await Future.delayed(const Duration(seconds: 1));
    _authToken = 'mock-jwt-token';
    
    if (_mockUsersDb.containsKey(username)) {
      final existingUser = _mockUsersDb[username]!;
      currentUser = User(
        id: existingUser.id,
        name: existingUser.name,
        username: existingUser.username,
        role: role, // use role from login drop-down
        department: existingUser.department,
        email: existingUser.email,
        createdAt: existingUser.createdAt,
        token: _authToken,
      );
    } else {
      currentUser = User(
        id: 'USR-001',
        name: username, // Fallback to username if no name
        username: username,
        role: role,
        department: 'Ministry of Statistics & Programme Implementation',
        email: '$username@mplads.gov.in',
        createdAt: DateTime.now(),
        token: _authToken,
      );
    }
    return currentUser!;
  }

  /// POST /auth/signup
  static Future<User> signup({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    // TODO: replace with real call
    await Future.delayed(const Duration(seconds: 1));
    _authToken = 'mock-jwt-token';
    currentUser = User(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', 
      name: name.isNotEmpty ? name : username,
      username: username,
      role: role,
      department: department.isNotEmpty ? department : 'Ministry of Statistics & Programme Implementation',
      email: email.isNotEmpty ? email : '$username@mplads.gov.in',
      createdAt: DateTime.now(),
      token: _authToken,
    );
    _mockUsersDb[username] = currentUser!;
    return currentUser!;
  }

  // ---------------- ML PREDICTIONS ----------------

  /// GET /projects/{work_id}/prediction
  static Future<MlPrediction> fetchMlPrediction(String workId) async {
    // TODO: GET '$baseUrl/projects/$workId/prediction' with headers: _headers
    await Future.delayed(const Duration(milliseconds: 500));
    return MlPrediction(
      predictionId: 'pred-${workId.toLowerCase().replaceAll('-', '')}',
      projectId: workId,
      modelName: 'IsolationForest',
      modelVersion: '1.0',
      rawAnomalyScore: -0.142,
      riskScore: 91.68,
      riskLevel: 'Critical',
      whyFlagged: [
        'Cost-to-progress ratio exceeds threshold',
        'Potential duplicate detected within 2 km radius',
        'Project timeline exceeded by > 180 days',
      ],
      rulesTriggered: {'high_cost_ratio': true, 'geo_duplicate': true, 'excessive_delay': true},
      processedFeatures: {
        'recommended_amount_log': 14.73,
        'description_length': 87,
        'description_word_count': 14,
        'has_images_flag': 0,
        'completion_delay_days_clean': 183,
        'completion_date_inconsistent': 1,
        'completion_delay_missing': 0,
      },
      predictionCreatedAt: DateTime(2026, 8, 28),
    );
  }

  // ---------------- PROJECTS ----------------

  /// GET /dashboard/summary (auditor_dashboard.dart)
  /// Returns counts for all four risk tiers.
  static Future<Map<String, int>> fetchDashboardStats() async {
    // TODO: GET '$baseUrl/dashboard/summary'
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      // Backend keys
      'total_projects': 54108,
      'critical_count': 234,
      'high_count': 464,
      'medium_count': 1821,
      'low_count': 51589,
      
      // Legacy keys kept for backward compat with frontend UI
      'total': 54108,
      'critical': 234,    // risk_score >= 90
      'high': 464,        // risk_score 75-89
      'medium': 1821,     // risk_score 50-74
      'normal': 51589,    // risk_score < 50  (Low)
      'highRisk': 234,
      'underReview': 1211,
    };
  }

  static Future<List<Project>> fetchProjects({String? riskFilter, String? searchQuery}) async {
    // TODO: if riskFilter == 'Critical' || 'High', GET '$baseUrl/dashboard/high-risk'
    //       else GET '$baseUrl/projects?search=$searchQuery'
    await Future.delayed(const Duration(milliseconds: 500));

    final all = [
      Project(
        id: 'PRJ-10452',
        name: 'Community Hall',
        location: 'Kolkata, West Bengal',
        status: 'Ongoing',
        estimatedCost: 2500000,
        // actualExpenditure: 2100000,
        startDate: DateTime(2024, 1, 10),
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
        name: 'Drainage',
        location: 'Burdwan, West Bengal',
        status: 'Delayed',
        estimatedCost: 1800000,
        // actualExpenditure: 1750000,
        startDate: DateTime(2023, 11, 5),
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
        name: 'Road Construction',
        location: 'Nadia, West Bengal',
        status: 'Ongoing',
        estimatedCost: 4200000,
        // actualExpenditure: 3000000,
        startDate: DateTime(2024, 2, 20),
        riskScore: 70,
        riskTags: ['Duplicate'],
        lastUpdated: '12 May 2024',
      ),
      Project(
        id: 'PRJ-10377',
        name: 'Street Light',
        location: 'Howrah, West Bengal',
        status: 'Completed',
        estimatedCost: 600000,
        // actualExpenditure: 610000,
        startDate: DateTime(2023, 9, 1),
        endDate: DateTime(2024, 1, 15),
        riskScore: 72,
        riskTags: ['Duplicate'],
        lastUpdated: '12 May 2024',
        completionDelayMissing: true,
      ),
    ];

    var results = all;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results
          .where((p) =>
              p.id.toLowerCase().contains(q) ||
              p.name.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))
          .toList();
    }
    if (riskFilter != null && riskFilter != 'All') {
      results = results.where((p) => p.riskLevel == riskFilter).toList();
    }
    return results;
  }

  /// GET /projects/{id}
  static Future<Project> fetchProjectDetails(String projectId) async {
    // TODO: GET '$baseUrl/projects/$projectId'
    final all = await fetchProjects();
    return all.firstWhere((p) => p.id == projectId);
  }

  // ---------------- ANOMALIES / RISK ANALYSIS ----------------

  /// GET /projects/{id}/anomalies (risk_analysis.dart "Why Flagged?")
  static Future<List<Anomaly>> fetchAnomalies(String projectId) async {
    // TODO: The backend does not have a dedicated anomalies endpoint.
    // Instead, GET '$baseUrl/projects/$projectId/prediction',
    // and map the `why_flagged` strings to Anomaly objects.
    final prediction = await fetchMlPrediction(projectId);
    
    return prediction.whyFlagged.asMap().entries.map((entry) {
      return Anomaly(
        id: 'a${entry.key}',
        projectId: projectId,
        type: 'Risk Flag',
        description: entry.value,
        source: prediction.modelName,
        confidence: prediction.riskScore / 100, // mock mapping
        recommendation: 'Review this flag during investigation.',
      );
    }).toList();
  }

  // ---------------- INVESTIGATIONS ----------------

  /// POST /investigations (investigation_form.dart)
  static Future<Investigation> submitInvestigation({
    required String projectId,
    required String auditorName,
    required String findings,
    required List<String> evidenceFiles,
  }) async {
    // TODO: POST '$baseUrl/investigations' with headers: _headers
    // Expected Payload:
    // {
    //   "project_id": projectId,
    //   "assigned_to": auditorName,
    //   "findings": findings
    // }
    await Future.delayed(const Duration(seconds: 1));
    return Investigation(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      auditorName: auditorName,
      findings: findings,
      evidenceFiles: evidenceFiles,
      status: 'Submitted',
      submittedAt: DateTime.now(),
    );
  }

  /// GET /investigations/{id} (case_status.dart)
  static Future<Investigation> fetchInvestigation(String investigationId) async {
    // TODO: GET '$baseUrl/investigations/$investigationId'
    // AND GET '$baseUrl/investigations/$investigationId/evidence' to populate evidenceFiles
    await Future.delayed(const Duration(milliseconds: 400));
    return Investigation(
      id: investigationId,
      projectId: 'PRJ-10452',
      auditorName: 'Auditor 102',
      findings: 'Site visit confirmed cost discrepancy; awaiting agency response.',
      evidenceFiles: ['site_photo_1.jpg', 'invoice_scan.pdf'],
      status: 'Under Review',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  /// GET /investigations
  static Future<List<Investigation>> fetchAllInvestigations() async {
    // TODO: GET '$baseUrl/investigations'
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      Investigation(id: 'INV-2024-001', projectId: '175556', auditorName: 'Ramesh Kumar', findings: '', evidenceFiles: [], status: 'Submitted', submittedAt: DateTime(2024, 9, 7)),
      Investigation(id: 'INV-2024-002', projectId: '172001', auditorName: 'Priya Sharma', findings: '', evidenceFiles: [], status: 'Under Review', submittedAt: DateTime(2024, 9, 6)),
      Investigation(id: 'INV-2024-003', projectId: '168934', auditorName: 'Arjun Mehta', findings: '', evidenceFiles: [], status: 'Closed', submittedAt: DateTime(2024, 9, 5)),
      Investigation(id: 'INV-2024-004', projectId: '177320', auditorName: 'Ramesh Kumar', findings: '', evidenceFiles: [], status: 'Submitted', submittedAt: DateTime(2024, 9, 4)),
      Investigation(id: 'INV-2024-005', projectId: '163210', auditorName: 'Priya Sharma', findings: '', evidenceFiles: [], status: 'In Progress', submittedAt: DateTime(2024, 9, 3)),
    ];
  }

  /// PATCH /investigations/{id}/decision (review_decision.dart)
  static Future<Investigation> submitReviewDecision({
    required String investigationId,
    required String decision, // "Approve" | "Reject" | "Escalate"
    required String comment,
  }) async {
    // TODO: PATCH '$baseUrl/investigations/$investigationId/decision'
    await Future.delayed(const Duration(seconds: 1));
    final current = await fetchInvestigation(investigationId);
    return Investigation(
      id: current.id,
      projectId: current.projectId,
      auditorName: current.auditorName,
      findings: current.findings,
      evidenceFiles: current.evidenceFiles,
      status: decision == 'Approve' ? 'Approved' : (decision == 'Reject' ? 'Rejected' : 'Escalated'),
      reviewComment: comment,
      reviewerDecision: decision,
      submittedAt: current.submittedAt,
    );
  }

  // ---------------- AUDIT LOGS ----------------

  /// GET /audit-logs
  static Future<List<AuditLog>> fetchAuditHistory(String projectId) async {
    // TODO: GET '$baseUrl/audit-logs' and filter by projectId
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      AuditLog.fromJson({
        'log_id': 'log1',
        'user_id': 'Auditor 102',
        'action': 'Submitted investigation',
        'project_id': projectId,
        'created_at': DateTime(2026, 8, 28).toIso8601String(),
        'status': 'Under Review',
      }),
      AuditLog.fromJson({
        'log_id': 'log2',
        'user_id': 'System',
        'action': 'Project flagged as high risk',
        'project_id': projectId,
        'created_at': DateTime(2024, 5, 12).toIso8601String(),
        'status': 'Flagged',
      }),
      AuditLog.fromJson({
        'log_id': 'log3',
        'user_id': 'System',
        'action': 'Project delayed beyond timeline',
        'project_id': projectId,
        'created_at': DateTime(2024, 4, 10).toIso8601String(),
        'status': 'Warning',
      }),
      AuditLog.fromJson({
        'log_id': 'log4',
        'user_id': 'Auditor 102',
        'action': 'Investigation approved',
        'project_id': projectId,
        'created_at': DateTime(2024, 3, 5).toIso8601String(),
        'status': 'Approved',
      }),
      AuditLog.fromJson({
        'log_id': 'log5',
        'user_id': 'Auditor 105',
        'action': 'Manual audit requested',
        'project_id': projectId,
        'created_at': DateTime(2024, 2, 20).toIso8601String(),
        'status': 'Pending',
      }),
    ];
  }

  // ---------------- REPORTS ----------------
  
  static Future<List<Map<String, String>>> fetchAuditReports() async {
    // TODO: GET '$baseUrl/reports'
    await Future.delayed(const Duration(milliseconds: 600));
    return [
      {'title': 'Monthly Risk Overview - Aug 2024', 'date': '01 Sep 2024', 'status': 'Generated'},
      {'title': 'Delay Anomalies Report', 'date': '28 Aug 2024', 'status': 'Viewed'},
      {'title': 'Cost Deviation Summary (Q2)', 'date': '15 Aug 2024', 'status': 'Generated'},
      {'title': 'Duplicate Project Findings', 'date': '05 Aug 2024', 'status': 'Archived'},
      {'title': 'July Risk Overview - Jul 2024', 'date': '01 Aug 2024', 'status': 'Archived'},
      {'title': 'June Risk Overview - Jun 2024', 'date': '01 Jul 2024', 'status': 'Archived'},
    ];
  }

  // ---------------- DATA MANAGER / UPLOADS ----------------

  /// GET /dashboard/data-manager
  static Future<Map<String, dynamic>> fetchDataManagerDashboardStats() async {
    // TODO: GET '$baseUrl/dashboard/data-manager'
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'totalProjects': 1500,
      'newProjects': 120,
      'recordsProcessed': 45000,
      'completedProjects': 900,
      'ongoingProjects': 500,
      'pendingProjects': 100,
      'highRisk': 15,
      'mediumRisk': 45,
      'lowRisk': 940,
    };
  }

  /// GET /data-quality
  static Future<Map<String, dynamic>> fetchDataQuality() async {
    // TODO: GET '$baseUrl/data-quality'
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'qualityScore': 98.0,
      'checksPassed': 5,
      'totalChecks': 5,
      'criticalIssues': 0,
      'checks': [
        {'name': 'Required Fields Complete', 'passed': true},
        {'name': 'Amount Values Valid', 'passed': true},
        {'name': 'Dates in Logical Range', 'passed': true},
        {'name': 'Status Mapping Correct', 'passed': true},
        {'name': 'No Duplicate IDs', 'passed': true},
      ]
    };
  }

  /// POST /uploads (upload_project.dart) — fileName is just the picked
  /// file's display name for now; real multipart upload wiring is a
  /// TODO once file_picker + backend endpoint are ready.
  static Future<bool> uploadProjectFile(String fileName) async {
    // TODO: multipart POST '$baseUrl/uploads' with the actual file bytes
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// GET /uploads/history (upload_history.dart)
  static Future<List<Map<String, String>>> fetchUploadHistory() async {
    // TODO: GET '$baseUrl/uploads/history'
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      {
        'workId': '175556',
        'mpName': 'Shri Rajesh Gupta',
        'fileName': 'mplads_batch_march.csv',
        'projectStatus': 'Processed',
        'validationStatus': 'Passed',
        'detectionStatus': 'Completed',
      },
      {
        'workId': '177320',
        'mpName': 'Shri Mohan Das',
        'fileName': 'mplads_batch_april.xlsx',
        'projectStatus': 'Pending',
        'validationStatus': 'In Progress',
        'detectionStatus': 'Not Started',
      },
    ];
  }

  /// POST /projects (manual entry from upload_project.dart).
  /// [data] is the raw payload matching the backend schema.
  static Future<bool> submitProject(Map<String, dynamic> data) async {
    // TODO: POST '$baseUrl/projects' with jsonEncode(data) and headers: _headers
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  /// GET /auth/me — returns currently logged-in user.
  static Future<User?> fetchCurrentUser() async {
    // TODO: GET '$baseUrl/auth/me' with headers: _headers
    await Future.delayed(const Duration(milliseconds: 300));
    return currentUser;
  }

  /// Clears the stored auth token (logout).
  static void logout() {
    _authToken = null;
    currentUser = null;
  }
}