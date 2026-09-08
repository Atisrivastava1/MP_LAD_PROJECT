import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/api_service.dart';
import '../widgets/app_shell.dart';

class DataManagerDashboardScreen extends StatefulWidget {
  const DataManagerDashboardScreen({super.key});

  @override
  State<DataManagerDashboardScreen> createState() => _DataManagerDashboardScreenState();
}

class _DataManagerDashboardScreenState extends State<DataManagerDashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = ApiService.fetchDataManagerDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Data Manager Dashboard',
      selectedIndex: 0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
              }
              final stats = snapshot.data!;

              if (isDesktop) {
                return _buildDesktopLayout(stats);
              }
              return _buildMobileLayout(stats);
            },
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, dynamic> stats) {
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
                  Text('Overview', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Track data ingestion and quality metrics.', style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 1: Stat Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Projects',
                  value: '${stats['totalProjects']}',
                  icon: Icons.folder,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Current Projects',
                  value: '${stats['newProjects']}',
                  icon: Icons.new_releases,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Processed Projects',
                  value: '${stats['recordsProcessed']}',
                  icon: Icons.dataset,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Row 2: Charts and Risks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildDataOverviewChart(stats),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildRiskSummary(stats),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Track data ingestion and quality metrics.', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 20),
          
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Projects',
                    value: '${stats['totalProjects']}',
                    icon: Icons.folder,
                    color: Colors.blue,
                    isSmall: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Current Projects',
                    value: '${stats['newProjects']}',
                    icon: Icons.new_releases,
                    color: Colors.purple,
                    isSmall: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Processed Projects',
                    value: '${stats['recordsProcessed']}',
                    icon: Icons.dataset,
                    color: Colors.teal,
                    isSmall: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDataOverviewChart(stats),
          const SizedBox(height: 24),
          _buildRiskSummary(stats),
        ],
      ),
    );
  }

  Widget _buildDataOverviewChart(Map<String, dynamic> stats) {
    final completed = (stats['completedProjects'] as int).toDouble();
    final ongoing = (stats['ongoingProjects'] as int).toDouble();
    final pending = (stats['pendingProjects'] as int).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 55,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: completed,
                              title: '',
                              radius: 15,
                            ),
                            PieChartSectionData(
                              color: Colors.blue,
                              value: ongoing,
                              title: '',
                              radius: 15,
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: pending,
                              title: '',
                              radius: 15,
                            ),
                          ],
                        ),
                      ),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('100%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text('Processed', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Completed', Colors.green, stats['completedProjects'].toString()),
                      const SizedBox(height: 12),
                      _buildLegendItem('Ongoing', Colors.blue, stats['ongoingProjects'].toString()),
                      const SizedBox(height: 12),
                      _buildLegendItem('Pending', Colors.orange, stats['pendingProjects'].toString()),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRiskSummary(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Risk Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Anomalies detected across all projects', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),
            _buildRiskRow('High Risk', stats['highRisk'].toString(), Colors.red, Icons.warning_rounded, 0.1),
            const Divider(height: 32),
            _buildRiskRow('Medium Risk', stats['mediumRisk'].toString(), Colors.orange, Icons.info_outline, 0.3),
            const Divider(height: 32),
            _buildRiskRow('Low Risk', stats['lowRisk'].toString(), Colors.green, Icons.check_circle_outline, 0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskRow(String label, String value, Color color, IconData icon, double fraction) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: fraction,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSmall;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (!isSmall) ...[
                  const Spacer(),
                  const Icon(Icons.arrow_outward, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  const Text('12%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: isSmall ? 22 : 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.black54, fontSize: isSmall ? 11 : 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
