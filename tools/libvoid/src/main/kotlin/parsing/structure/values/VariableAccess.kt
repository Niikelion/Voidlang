package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class VariableAccess(val name: String, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return name
    }
}