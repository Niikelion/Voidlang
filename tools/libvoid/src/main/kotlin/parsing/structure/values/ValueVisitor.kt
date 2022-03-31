package parsing.structure.values

import VoidParserBaseVisitor
import VoidParser

class ValueVisitor: VoidParserBaseVisitor<Value>() {
    fun getValue(ctx: VoidParser.ValueExpressionContext?): Value? {
        return ctx ?. let { visit(ctx) }
    }
}