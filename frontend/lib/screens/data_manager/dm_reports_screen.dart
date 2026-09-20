import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../services/api_service.dart';

class DmReportsScreen extends StatelessWidget {
  const DmReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Reports & Exports',
      selectedIndex: 4,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : (constraints.maxWidth >= 750 ? 2 : 1);
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isMobile ? 1.5 : 1.7,
                children: [
                  _ReportCard(
                    icon: Icons.map_outlined,
                    color: const Color(0xFF00B09B),
                    title: 'Overall Status Report',
                    description: 'A complete CSV dataset of all projects including status, risk scores, and region data.',
                    onTap: () {
                      _showSnack(context, 'Downloading Overall Status Report...');
                      ApiService.downloadReport('/reports/overall');
                    },
                  ),
                  _ReportCard(
                    icon: Icons.verified_user_outlined,
                    color: const Color(0xFF4318FF),
                    title: 'Cleaned Data',
                    description: 'Extract of all verified low-risk projects that passed the initial AI screening (< 50).',
                    onTap: () {
                      _showSnack(context, 'Downloading Cleaned Data...');
                      ApiService.downloadReport('/reports/clean');
                    },
                  ),
                  _ReportCard(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFFF9800),
                    title: 'Anomaly Breakdown',
                    description: 'Focused dataset extracting projects flagged with critical and high risk scores (>= 75).',
                    onTap: () {
                      _showSnack(context, 'Downloading Anomaly Breakdown...');
                      ApiService.downloadReport('/reports/anomaly');
                    },
                  ),
                  _ReportCard(
                    icon: Icons.flag_outlined,
                    color: const Color(0xFFE53935),
                    title: 'Flagged Data',
                    description: 'Download projects flagged for review or requiring further investigation (>= 50).',
                    onTap: () {
                      _showSnack(context, 'Downloading Flagged Data...');
                      ApiService.downloadReport('/reports/flagged');
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3674), Color(0xFF4318FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Exports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Download comprehensive CSV reports and data extracts for your assigned regions. Keep your records up-to-date with real-time database snapshots.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF0B1F3A),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CSV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F9BBA),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2B3674),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA3AED0),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Download Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
