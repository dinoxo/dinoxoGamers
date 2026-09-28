package com.dinoxo.dinoxo_gamers

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PhotoImageBudgetTest {
    @Test fun highResolutionPhotosFitTheDecodedMemoryBudget() {
        // Includes the 12/50/200 MP camera sizes and long gallery panoramas.
        for ((width, height) in listOf(4000 to 3000, 8160 to 6120, 16320 to 12240,
            12240 to 16320, 30000 to 1000, Int.MAX_VALUE to Int.MAX_VALUE)) {
            val sample = PhotoImageBudget.sampleSize(width, height)
            val scaledWidth = (width.toLong() + sample - 1) / sample
            val scaledHeight = (height.toLong() + sample - 1) / sample
            assertTrue(scaledWidth <= 2048 && scaledHeight <= 2048)
            assertTrue(scaledWidth * scaledHeight <= 3_000_000L)
        }
    }
    @Test fun smallReadablePhotosKeepTheirResolution() {
        assertEquals(1, PhotoImageBudget.sampleSize(1200, 1600))
    }
    @Test(expected = IllegalArgumentException::class)
    fun unreadableDimensionsDoNotStartDecoding() {
        PhotoImageBudget.sampleSize(-1, -1)
    }
}
