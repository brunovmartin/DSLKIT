package com.example.ComposeDSL

object ConditionalOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("Operator.if") { input, ctx ->
            val dict = input as? Map<*, *> ?: return@register null
            val cond = DSLExpression.evaluate(dict["condition"], ctx) as? Boolean ?: false
            return@register if (cond) {
                DSLExpression.evaluate(dict["then"], ctx)
            } else {
                dict["else"]?.let { DSLExpression.evaluate(it, ctx) }
            }
        }
    }
}
