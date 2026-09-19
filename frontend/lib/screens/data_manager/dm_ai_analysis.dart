import 'package:flutter/material.dart';
import '../../models/project.dart';

class DmAiAnalysisScreen extends StatelessWidget {
  final Project project;
  final bool isEmbedded;

  const DmAiAnalysisScreen({super.key, required this.project, this.isEmbedded = false});

  Color _getRiskColor(String level) {
    switch (level) {
      case 'Critical': return const Color(0xFFE53935);
      case 'High': return Colors.orange;
      case 'Medium': return Colors.amber;
      default: return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFlagged = project.effectiveRiskScore >= 50;
    final Color riskColor = _getRiskColor(project.riskLevel);
    
    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEmbedded)
            const Text('AI Analysis Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0B1F3A))),
          if (isEmbedded) const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor),
            ),
            child: Row(
              children: [
                Icon(
                  isFlagged ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: riskColor,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ML Anomaly Prediction', style: TextStyle(color: Colors.black54, fontSize: 14)),
                      Text(
                        'Risk Score: ${project.effectiveRiskScore}/100',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: riskColor),
                      ),
                      Text(
                        isFlagged ? 'Anomalies Detected (${project.riskLevel} Risk)' : 'Passed / No Anomalies Detected',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: riskColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (isFlagged) ...[
            const SizedBox(height: 32),
            const Text('Detected Anomalies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B1F3A))),
            const SizedBox(height: 16),
            ...project.effectiveRiskTags.map((tag) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: riskColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tag, style: const TextStyle(fontSize: 15, color: Colors.black87))),
                ],
              ),
            )),
          ],
        ],
      ),
    );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Analysis'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: content,
    );
  }
}
