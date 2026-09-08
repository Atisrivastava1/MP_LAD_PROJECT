import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/api_service.dart';
import '../../widgets/app_shell.dart';

/// Auditor Dashboard — Total projects, Critical/High/Medium/Low risk,
/// Under Investigation, recent high-risk alerts.
///
/// Stats come from ApiService.fetchDashboardStats().
/// Navigation: High-Risk list, Audit History.
class AuditorDashboardScreen extends StatefulWidget {
  const AuditorDashboardScreen({super.key});

  @override
  State<AuditorDashboardScreen> createState() => _AuditorDashboardScreenState();
}

class _AuditorDashboardScreenState extends State<AuditorDashboardScreen> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiService.fetchDashboardStats();
  }

  void _refresh() => setState(() => _statsFuture = ApiService.fetchDashboardStats());

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Auditor Dashboard',
      selectedIndex: 0,
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Failed to load dashboard: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final stats = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _buildDesktopLayout(stats);
              }
              return _buildMobileLayout(stats);
            },
          );
        },
      ),
    );
  }

  // ── Desktop Layout ────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(Map<String, int> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MPLADS Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor projects and identify potential fraud.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, color: Color(0xFF2F6FED)),
                  tooltip: 'Refresh Data',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 1: 4 Stat Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Projects',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.folder_outlined,
                  color: const Color(0xFF2F6FED),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Critical Risk',
                  value: '${stats['critical'] ?? stats['highRisk'] ?? 0}',
                  icon: Icons.dangerous_outlined,
                  color: const Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'High Risk',
                  value: '${stats['high'] ?? 0}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFF57C00),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Under Review',
                  value: '${stats['underReview'] ?? 0}',
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Charts and Alerts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Risk Overview Donut Chart Placeholder
              Expanded(
                flex: 6,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Risk Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            // Donut Chart Placeholder
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: Stack(
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 55,
                                      sections: [
                                        PieChartSectionData(
                                          color: const Color(0xFFD32F2F),
                                          value: (stats['critical'] ?? 0).toDouble(),
                                          title: '',
                                          radius: 20,
                                        ),
                                        PieChartSectionData(
                                          color: const Color(0xFFF57C00),
                                          value: (stats['high'] ?? 0).toDouble(),
                                          title: '',
                                          radius: 20,
                                        ),
                                        PieChartSectionData(
                                          color: const Color(0xFFF9A825),
                                          value: (stats['medium'] ?? 0).toDouble(),
                                          title: '',
                                          radius: 20,
                                        ),
                                        PieChartSectionData(
                                          color: const Color(0xFF388E3C),
                                          value: (stats['normal'] ?? 0).toDouble(),
                                          title: '',
                                          radius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '${stats['total'] ?? 0}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                            // Legend
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegendItem('Critical Risk', '${stats['critical'] ?? 0}', const Color(0xFFD32F2F)),
                                  const SizedBox(height: 12),
                                  _buildLegendItem('High Risk', '${stats['high'] ?? 0}', const Color(0xFFF57C00)),
                                  const SizedBox(height: 12),
                                  _buildLegendItem('Medium Risk', '${stats['medium'] ?? 0}', const Color(0xFFF9A825)),
                                  const SizedBox(height: 12),
                                  _buildLegendItem('Low Risk', '${stats['normal'] ?? 0}', const Color(0xFF388E3C)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Recent Alerts
              Expanded(
                flex: 4,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent High-Risk Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed('/risk-projects'),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _RecentAlertTile(workId: '175556', mpName: 'Shri Rajesh Gupta', riskScore: 91.7, riskLevel: 'Critical', reasons: 'Cost Anomaly, Delay, Duplicate'),
                        const _RecentAlertTile(workId: '177320', mpName: 'Shri Mohan Das', riskScore: 84.0, riskLevel: 'High', reasons: 'Missing Completion Date, Generic Description'),
                        const _RecentAlertTile(workId: '172001', mpName: 'Smt. Kavita Sharma', riskScore: 78.0, riskLevel: 'High', reasons: 'Duplicate Detected'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout(Map<String, int> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'MPLADS Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor projects and identify potential fraud.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          
          // Row 1: Total / Critical
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Projects',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.folder_outlined,
                  color: const Color(0xFF2F6FED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Critical Risk',
                  value: '${stats['critical'] ?? stats['highRisk'] ?? 0}',
                  icon: Icons.dangerous_outlined,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: High Risk / Under Review
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'High Risk',
                  value: '${stats['high'] ?? 0}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFF57C00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Under Review',
                  value: '${stats['underReview'] ?? 0}',
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Risk Overview (Circular Graph)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Risk Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Graph
                      SizedBox(
                        width: 120, // Slightly smaller to fit nicely next to legend
                        height: 120,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFFD32F2F),
                                    value: (stats['critical'] ?? 0).toDouble(),
                                    title: '',
                                    radius: 12,
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFF57C00),
                                    value: (stats['high'] ?? 0).toDouble(),
                                    title: '',
                                    radius: 12,
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFFF9A825),
                                    value: (stats['medium'] ?? 0).toDouble(),
                                    title: '',
                                    radius: 12,
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFF388E3C),
                                    value: (stats['normal'] ?? 0).toDouble(),
                                    title: '',
                                    radius: 12,
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: Text(
                                '${stats['total'] ?? 0}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Legend
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Critical Risk', '${stats['critical'] ?? 0}', const Color(0xFFD32F2F)),
                            const SizedBox(height: 12),
                            _buildLegendItem('High Risk', '${stats['high'] ?? 0}', const Color(0xFFF57C00)),
                            const SizedBox(height: 12),
                            _buildLegendItem('Medium Risk', '${stats['medium'] ?? 0}', const Color(0xFFF9A825)),
                            const SizedBox(height: 12),
                            _buildLegendItem('Low Risk', '${stats['normal'] ?? 0}', const Color(0xFF388E3C)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Recent Alerts
          const Text('Recent High-Risk Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _RecentAlertTile(workId: '175556', mpName: 'Shri Rajesh Gupta', riskScore: 91.7, riskLevel: 'Critical', reasons: 'Cost Anomaly, Delay, Duplicate'),
          const _RecentAlertTile(workId: '177320', mpName: 'Shri Mohan Das', riskScore: 84.0, riskLevel: 'High', reasons: 'Missing Completion Date'),
          const _RecentAlertTile(workId: '172001', mpName: 'Smt. Kavita Sharma', riskScore: 78.0, riskLevel: 'High', reasons: 'Duplicate Detected'),

        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Stat Card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Alert Tile
// ---------------------------------------------------------------------------

class _RecentAlertTile extends StatelessWidget {
  final String workId;
  final String mpName;
  final double riskScore;
  final String riskLevel;
  final String reasons;

  const _RecentAlertTile({
    required this.workId,
    required this.mpName,
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
  });

  Color get _color {
    switch (riskLevel) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.15),
          child: Text(
            riskScore.toStringAsFixed(0),
            style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text('Work ID: $workId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mpName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text(reasons, style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(riskLevel, style: const TextStyle(fontSize: 11)),
          backgroundColor: _color.withValues(alpha: 0.1),
          labelStyle: TextStyle(color: _color, fontWeight: FontWeight.bold),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => Navigator.of(context).pushNamed('/risk-projects'),
      ),
    );
  }
}
