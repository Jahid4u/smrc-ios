// Android build settings.
//
// IMPORTANT: this file (and the rest of android/) is checked in on purpose so
// that `flutter create .` NEVER has to be run again. Running that command
// regenerates the Android folder from Flutter's default template and wipes
// out the branded native splash (it drops a default
// drawable-v21/launch_background.xml which overrides ours on every real
// device, and resets styles.xml / AndroidManifest.xml / the applicationId).
// If the iOS folder is ever missing, generate ONLY that:
//     flutter create --platforms=ios .
//
// The Kotlin plugin version below is what fixes the
//     "Could not find method kotlin() ... on project ':jni'"
// build failure: package:jni's own android/build.gradle uses the Kotlin DSL,
// so a modern Kotlin Gradle plugin has to be resolvable from the root build.
// Flutter's older pinned default (1.8.x) does not provide it.
//
// The AGP version is pinned at 8.11.1 because the androidx libraries the
// plugins now pull in (androidx.core 1.18, androidx.activity 1.12,
// androidx.browser 1.9) refuse to build on anything older than AGP 8.9.1 and
// require compileSdk 36 — which is why app/build.gradle.kts sets
// compileSdk/targetSdk = 36. Downgrading any of these three together brings
// back "12 issues were found when checking AAR metadata".
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
