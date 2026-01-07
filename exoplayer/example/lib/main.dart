import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:exoplayer_bindings/exoplayer_bindings.dart';
import 'package:jni/jni.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Idle';
  ExoPlayer? _player;
  int? _textureId;

  // Keep references to prevent GC if needed, though JNI objects handle it.
  JObject? _surface;
  JObject? _textureEntry;

  // Media URL (Simpler video for emulator compatibility)
  static const _mediaUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  @override
  void initState() {
    super.initState();
    _initExoPlayer();
  }

  @override
  void dispose() {
    _player?.release();
    // Explicitly release Surface if possible, though JNI GC helps.
    if (_surface != null) {
      // call release() on surface?
      // For now, just clearing the reference.
      // Ideally we should call Surface.release() via JNI.
      _releaseSurface(_surface!);
    }
    super.dispose();
  }

  void _releaseSurface(JObject surface) {
    using((arena) {
      final releaseMethod = Jni.env.GetMethodID(
        Jni.env.GetObjectClass(surface.reference.pointer),
        'release'.toNativeUtf8(allocator: arena).cast(),
        '()V'.toNativeUtf8(allocator: arena).cast(),
      );
      Jni.env.CallVoidMethodA(
        surface.reference.pointer,
        releaseMethod,
        nullptr,
      );
    });
  }

  Future<void> _initExoPlayer() async {
    if (!Platform.isAndroid) return;

    try {
      setState(() => _status = "Initializing...");

      final context = _getApplicationContext();

      // We must use the application class loader to find MainActivity
      final result = _createTextureWithClassLoader(context);

      final array = result.as(JArray.type(JObject.type));
      final idObj = array[0].as(JLong.type);
      final textureId = idObj.longValue;
      final surface = array[1].as(JObject.type);
      final entry = array[2].as(JObject.type); // Keep entry alive!

      _textureId = textureId();
      _surface = surface;
      _textureEntry = entry;

      final mainLooper = _getMainLooper();

      final builder = ExoPlayer_Builder(context);
      builder.setPlaybackLooper(mainLooper);
      _player = builder.build();

      _player!.getVideoComponent().setVideoSurface(surface);

      final playerInterface = _player!.as(Player.type);

      print('DEBUG: Setup DRM');

      // Example DRM stream (Widevine)
      // Tears of Steel (DASH)
      const drmMediaUrl =
          'https://storage.googleapis.com/wvmedia/cenc/h264/tears/tears.mpd';
      const licenseUrl =
          'https://proxy.uat.widevine.com/proxy?provider=widevine_test';
      const widevineUuid = 'edef8ba9-79d6-4ace-a3c8-27dcd51d21ed';

      // 1. Create UUID
      final uuid = _createUUID(widevineUuid);

      // 2. Create DrmConfiguration
      final drmConfigBuilder = MediaItem_DrmConfiguration_Builder(
        uuid,
      ).setLicenseUri$1(licenseUrl.toJString());

      final drmConfig = drmConfigBuilder.build();

      // 3. Create MediaItem with DRM
      final mediaItemBuilder = MediaItem_Builder()
          .setUri(drmMediaUrl.toJString())
          .setDrmConfiguration(drmConfig);

      final mediaItem = mediaItemBuilder.build();

      playerInterface.setMediaItem(mediaItem);

      playerInterface.prepare();

      playerInterface.setPlayWhenReady(true);

      setState(() {
        _status = 'Top: Playing texture $_textureId';
      });
    } catch (e, stack) {
      setState(() => _status = 'Error: $e');
      print(e);
      print(stack);
    }
  }

  JObject _createUUID(String uuidString) {
    return using((arena) {
      final uuidClass = Jni.env.FindClass(
        'java/util/UUID'.toNativeUtf8(allocator: arena).cast(),
      );
      final fromStringMethod = Jni.env.GetStaticMethodID(
        uuidClass,
        'fromString'.toNativeUtf8(allocator: arena).cast(),
        '(Ljava/lang/String;)Ljava/util/UUID;'
            .toNativeUtf8(allocator: arena)
            .cast(),
      );

      final jString = uuidString.toJString().reference.pointer;
      final args = arena<JValue>(1);
      args[0].l = jString;

      final result = Jni.env.CallStaticObjectMethodA(
        uuidClass,
        fromStringMethod,
        args,
      );
      return JObject.fromReference(JGlobalReference(result));
    });
  }

  JObject _getMainLooper() {
    return using((arena) {
      final looperClass = Jni.env.FindClass(
        'android/os/Looper'.toNativeUtf8(allocator: arena).cast(),
      );
      final getMainLooperMethod = Jni.env.GetStaticMethodID(
        looperClass,
        'getMainLooper'.toNativeUtf8(allocator: arena).cast(),
        '()Landroid/os/Looper;'.toNativeUtf8(allocator: arena).cast(),
      );
      final looper = Jni.env.CallStaticObjectMethodA(
        looperClass,
        getMainLooperMethod,
        nullptr,
      );
      return JObject.fromReference(JGlobalReference(looper));
    });
  }

  // Helper to load MainActivity using the Context's ClassLoader
  JObject _createTextureWithClassLoader(JObject context) {
    return using((arena) {
      // context.getClassLoader()
      final getClassLoaderId = Jni.env.GetMethodID(
        Jni.env.GetObjectClass(context.reference.pointer),
        'getClassLoader'.toNativeUtf8(allocator: arena).cast(),
        '()Ljava/lang/ClassLoader;'.toNativeUtf8(allocator: arena).cast(),
      );
      final classLoaderRef = Jni.env.CallObjectMethodA(
        context.reference.pointer,
        getClassLoaderId,
        nullptr,
      );

      final classLoader = JObject.fromReference(
        JGlobalReference(classLoaderRef),
      );

      final loadClassId = Jni.env.GetMethodID(
        Jni.env.GetObjectClass(classLoader.reference.pointer),
        'loadClass'.toNativeUtf8(allocator: arena).cast(),
        '(Ljava/lang/String;)Ljava/lang/Class;'
            .toNativeUtf8(allocator: arena)
            .cast(),
      );

      final className = 'com.example.example.MainActivity'
          .toJString()
          .reference
          .pointer;
      // We need to pass args.
      final args = arena<JValue>(1);
      args[0].l = className;

      final mainActivityClassRef = Jni.env.CallObjectMethodA(
        classLoader.reference.pointer,
        loadClassId,
        args,
      );

      if (mainActivityClassRef == nullptr) {
        throw 'Failed to load MainActivity class';
      }

      final createTextureMethod = Jni.env.GetStaticMethodID(
        mainActivityClassRef.cast(), // cast to jclass
        'createTexture'.toNativeUtf8(allocator: arena).cast(),
        '()Ljava/lang/Object;'.toNativeUtf8(allocator: arena).cast(),
      );

      final res = Jni.env.CallStaticObjectMethodA(
        mainActivityClassRef.cast(),
        createTextureMethod,
        nullptr,
      );

      return JObject.fromReference(JGlobalReference(res));
    });
  }

  JObject _getApplicationContext() {
    return using((arena) {
      final className = 'android/app/ActivityThread'
          .toNativeUtf8(allocator: arena)
          .cast<Char>();
      final activityThreadClass = Jni.env.FindClass(className);

      if (activityThreadClass == nullptr) {
        throw 'Failed to find ActivityThread class';
      }

      final currentAppMethod = Jni.env.GetStaticMethodID(
        activityThreadClass,
        'currentApplication'.toNativeUtf8(allocator: arena).cast(),
        '()Landroid/app/Application;'.toNativeUtf8(allocator: arena).cast(),
      );

      final app = Jni.env.CallStaticObjectMethodA(
        activityThreadClass,
        currentAppMethod,
        nullptr,
      );

      // Warning: 'reference' is internal.
      // But we are using low-level JNI, so it's unavoidable or we use JObject.fromReference directly.
      return JObject.fromReference(JGlobalReference(app));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ExoPlayer JNI Example')),
        body: Column(
          children: [
            if (_textureId != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Texture(textureId: _textureId!),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            Padding(padding: const EdgeInsets.all(8.0), child: Text(_status)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () =>
                      _player != null ? _player!.as(Player.type).play() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () =>
                      _player != null ? _player!.as(Player.type).pause() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () =>
                      _player != null ? _player!.as(Player.type).stop() : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
