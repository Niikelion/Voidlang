package parsing.structure.types

import parsing.structure.Member
import parsing.structure.values.Value

class LambdaObjectType(val members: List<Member>): Type {
    override fun toString(): String {
        val members = members.joinToString(", ")
        return "{ $members }"
    }
}