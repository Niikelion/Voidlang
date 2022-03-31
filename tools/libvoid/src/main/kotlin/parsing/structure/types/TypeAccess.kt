package parsing.structure.types

class TypeAccess(val parent: Type, var child: Type): Type {
    override fun toString(): String {
        return "$parent.$child"
    }
}