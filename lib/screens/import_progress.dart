import 'package:flutter/material.dart';

class ImportProgressScreen extends StatefulWidget {
  final String fileName;
  final bool isEmbedded;
  final VoidCallback? onBack;

  const ImportProgressScreen({
    super.key,
    required this.fileName,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<ImportProgressScreen> createState() => _ImportProgressScreenState();
}

class _ImportProgressScreenState extends State<ImportProgressScreen> {
  // Step 0: Uploaded, 1: Validated, 2: Importing, 3: AI Analysis, 4: Done
  int _currentStep = 2; 

  @override
  void initState() {
    super.initState();
    _simulateProgress();
  }

  void _simulateProgress() async {
    // Simulate progression through the steps
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _currentStep = 3);
    
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _currentStep = 4);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isEmbedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              children: [
                if (widget.onBack != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                ],
                const Text('Import Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
        Text('Importing data from ${widget.fileName}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 40),
        
        _buildProgressStep('File Uploaded', stepIndex: 0),
        _buildProgressLine(stepIndex: 0),
        
        _buildProgressStep('Data Validation', stepIndex: 1),
        _buildProgressLine(stepIndex: 1),
        
        _buildProgressStep('Importing Data', stepIndex: 2),
        _buildProgressLine(stepIndex: 2),
        
        _buildProgressStep('AI Analysis & Anomaly Detection', stepIndex: 3),
        _buildProgressLine(stepIndex: 3),
        
        _buildProgressStep('Completed', stepIndex: 4, isLast: true),
        
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _currentStep == 4
                ? () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/data-manager-dashboard', (r) => false);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6FED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Progress'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }

  Widget _buildProgressStep(String title, {required int stepIndex, bool isLast = false}) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;

    IconData icon;
    Color iconColor;
    Color circleColor;

    if (isCompleted) {
      icon = Icons.check;
      iconColor = Colors.white;
      circleColor = Colors.green;
    } else if (isActive) {
      icon = Icons.sync; // Use a spinner-like icon if we wanted, or just highlight
      iconColor = Colors.white;
      circleColor = const Color(0xFF2F6FED);
    } else {
      icon = Icons.circle;
      iconColor = Colors.grey.shade300;
      circleColor = Colors.white;
    }

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: !isCompleted && !isActive ? Border.all(color: Colors.grey.shade300, width: 2) : null,
          ),
          child: isActive
              ? const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Icon(icon, color: iconColor, size: isCompleted ? 18 : 12),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine({required int stepIndex}) {
    bool isCompleted = _currentStep > stepIndex;
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      height: 30,
      width: 2,
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }
}
