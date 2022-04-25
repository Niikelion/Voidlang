package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.types.Type

class ValueCast(val source: Value, val type: Type, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        return "$source as $type"
    }
}