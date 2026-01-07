import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

void main() {
  final classpathFile = File('classpath.txt');
  if (!classpathFile.existsSync()) {
    print('classpath.txt not found');
    exit(1);
  }

  final lines = classpathFile
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .toList();
  final libsDir = Directory('libs');
  if (!libsDir.existsSync()) {
    libsDir.createSync();
  }

  final newClasspath = <String>[];

  for (final line in lines) {
    final path = line.trim();
    if (path.endsWith('.aar')) {
      final name = p.basenameWithoutExtension(path);
      final destJar = p.join(libsDir.path, '$name.jar');
      print('Extracting $name.aar to $destJar');

      // Extract classes.jar from AAR
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? classesJar;
      for (final file in archive.files) {
        if (file.name == 'classes.jar') {
          classesJar = file;
          break;
        }
      }

      if (classesJar != null) {
        final outputStream = OutputFileStream(destJar);
        classesJar.writeContent(outputStream);
        outputStream.close();
        newClasspath.add(File(destJar).absolute.path);
      } else {
        print('Warning: classes.jar not found in $path');
      }
    } else {
      // It's a jar, just copy it or use it. We'll copy to be clean.
      final name = p.basename(path);
      final destJar = p.join(libsDir.path, name);
      File(path).copySync(destJar);
      newClasspath.add(File(destJar).absolute.path);
    }
  }

  File('classpath_jars.txt').writeAsStringSync(newClasspath.join('\n'));
  print('Done. Created classpath_jars.txt');
}
