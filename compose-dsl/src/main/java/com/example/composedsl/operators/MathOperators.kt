package com.example.composedsl.operators
import com.example.composedsl.core.DSLContext

import kotlin.random.Random

object MathOperators {
    fun registerAll() {
        DSLOperatorRegistry.register("Math.add") { input, _ ->
            val list = input as? List<*> ?: return@register 0.0
            list.sumOf { (it as? Number)?.toDouble() ?: 0.0 }
        }

        DSLOperatorRegistry.register("Math.subtract") { input, _ ->
            val list = input as? List<*> ?: return@register 0.0
            val nums = list.mapNotNull { (it as? Number)?.toDouble() }
            if (nums.isEmpty()) return@register 0.0
            nums.drop(1).fold(nums.first()) { acc, d -> acc - d }
        }

        DSLOperatorRegistry.register("Math.multiply") { input, _ ->
            val list = input as? List<*> ?: return@register 0.0
            list.mapNotNull { (it as? Number)?.toDouble() }.fold(1.0) { acc, d -> acc * d }
        }

        DSLOperatorRegistry.register("Math.divide") { input, _ ->
            val list = input as? List<*> ?: return@register 0.0
            val nums = list.mapNotNull { (it as? Number)?.toDouble() }
            if (nums.size != 2 || nums[1] == 0.0) return@register 0.0
            nums[0] / nums[1]
        }

        DSLOperatorRegistry.register("Math.mod") { input, _ ->
            val list = input as? List<*> ?: return@register 0
            val a = (list.getOrNull(0) as? Number)?.toInt() ?: return@register 0
            val b = (list.getOrNull(1) as? Number)?.toInt() ?: return@register 0
            if (b == 0) 0 else a % b
        }

        DSLOperatorRegistry.register("Math.random") { input, context ->
            val args = input as? List<*> ?: return@register 0
            if (args.size < 2) return@register 0
            val min = (DSLExpression.evaluate(args[0], context) as? Number)?.toDouble() ?: 0.0
            val max = (DSLExpression.evaluate(args[1], context) as? Number)?.toDouble() ?: 0.0
            if (min > max) Random.nextDouble(max, min) else Random.nextDouble(min, max)
        }
    }
}
