package com.example.ComposeDSL

import android.content.Context
import android.content.SharedPreferences

object StorageOperators {
    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        prefs = context.getSharedPreferences("dsl", Context.MODE_PRIVATE)
    }

    fun registerAll() {
        DSLOperatorRegistry.register("Storage.get") { input, ctx ->
            val key = when (input) {
                is String -> input
                is Map<*, *> -> DSLExpression.evaluate(input["key"], ctx) as? String
                else -> null
            }
            key?.let { prefs?.all?.get(it) }
        }
    }
}
