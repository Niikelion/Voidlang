package parsing.structure

import parsing.structure.variables.CStyleVariable
import parsing.structure.variables.VariableDeclaration

class Module(val name: String): Token {
    private val imports = mutableListOf<String>()
    private val functions = mutableListOf<Function>()
    private val variableDeclarations = mutableListOf<VariableDeclaration>()

    fun import(module: String) {
        imports.add(module)
    }

    fun registerFunction(func: Function) {
        functions.add(func)
    }

    fun registerVariableDecl(variableDecl: VariableDeclaration) {
        variableDeclarations.add(variableDecl)
    }

    override fun readable(pad: Int): String {
        val imports = "import " + imports.toList().joinToString(separator = ", ")
        val functions = functions.toList().joinToString(separator = "\n") { func -> func.readable(pad+1) }
        val vars = variableDeclarations.toList().map { decl -> decl.getVariables() }.flatten().joinToString(separator = "\n") { variable -> padding(pad+1) + variable }
        return padding(pad) + "module $name" +
                if (this.imports.isNotEmpty()) "\n$imports" else "" +
                if (this.functions.isNotEmpty()) "\n$functions" else "" +
                if (variableDeclarations.isNotEmpty()) "\n$vars" else ""
    }
}