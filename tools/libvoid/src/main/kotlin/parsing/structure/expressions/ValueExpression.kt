package parsing.structure.expressions

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.values.Value

class ValueExpression(val value: Value): Expression(value.getOrigin()) {
    override fun toString(): String {
        return value.toString()
    }
}