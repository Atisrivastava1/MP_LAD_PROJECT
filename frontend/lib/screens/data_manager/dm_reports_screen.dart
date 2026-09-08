import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reports & Exports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0B1F3A))),
          const SizedBox(height: 32),
          
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: MediaQuery.of(context).size.width >= 900 ? 3.5 : 2.5,
            children: [
              _ReportCard(
                icon: Icons.map_outlined,
                color: Colors.green,
                title: 'Overall Status Report',
                onTap: () => _showSnack(context, 'Generating Overall Status Report...'),
              ),
              _ReportCard(
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                title: 'Anomaly Breakdown',
                onTap: () => _showSnack(context, 'Generating Anomaly Breakdown...'),
              ),
              _ReportCard(
                icon: Icons.download_outlined,
                color: const Color(0xFF2F6FED),
                title: 'Export Cleaned Data',
                onTap: () => _showSnack(context, 'Exporting Cleaned Data...'),
              ),
              _ReportCard(
                icon: Icons.file_download_outlined,
                color: Colors.red,
                title: 'Export Flagged Data',
                onTap: () => _showSnack(context, 'Exporting Flagged Data...'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _ReportCard({required this.icon, required this.color, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1F3A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
