package parsing.structure

import parsing.structure.expressions.Expression
import parsing.structure.types.Type

class Function(val name: String, val returnType: Type, val arguments: List<Pair<Type, String>>): Token {
    val body = mutableListOf<Expression>()

    override fun readable(pad: Int): String {
        val args = arguments.joinToString(separator = ", ") { arg -> "${arg.first} ${arg.second}" }
        return padding(pad) + "$returnType $name()"
    }
}