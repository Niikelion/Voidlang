package void.compiler

import parsing.Parser
import parsing.structure.Module
import java.io.File

class App {
    val files = mutableListOf<String>()

    fun run() {
        val parser = Parser()
        val modules = files.mapNotNull { file -> parser.parseFile(file) }

        parser.printErrors()
        println("Modules:")
        println(modules.joinToString(separator = "\n-----\n") { module -> module.readable() })
    }

    fun addFile(file: String) {
        files.add(file)
    }
}

fun main(args: Array<String>) {
    val app = App()
    for (file in args)
        app.addFile(file)
    app.run()
}