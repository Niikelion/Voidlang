package parsing.structure.variables

import parsing.structure.Token
import parsing.structure.types.Type
import parsing.structure.values.Value

class CStyleVariable(val name: String, val type: Type? = null, val value: Value? = null): Token {
    override fun readable(pad: Int): String {
        return padding(pad) + "$type $name" + (value?.toString() ?: "")
    }
}