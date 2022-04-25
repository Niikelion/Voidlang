package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class TupleValue(val values: List<Value>, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        val joinedValues = values.joinToString(", ")
        return "($joinedValues)"
    }
}