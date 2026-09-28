package com.dinoxo.dinoxo_gamers

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.exifinterface.media.ExifInterface
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class PhotoTextReader(private val context: Context) {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var current: Read? = null
    private var closed = false

    private class Read(val result: MethodChannel.Result) {
        val cancelled = AtomicBoolean(false)
        val answered = AtomicBoolean(false)
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
        val read = Read(result)
        current = read
        read.timeout = Runnable {
            read.cancelled.set(true)
            error(read, "OCR_TIMEOUT", "La lectura tardó demasiado.")
        }
        main.postDelayed(read.timeout!!, 18_000)
        executor.execute {
            var bitmap: Bitmap? = null
            var recognizer: com.google.mlkit.vision.text.TextRecognizer? = null
            try {
                if (read.cancelled.get()) { release(read); return@execute }
                bitmap = decode(path)
                if (read.cancelled.get()) {
                    bitmap.recycle(); release(read); return@execute
                }
                val image = bitmap
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
                                } else error(read, "OCR_FAILED", "No se pudo reconocer el texto.")
                            }
                        } finally {
                            image.recycle()
                            reader.close()
                            release(read)
                        }
                    }
            } catch (_: OutOfMemoryError) {
                bitmap?.recycle(); recognizer?.close()
                error(read, "IMAGE_INVALID", "No hay memoria suficiente para leer esta imagen.")
                release(read)
            } catch (_: SecurityException) {
                bitmap?.recycle(); recognizer?.close()
                error(read, "photo_access_denied", "No se permitió leer esta foto.")
                release(read)
            } catch (e: Exception) { android.util.Log.e("OCR", "Decode failed", e)
                bitmap?.recycle(); recognizer?.close()
                error(read, "IMAGE_INVALID", "No se pudo abrir el formato de imagen.")
                release(read)
            }
        }
    }

    private fun getStream(path: String): java.io.InputStream {
        return if (path.startsWith("content://") || path.startsWith("file://")) {
            context.contentResolver.openInputStream(Uri.parse(path))
                ?: throw IllegalArgumentException("Cannot open stream for URI")
        } else {
            java.io.FileInputStream(java.io.File(path))
        }
    }

    private fun decode(path: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        getStream(path).use { stream ->
            BitmapFactory.decodeStream(stream, null, bounds)
        }
        val sample = PhotoImageBudget.sampleSize(bounds.outWidth, bounds.outHeight)
        val orientation = getStream(path).use { stream ->
            ExifInterface(stream).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        val original = getStream(path).use { stream ->
            requireNotNull(BitmapFactory.decodeStream(stream, null, options))
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

    private fun error(read: Read, code: String, message: String) {
        main.post { if (read.answered.compareAndSet(false, true)) read.result.error(code, message, null) }
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
