package parsing.structure.expressions

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.values.Value

class ReturnExpression(val value: Value?, ctx: ParserRuleContext): Expression(ctx) {
    override fun toString(): String {
        return "return $value"
    }
}