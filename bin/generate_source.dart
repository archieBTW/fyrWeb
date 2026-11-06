import 'dart:io';
import 'dart:convert';

void main() {
  final libDir = Directory('lib');
  final Map<String, String> filesMap = {};

  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'));

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    final rawContent = file.readAsStringSync();
    filesMap[path] = stripCommentedCode(rawContent, path);
  }

  // Also include key WE-IAC DevOps and Infrastructure configs
  final iacFiles = [
    'terraform/main.tf',
    'terraform/cloudflare.tf',
    'ansible/deploy-sites.yml',
    'ansible/roles/nginx/templates/site.conf.j2',
    'ansible/roles/bybl_backend/templates/docker-compose.yml.j2',
    'scripts/deploy_all.sh',
  ];
  for (final rel in iacFiles) {
    final f = File('../WE-IAC/$rel');
    if (f.existsSync()) {
      final rawContent = f.readAsStringSync();
      filesMap['infra/$rel'] = stripCommentedCode(rawContent, rel);
    }
  }

  final generatedDir = Directory('lib/generated');
  if (!generatedDir.existsSync()) {
    generatedDir.createSync();
  }

  final outputFile = File('lib/generated/source_code.dart');

  final buffer = StringBuffer();
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ignore_for_file: constant_identifier_names');
  buffer.writeln('');
  buffer.writeln('const Map<String, String> sourceCodeFiles = {');

  filesMap.forEach((path, content) {
    final escapedContent = jsonEncode(content).replaceAll(r'$', r'\$');
    buffer.writeln('  "$path": $escapedContent,');
  });

  buffer.writeln('};');

  outputFile.writeAsStringSync(buffer.toString());
  print('Source code generated cleanly at ${outputFile.path} (commented code stripped).');
}

/// Strips all comments and commented-out code from [input] based on file type
/// while safely preserving string literals, URLs, and formatting.
String stripCommentedCode(String input, String path) {
  final ext = path.split('.').last.toLowerCase();
  final isDartOrTf = ext == 'dart' || ext == 'tf';
  final isHashComment = ext == 'yml' ||
      ext == 'yaml' ||
      ext == 'sh' ||
      ext == 'conf' ||
      ext == 'j2' ||
      ext == 'tf';

  final buffer = StringBuffer();
  final len = input.length;
  int i = 0;

  while (i < len) {
    // Check raw string prefix (r' or r") in Dart
    if (isDartOrTf &&
        input[i] == 'r' &&
        i + 1 < len &&
        (input[i + 1] == "'" || input[i + 1] == '"')) {
      final quote = input[i + 1];
      final isTriple =
          i + 3 < len && input[i + 2] == quote && input[i + 3] == quote;
      buffer.write(input[i]);
      i++;
      if (isTriple) {
        final delim = quote * 3;
        buffer.write(delim);
        i += 3;
        while (i < len) {
          if (input.startsWith(delim, i)) {
            buffer.write(delim);
            i += 3;
            break;
          }
          buffer.write(input[i]);
          i++;
        }
      } else {
        buffer.write(quote);
        i++;
        while (i < len) {
          if (input[i] == quote) {
            buffer.write(quote);
            i++;
            break;
          }
          buffer.write(input[i]);
          i++;
        }
      }
      continue;
    }

    // Check standard strings ('...' or "...")
    if (input[i] == "'" || input[i] == '"') {
      final quote = input[i];
      final isTriple = isDartOrTf &&
          i + 2 < len &&
          input[i + 1] == quote &&
          input[i + 2] == quote;
      if (isTriple) {
        final delim = quote * 3;
        buffer.write(delim);
        i += 3;
        while (i < len) {
          if (input[i] == r'\' && i + 1 < len) {
            buffer.write(input[i]);
            buffer.write(input[i + 1]);
            i += 2;
            continue;
          }
          if (input.startsWith(delim, i)) {
            buffer.write(delim);
            i += 3;
            break;
          }
          buffer.write(input[i]);
          i++;
        }
      } else {
        buffer.write(quote);
        i++;
        while (i < len) {
          if (input[i] == r'\' && i + 1 < len) {
            buffer.write(input[i]);
            buffer.write(input[i + 1]);
            i += 2;
            continue;
          }
          if (input[i] == quote) {
            buffer.write(quote);
            i++;
            break;
          }
          buffer.write(input[i]);
          i++;
        }
      }
      continue;
    }

    // Check single-line // comment
    if (isDartOrTf && input[i] == '/' && i + 1 < len && input[i + 1] == '/') {
      i += 2;
      while (i < len && input[i] != '\n') {
        i++;
      }
      continue;
    }

    // Check multi-line /* ... */ comment
    if (isDartOrTf && input[i] == '/' && i + 1 < len && input[i + 1] == '*') {
      i += 2;
      while (i < len) {
        if (input[i] == '*' && i + 1 < len && input[i + 1] == '/') {
          i += 2;
          break;
        }
        i++;
      }
      continue;
    }

    // Check hash # comment for YAML, shell, nginx, tf
    if (isHashComment && input[i] == '#') {
      i++;
      while (i < len && input[i] != '\n') {
        i++;
      }
      continue;
    }

    buffer.write(input[i]);
    i++;
  }

  // Post-process to collapse empty lines from stripped comments
  final rawOutput = buffer.toString();
  final lines = rawOutput.split('\n');
  final cleanedLines = <String>[];
  bool prevBlank = false;

  for (final line in lines) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      if (!prevBlank && cleanedLines.isNotEmpty) {
        cleanedLines.add('');
        prevBlank = true;
      }
    } else {
      cleanedLines.add(trimmed);
      prevBlank = false;
    }
  }

  while (cleanedLines.isNotEmpty && cleanedLines.first.isEmpty) {
    cleanedLines.removeAt(0);
  }
  while (cleanedLines.isNotEmpty && cleanedLines.last.isEmpty) {
    cleanedLines.removeLast();
  }

  return cleanedLines.join('\n');
}
