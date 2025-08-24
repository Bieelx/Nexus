/*
 * Project-level Gradle build file (Kotlin DSL).
 * Keep only plugin declarations here. App/module plugins are applied in android/app/build.gradle(.kts).
 */

//plugins {
    // Android & Kotlin plugins declared here with versions but NOT applied at the root project.
    //id("com.android.application") version "8.8.0" apply false
    //id("com.android.library") version "8.8.0" apply false
    //id("org.jetbrains.kotlin.android") version "1.9.25" apply false

    // Flutter's Gradle integration.
    //id("dev.flutter.flutter-gradle-plugin") version "1.0.0"

    // Google Services plugin (for Firebase, etc.). Applied in the app module only.
    //id("com.google.gms.google-services") version "4.4.3" apply false
//}

// (Optional) Keep Flutter's shared build directory structure for subprojects.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}