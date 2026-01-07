# ExoPlayer JNI Bindings

This package provides direct JNI bindings for the Android ExoPlayer library, allowing you to control ExoPlayer directly from Dart in your Flutter application.

It bypasses the need for manual MethodChannels by using `package:jni` to call Android APIs directly.

## Features

- **Direct API Access**: interact with `ExoPlayer`, `MediaItem`, `Player` and more directly from Dart.
- **Zero Boilerplate**: No need to write Java/Kotlin wrappers for every method you want to use.
- **Performance**: High-performance JNI calls.

## Project Structure

- **`lib/`**: Contains the generated Dart bindings (`exoplayer_bindings.g.dart`).
- **`example/`**: A complete Flutter example app demonstrating:
    - Video playback with a `Texture` widget.
    - DASH streaming.
    - DRM (Widevine) configuration.
- **`tool/`**: Scripts and configuration for generating the bindings using `jnigen`.

## Getting Started

Check out the [example app](example/README.md) to see it in action.

```bash
cd example
flutter run
```

## Regenerating Bindings

If you need to update the ExoPlayer version or expose new classes:

1. Update `classpath.txt` with the new paths if necessary.
2. Run the generator script:

```bash
dart run tool/generator.dart
```
