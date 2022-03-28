package compiling.structure

import java.io.OutputStreamWriter

interface Token {
    fun emit(output: OutputStreamWriter)
}