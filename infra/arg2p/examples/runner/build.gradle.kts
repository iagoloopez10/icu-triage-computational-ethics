plugins {
    kotlin("jvm") version "2.3.0"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("it.unibo.tuprolog.argumentation:arg2p-jvm:0.15.0")
}

application {
    mainClass.set("lesson03.RunnerKt")
}

kotlin {
    jvmToolchain(21)
}
