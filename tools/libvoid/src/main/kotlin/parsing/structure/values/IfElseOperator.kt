package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class IfElseOperator(val condition: Value, val trueVal: Value, val falseVal: Value, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return "$condition ? $trueVal : $falseVal"
    }
}