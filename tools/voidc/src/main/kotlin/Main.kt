package void.compiler

import parsing.Parser

class App {
    private val files = mutableListOf<String>()

    fun run() {
        val parser = Parser()

        val modules = if (files.isNotEmpty())
            files.mapNotNull { file -> parser.parseFile(file) }
        else {
            listOf(parser.parse(System.`in`))
        }

        parser.printErrors()
        parser.clearErrors()
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