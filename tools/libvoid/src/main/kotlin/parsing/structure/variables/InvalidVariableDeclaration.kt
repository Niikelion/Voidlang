package parsing.structure.variables

class InvalidVariableDeclaration: VariableDeclaration {
    override fun getVariables(): List<Variable> {
        return listOf()
    }

    override fun toString(): String {
        return ""
    }
}