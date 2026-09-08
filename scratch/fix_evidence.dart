import 'dart:io';

void main() {
  final file = File('lib/screens/evidence_upload.dart');
  String content = file.readAsStringSync();
  
  // 1. Add profile_header.dart import
  if (!content.contains('profile_header.dart')) {
    content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../widgets/profile_header.dart';");
  }

  // 2. Refactor build method
  final buildRegex = RegExp(r'@override\s+Widget build\(BuildContext context\) \{.*?\n  \}', dotAll: true);
  
  final newBuild = '''@override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Upload'),
        backgroundColor: isDesktop ? Colors.white : const Color(0xFF0B1F3A),
        foregroundColor: isDesktop ? const Color(0xFF0B1F3A) : Colors.white,
        elevation: isDesktop ? 1 : 4,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_files.map((f) => f.fileName).toList());
            },
            child: Text('Done', style: TextStyle(color: isDesktop ? const Color(0xFF0B1F3A) : Colors.white, fontWeight: FontWeight.bold)),
          ),
          ...buildProfileAppBarActions(context),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }''';

  content = content.replaceFirst(buildRegex, newBuild);

  // 3. Add desktop and mobile layouts
  if (!content.contains('_buildMobileLayout')) {
    content = content.replaceFirst('class _EvidenceItem {', '''
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUploadForm(),
        const SizedBox(height: 24),
        Expanded(child: _buildEvidenceList()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Upload photos from the site visit.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildUploadForm(isPhoto: true),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Documents & GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Upload official documents and tag GPS location.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildUploadForm(isPhoto: false),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('GPS Location captured:\\nLat: 23.2599, Lng: 77.4126', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Uploaded Files ()', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(child: _buildEvidenceList()),
            ],
          ),
        ),
      ],
    );
  }

class _EvidenceItem {''');
  }

  // 4. Update form signature
  content = content.replaceAll('Widget _buildUploadForm() {', 'Widget _buildUploadForm({bool isPhoto = false}) {');
  content = content.replaceAll("icon: const Icon(Icons.upload_file),", "icon: Icon(isPhoto ? Icons.add_a_photo : Icons.upload_file),");
  content = content.replaceAll("label: const Text('Upload Document'),", "label: Text(isPhoto ? 'Upload Photo' : 'Upload Document'),");

  file.writeAsStringSync(content);
}
