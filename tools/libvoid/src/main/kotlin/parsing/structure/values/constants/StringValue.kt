package parsing.structure.values.constants

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.values.Value
import kotlin.String

class StringValue(val value: String, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return "string(\"$value\")"
    }
}