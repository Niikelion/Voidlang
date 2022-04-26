package parsing.structure.variables

import parsing.structure.types.TypeAuto
import parsing.structure.values.Value

class VariableTupleDeconstruction(val members: List<String>, val value: Value): VariableDeclaration {

    override fun getVariables(): List<Variable> {
        return members.map { m -> Variable(TypeAuto(), m) }
    }

    override fun toString(): String {
        return members.joinToString("\n") { "${TypeAuto()} $it = ($value).$it" }
    }
}