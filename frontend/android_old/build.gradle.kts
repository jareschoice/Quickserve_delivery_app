// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ✅ Firebase Google services classpath
        classpath("com.google.gms:google-services:4.3.15")
    }
}

plugins {
    // ✅ Add explicit versions here
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("dev.flutter.flutter-gradle-plugin") apply false // ✅ this was missing!
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
