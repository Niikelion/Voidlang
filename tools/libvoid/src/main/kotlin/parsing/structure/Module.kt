package parsing.structure

import parsing.structure.expressions.Expression

class Module(val name: String): Token {
    val expressions = mutableListOf<Expression>()
    val imports = mutableListOf<String>()

    override fun readable(pad: Int): String {
        val padding = "\t".repeat(pad)
        val imprts = "import " + imports.toList().joinToString(separator = ", ")
        val exprs = expressions.toList().joinToString("\n") { x -> x.readable(pad + 1) }
        return "${padding}module $name" +
                if (imports.isNotEmpty()) "\n$imprts" else "" +
                if (expressions.isNotEmpty()) "\n$exprs" else ""
    }

    fun isValid(): Boolean {
        return true
    }
}