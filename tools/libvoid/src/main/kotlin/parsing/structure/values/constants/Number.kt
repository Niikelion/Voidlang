package parsing.structure.values.constants

import parsing.structure.values.Value
import kotlin.String

class Number(val value: Double): Value {
    override fun toString(): String {
        return "$value"//TODO: print number type
    }
}