import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class DataManagerDashboardScreen extends StatefulWidget {
  const DataManagerDashboardScreen({super.key});

  @override
  State<DataManagerDashboardScreen> createState() => _DataManagerDashboardScreenState();
}

class _DataManagerDashboardScreenState extends State<DataManagerDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardStatsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardStatsFuture = ApiService.fetchDataManagerDashboardStats();
  }

  Future<void> _refreshData() async {
    setState(() {
      _dashboardStatsFuture = ApiService.fetchDataManagerDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Error loading dashboard: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildDesktopLayout(stats);
              }
              return _buildMobileLayout(stats);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: const Color(0xFF4318FF),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGradientStatCard(
                  title: 'Total Uploads',
                  value: '${stats['totalProjects']}',
                  icon: Icons.cloud_upload_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF4318FF), Color(0xFF868CFF)]),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGradientStatCard(
                  title: 'Pending Review',
                  value: '${stats['pendingProjects']}',
                  icon: Icons.pending_actions_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFC107)]),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGradientStatCard(
                  title: 'Completed Audits',
                  value: '${stats['completedProjects']}',
                  icon: Icons.verified_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF00B09B), Color(0xFF96C93D)]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildModernDataOverview(stats),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 4,
                child: _buildAIAnalysisSummary(stats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: true),
          const SizedBox(height: 24),
          _buildGradientStatCard(
            title: 'Total Uploads',
            value: '${stats['totalProjects']}',
            icon: Icons.cloud_upload_rounded,
            gradient: const LinearGradient(colors: [Color(0xFF4318FF), Color(0xFF868CFF)]),
          ),
          const SizedBox(height: 16),
          _buildGradientStatCard(
            title: 'Pending Review',
            value: '${stats['pendingProjects']}',
            icon: Icons.pending_actions_rounded,
            gradient: const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFC107)]),
          ),
          const SizedBox(height: 16),
          _buildGradientStatCard(
            title: 'Completed Audits',
            value: '${stats['completedProjects']}',
            icon: Icons.verified_rounded,
            gradient: const LinearGradient(colors: [Color(0xFF00B09B), Color(0xFF96C93D)]),
          ),
          const SizedBox(height: 24),
          _buildModernDataOverview(stats),
          const SizedBox(height: 24),
          _buildAIAnalysisSummary(stats),
          const SizedBox(height: 48), // Padding for FAB
        ],
      ),
    );
  }

  Widget _buildHeader({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workspace Overview',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2B3674),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor your dataset ingestion and ML anomaly predictions.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: const Color(0xFFA3AED0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA3AED0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3674),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDataOverview(Map<String, dynamic> stats) {
    final int total = stats['totalProjects'] ?? 1;
    final int completed = stats['completedProjects'] ?? 0;
    final int ongoing = stats['ongoingProjects'] ?? 0;
    final int pending = stats['pendingProjects'] ?? 0;
    
    // Prevent division by zero
    final safeTotal = total == 0 ? 1 : total;
    final double completePct = (completed / safeTotal) * 100;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pipeline Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 65,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF00B09B),
                            value: completed.toDouble(),
                            title: '',
                            radius: 12,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF4318FF),
                            value: ongoing.toDouble(),
                            title: '',
                            radius: 12,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFFF9800),
                            value: pending.toDouble(),
                            title: '',
                            radius: 12,
                          ),
                          if (total == 0)
                            PieChartSectionData(
                              color: Colors.grey.shade200,
                              value: 1,
                              title: '',
                              radius: 12,
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${completePct.toInt()}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B3674),
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            'Done',
                            style: TextStyle(
                              color: Color(0xFFA3AED0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPipelineLegend('Completed', completed, total, const Color(0xFF00B09B)),
                    const SizedBox(height: 24),
                    _buildPipelineLegend('In Progress', ongoing, total, const Color(0xFF4318FF)),
                    const SizedBox(height: 24),
                    _buildPipelineLegend('Submitted', pending, total, const Color(0xFFFF9800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineLegend(String label, int value, int total, Color color) {
    final double pct = total > 0 ? value / total : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA3AED0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildAIAnalysisSummary(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF4318FF)),
              SizedBox(width: 8),
              Text(
                'ML Risk Distribution',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3674),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Latest anomaly predictions by Sentinel Engine.',
            style: TextStyle(color: Color(0xFFA3AED0), fontSize: 13),
          ),
          const SizedBox(height: 32),
          _buildRiskBar('Critical', stats['criticalRisk'] ?? 0, const Color(0xFFE53935)),
          const SizedBox(height: 24),
          _buildRiskBar('High', stats['highRisk'] ?? 0, const Color(0xFFFF9800)),
          const SizedBox(height: 24),
          _buildRiskBar('Medium', stats['mediumRisk'] ?? 0, const Color(0xFFFFC107)),
          const SizedBox(height: 24),
          _buildRiskBar('Low', stats['lowRisk'] ?? 0, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildRiskBar(String label, int value, Color color) {
    // Assuming max possible per risk is 50 for a nice visual scale, or dynamically calc max.
    // Let's dynamically calculate max safely.
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B3674),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // visually scale the bar (cap at 100% width for visual max of 25 items)
                  double widthFactor = value / 25.0;
                  if (widthFactor > 1.0) widthFactor = 1.0;
                  return Container(
                    width: constraints.maxWidth * widthFactor,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
