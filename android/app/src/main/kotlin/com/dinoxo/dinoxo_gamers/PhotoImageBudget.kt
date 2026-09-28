package com.dinoxo.dinoxo_gamers

object PhotoImageBudget {
    fun sampleSize(width: Int, height: Int): Int {
        require(width > 0 && height > 0) { "Invalid image dimensions" }
        var sample = 1
        fun scaled(value: Int) = (value.toLong() + sample - 1) / sample
        while (scaled(width) > 2048 || scaled(height) > 2048 ||
            scaled(width) * scaled(height) > 3_000_000L) {
            sample *= 2
        }
        return sample
    }
}
