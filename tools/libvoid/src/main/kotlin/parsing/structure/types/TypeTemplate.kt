package parsing.structure.types

class TypeTemplate(val base: Type, val args: List<Type>): Type {
    override fun toString(): String {
        val arg = args.joinToString(separator = ",")
        return "$base<$args>"
    }
}