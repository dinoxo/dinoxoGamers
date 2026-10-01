package com.dinoxo.dinoxo_gamers

import android.content.ContentProvider
import android.content.ContentValues
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.net.Uri
import android.os.Looper
import android.os.ParcelFileDescriptor
import androidx.exifinterface.media.ExifInterface
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.shadows.ShadowContentResolver
import java.io.File
import java.io.FileNotFoundException
import java.lang.reflect.InvocationTargetException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
// Robolectric's JVM ImageDecoder stub cannot decode pixel data; API 27
// exercises the supported BitmapFactory fallback with real image bytes.
@Config(sdk = [27], manifest = Config.NONE)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class PhotoTextReaderTest {
    @get:Rule val files = TemporaryFolder()
    private lateinit var reader: PhotoTextReader

    @Before fun createReader() {
        reader = PhotoTextReader(RuntimeEnvironment.getApplication())
    }

    @After fun closeReader() {
        reader.close()
        Shadows.shadowOf(Looper.getMainLooper()).idle()
    }

    @Test fun decodesActualPngPixelsFromFilePathsAndEncodedFileUris() {
        val image = imageFile("cover with spaces.png", "png", 80, 40)
        for (path in listOf(image.path, Uri.fromFile(image).toString())) {
            val bitmap = decode(path)
            try {
                assertEquals(80, bitmap.width)
                assertEquals(40, bitmap.height)
                assertEquals(Bitmap.Config.ARGB_8888, bitmap.config)
                assertFalse(bitmap.isRecycled)
                assertCorners(bitmap, listOf(RED, GREEN, BLUE, YELLOW))
            } finally { bitmap.recycle() }
        }
    }

    @Test fun decodesActualJpegPixelsAndAppliesEveryExifOrientationOnce() {
        val orientations = listOf(
            1 to listOf(RED, GREEN, BLUE, YELLOW),
            2 to listOf(GREEN, RED, YELLOW, BLUE),
            3 to listOf(YELLOW, BLUE, GREEN, RED),
            4 to listOf(BLUE, YELLOW, RED, GREEN),
            5 to listOf(RED, BLUE, GREEN, YELLOW),
            6 to listOf(BLUE, RED, YELLOW, GREEN),
            7 to listOf(YELLOW, GREEN, BLUE, RED),
            8 to listOf(GREEN, YELLOW, RED, BLUE),
        )
        for ((orientation, corners) in orientations) {
            val image = imageFile("orientation-$orientation.jpg", "jpeg", 80, 40)
            ExifInterface(image).apply {
                setAttribute(ExifInterface.TAG_ORIENTATION, orientation.toString())
                saveAttributes()
            }
            val bitmap = decode(image.path)
            try {
                assertEquals(if (orientation >= 5) 40 else 80, bitmap.width)
                assertEquals(if (orientation >= 5) 80 else 40, bitmap.height)
                assertCorners(bitmap, corners)
            } finally { bitmap.recycle() }
        }
    }

    @Test fun contentPhotoSurvivesUnavailableOptionalExifMetadata() {
        val image = imageFile("provider.png", "png", 80, 40)
        val uri = registerPhotoProvider(image, maxOpens = 2)
        val bitmap = decode(uri.toString())
        try {
            assertEquals(80, bitmap.width)
            assertEquals(40, bitmap.height)
            assertCorners(bitmap, listOf(RED, GREEN, BLUE, YELLOW))
        } finally { bitmap.recycle() }
    }

    @Test fun boundsThePixelsActuallyDecodedForAHighResolutionPhoto() {
        val image = imageFile("camera.png", "png", 4000, 3000)
        val bitmap = decode(image.path)
        try {
            assertEquals(2000, bitmap.width)
            assertEquals(1500, bitmap.height)
            assertEquals(Bitmap.Config.ARGB_8888, bitmap.config)
            assertTrue(bitmap.allocationByteCount <= 12_000_000)
        } finally { bitmap.recycle() }
    }

    @Test fun aMissingFileIsAnAccessFailureRatherThanAnInvalidImage() {
        val failure = recognizeFailure(File(files.root, "missing.jpg").path)
        assertEquals("IMAGE_MISSING", failure.code)
        assertEquals("decode", failure.details?.get("stage"))
    }

    @Test fun unreadableEncodedBytesAreReportedAsAnInvalidImage() {
        val image = files.newFile("not-a-photo.jpg").apply {
            writeBytes(byteArrayOf(1, 2, 3, 4))
        }
        val failure = recognizeFailure(image.path)
        assertEquals("IMAGE_INVALID", failure.code)
        assertEquals("decode", failure.details?.get("stage"))
    }

    @Test fun anUnreadableContentGrantIsReportedAsPhotoAccessDenied() {
        val uri = registerPhotoProvider(
            imageFile("denied.png", "png", 80, 40), denyAccess = true,
        )
        assertEquals("photo_access_denied", recognizeFailure(uri.toString()).code)
    }

    @Test fun mlKitStartupFailureDoesNotBlameTheValidImageFormat() {
        // Config.NONE deliberately omits MlKitInitProvider. The real ML Kit
        // client must reject this uninitialized host application after decode.
        val image = imageFile("valid.png", "png", 80, 40)
        val failure = recognizeFailure(image.path)
        assertEquals("OCR_FAILED", failure.code)
        assertEquals("mlkit_start", failure.details?.get("stage"))
        assertEquals("java.lang.IllegalStateException", failure.details?.get("exceptionType"))
    }

    private fun decode(path: String): Bitmap {
        val method = PhotoTextReader::class.java.getDeclaredMethod(
            "decode", String::class.java, MutableMap::class.java)
        method.isAccessible = true
        return try { method.invoke(reader, path, mutableMapOf<String, Any>()) as Bitmap }
        catch (e: InvocationTargetException) { throw e.targetException }
    }

    private data class Failure(val code: String, val details: Map<*, *>?)

    private fun recognizeFailure(path: String): Failure {
        val answer = CountDownLatch(1)
        var failure: Failure? = null
        var success = false
        reader.recognize(path, object : MethodChannel.Result {
            override fun success(result: Any?) { success = true; answer.countDown() }
            override fun error(code: String, message: String?, details: Any?) {
                failure = Failure(code, details as? Map<*, *>)
                answer.countDown()
            }
            override fun notImplemented() { answer.countDown() }
        })
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
        while (answer.count > 0 && System.nanoTime() < deadline) {
            Shadows.shadowOf(Looper.getMainLooper()).idle()
            answer.await(10, TimeUnit.MILLISECONDS)
        }
        assertEquals("Native reader did not reply", 0L, answer.count)
        assertFalse("Expected an error, received OCR success", success)
        assertNotNull("Expected an error result", failure)
        return failure!!
    }

    private fun imageFile(name: String, format: String, width: Int, height: Int): File {
        val image = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        try {
            val canvas = Canvas(image)
            val paint = Paint()
            val quadrants = listOf(
                Triple(0 to 0, width / 2 to height / 2, RED),
                Triple(width / 2 to 0, width to height / 2, GREEN),
                Triple(0 to height / 2, width / 2 to height, BLUE),
                Triple(width / 2 to height / 2, width to height, YELLOW),
            )
            for ((start, end, color) in quadrants) {
                paint.color = color
                canvas.drawRect(start.first.toFloat(), start.second.toFloat(),
                    end.first.toFloat(), end.second.toFloat(), paint)
            }
            val encoded = if (format == "png") Bitmap.CompressFormat.PNG
                else Bitmap.CompressFormat.JPEG
            return files.newFile(name).also { output ->
                output.outputStream().use { stream ->
                    assertTrue(image.compress(encoded, 95, stream))
                }
            }
        } finally {
            image.recycle()
        }
    }

    private fun assertCorners(bitmap: Bitmap, expected: List<Int>) {
        val points = listOf(
            bitmap.width / 4 to bitmap.height / 4,
            bitmap.width * 3 / 4 to bitmap.height / 4,
            bitmap.width / 4 to bitmap.height * 3 / 4,
            bitmap.width * 3 / 4 to bitmap.height * 3 / 4,
        )
        for ((index, point) in points.withIndex()) {
            val actual = bitmap.getPixel(point.first, point.second)
            for (shift in listOf(16, 8, 0)) {
                val delta = kotlin.math.abs(((actual shr shift) and 255) - ((expected[index] shr shift) and 255))
                assertTrue("Wrong pixel at corner $index: $actual", delta < 25)
            }
        }
    }

    private fun registerPhotoProvider(
        image: File, maxOpens: Int? = null, denyAccess: Boolean = false,
    ): Uri {
        val authority = "com.dinoxo.test.photos"
        val provider = object : ContentProvider() {
            var opens = 0
            override fun onCreate() = true
            override fun getType(uri: Uri) = "image/png"
            override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
                if (denyAccess) throw SecurityException("Photo grant denied")
                if (maxOpens != null && opens++ >= maxOpens)
                    throw FileNotFoundException("Metadata reopen failed")
                return ParcelFileDescriptor.open(image, ParcelFileDescriptor.MODE_READ_ONLY)
            }
            override fun query(uri: Uri, projection: Array<out String>?, selection: String?,
                selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
            override fun insert(uri: Uri, values: ContentValues?): Uri? = null
            override fun update(uri: Uri, values: ContentValues?, selection: String?,
                selectionArgs: Array<out String>?): Int = 0
            override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
        }
        provider.attachInfo(RuntimeEnvironment.getApplication(), ProviderInfo().apply { this.authority = authority })
        ShadowContentResolver.registerProviderInternal(authority, provider)
        return Uri.parse("content://$authority/photo")
    }

    private companion object {
        val RED = 0xffff0000.toInt()
        val GREEN = 0xff00ff00.toInt()
        val BLUE = 0xff0000ff.toInt()
        val YELLOW = 0xffffff00.toInt()
    }
}
