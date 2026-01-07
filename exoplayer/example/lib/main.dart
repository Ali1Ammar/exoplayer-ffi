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

  @override
  void initState() {
    super.initState();
    _initExoPlayer();
  }

  Future<void> _initExoPlayer() async {
    if (!Platform.isAndroid) {
      setState(() {
        _status = 'Not running on Android';
      });
      return;
    }

    try {
      setState(() {
        _status = "Initializing...";
      });

      // Get Android Application Context
      final context = _getApplicationContext();

      // Build ExoPlayer
      // Note: If generated bindings do not include nested classes like ExoPlayer.Builder
      // directly, you might need to use JNI reflection or ensure they are generated.
      // Based on typical jnigen output, nested classes are flattened (e.g. ExoPlayer_Builder).

      // Assuming ExoPlayer_Builder is generated:
      final builder = ExoPlayer_Builder(context);
      _player = builder.build();

      setState(() {
        _status = 'ExoPlayer initialized: ${_player}';
      });
    } catch (e, stack) {
      setState(() {
        _status = 'Error: $e';
      });
      print(e);
      print(stack);
    }
  }

  JObject _getApplicationContext() {
    return using((arena) {
      final activityThreadClass = Jni.env.FindClass(
        'android/app/ActivityThread'.toNativeUtf8(allocator: arena).cast(),
      );
      final currentAppMethod = Jni.env.GetStaticMethodID(
        activityThreadClass,
        'currentApplication'.toNativeUtf8(allocator: arena).cast(),
        '()Landroid/app/Application;'.toNativeUtf8(allocator: arena).cast(),
      );
      // Use CallStaticObjectMethodA with nullptr for empty arguments
      final app = Jni.env.CallStaticObjectMethodA(
        activityThreadClass,
        currentAppMethod,
        nullptr,
      );

      return JObject.fromReference(JGlobalReference(app));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ExoPlayer JNI Example')),
        body: Center(child: Text(_status)),
      ),
    );
  }
}
