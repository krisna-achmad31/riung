import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// M7 Task 5 — baca android/key.properties kalau ada (lihat
// docs/release-signing.md). File ini TIDAK di-commit (lihat .gitignore),
// jadi build debug/CI tanpa keystore tetap jalan lewat fallback ke
// signingConfigs.debug di buildTypes.release di bawah.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.riung.riung"
    // M7 Task 3: dipatok manual (bukan flutter.compileSdkVersion) supaya
    // versi rilis stabil & tidak diam-diam berubah tiap Flutter SDK di-update.
    // compileSdk = 36, BUKAN 34 seperti diminta — beberapa plugin (Firebase,
    // permission_handler, androidx.core, dst) mewajibkan compileSdk 35/36,
    // build gagal keras di compileSdk 34 (lihat error checkReleaseAarMetadata).
    // compileSdk cuma menentukan API compile-time yang tersedia, BUKAN
    // perilaku runtime — jadi ini aman dinaikkan sendiri tanpa mengubah
    // targetSdk 34 yang memang diminta eksplisit (itu yang menentukan
    // perilaku runtime & yang Play Store syaratkan minimalnya).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (Fix 2/3) butuh ini diaktifkan —
        // dia memakai java.time API lewat desugaring buat scheduling.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.riung.riung"
        // M7 Task 3: targetSdk 34, versionCode/Name mengikuti rilis pertama Play Store.
        // minSdk 26: syarat Health Connect (data tidur dari jam tangan).
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // M7 Task 4: shrink & obfuscate rilis (lihat proguard-rules.pro).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // M7 Task 5: signingConfig "release" dibaca dari android/key.properties
            // kalau file itu ada (lihat blok signingConfigs & docs/release-signing.md);
            // fallback ke kunci debug supaya `flutter build apk --release` tetap
            // jalan sebelum keystore sungguhan dibuat.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Pasangan isCoreLibraryDesugaringEnabled di atas.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
