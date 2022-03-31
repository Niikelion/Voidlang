package parsing.structure.variables

import parsing.structure.types.Type

class Variable(val type: Type, val name: String) {
    override fun toString(): String {
        return "$type $name"
    }
}