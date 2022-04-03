package parsing.structure.variables

import parsing.structure.Member
import parsing.structure.types.Type
import parsing.structure.values.Value

class SimpleVariableDeclaration(val type: Type, variables: List<SubDecl>): VariableDeclaration {
    class SubDecl(val name: String, val value: Value? = null) {
        override fun toString(): String {
            return name + (value ?. let { " = $value" } ?: "")
        }
    }

    val declaredVariables = variables.map { v -> Member(type, v.name, v.value) }

    override fun getVariables(): List<Variable> {
        return declaredVariables.map { v -> Variable(type, v.name) }
    }
}