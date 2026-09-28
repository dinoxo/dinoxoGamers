package com.dinoxo.dinoxo_gamers

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var photoReader: PhotoTextReader? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        photoReader = PhotoTextReader(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.dinoxo.gamers/ocr")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "recognizeText" -> photoReader?.recognize(call.argument<String>("path"), result)
                    "cancelRecognition" -> {
                        photoReader?.cancel()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        photoReader?.close()
        photoReader = null
        super.onDestroy()
    }
}
