import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('login') || file.path.contains('dashboard') || file.path.contains('app_shell')) {
      continue;
    }
    
    String content = file.readAsStringSync();
    if (content.contains('buildProfileAppBarActions(context)')) continue;

    if (!content.contains("import '../widgets/profile_header.dart';")) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../widgets/profile_header.dart';");
    }

    content = content.replaceAll('AppBar(title:', 'AppBar(actions: buildProfileAppBarActions(context), title:');
    content = content.replaceAll('AppBar(\n        title:', 'AppBar(\n        actions: buildProfileAppBarActions(context),\n        title:');

    file.writeAsStringSync(content);
    print('Updated ${file.path}');
  }
}
