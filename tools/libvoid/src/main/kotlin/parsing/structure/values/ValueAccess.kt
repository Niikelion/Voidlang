package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class ValueAccess(val target: Value, val property: String, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return "$target.$property"
    }
}