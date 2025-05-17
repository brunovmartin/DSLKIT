package com.example.composedsl.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import android.util.Log
import com.example.composedsl.core.DSLContext
import com.example.composedsl.core.DSLRenderer

object DSLScreenRenderer {
    private const val TAG = "DSLScreenRenderer"

    @OptIn(ExperimentalMaterial3Api::class)
    @Composable
    fun render(screen: Map<String, Any?>, context: DSLContext) {
        val navBar = screen["navigationBar"] as? Map<*, *>
        val title = navBar?.get("title")?.toString() ?: ""
        val leadingItems = navBar?.get("leadingItems") as? List<Map<String, Any?>>
        val body = screen["body"] as? List<Map<String, Any?>> ?: emptyList()
        Log.d(TAG, "Rendering screen with title=$title")
        Scaffold(
            topBar = {
                if (navBar != null) {
                    TopAppBar(
                        title = { Text(title) },
                        navigationIcon = {
                            leadingItems?.firstOrNull()?.let {
                                DSLRenderer.renderComponent(it, context)
                            }
                        }
                    )
                }
            }
        ) { padding ->
            Column(modifier = Modifier.padding(padding)) {
                DSLRenderer.renderChildren(body, context)
            }
        }
    }
}
