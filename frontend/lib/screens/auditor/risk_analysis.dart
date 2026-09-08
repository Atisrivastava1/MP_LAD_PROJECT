import 'package:flutter/material.dart';
import '../../widgets/profile_header.dart';

import '../../models/anomaly.dart';
import '../../services/api_service.dart';

/// Risk Analysis / "Why Flagged?" — shows the ML risk score summary
/// at the top, then lists each detected anomaly with type, description,
/// source, confidence, and recommendation.
///
/// All values come from the backend; nothing is calculated here.
class RiskAnalysisScreen extends StatefulWidget {
  final String projectId;

  const RiskAnalysisScreen({super.key, required this.projectId});

  @override
  State<RiskAnalysisScreen> createState() => _RiskAnalysisScreenState();
}

class _RiskAnalysisScreenState extends State<RiskAnalysisScreen> {
  late Future<_AnalysisData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_AnalysisData> _loadData() async {
    final proj = await ApiService.fetchProjectDetails(widget.projectId);
    final anoms = await ApiService.fetchAnomalies(widget.projectId);
    return _AnalysisData(
      project: proj as dynamic,
      anomalies: (anoms as List).cast<Anomaly>(),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'Critical':
        return const Color(0xFFD32F2F);
      case 'High':
        return const Color(0xFFF57C00);
      case 'Medium':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF388E3C);
    }
  }

  Color _sourceColor(String source) {
    if (source.contains('Rule')) return const Color(0xFF1565C0);
    if (source.contains('Isolation')) return const Color(0xFF6A1B9A);
    if (source.contains('Duplicate')) return const Color(0xFF00695C);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: buildProfileAppBarActions(context),
        title: const Text('Why Flagged?'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_AnalysisData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load analysis: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _dataFuture = _loadData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final project = data.project;
          final anomalies = data.anomalies;
          final riskColor = _riskColor(project.riskLevel);

          final isDesktop = MediaQuery.of(context).size.width >= 900;
          Widget content = isDesktop
              ? _buildDesktopLayout(project, anomalies, riskColor)
              : _buildMobileLayout(project, anomalies, riskColor);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(dynamic project, List<Anomaly> anomalies, Color riskColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRiskSummary(project, riskColor),
        const SizedBox(height: 20),
        _buildAnomaliesList(anomalies),
      ],
    );
  }

  Widget _buildDesktopLayout(dynamic project, List<Anomaly> anomalies, Color riskColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildRiskSummary(project, riskColor),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: _buildAnomaliesList(anomalies),
        ),
      ],
    );
  }

  Widget _buildRiskSummary(dynamic project, Color riskColor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: riskColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(project.name,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    project.riskLevel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  backgroundColor: riskColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: riskColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Risk Score',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      Text(
                        '${project.riskScore} / 100',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: project.riskScore / 100,
                    color: riskColor,
                    backgroundColor: riskColor.withValues(alpha: 0.1),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score provided by ML backend. Higher = greater audit priority.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesList(List<Anomaly> anomalies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Anomalies (${anomalies.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (anomalies.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No anomalies detected for this project.'),
            ),
          )
        else
          ...anomalies.asMap().entries.map((entry) {
            final index = entry.key;
            final anomaly = entry.value;
            final color = _sourceColor(anomaly.source);
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  anomaly.type,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Confidence badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            anomaly.confidencePercent,
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(anomaly.description, style: const TextStyle(fontSize: 13, height: 1.5)),
                    const SizedBox(height: 10),

                    // Source badge
                    Row(
                      children: [
                        Icon(Icons.memory, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Detected by: ${anomaly.source}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Recommendation
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            anomaly.recommendation,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _AnalysisData {
  final dynamic project;
  final List<Anomaly> anomalies;
  _AnalysisData({required this.project, required this.anomalies});
}
