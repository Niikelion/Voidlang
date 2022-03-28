package parsing.structure.values.constants

import parsing.structure.values.Value
import kotlin.String

class String(val value: kotlin.String): Value {
    override fun toString(): String {
        return "\"$value\""//TODO: better printing
    }
}