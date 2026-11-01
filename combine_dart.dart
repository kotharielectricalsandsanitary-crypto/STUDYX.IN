import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final currentDir = Directory.current.path;
  final libDir = Directory(p.join(currentDir, 'lib'));

  if (!libDir.existsSync()) {
    stdout.writeln('Error: Could not find a "lib" folder in this directory.');
    stdout.writeln('Make sure you are running this command from your project root.');
    return;
  }

  final dartFiles = <String>[];

  // 1. Recursively collect .dart files ONLY inside the lib folder
  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath = p.relative(entity.path, from: currentDir);

      // Filter out auto-generated code files if any exist (e.g. .g.dart, .freezed.dart)
      if (!relativePath.endsWith('.g.dart') &&
          !relativePath.endsWith('.freezed.dart')) {
        dartFiles.add(relativePath);
      }
    }
  });

  if (dartFiles.isEmpty) {
    stdout.writeln('No .dart files found in the "lib" folder.');
    return;
  }

  // Sort files alphabetically for clean presentation
  dartFiles.sort();

  // Track selection state for each file
  final selectedFlags = List<bool>.filled(dartFiles.length, false);

  // 2. Interactive Selection Menu
  while (true) {
    _clearScreen();
    stdout.writeln('=== Project Files (lib/ folder) ===\n');

    for (var i = 0; i < dartFiles.length; i++) {
      final mark = selectedFlags[i] ? '[x]' : '[ ]';
      stdout.writeln('${(i + 1).toString().padLeft(2)}. $mark ${dartFiles[i]}');
    }

    stdout.writeln('\n-----------------------------------');
    stdout.writeln('Commands:');
    stdout.writeln(' - Enter a number (e.g. 1) to toggle selection');
    stdout.writeln(' - Type "all" to select everything');
    stdout.writeln(' - Type "none" to unselect everything');
    stdout.writeln(' - Type "go" when finished');
    stdout.write('\nYour choice: ');

    final input = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase() ?? '';

    if (input == 'go') {
      break;
    } else if (input == 'all') {
      selectedFlags.fillRange(0, selectedFlags.length, true);
    } else if (input == 'none') {
      selectedFlags.fillRange(0, selectedFlags.length, false);
    } else {
      final index = int.tryParse(input);
      if (index != null && index >= 1 && index <= dartFiles.length) {
        selectedFlags[index - 1] = !selectedFlags[index - 1];
      }
    }
  }

  // Filter selected files
  final selectedFiles = <String>[];
  for (var i = 0; i < dartFiles.length; i++) {
    if (selectedFlags[i]) {
      selectedFiles.add(dartFiles[i]);
    }
  }

  if (selectedFiles.isEmpty) {
    stdout.writeln('\nNo files selected. Exiting.');
    return;
  }

  // 3. Ask for Output File Name
  stdout.write('\nEnter output Markdown filename [default: project_code.md]: ');
  var outputFile = stdin.readLineSync(encoding: utf8)?.trim() ?? '';
  if (outputFile.isEmpty) {
    outputFile = 'project_code.md';
  }

  // 4. Build Markdown Content
  final buffer = StringBuffer()..writeln('# Project Source Files (`lib/`)\n');

  for (final filePath in selectedFiles) {
    final fullPath = p.join(currentDir, filePath);
    final fileContent = File(fullPath).readAsStringSync();

    buffer
      ..writeln('## `$filePath`')
      ..writeln('```dart')
      ..writeln(fileContent)
      ..writeln('```\n');
  }

  // 5. Write Markdown Output
  File(outputFile).writeAsStringSync(buffer.toString());
  stdout.writeln(
    '\nSuccess! Wrote ${selectedFiles.length} file(s) to "$outputFile"',
  );
}

void _clearScreen() {
  if (Platform.isWindows) {
    stdout.write('\x1B[2J\x1B[0;0H');
  } else {
    stdout.write('\x1B[2J\x1B[H');
  }
}