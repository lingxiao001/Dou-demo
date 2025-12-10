plugins {
  id("org.jetbrains.kotlin.jvm")
  id("application")
}

repositories {
  mavenCentral()
}

dependencies {
  implementation("org.json:json:20231013")
  implementation("org.jcodec:jcodec:0.2.5")
  implementation("org.jcodec:jcodec-javase:0.2.5")
}

application {
  mainClass.set("CoverGeneratorKt")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
  kotlinOptions.jvmTarget = "1.8"
}

tasks.withType<org.gradle.api.tasks.compile.JavaCompile> {
  options.release.set(8)
}
