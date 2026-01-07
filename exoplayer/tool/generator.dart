import 'dart:io';

import 'package:jnigen/jnigen.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final packageRoot = Directory.current.path;

  // Read classpath from file
  final classpathFile = File(p.join(packageRoot, 'classpath_jars.txt'));
  if (!classpathFile.existsSync()) {
    print(
        'Error: classpath_jars.txt not found. Run dart tool/extract_jars.dart first.');
    exit(1);
  }

  final classPath = classpathFile
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => Uri.file(l.trim()))
      .toList();

  await generateJniBindings(
    Config(
      outputConfig: OutputConfig(
        dartConfig: DartCodeOutputConfig(
          path: Uri.directory(packageRoot)
              .resolve('lib/src/exoplayer_bindings.g.dart'),
          structure: OutputStructure.singleFile,
        ),
      ),
      classPath: classPath,
      androidSdkConfig: AndroidSdkConfig(
        addGradleDeps: false,
        addGradleSources: false,
        versions: [34],
        sdkRoot: '/Users/aliammar/Library/Android/sdk',
      ),
      classes: [
        'androidx.media3.exoplayer.ExoPlayer',
        'androidx.media3.common.MediaItem',
        'androidx.media3.common.Player',
        'androidx.media3.common.Timeline',
        'androidx.media3.common.Tracks',
        'androidx.media3.common.VideoSize',
        'androidx.media3.common.DeviceInfo',
        'androidx.media3.common.MediaMetadata',
        'androidx.media3.common.PlaybackException',
        'androidx.media3.common.PlaybackParameters',
        'androidx.media3.common.AudioAttributes',
        // Add more classes as needed
      ],
      preamble: '// Generated bindings for ExoPlayer',
    ),
  );
}
