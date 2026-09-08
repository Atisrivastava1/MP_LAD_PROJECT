import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import 'api_service.dart';

class ProjectService {
  
  static Future<List<Project>> fetchHighRiskProjects() async {
    try {
      final token = await ApiService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/projects'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final projects = data.map((e) => Project.fromJson(e)).toList();
        
        // Filter out non-high-risk for this specific view
        // The backend might return all, or we could have a specific endpoint.
        // For now, we fetch all and filter in frontend to match legacy mock behavior
        final highRisk = projects.where((p) => p.riskScore >= 50).toList();
        return highRisk.isNotEmpty ? highRisk : projects; // Fallback to all if no anomalies yet
      }
      return [];
    } catch (e) {
      print('Fetch projects error: $e');
      return [];
    }
  }

  static Future<Project?> fetchProjectDetails(String workId) async {
    try {
      final token = await ApiService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/projects/$workId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return Project.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Fetch project details error: $e');
      return null;
    }
  }
}
