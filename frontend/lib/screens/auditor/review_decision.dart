import 'package:flutter/material.dart';

import '../../models/investigation.dart';
import '../../services/api_service.dart';

/// Review Decision — investigation summary, evidence, findings,
/// approve/reject/escalate decision. Used by the Senior/Independent
/// Reviewer role.
class ReviewDecisionScreen extends StatefulWidget {
  final String investigationId;

  const ReviewDecisionScreen({super.key, required this.investigationId});

  @override
  State<ReviewDecisionScreen> createState() => _ReviewDecisionScreenState();
}

class _ReviewDecisionScreenState extends State<ReviewDecisionScreen> {
  late Future<Investigation> _investigationFuture;
  final _commentController = TextEditingController();
  String? _selectedDecision; // "Approve" | "Reject" | "Escalate"
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _investigationFuture = ApiService.fetchInvestigation(widget.investigationId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision() async {
    if (_selectedDecision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a decision')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.submitReviewDecision(
        investigationId: widget.investigationId,
        decision: _selectedDecision!,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decision "$_selectedDecision" recorded.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit decision: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Decision'),
        backgroundColor: isDesktop ? Colors.white : const Color(0xFF0B1F3A),
        foregroundColor: isDesktop ? const Color(0xFF0B1F3A) : Colors.white,
        elevation: isDesktop ? 1 : 4,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<Investigation>(
        future: _investigationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load case: ${snapshot.error}'));
          }

          final investigation = snapshot.data!;

          Widget formContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Investigation Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: isDesktop ? Colors.grey.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project: ${investigation.projectId}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Auditor: ${investigation.auditorName}'),
                      const SizedBox(height: 12),
                      const Text('Findings', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(investigation.findings),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Evidence (${investigation.evidenceFiles.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: investigation.evidenceFiles
                    .map((file) => Chip(
                          avatar: const Icon(Icons.insert_drive_file_outlined, size: 16),
                          label: Text(file, style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 32),
              const Text('Your Decision', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['Approve', 'Reject', 'Escalate'].map((decision) {
                  final selected = _selectedDecision == decision;
                  final color = decision == 'Approve'
                      ? Colors.green
                      : (decision == 'Reject' ? Colors.red : Colors.purple);
                  return ChoiceChip(
                    label: Text(decision, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    selected: selected,
                    selectedColor: color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? color : Colors.black87),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    onSelected: (_) => setState(() => _selectedDecision = decision),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Text('Comment', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add a review comment...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDecision,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Decision'),
                ),
              ),
            ],
          );

          return isDesktop
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: formContent,
                        ),
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: formContent,
                );
        },
      ),
    );
  }
}
