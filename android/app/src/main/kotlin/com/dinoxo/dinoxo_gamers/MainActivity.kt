package com.dinoxo.dinoxo_gamers

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.dinoxo.gamers/ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("IMAGE_MISSING", "No se pudo abrir la imagen.", null)
                    return@setMethodCallHandler
                }
                val uri = when {
                    path.startsWith("content://") || path.startsWith("file://") -> Uri.parse(path)
                    else -> Uri.fromFile(File(path))
                }
                if (uri.scheme == "file" && !File(uri.path ?: "").isFile) {
                    result.error("IMAGE_MISSING", "La imagen ya no está disponible. Selecciónala de nuevo.", null)
                    return@setMethodCallHandler
                }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    // ML Kit resolves EXIF rotation and supports photo-picker content URIs.
                    val input = InputImage.fromFilePath(this, uri)
                    recognizer.process(input)
                        .addOnSuccessListener { text ->
                            result.success(text.textBlocks.flatMap { block -> block.lines.map { it.text } })
                        }
                        .addOnFailureListener {
                            result.error("OCR_FAILED", "No se pudo reconocer el texto de la imagen.", null)
                        }
                        .addOnCompleteListener { recognizer.close() }
                } catch (_: SecurityException) {
                    recognizer.close()
                    result.error("photo_access_denied", "No se permitió leer esta foto.", null)
                } catch (_: Exception) {
                    recognizer.close()
                    result.error("IMAGE_INVALID", "El formato de imagen no es compatible.", null)
                }
            }
    }
}
