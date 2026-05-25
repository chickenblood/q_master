buildscript {
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20")
        classpath("com.google.gms:google-services:4.4.4")
    }
}
plugins {
    id("com.android.application") version "9.2.1" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // firebase_ai 3.10.0 skips applying kotlin-android on AGP 9+, relying on built-in Kotlin.
    // Since we opt out of built-in Kotlin globally (for compatibility with plugins that apply
    // kotlin-android themselves), we inject it here before firebase_ai's build script runs.
    if (name == "firebase_ai" || name == "firebase_app_check") {
        apply(plugin = "org.jetbrains.kotlin.android")
        // FlutterFire plugins set javaVersion = 17; align Kotlin JVM target to match.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
