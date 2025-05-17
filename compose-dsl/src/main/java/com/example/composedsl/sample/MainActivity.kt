package com.example.composedsl.sample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.composedsl.core.*
import com.example.composedsl.ui.components.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val context = DSLContext()
        DSLOperatorRegistry.registerDefaults()
        DSLCommandRegistry.registerDefaults()
        DSLComponentRegistry.registerDefaults()
        DSLAppEngine.load(this)
        DSLAppEngine.start(this, context, DSLInterpreter.shared)

        setContent {
            val root = DSLInterpreter.shared.getRootScreenDefinition()
            if (root != null) {
                DSLRenderer.renderChildren(root["body"] as List<Map<String, Any?>>, context)
            }
        }
    }
}
