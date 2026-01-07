package com.example.example

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import android.view.Surface

class MainActivity : FlutterActivity() {
    companion object {
        var flutterEngineInstance: FlutterEngine? = null

        @JvmStatic
        fun createTexture(): Any {
            if (android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) {
                return createTextureInternal()
            }
            
            val latch = java.util.concurrent.CountDownLatch(1)
            var result: Any? = null
            var exception: Throwable? = null
            
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    result = createTextureInternal()
                } catch (e: Throwable) {
                    exception = e
                } finally {
                    latch.countDown()
                }
            }
            
            latch.await()
            
            if (exception != null) {
                throw RuntimeException(exception)
            }
            
            return result!!
        }

        private fun createTextureInternal(): Any {
            val engine = flutterEngineInstance ?: throw IllegalStateException("FlutterEngine not initialized")
            val registry = engine.renderer
            val entry = registry.createSurfaceTexture()
            val surface = Surface(entry.surfaceTexture())
            return arrayOf<Any>(entry.id(), surface, entry)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineInstance = flutterEngine
    }
}
