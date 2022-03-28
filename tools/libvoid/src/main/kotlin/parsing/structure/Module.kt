package parsing.structure

import parsing.structure.expressions.Expression

class Module(val name: String): Token {
    val imports = mutableListOf<String>()
    val functions = mutableListOf<Function>()

    fun registerFunction(func: Function) {
        functions.add(func)
    }

    override fun readable(pad: Int): String {
        val imprts = "import " + imports.toList().joinToString(separator = ", ")
        val funcs = functions.toList().joinToString(separator = "\n") { func -> func.readable(pad+1) }
        return padding(pad) + "module $name" +
                if (imports.isNotEmpty()) "\n$imprts" else "" +
                if (functions.isNotEmpty()) "\n$funcs" else ""
    }
}