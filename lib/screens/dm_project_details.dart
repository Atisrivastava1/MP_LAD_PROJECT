import 'package:flutter/material.dart';
import '../models/project.dart';
import 'dm_ai_analysis.dart';

class DmProjectDetailsScreen extends StatelessWidget {
  final Project project;
  final bool isEmbedded;

  const DmProjectDetailsScreen({super.key, required this.project, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmbedded)
            const Text('Project Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0B1F3A))),
          if (isEmbedded) const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Work ID', project.id),
                const Divider(height: 24),
                _buildDetailRow('Project Name', project.name),
                const Divider(height: 24),
                _buildDetailRow('Location', project.location),
                const Divider(height: 24),
                _buildDetailRow('Status', project.status),
                const Divider(height: 24),
                _buildDetailRow('Estimated Cost', '₹${project.estimatedCost}'),
                const Divider(height: 24),
                _buildDetailRow('Start Date', project.startDate.toString().split(' ')[0]),
                const Divider(height: 24),
                _buildDetailRow('Risk Score', '${project.riskScore}/100'),
                const Divider(height: 24),
                _buildDetailRow('Last Updated', project.lastUpdated),
              ],
            ),
          ),
          
          if (!isEmbedded) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DmAiAnalysisScreen(project: project),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6FED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View AI Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: content,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0B1F3A)))),
      ],
    );
  }
}
