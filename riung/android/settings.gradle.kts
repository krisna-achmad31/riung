pluginManagement {
    val flutterSdkPath =
        run {
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
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    // M7 Task 8 — wajib supaya firebase_crashlytics tidak crash saat start
    // (plugin ini yang meng-generate resource "build ID" yang dibutuhkan
    // Crashlytics native SDK; tanpa ini app crash fatal di
    // FirebaseInitProvider begitu proses dimulai, lihat commit message).
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
}

include(":app")
