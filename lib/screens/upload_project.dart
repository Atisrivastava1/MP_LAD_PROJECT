import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'project_data_validation.dart';
import 'import_progress.dart';
import '../widgets/app_shell.dart';

class UploadProjectScreen extends StatefulWidget {
  const UploadProjectScreen({super.key});

  @override
  State<UploadProjectScreen> createState() => _UploadProjectScreenState();
}

class _UploadProjectScreenState extends State<UploadProjectScreen> {
  String? _pickedFileName;
  bool _isUploading = false;
  final TextEditingController _validityDaysCtrl = TextEditingController(text: '30');

  // Desktop flow state: 0 = Upload, 1 = Validation, 2 = Progress
  int _desktopStep = 0;

  @override
  void dispose() {
    _validityDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // Mock file picking
    setState(() => _pickedFileName = 'mplads_batch_may.csv');
  }

  Future<void> _submitUpload() async {
    if (_pickedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final success = await ApiService.uploadProjectFile(_pickedFileName!);
      if (!mounted) return;
      if (success) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        if (isDesktop) {
          setState(() => _desktopStep = 1);
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProjectDataValidationScreen(
              fileName: _pickedFileName!,
              validityDays: int.tryParse(_validityDaysCtrl.text) ?? 30,
            ),
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onValidationComplete() {
    setState(() => _desktopStep = 2);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    Widget body;
    if (isDesktop) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Stepper
          Container(
            width: 300,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Import Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildDesktopStepIndicator('1. Upload Data', isActive: _desktopStep == 0, isDone: _desktopStep > 0),
                _buildDesktopStepLine(),
                _buildDesktopStepIndicator('2. Validation', isActive: _desktopStep == 1, isDone: _desktopStep > 1),
                _buildDesktopStepLine(),
                _buildDesktopStepIndicator('3. Progress', isActive: _desktopStep == 2, isDone: _desktopStep > 2),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Right Panel: Active Step Content
          Expanded(
            child: _buildDesktopStepContent(),
          ),
        ],
      );
    } else {
      // Mobile layout
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a CSV or Excel file to upload.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supported formats: .csv, .xlsx',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 24),
            
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Icon(
                      _pickedFileName != null ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _pickedFileName != null ? const Color(0xFF2F6FED) : Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _pickedFileName ?? 'Tap to select a file',
                      style: TextStyle(
                        fontWeight: _pickedFileName != null ? FontWeight.bold : FontWeight.normal,
                        color: _pickedFileName != null ? const Color(0xFF2F6FED) : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('Update Validity Days', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
            const SizedBox(height: 8),
            const Text(
              'How many days until the next project update is due?',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _validityDaysCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'e.g. 30',
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6FED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Upload & Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return AppShell(
      title: 'Upload Data',
      selectedIndex: 1,
      body: body,
    );
  }

  Widget _buildDesktopStepIndicator(String title, {required bool isActive, required bool isDone}) {
    Color color = Colors.grey.shade400;
    if (isActive) color = const Color(0xFF2F6FED);
    if (isDone) color = Colors.green;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? Colors.green : (isActive ? const Color(0xFF2F6FED) : Colors.white),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    title.split('.')[0],
                    style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.black54)),
      ],
    );
  }

  Widget _buildDesktopStepLine() {
    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      height: 40,
      width: 2,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildDesktopStepContent() {
    if (_desktopStep == 0) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upload New Data', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Select a CSV or Excel file to upload. Supported formats: .csv, .xlsx'),
                  const SizedBox(height: 32),
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFileName != null ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                            size: 64,
                            color: _pickedFileName != null ? const Color(0xFF2F6FED) : Colors.blueGrey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pickedFileName ?? 'Drag & drop your CSV or Excel file here',
                            style: TextStyle(
                              fontWeight: _pickedFileName != null ? FontWeight.bold : FontWeight.normal,
                              color: _pickedFileName != null ? const Color(0xFF2F6FED) : Colors.black54,
                            ),
                          ),
                          if (_pickedFileName == null) ...[
                            const SizedBox(height: 8),
                            const Text('or click to browse files', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F6FED))),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Update Validity Days', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B1F3A))),
                  const SizedBox(height: 8),
                  const Text(
                    'How many days until the next project update is due?',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _validityDaysCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6FED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isUploading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Upload & Validate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (_desktopStep == 1) {
      // Embed validation screen inside desktop layout without an app bar
      return ProjectDataValidationScreen(
        fileName: _pickedFileName!,
        validityDays: int.tryParse(_validityDaysCtrl.text) ?? 30,
        isEmbedded: true,
        onValidationComplete: _onValidationComplete,
        onBack: () => setState(() => _desktopStep = 0),
      );
    } else {
      // Embed progress screen inside desktop layout
      return ImportProgressScreen(
        fileName: _pickedFileName!,
        isEmbedded: true,
        onBack: () => setState(() => _desktopStep = 1),
      );
    }
  }
}
