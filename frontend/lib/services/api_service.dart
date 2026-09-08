import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/investigation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/audit_log.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static User? currentUser;

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------- AUTH ----------------

  static Future<bool> login({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _storage.write(key: 'jwt_token', value: data['access_token']);
        currentUser = User(
          id: data['user_id'],
          name: data['name'],
          username: username,
          role: data['role'],
          department: '',
          email: '',
          createdAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: ');
      return false;
    }
  }

  static Future<bool> signup({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
          'department': department,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _storage.write(key: 'jwt_token', value: data['access_token']);
        currentUser = User(
          id: data['user_id'],
          name: data['name'],
          username: username,
          role: data['role'],
          department: department,
          email: email,
          createdAt: DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: ');
      return false;
    }
  }

  static Future<User?> fetchCurrentUser() async {
    try {
      final headers = await _getHeaders();
      if (!headers.containsKey('Authorization')) return null;
      
      final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
      if (response.statusCode == 200) {
        currentUser = User.fromJson(jsonDecode(response.body));
        return currentUser;
      }
      return null;
    } catch (e) {
      print('Fetch current user error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    currentUser = null;
  }

  // ---------------- DATA MANAGER / UPLOADS ----------------

  static Future<Map<String, dynamic>> fetchDataManagerDashboardStats() async {
    // We will keep some basic mock aggregation unless you add a stats endpoint.
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/projects'), headers: headers);
    
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return {
        'totalProjects': data.length,
        'newProjects': data.where((p) => p['project_status'] == 'SUBMITTED').length,
        'recordsProcessed': data.length * 10, // Mock metric
        'completedProjects': data.where((p) => p['project_status'] == 'COMPLETED').length,
        'ongoingProjects': data.where((p) => p['project_status'] == 'IN_PROGRESS').length,
        'pendingProjects': data.where((p) => p['project_status'] == 'SUBMITTED').length,
        'highRisk': data.length > 5 ? 5 : data.length, // Placeholder logic
        'mediumRisk': 0,
        'lowRisk': 0,
      };
    }
    return {};
  }

  static Future<Map<String, dynamic>> fetchDataQuality() async {
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

  static Future<List<Map<String, String>>> fetchUploadHistory() async {
    return [
      {
        'workId': 'CSV-TEST-01',
        'mpName': 'Test MP',
        'fileName': 'test1.csv',
        'projectStatus': 'Processed',
        'validationStatus': 'Passed',
        'detectionStatus': 'Completed',
      },
    ];
  }

  static Future<List<Map<String, String>>> fetchAuditReports() async {
    return [
      {'title': 'Monthly Risk Overview', 'date': '01 Sep 2026', 'status': 'Generated'},
    ];
  }

  static Future<bool> uploadProjectFile(String filePath) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/upload'));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  static Future<bool> submitProject(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Submit error: $e');
      return false;
    }
  }


  // --- Mock methods restored to fix compilation ---
  static Future<T> _mockError<T>() => Future<T>.error('Not implemented');

  static Future<List<AuditLog>> fetchAuditHistory([String? query]) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$baseUrl/audit-logs'), headers: headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((json) => AuditLog.fromJson(json)).toList();
      } else {
        print('Failed to fetch audit history: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching audit history: $e');
      return [];
    }
  }
  
  static Future<Map<String, int>> fetchDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$baseUrl/dashboard/summary'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'total_projects': data['total_projects'] ?? 0,
          'investigations': data['investigations_open'] ?? 0,
          'anomalies_detected': data['high_count'] ?? 0,
        };
      }
    } catch (e) {
      print('fetchDashboardStats error: ');
    }
    return {'total_projects': 0, 'investigations': 0, 'anomalies_detected': 0};
  }

  static Future<List<Project>> fetchProjects({String? searchQuery}) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$baseUrl/projects'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Project.fromJson(e)).toList();
      }
    } catch (e) {
      print('fetchProjects error: ');
    }
    return [];
  }

  static Future<List<Investigation>> fetchAllInvestigations() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$baseUrl/investigations'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((e) => Investigation.fromJson(e)).toList();
      }
    } catch (e) {
      print('fetchAllInvestigations error: ');
    }
    return [];
  }

  
  
  static fetchInvestigation(String id) => _mockError();
  static submitReviewDecision({required String investigationId, required String decision, required String comment}) => _mockError();
  static fetchAnomalies(String id) => _mockError();
  static fetchProjectDetails(String id) => _mockError();
}
