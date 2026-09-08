import 'dart:io';

void main() {
  final file = File('lib/routes/app_routes.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains('/data-quality')) {
    content = content.replaceFirst("import '../screens/upload_history.dart';", "import '../screens/upload_history.dart';\nimport '../screens/data_quality.dart';");
    content = content.replaceFirst("static const String uploadHistory = '/upload-history';", "static const String uploadHistory = '/upload-history';\n  static const String dataQuality = '/data-quality';");
    content = content.replaceFirst("uploadHistory: (context) => const UploadHistoryScreen(),", "uploadHistory: (context) => const UploadHistoryScreen(),\n    dataQuality: (context) => const DataQualityScreen(),");
    file.writeAsStringSync(content);
  }

  final shellFile = File('lib/widgets/app_shell.dart');
  String shellContent = shellFile.readAsStringSync();
  if (!shellContent.contains("case 2:")) {
    final oldCases = '''    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.role == 'Data Manager' ? '/data-manager-dashboard' : '/auditor-dashboard',
          (r) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushNamed(
          widget.role == 'Data Manager' ? '/upload-project' : '/risk-projects',
        );
        break;
    }''';

    final newCases = '''    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.role == 'Data Manager' ? '/data-manager-dashboard' : '/auditor-dashboard',
          (r) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushNamed(
          widget.role == 'Data Manager' ? '/upload-project' : '/risk-projects',
        );
        break;
      case 2:
        if (widget.role == 'Data Manager') {
          Navigator.of(context).pushNamed('/data-quality');
        }
        break;
    }''';
    shellContent = shellContent.replaceFirst(oldCases, newCases);
    shellFile.writeAsStringSync(shellContent);
  }
}
