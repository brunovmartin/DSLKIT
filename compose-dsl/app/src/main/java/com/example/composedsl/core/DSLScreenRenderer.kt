package com.example.composedsl.core

import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.unit.dp
import android.util.Log

object DSLScreenRenderer {
    private const val TAG = "DSLScreenRenderer"

    @Composable
    fun Render(screen: Map<String, Any?>, context: DSLContext) {
        val body = screen["body"] as? List<Map<String, Any?>> ?: emptyList()
        val navBar = screen["navigationBar"] as? Map<String, Any?>
        val titleExpr = navBar?.get("title")
        val title = DSLExpression.evaluate(titleExpr, context)?.toString() ?: ""
        Log.d(TAG, "Rendering screen with title=$title")
        Scaffold(
            topBar = {
                if (navBar != null) {
                    TopAppBar(title = { Text(title) })
                }
            }
        ) { padding ->
            Column(modifier = Modifier.padding(padding)) {
                DSLRenderer.renderChildren(body, context)
            }
        }
    }
}
