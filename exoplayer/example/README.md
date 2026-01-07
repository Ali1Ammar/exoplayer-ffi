# ExoPlayer JNI Example

This example demonstrates how to use `package:jni` to integrate Android's ExoPlayer directly into a Flutter application without writing any Java/Kotlin platform channel code.

It showcases:
- **Direct JNI Integration**: initializing `ExoPlayer` from Dart.
- **Surface Texture Rendering**: passing a Flutter `SurfaceTexture` to ExoPlayer for video rendering.
- **DRM Support**: Configuring Widevine DRM for protected content playback.
- **DASH Playback**: playing adaptive streaming content.

## Screenshots

<img src="screenshot.png" width="300" />

## Demo Video

Note: The video below is a short recording of the playback.

<video src="demo.mp4" width="300" controls></video>

## How it works

1. **JNI Bindings**: We use `jnigen` to generate bindings for the ExoPlayer Android library.
2. **Texture Registry**: We create a `SurfaceTexture` on the Android side (via `MainActivity.kt` helper for now) and pass the surface to ExoPlayer.
3. **Dart Control**: All player controls (prepare, play, pause, setMediaItem) are called directly from Dart using the generated JNI bindings.

## Running

```bash
flutter run
```
