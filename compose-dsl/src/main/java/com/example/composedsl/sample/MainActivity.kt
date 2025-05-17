package com.example.composedsl.sample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.example.composedsl.core.DSLContext
import com.example.composedsl.core.DSLInterpreter
import com.example.composedsl.core.DSLAppEngine
import com.example.composedsl.core.DSLComponentRegistry
import com.example.composedsl.core.DSLRenderer
import com.example.composedsl.commands.DSLCommandRegistry
import com.example.composedsl.operators.DSLOperatorRegistry
import com.example.composedsl.helper.DSLModifierRegistry

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val context = DSLContext()
        DSLOperatorRegistry.registerDefaults()
        DSLCommandRegistry.registerDefaults()
        DSLComponentRegistry.registerDefaults()
        DSLModifierRegistry.registerDefaults()
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
