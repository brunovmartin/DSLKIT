package com.example.composedsl.helper

import androidx.compose.ui.graphics.Color

object ColorHelper {
    fun parse(colorString: String?): Color? {
        if (colorString == null) return null
        return runCatching { Color(android.graphics.Color.parseColor(colorString)) }.getOrNull()
    }
}
