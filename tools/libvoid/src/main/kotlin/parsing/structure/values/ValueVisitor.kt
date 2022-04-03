package parsing.structure.values

import VoidParserBaseVisitor
import VoidParser
import parsing.structure.ErrorLogger
import parsing.structure.variables.Variable

class ValueVisitor(private val errorLogger: ErrorLogger): VoidParserBaseVisitor<Value?>() {
    fun getValue(ctx: VoidParser.ValueExpressionContext?): Value? {
        return ctx ?. let { visit(ctx) }
    }

    override fun visitVariableExpression(ctx: VoidParser.VariableExpressionContext?): Value? {
        return ctx ?. run {
            ctx.identifier()?.Name()?.let { VariableAccess(it.text) }
        }
    }
}