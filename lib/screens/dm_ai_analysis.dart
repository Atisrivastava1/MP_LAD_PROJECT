import 'package:flutter/material.dart';
import '../models/project.dart';

class DmAiAnalysisScreen extends StatelessWidget {
  final Project project;
  final bool isEmbedded;

  const DmAiAnalysisScreen({super.key, required this.project, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final bool isFlagged = project.riskScore > 50;
    
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
              color: isFlagged ? const Color(0xFFE53935).withValues(alpha: 0.05) : const Color(0xFF43A047).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isFlagged ? const Color(0xFFE53935) : const Color(0xFF43A047)),
            ),
            child: Row(
              children: [
                Icon(
                  isFlagged ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: isFlagged ? const Color(0xFFE53935) : const Color(0xFF43A047),
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ML Anomaly Prediction', style: TextStyle(color: Colors.black54, fontSize: 14)),
                      Text(
                        'Risk Score: ${project.riskScore}/100',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isFlagged ? const Color(0xFFE53935) : const Color(0xFF43A047)),
                      ),
                      Text(
                        isFlagged ? 'Anomalies Detected' : 'Passed / No Anomalies Detected',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isFlagged ? const Color(0xFFE53935) : const Color(0xFF43A047)),
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
            ...project.riskTags.map((tag) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFFE53935)),
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
