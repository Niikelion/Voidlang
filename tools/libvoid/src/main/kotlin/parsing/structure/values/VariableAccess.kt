package parsing.structure.values

class VariableAccess(val name: String): Value {
    override fun toString(): String {
        return name
    }
}