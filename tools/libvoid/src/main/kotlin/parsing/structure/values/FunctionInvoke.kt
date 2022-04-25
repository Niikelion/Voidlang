package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext

class FunctionInvoke(val function: Value, val args: List<Value>, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        val joinedArgs = args.joinToString(", ")
        return "$function($joinedArgs)"
    }
}