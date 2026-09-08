import 'dart:io';

void main() {
  // Fix risk_analysis.dart
  final raFile = File('lib/screens/risk_analysis.dart');
  String raContent = raFile.readAsStringSync();
  
  if (!raContent.contains('final isDesktop = MediaQuery.of(context).size.width >= 900;')) {
    raContent = raContent.replaceFirst(
      'Widget content = isDesktop',
      'final isDesktop = MediaQuery.of(context).size.width >= 900;\n          Widget content = isDesktop'
    );
  }
  
  if (!raContent.contains('}\n\nclass _AnalysisData')) {
    raContent = raContent.replaceFirst(
      '    );\n}\n\nclass _AnalysisData',
      '    );\n  }\n}\n\nclass _AnalysisData'
    );
  } else {
    // try replacing exact end of _buildAnomaliesList
    raContent = raContent.replaceFirst(
      '    );\n}\n\nclass _AnalysisData',
      '    );\n  }\n}\n\nclass _AnalysisData'
    );
    if (!raContent.contains('  }\n}\n\nclass _AnalysisData')) {
       // Just append it correctly
       raContent = raContent.replaceFirst('    );\n}\n\nclass _AnalysisData', '    );\n  }\n}\n\nclass _AnalysisData');
    }
  }
  raFile.writeAsStringSync(raContent);

  // Fix risk_project_list.dart
  final rplFile = File('lib/screens/risk_project_list.dart');
  String rplContent = rplFile.readAsStringSync();
  rplContent = rplContent.replaceAll(', isDesktopPanel: true', '');
  rplFile.writeAsStringSync(rplContent);
}
