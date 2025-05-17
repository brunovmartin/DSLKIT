package com.example.composedsl.sample

import android.os.Bundle
import com.example.composedsl.core.*
import com.example.composedsl.commands.DSLCommandRegistry
import com.example.composedsl.operators.DSLOperatorRegistry
import com.example.composedsl.ui.components.*
import com.example.composedsl.ui.DSLScreenRenderer
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent

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
            Log.d("MainActivity", "Root screen: $root")
            if (root != null) {
                DSLScreenRenderer.render(root, context)
            }
        }
    }
}
