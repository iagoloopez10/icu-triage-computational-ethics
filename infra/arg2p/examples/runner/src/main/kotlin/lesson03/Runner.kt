package lesson03

import it.unibo.tuprolog.argumentation.core.Arg2pSolverFactory
import it.unibo.tuprolog.argumentation.core.libs.basic.FlagsBuilder
import java.nio.file.Files
import java.nio.file.Path

fun main(args: Array<String>) {
    val programPath = if (args.isNotEmpty()) args[0] else "../01-conflicting-duties.arg2p"
    val file = resolveInput(programPath)

    require(Files.exists(file)) {
        "Example file not found: $programPath"
    }

    val source = Files.readString(file)
    val result = Arg2pSolverFactory.evaluate(source, FlagsBuilder())
    val graph = result.first()

    println("=== Lesson 3 Defeasible Reasoning Runner ===")
    println("Input file: $programPath")
    println("Computed labellings:")
    graph.labellings.forEach {
        println("${it.label} -> ${it.argument.conclusion}")
    }
}

private fun resolveInput(programPath: String): Path {
    val direct = Path.of(programPath)
    if (Files.exists(direct)) {
        return direct
    }

    if (programPath.startsWith("examples/")) {
        val nested = Path.of("..", programPath.removePrefix("examples/"))
        if (Files.exists(nested)) {
            return nested
        }
    }

    return direct
}
