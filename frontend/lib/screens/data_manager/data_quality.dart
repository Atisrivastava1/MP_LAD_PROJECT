import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_shell.dart';
import '../../services/api_service.dart';

class DataQualityScreen extends StatefulWidget {
  const DataQualityScreen({super.key});

  @override
  State<DataQualityScreen> createState() => _DataQualityScreenState();
}

class _DataQualityScreenState extends State<DataQualityScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _qualityData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchDataQuality();
      if (mounted) {
        setState(() {
          _qualityData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Data Quality',
      selectedIndex: 2,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qualityData == null
              ? const Center(child: Text('Failed to load data quality.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Quality Score',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A)),
                          ),
                          const SizedBox(height: 24),
                          
                          // Top Section: Gauge & Stats
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Wrap(
                              spacing: 32,
                              runSpacing: 32,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Gauge Chart
                                SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: Stack(
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 60,
                                          sections: [
                                            PieChartSectionData(
                                              color: Colors.green,
                                              value: _qualityData!['qualityScore'].toDouble(),
                                              title: '',
                                              radius: 12,
                                            ),
                                            PieChartSectionData(
                                              color: Colors.grey.withValues(alpha: 0.2),
                                              value: (100 - _qualityData!['qualityScore']).toDouble(),
                                              title: '',
                                              radius: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${_qualityData!['qualityScore'].toInt()}%',
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Stats Next to Gauge
                                SizedBox(
                                  width: 250,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatRow(
                                        '${_qualityData!['checksPassed']}/${_qualityData!['totalChecks']} Checks Passed',
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatRow(
                                        '${_qualityData!['qualityScore'].toInt()}% Clean Records',
                                        Icons.data_usage,
                                        const Color(0xFF2F6FED),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStatRow(
                                        '${_qualityData!['criticalIssues']} Critical Issues',
                                        Icons.warning,
                                        _qualityData!['criticalIssues'] > 0 ? Colors.red : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          const Text(
                            'Quality Checks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A)),
                          ),
                          const SizedBox(height: 16),
                          
                          // List of Checks
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: (_qualityData!['checks'] as List).map((check) {
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: check['passed'] ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          check['passed'] ? Icons.check : Icons.close,
                                          color: check['passed'] ? Colors.green : Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        check['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                    ),
                                    if (check != _qualityData!['checks'].last)
                                      const Divider(height: 1, indent: 72, endIndent: 24),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatRow(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
