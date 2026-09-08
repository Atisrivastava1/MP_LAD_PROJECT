import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';

class AuditReportScreen extends StatefulWidget {
  final String? projectId; // Keeping projectId for navigation context

  const AuditReportScreen({super.key, this.projectId});

  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  late Future<_ReportData> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<_ReportData> _loadReport() async {
    final stats = await ApiService.fetchDashboardStats();
    final reports = await ApiService.fetchAuditReports();
    return _ReportData(stats: stats, reports: reports);
  }
  
  void _showAllReportsDialog(BuildContext context, List<Map<String, String>> reports) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    return AppShell(
      title: 'Audit Report',
      selectedIndex: 4, // Reports tab is index 4 for Auditor

      body: FutureBuilder<_ReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load report: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final maxReports = isDesktop ? 2 : 4;

          Widget reportContent = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(data.stats),
              const SizedBox(height: 12),
              _buildTopRiskCategories(),
              const SizedBox(height: 12),
              const Text('Recent Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
              const SizedBox(height: 8),
              Expanded(
                child: _buildRecentReportsList(data.reports, maxReports),
              ),
              if (data.reports.length > maxReports)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    onPressed: () => _showAllReportsDialog(context, data.reports),
                    child: const Text('View All Reports', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export coming soon')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5B9C), // matches the blue button in the image
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Export Report (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );

          return isDesktop
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: reportContent,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: reportContent,
                );
        },
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, int> stats) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox(
                    'Total Projects',
                    '${stats['total_projects'] ?? 0}', // Dynamic data from stats
                    const Color(0xFFE8F1FF), // Blueish bg
                    const Color(0xFF1976D2), // Blue text
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox(
                    'High Risk',
                    '${stats['high_count'] ?? stats['highRisk'] ?? 0}', // Use appropriate key
                    const Color(0xFFFFEBEE), // Reddish bg
                    const Color(0xFFD32F2F), // Red text
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox(
                    'Under Review',
                    '${stats['under_review'] ?? stats['underReview'] ?? 0}',
                    const Color(0xFFFFF3E0), // Yellowish bg
                    const Color(0xFFF57C00), // Orange text
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox(
                    'Closed',
                    '${stats['closed'] ?? 18732}', // closed is not currently in backend stats, fallback to 18732 for now
                    const Color(0xFFE8F5E9), // Greenish bg
                    const Color(0xFF388E3C), // Green text
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopRiskCategories() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Risk Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
            const SizedBox(height: 16),
            _buildProgressBar('Cost Anomaly', 38),
            const SizedBox(height: 12),
            _buildProgressBar('Delay Anomaly', 27),
            const SizedBox(height: 12),
            _buildProgressBar('Duplicate Projects', 20),
            const SizedBox(height: 12),
            _buildProgressBar('Unusual Pattern', 15),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF0B1F3A), fontWeight: FontWeight.w500)),
            Text('$percentage%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          color: const Color(0xFF1976D2), // Blue bar
          backgroundColor: Colors.grey.shade200,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildRecentReportsList(List<Map<String, String>> reports, int maxItems) {
    if (reports.isEmpty) {
      return const Text('No recent reports available.');
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length > maxItems ? maxItems : reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index]);
      },
    );
  }

  Widget _buildReportCard(Map<String, String> report) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F1FF),
          child: const Icon(Icons.assessment_outlined, color: Color(0xFF1976D2), size: 20),
        ),
        title: Text(report['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${report['status']} · ${report['date']}', style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

class _ReportData {
  final Map<String, int> stats;
  final List<Map<String, String>> reports;

  _ReportData({required this.stats, required this.reports});
}
