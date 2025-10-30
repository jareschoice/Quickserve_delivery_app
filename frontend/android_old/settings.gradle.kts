pluginManagement {
    // ✅ Correct path to your Flutter SDK gradle tools
    includeBuild("C:/src/flutter/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.application") version "8.2.2"
        id("org.jetbrains.kotlin.android") version "2.0.21"
        id("dev.flutter.flutter-gradle-plugin") version "1.0.0"
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "quickserve
"
include(":app")
