package parsing.structure

import parsing.structure.types.Type
import parsing.structure.values.Value

class Member(val type: Type, val name: String, val initialValue: Value? = null) {
    override fun toString(): String {
        return "$type $name" + (initialValue?.let { " = $it" } ?: "")
    }
}