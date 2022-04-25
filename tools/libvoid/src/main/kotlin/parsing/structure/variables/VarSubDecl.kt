package parsing.structure.variables

import parsing.structure.values.Value

class VarSubDecl(val name: String, val value: Value? = null) {
    override fun toString(): String {
        return name + (value ?. let { " = $value" } ?: "")
    }
}