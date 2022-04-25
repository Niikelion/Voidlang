package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.expressions.Expression
import parsing.structure.types.Type

class LambdaFunction(val args: List<ArgDef>, val returnType: Type, val body: List<Expression>, ctx: ParserRuleContext): Value(ctx) {
    class ArgDef(val type: Type, val name: String) {
        override fun toString(): String {
            return "$type $name"
        }
    }

    override fun toString(): String {
        val joinedArgs = args.joinToString(", ")
        val joinedExpressions = body.joinToString("; ")
        return "($joinedArgs): $returnType -> {$joinedExpressions}"
    }
}