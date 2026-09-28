package com.dinoxo.dinoxo_gamers

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val photoReader = Executors.newSingleThreadExecutor()

    override fun onDestroy() {
        photoReader.shutdown()
        super.onDestroy()
    }
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
                photoReader.execute {
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    // ML Kit resolves EXIF rotation and supports photo-picker content URIs.
                    val input = InputImage.fromFilePath(this, uri)
                    recognizer.process(input)
                        .addOnSuccessListener { text ->
                            // Large logo lettering is usually the title. Return a
                            // whole block plus its lines so split logos remain searchable.
                            val blocks = text.textBlocks.sortedByDescending { block ->
                                block.lines.maxOfOrNull { it.boundingBox?.height() ?: 0 } ?: 0
                            }
                            result.success(blocks.flatMap { block ->
                                listOf(block.lines.joinToString(" ") { it.text }) + block.lines.map { it.text }
                            }.distinct())
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
}
