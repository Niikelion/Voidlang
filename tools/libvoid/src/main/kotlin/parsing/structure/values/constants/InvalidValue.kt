package parsing.structure.values.constants

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.values.Value

class InvalidValue(val ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return ":invalid:"
    }
}