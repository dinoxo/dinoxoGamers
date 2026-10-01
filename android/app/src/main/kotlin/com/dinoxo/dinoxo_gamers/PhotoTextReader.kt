package com.dinoxo.dinoxo_gamers

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ColorSpace
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class PhotoTextReader(private val context: Context) {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var current: Read? = null
    private var closed = false

    private class Read(val result: MethodChannel.Result, path: String) {
        val cancelled = AtomicBoolean(false)
        val answered = AtomicBoolean(false)
        val diagnostics = ConcurrentHashMap<String, Any>().apply {
            put("sourceKind", when {
                path.startsWith("content://", ignoreCase = true) -> "content_uri"
                path.startsWith("file://", ignoreCase = true) -> "file_uri"
                else -> "file_path"
            })
            put("decoder", if (Build.VERSION.SDK_INT >= 28) "ImageDecoder" else "BitmapFactory")
            put("sdk", Build.VERSION.SDK_INT)
        }
        var timeout: Runnable? = null
    }

    fun recognize(path: String?, result: MethodChannel.Result) {
        if (closed || current != null) {
            result.error("OCR_BUSY", "La lectura anterior sigue terminando.", null)
            return
        }
        if (path.isNullOrBlank()) {
            result.error("IMAGE_MISSING", "No se pudo abrir la imagen.", null)
            return
        }
        val read = Read(result, path)
        current = read
        read.timeout = Runnable {
            read.cancelled.set(true)
            error(read, "OCR_TIMEOUT", "La lectura tardó demasiado.")
        }
        main.postDelayed(read.timeout!!, 18_000)
        executor.execute {
            var bitmap: Bitmap? = null
            var recognizer: com.google.mlkit.vision.text.TextRecognizer? = null
            var stage = "decode"
            try {
                if (read.cancelled.get()) { release(read); return@execute }
                bitmap = decode(path, read.diagnostics)
                if (read.cancelled.get()) {
                    bitmap.recycle(); release(read); return@execute
                }
                val image = bitmap
                stage = "mlkit_start"
                val reader = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                recognizer = reader
                // Completing on the executor also keeps sorting/results off the UI thread.
                reader.process(InputImage.fromBitmap(image, 0))
                    .addOnCompleteListener(executor) { task ->
                        try {
                            if (!read.cancelled.get()) {
                                if (task.isSuccessful) {
                                    val lines = task.result.textBlocks
                                        .sortedByDescending { block -> block.lines.maxOfOrNull { it.boundingBox?.height() ?: 0 } ?: 0 }
                                        .take(40)
                                        .flatMap { block ->
                                            val text = block.lines.take(12).map { it.text.take(200) }
                                            listOf(text.joinToString(" ").take(200)) + text
                                        }.distinct().take(100)
                                    main.post {
                                        if (!read.cancelled.get() && read.answered.compareAndSet(false, true))
                                            read.result.success(lines)
                                    }
                                } else {
                                    reportFailure(read, "recognition", task.exception)
                                    error(read, "OCR_FAILED", "No se pudo reconocer el texto.")
                                }
                            }
                        } catch (e: Exception) {
                            reportFailure(read, "result", e)
                            error(read, "OCR_FAILED", "No se pudo procesar el resultado del texto.")
                        } finally {
                            try { image.recycle() }
                            finally {
                                try { reader.close() }
                                finally { release(read) }
                            }
                        }
                    }
            } catch (e: OutOfMemoryError) {
                fail(read, stage, e, bitmap, recognizer)
            } catch (e: LinkageError) {
                if (stage == "mlkit_start") fail(read, stage, e, bitmap, recognizer)
                else throw e
            } catch (e: Exception) {
                fail(read, stage, e, bitmap, recognizer)
            }
        }
    }

    private fun getStream(path: String): InputStream {
        return if (path.startsWith("content://", ignoreCase = true) ||
            path.startsWith("file://", ignoreCase = true)) {
            context.contentResolver.openInputStream(Uri.parse(path))
                ?: throw FileNotFoundException("No stream for image URI")
        } else {
            File(path).inputStream()
        }
    }

    private fun decode(path: String, diagnostics: MutableMap<String, Any>): Bitmap {
        return if (Build.VERSION.SDK_INT >= 28) decodeModern(path, diagnostics)
        else decodeLegacy(path, diagnostics)
    }

    private fun decodeModern(path: String, diagnostics: MutableMap<String, Any>): Bitmap {
        val source = if (path.startsWith("content://", ignoreCase = true) ||
            path.startsWith("file://", ignoreCase = true)) {
            ImageDecoder.createSource(context.contentResolver, Uri.parse(path))
        } else ImageDecoder.createSource(File(path))
        return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            diagnostics["mimeType"] = info.mimeType
            diagnostics["sourceWidth"] = info.size.width
            diagnostics["sourceHeight"] = info.size.height
            decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE)
            decoder.setTargetColorSpace(ColorSpace.get(ColorSpace.Named.SRGB))
            decoder.setTargetSampleSize(PhotoImageBudget.sampleSize(info.size.width, info.size.height))
        }.also { bitmap ->
            diagnostics["decodedWidth"] = bitmap.width
            diagnostics["decodedHeight"] = bitmap.height
        }
    }

    private fun decodeLegacy(path: String, diagnostics: MutableMap<String, Any>): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        getStream(path).use { stream ->
            BitmapFactory.decodeStream(stream, null, bounds)
        }
        val sample = PhotoImageBudget.sampleSize(bounds.outWidth, bounds.outHeight)
        diagnostics["sourceWidth"] = bounds.outWidth
        diagnostics["sourceHeight"] = bounds.outHeight
        bounds.outMimeType?.let { diagnostics["mimeType"] = it }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val original = getStream(path).use { stream ->
            BitmapFactory.decodeStream(stream, null, options)
                ?: throw IllegalArgumentException("Invalid image pixels")
        }
        diagnostics["decodedWidth"] = original.width
        diagnostics["decodedHeight"] = original.height
        // Keep usable pixels when optional metadata cannot be read.
        val orientation = try {
            getStream(path).use { stream ->
                ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            }
        } catch (e: Exception) {
            diagnostics["exifStatus"] = "unavailable"
            Log.w("OCR", "EXIF unavailable (${e.javaClass.simpleName})")
            ExifInterface.ORIENTATION_NORMAL
        }
        val transform = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> transform.setScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> transform.setRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> transform.setScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { transform.setRotate(90f); transform.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_90 -> transform.setRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> { transform.setRotate(270f); transform.postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_270 -> transform.setRotate(270f)
        }
        if (transform.isIdentity) return original
        try {
            return Bitmap.createBitmap(original, 0, 0, original.width, original.height, transform, true)
        } finally { original.recycle() }
    }

    private fun fail(
        read: Read, stage: String, failure: Throwable,
        bitmap: Bitmap?, recognizer: com.google.mlkit.vision.text.TextRecognizer?
    ) {
        reportFailure(read, stage, failure)
        val code = when {
            stage != "decode" -> "OCR_FAILED"
            failure is OutOfMemoryError -> "IMAGE_TOO_LARGE"
            failure is SecurityException || failure.cause is SecurityException -> "photo_access_denied"
            failure is FileNotFoundException || failure.cause is FileNotFoundException -> "IMAGE_MISSING"
            failure is ImageDecoder.DecodeException ->
                if (failure.error == ImageDecoder.DecodeException.SOURCE_EXCEPTION)
                    "IMAGE_READ_FAILED" else "IMAGE_INVALID"
            failure is IOException -> "IMAGE_READ_FAILED"
            else -> "IMAGE_INVALID"
        }
        val message = when (code) {
            "IMAGE_TOO_LARGE" -> "No hay memoria suficiente para leer esta imagen."
            "photo_access_denied" -> "No se permitió leer esta foto."
            "IMAGE_MISSING" -> "No se pudo abrir la imagen."
            "IMAGE_READ_FAILED" -> "No se pudo leer esta imagen."
            "OCR_FAILED" -> "No se pudo iniciar el reconocimiento del texto."
            else -> "No se pudo abrir el formato de imagen."
        }
        error(read, code, message)
        try {
            bitmap?.recycle()
            recognizer?.close()
        } catch (e: Exception) {
            Log.w("OCR", "Cleanup failed (${e.javaClass.simpleName})")
        } finally {
            release(read)
        }
    }

    private fun reportFailure(read: Read, stage: String, failure: Throwable?) {
        read.diagnostics["stage"] = stage
        if (failure != null) read.diagnostics["exceptionType"] = failure.javaClass.name
        if (failure is com.google.mlkit.common.MlKitException)
            read.diagnostics["mlKitCode"] = failure.errorCode
        Log.w("OCR", "stage=$stage, source=${read.diagnostics["sourceKind"]}, " +
            "decoder=${read.diagnostics["decoder"]}, type=${failure?.javaClass?.simpleName}")
    }

    private fun error(read: Read, code: String, message: String) {
        main.post {
            if (read.answered.compareAndSet(false, true))
                read.result.error(code, message, HashMap(read.diagnostics))
        }
    }

    private fun release(read: Read) {
        main.post {
            read.timeout?.let { main.removeCallbacks(it) }
            if (current === read) current = null
            if (closed) executor.shutdown()
        }
    }

    fun cancel() {
        current?.let { read ->
            read.cancelled.set(true)
            error(read, "OCR_CANCELLED", "Lectura cancelada.")
        }
    }

    fun close() {
        closed = true
        cancel()
        if (current == null) executor.shutdown()
    }
}
