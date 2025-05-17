package com.example.composedsl.ui.screen

import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import com.example.composedsl.core.DSLRenderer
import com.example.composedsl.core.DSLContext
import android.util.Log

object DSLScreenRenderer {
    private const val TAG = "DSLScreenRenderer"

    @Composable
    fun Render(screen: Map<String, Any?>, context: DSLContext) {
        Log.d(TAG, "Rendering screen with title=${screen["navigationBar"]?.let { (it as? Map<*, *>)?.get("title") }}")
        val nav = screen["navigationBar"] as? Map<String, Any?>
        val title = nav?.get("title") as? String ?: ""
        val leading = nav?.get("leadingItems") as? List<Map<String, Any?>>
        val trailing = nav?.get("trailingItems") as? List<Map<String, Any?>>
        val body = screen["body"] as? List<Map<String, Any?>> ?: emptyList()

        Scaffold(
            topBar = {
                if (nav != null) {
                    TopAppBar(
                        title = { Text(title) },
                        navigationIcon = {
                            leading?.let { DSLRenderer.renderChildren(it, context) }
                        },
                        actions = {
                            trailing?.let { DSLRenderer.renderChildren(it, context) }
                        }
                    )
                }
            }
        ) { inner ->
            Column(modifier = Modifier.padding(inner)) {
                DSLRenderer.renderChildren(body, context)
            }
        }
    }
}
