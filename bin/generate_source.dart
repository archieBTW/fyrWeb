import 'dart:io';
import 'dart:convert';

void main() {
  final libDir = Directory('lib');
  final Map<String, String> filesMap = {};

  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'));

  for (final file in files) {
    // Normalize path to use forward slashes
    final path = file.path.replaceAll('\\', '/');
    final content = file.readAsStringSync();
    filesMap[path] = content;
  }

  final generatedDir = Directory('lib/generated');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync();
  }

  final outputFile = File('lib/generated/source_code.dart');
  
  // Create a clean dart file with a const map
  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ignore_for_file: constant_identifier_names');
  buffer.writeln('');
  buffer.writeln('const Map<String, String> sourceCodeFiles = {');
  
  filesMap.forEach((path, content) {
    // Escape string correctly
    final escapedContent = jsonEncode(content).replaceAll(r'$', r'\$');
    buffer.writeln('  "$path": $escapedContent,');
  });
  
  buffer.writeln('};');

  outputFile.writeAsStringSync(buffer.toString());
  print('Source code generated at ${outputFile.path}');
}
