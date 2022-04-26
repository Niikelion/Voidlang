package parsing.structure.variables

import parsing.structure.Member
import parsing.structure.types.Type

class SimpleVariableDeclaration(val type: Type, variables: List<VarSubDecl>): VariableDeclaration {
    val declaredVariables = variables.map { v -> Member(type, v.name, v.value) }

    override fun getVariables(): List<Variable> {
        return declaredVariables.map { v -> Variable(type, v.name) }
    }

    override fun toString(): String {
        return declaredVariables.joinToString("\n") {
            "${it.type} ${it.name}" + (it.initialValue ?. let { v -> " = $v" } ?: "")
        }
    }
}