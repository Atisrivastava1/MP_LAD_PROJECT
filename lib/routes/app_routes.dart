import 'package:flutter/material.dart';

import '../screens/login.dart';
import '../screens/signup.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/auditor_dashboard.dart';
import '../screens/risk_project_list.dart';
import '../screens/investigation_list_screen.dart';
import '../screens/audit_history.dart';
import '../screens/audit_report.dart';
import '../screens/data_manager_dashboard.dart';
import '../screens/upload_project.dart';

import '../screens/data_quality.dart';
import '../screens/dm_projects_screen.dart';
import '../screens/dm_reports_screen.dart';

/// Central place for all named routes.
///
/// Screens that require constructor arguments (projectId, investigationId, etc.)
/// are pushed manually via Navigator.push(...) from their parent screen.
///
/// Those screens are:
///   - RiskAnalysisScreen(projectId)
///   - EvidenceUploadScreen(initialFiles)
///   - ReviewDecisionScreen(investigationId)
///   - AuditHistoryScreen(projectId)
///   - ProjectDataValidationScreen(fileName)
class AppRoutes {
  // Auth
  static const String login = '/login';
  static const String signup = '/signup';

  // Shared
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // Auditor
  static const String auditorDashboard = '/auditor-dashboard';
  static const String riskProjectList = '/risk-projects';
  static const String auditorInvestigations = '/auditor-investigations';
  static const String auditHistory = '/audit-history';
  static const String auditReport = '/audit-report';

  // Data Manager
  static const String dataManagerDashboard = '/data-manager-dashboard';
  static const String uploadProject = '/upload-project';

  static const String dataQuality = '/data-quality';
  static const String dmProjects = '/dm-projects';
  static const String dmReports = '/dm-reports';

  static Map<String, WidgetBuilder> routes = {
    // Auth
    login: (context) => const LoginScreen(),
    signup: (context) => const SignUpScreen(),

    // Shared
    profile: (context) => const ProfileScreen(),
    notifications: (context) => const NotificationsScreen(),

    // Auditor
    auditorDashboard: (context) => const AuditorDashboardScreen(),
    riskProjectList: (context) => const RiskProjectListScreen(),
    auditorInvestigations: (context) => const InvestigationListScreen(),
    auditHistory: (context) => const AuditHistoryScreen(),
    auditReport: (context) => const AuditReportScreen(),

    // Data Manager
    dataManagerDashboard: (context) => const DataManagerDashboardScreen(),
    uploadProject: (context) => const UploadProjectScreen(),

    dataQuality: (context) => const DataQualityScreen(),
    dmProjects: (context) => const DmProjectsScreen(),
    dmReports: (context) => const DmReportsScreen(),
  };

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('No screen registered for "${settings.name}"'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(login, (_) => false),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}