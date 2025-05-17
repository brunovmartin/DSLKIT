package com.example.ComposeDSL

object NumberOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("Number.toIntString") { input, ctx ->
            val value = DSLExpression.evaluate(input, ctx)
            val number = value as? Number ?: return@register value?.toString() ?: ""
            val dbl = number.toDouble()
            if (dbl % 1.0 == 0.0) dbl.toInt().toString() else dbl.toString()
        }
    }
}
