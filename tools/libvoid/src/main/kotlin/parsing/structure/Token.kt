package parsing.structure

import Positional

interface Token {
    fun getOrigin(): Positional
}