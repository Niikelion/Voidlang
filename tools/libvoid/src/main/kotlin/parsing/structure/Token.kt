package parsing.structure

interface Token {
    fun readable(): String {
        return readable(0)
    }

    fun readable(pad: Int): String {
        return "\t".repeat(pad) + toString()
    }
}