package parsing.structure.variables

import org.antlr.v4.runtime.ParserRuleContext

class InvalidVariableDeclaration: VariableDeclaration {
    override fun getVariables(): List<Variable> {
        return listOf()
    }
}