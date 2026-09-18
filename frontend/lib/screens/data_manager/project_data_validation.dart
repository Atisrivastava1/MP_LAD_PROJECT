import 'package:flutter/material.dart';
import 'import_progress.dart';

class ProjectDataValidationScreen extends StatefulWidget {
  final String fileName;
  final int validityDays;
  final Map<String, dynamic> uploadResult;
  final bool isEmbedded;
  final Function(List<String>)? onValidationComplete;
  final VoidCallback? onBack;

  const ProjectDataValidationScreen({
    super.key,
    required this.fileName,
    required this.validityDays,
    required this.uploadResult,
    this.isEmbedded = false,
    this.onValidationComplete,
    this.onBack,
  });

  @override
  State<ProjectDataValidationScreen> createState() => _ProjectDataValidationScreenState();
}

class _ProjectDataValidationScreenState extends State<ProjectDataValidationScreen> {
  bool _isSubmitting = false;

  List<dynamic> get _results => widget.uploadResult['results'] ?? [];
  int get _errorCount => widget.uploadResult['errors'] ?? 0;
  int get _validCount => (widget.uploadResult['created'] ?? 0) + (widget.uploadResult['updated'] ?? 0);
  int get _totalRows => widget.uploadResult['total_rows'] ?? 0;

  Future<void> _startImport() async {
    setState(() => _isSubmitting = true);

    // Mock API call to send validated data
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final List<String> workIds = _results
        .where((r) => r['status'] == 'created' || r['status'] == 'updated')
        .map((r) => r['work_id'] as String)
        .toList();
        
    if (widget.isEmbedded && widget.onValidationComplete != null) {
      widget.onValidationComplete!(workIds);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ImportProgressScreen(
          fileName: widget.fileName,
          workIds: workIds,
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Total Rows', _totalRows.toString(), Colors.blue),
            _buildStatColumn('Valid', _validCount.toString(), Colors.green),
            _buildStatColumn('Invalid', _errorCount.toString(), Colors.red),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Validated Rows', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // List of Rows
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = _results[index];
              final hasError = row['status'] == 'error';
              final statusText = hasError ? 'Failed: ${row['reason'] ?? 'Unknown'}' : 'Passed (${row['status']})';
              final description = row['description']?.toString() ?? '(missing)';
              final amount = row['recommended_amount'] != null ? '₹${row['recommended_amount']}' : 'N/A';
              
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: hasError ? Colors.red.shade200 : Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Work ID: ${row['work_id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: hasError ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Description: $description'),
                      Text('Recommended Amount: $amount'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _startImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6FED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Start Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.onBack != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                ],
                const Text('Validation & Preview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation & Preview'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
