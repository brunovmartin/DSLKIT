package com.example.composedsl.core

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

object DSLAppEngine {
    var initialScreenId: String? = null
    val screens = mutableMapOf<String, Map<String, Any?>>()
    var tabDefinitions: List<Map<String, Any?>>? = null

    fun load(context: Context) {
        val text = context.assets.open("app.compiled.json").bufferedReader().use { it.readText() }
        val json = JSONObject(text)
        initialScreenId = json.optString("mainScreen")
        val screenList = json.optJSONArray("screens") ?: JSONArray()
        for (i in 0 until screenList.length()) {
            val obj = screenList.getJSONObject(i)
            val id = obj.getString("id")
            screens[id] = obj.toMap()
        }
    }

    fun start(context: Context, dslContext: DSLContext, interpreter: DSLInterpreter) {
        val rawContext = JSONObject(context.assets.open("app.compiled.json").bufferedReader().use { it.readText() }).optJSONObject("context")
        if (rawContext != null) {
            val contextMap = rawContext.toMap()
            contextMap.forEach { (key, value) -> dslContext[key] = value }
            Log.d("DSLAppEngine", "Loaded initial context: $contextMap")
        }
        if (initialScreenId != null) {
            screens[initialScreenId!!]?.let { interpreter.present(it, dslContext) }
        }
    }

    fun navigate(id: String) {
        screens[id]?.let { DSLInterpreter.shared.pushScreen(id) }
    }
}

private fun JSONObject.toMap(): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    keys().forEach { key ->
        result[key] = when (val value = get(key)) {
            is JSONObject -> value.toMap()
            is JSONArray -> (0 until value.length()).map { index ->
                val item = value.get(index)
                if (item is JSONObject) item.toMap() else item
            }
            else -> value
        }
    }
    return result
}
