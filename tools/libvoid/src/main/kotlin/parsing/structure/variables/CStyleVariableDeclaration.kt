package parsing.structure.variables

import parsing.structure.types.Type
import parsing.structure.values.Value

class CStyleVariableDeclaration(private val type: Type, private val variables: List<SubDecl>): VariableDeclaration {
    class SubDecl(val name: String, val value: Value? = null) {
        override fun toString(): String {
            return name + (value ?. let { " = $value" } ?: "")
        }
    }

    fun getType(): Type {
        return type
    }

    fun getInitialValues(): List<Value?> {
        return variables.map { v -> v.value }
    }

    override fun getVariables(): List<Variable> {
        return variables.map { v -> Variable(type, v.name) }
    }
}