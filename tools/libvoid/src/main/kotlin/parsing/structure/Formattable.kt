package parsing.structure

interface Formattable {
    fun readable(): String {
        return readable(0)
    }

    fun padding(pad: Int): String {
        return "\t".repeat(pad)
    }

    fun readable(pad: Int): String {
        return "\t".repeat(pad) + toString()
    }
}