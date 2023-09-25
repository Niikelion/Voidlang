package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.expressions.Block
import parsing.structure.types.Type
import parsing.structure.types.TypeAuto

class Function(val args: List<ArgDef>, val returnType: Type, val body: Block, val isLambda: Boolean, ctx: ParserRuleContext): Value(ctx) {
    class ArgDef(val type: Type, val name: String) {
        override fun toString(): String {
            return "$type $name"
        }
    }

    override fun toString(): String {
        val joinedArgs = args.joinToString(", ")
        val joinedExpressions = body.expressions.joinToString("; ")
        val type = when(returnType) {
            is TypeAuto -> ""
            else -> returnType.toString()
        }
        return "$type ($joinedArgs) -> {$joinedExpressions}"
    }
}