import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'project_data_validation.dart';
import 'import_progress.dart';
import '../../widgets/app_shell.dart';

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
  Map<String, dynamic>? _uploadResult;
  List<String> _workIds = [];

  @override
  void dispose() {
    _validityDaysCtrl.dispose();
    super.dispose();
  }

  String? _pickedFilePath;
  Uint8List? _pickedFileBytes;

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (files.isNotEmpty) {
        final bytes = await files.single.readAsBytes();
        setState(() {
          _pickedFileName = files.single.name;
          _pickedFilePath = files.single.path;
          _pickedFileBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _submitUpload() async {
    if (_pickedFilePath == null && _pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      Map<String, dynamic>? uploadResult;
      int vDays = int.tryParse(_validityDaysCtrl.text) ?? 30;
      if (kIsWeb && _pickedFileBytes != null) {
        uploadResult = await ApiService.uploadProjectFileWeb(_pickedFileBytes!, _pickedFileName!, vDays);
      } else if (_pickedFilePath != null) {
        uploadResult = await ApiService.uploadProjectFile(_pickedFilePath!, vDays);
      }
      if (!mounted) return;
      if (uploadResult != null) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        if (isDesktop) {
          setState(() {
            _uploadResult = uploadResult;
            _desktopStep = 1;
          });
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProjectDataValidationScreen(
              fileName: _pickedFileName!,
              validityDays: int.tryParse(_validityDaysCtrl.text) ?? 30,
              uploadResult: uploadResult!,
            ),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onValidationComplete(List<String> workIds) {
    setState(() {
      _workIds = workIds;
      _desktopStep = 2;
    });
  }

  Widget _buildGuidelinesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Text('Smart Upsert Guidelines', style: TextStyle(color: Colors.blue.shade800, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuidelineItem('Unique Anchor', 'The system uses the "work_id" column to uniquely identify projects.'),
          _buildGuidelineItem('New Projects', 'If the "work_id" is new, a brand new project record is created automatically.'),
          _buildGuidelineItem('Existing Projects', 'If the "work_id" already exists, the project is updated with the new values. A snapshot of the old data is securely stored in history.'),
          _buildGuidelineItem('Multiple Uploads', "Upload as often as needed. Duplicates won't be created as long as \"work_id\" matches."),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Colors.blue.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStepIndicator(String title, {required bool isActive, required bool isDone}) {
    Color color = Colors.grey.shade300;
    if (isActive) color = const Color(0xFF4318FF);
    if (isDone) color = const Color(0xFF01B574);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF01B574) : (isActive ? const Color(0xFF4318FF) : Colors.white),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: const Color(0xFF4318FF).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : [],
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    title.split('.')[0],
                    style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Text(title, style: TextStyle(
          fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFF2B3674) : Colors.grey.shade500,
          fontSize: 15,
        )),
      ],
    );
  }

  Widget _buildDesktopStepLine() {
    return Container(
      margin: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
      height: 40,
      width: 2,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildDesktopStepContent() {
    if (_desktopStep == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Project Data', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2B3674))),
              const SizedBox(height: 8),
              const Text('Select a CSV or Excel file to begin the import process.', style: TextStyle(fontSize: 15, color: Colors.black54)),
              const SizedBox(height: 32),
              
              _buildGuidelinesCard(),
              const SizedBox(height: 40),
              
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    color: _pickedFileName != null ? const Color(0xFF4318FF).withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedFileName != null ? const Color(0xFF4318FF) : Colors.grey.shade300, 
                      width: 2, 
                      style: BorderStyle.solid
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _pickedFileName != null ? const Color(0xFF4318FF).withOpacity(0.1) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, spreadRadius: 2)],
                        ),
                        child: Icon(
                          _pickedFileName != null ? Icons.description_rounded : Icons.cloud_upload_rounded,
                          size: 48,
                          color: _pickedFileName != null ? const Color(0xFF4318FF) : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _pickedFileName ?? 'Drag & drop your file here',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _pickedFileName != null ? FontWeight.w700 : FontWeight.w600,
                          color: _pickedFileName != null ? const Color(0xFF4318FF) : const Color(0xFF2B3674),
                        ),
                      ),
                      if (_pickedFileName == null) ...[
                        const SizedBox(height: 8),
                        const Text('or click to browse from your computer', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              const Text('Update Validity Period', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B3674))),
              const SizedBox(height: 8),
              const Text(
                'Specify the number of days until the next project update is due.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _validityDaysCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4318FF), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixText: 'Days',
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Proceed to Validation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ));
    } else if (_desktopStep == 1) {
      return ProjectDataValidationScreen(
        uploadResult: _uploadResult ?? {},
        fileName: _pickedFileName!,
        validityDays: int.tryParse(_validityDaysCtrl.text) ?? 30,
        isEmbedded: true,
        onValidationComplete: _onValidationComplete,
        onBack: () => setState(() => _desktopStep = 0),
      );
    } else {
      return ImportProgressScreen(
        workIds: _workIds,
        fileName: _pickedFileName!,
        isEmbedded: true,
        onBack: () => setState(() => _desktopStep = 1),
      );
    }
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
            width: 320,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Import Flow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2B3674))),
                const SizedBox(height: 40),
                _buildDesktopStepIndicator('1. Upload Data', isActive: _desktopStep == 0, isDone: _desktopStep > 0),
                _buildDesktopStepLine(),
                _buildDesktopStepIndicator('2. Validation', isActive: _desktopStep == 1, isDone: _desktopStep > 1),
                _buildDesktopStepLine(),
                _buildDesktopStepIndicator('3. Progress', isActive: _desktopStep == 2, isDone: _desktopStep > 2),
              ],
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
          // Right Panel: Active Step Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildDesktopStepContent()
            ),
          ),
        ],
      );
    } else {
      // Mobile layout
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Project Data', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2B3674))),
            const SizedBox(height: 8),
            const Text('Select a CSV or Excel file to begin.', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            
            _buildGuidelinesCard(),
            const SizedBox(height: 32),

            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: _pickedFileName != null ? const Color(0xFF4318FF).withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedFileName != null ? const Color(0xFF4318FF) : Colors.grey.shade300, 
                    width: 2, 
                    style: BorderStyle.solid
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _pickedFileName != null ? const Color(0xFF4318FF).withOpacity(0.1) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: Icon(
                        _pickedFileName != null ? Icons.description_rounded : Icons.cloud_upload_rounded,
                        size: 40,
                        color: _pickedFileName != null ? const Color(0xFF4318FF) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pickedFileName ?? 'Tap to select file',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _pickedFileName != null ? FontWeight.w700 : FontWeight.w600,
                        color: _pickedFileName != null ? const Color(0xFF4318FF) : const Color(0xFF2B3674),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Update Validity Period', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2B3674))),
            const SizedBox(height: 8),
            const Text(
              'Specify days until next update.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _validityDaysCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4318FF), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixText: 'Days',
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4318FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Proceed to Validation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
}
