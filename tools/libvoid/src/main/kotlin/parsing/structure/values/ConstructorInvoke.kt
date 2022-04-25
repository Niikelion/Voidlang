package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.types.Type

class ConstructorInvoke(val type: Type, val args: List<Value>, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        val argsStr = args.joinToString(", ")
        return "$type($argsStr)"
    }
}