package parsing.structure.expressions

import org.antlr.v4.runtime.ParserRuleContext
import parsing.structure.variables.VariableDeclaration

class VariableDeclarationExp(val declaration: VariableDeclaration, ctx: ParserRuleContext): Expression(ctx) {
    override fun toString(): String {
        return declaration.toString()
    }
}