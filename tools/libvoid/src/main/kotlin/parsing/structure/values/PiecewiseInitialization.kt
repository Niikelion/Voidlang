package parsing.structure.values

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.types.Type
import parsing.structure.variables.VarSubDecl

class PiecewiseInitialization(val type: Type, val members: List<VarSubDecl>, ctx: ParserRuleContext): Value(ctx) {
    override fun toString(): String {
        val mes = members.joinToString(", ") { v -> ".$v" }
        return "$type($mes)"
    }
}