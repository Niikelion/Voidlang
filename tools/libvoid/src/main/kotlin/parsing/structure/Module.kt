package parsing.structure

import parsing.structure.variables.CStyleVariable

class Module(val name: String): Token {
    val imports = mutableListOf<String>()
    val functions = mutableListOf<Function>()
    val variables = mutableListOf<CStyleVariable>()

    fun registerFunction(func: Function) {
        functions.add(func)
    }

    fun registerVariable(variable: CStyleVariable) {
        variables.add(variable)
    }

    override fun readable(pad: Int): String {
        val imprts = "import " + imports.toList().joinToString(separator = ", ")
        val funcs = functions.toList().joinToString(separator = "\n") { func -> func.readable(pad+1) }
        val vars = variables.toList().joinToString(separator = "\n") { variable -> variable.readable(pad+1) }
        return padding(pad) + "module $name" +
                if (imports.isNotEmpty()) "\n$imprts" else "" +
                if (functions.isNotEmpty()) "\n$funcs" else "" +
                if (variables.isNotEmpty()) "\n$vars" else ""
    }
}