# ExoPlayer JNI Bindings

This package provides JNI bindings for ExoPlayer (androidx.media3).

## Generating Bindings

Prerequisites:
- Flutter/Dart SDK
- Maven (`mvn`) installed (required by jnigen)
- Android SDK

To generate the bindings:

1. Navigate to this directory.
2. Run `dart pub get`.
3. Run `dart tool/generator.dart`.

This will generate `lib/src/exoplayer_bindings.g.dart`.

## Usage

Import the package and use the generated classes.
