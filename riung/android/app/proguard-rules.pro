# M7 Task 4 — ProGuard/R8 keep rules untuk rilis (isMinifyEnabled/isShrinkResources
# aktif di buildTypes.release, lihat build.gradle.kts). Flutter engine sendiri
# sudah otomatis di-keep oleh Flutter Gradle Plugin; rules di bawah cuma untuk
# plugin pihak ketiga yang dipakai app ini dan rawan kena strip/obfuscate
# karena akses lewat refleksi atau JSON (de)serialization.

# Firebase (Auth, Firestore, Remote Config, Analytics, Crashlytics)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore memetakan field POJO lewat refleksi kalau ada model custom
# (app ini pakai Map<String,dynamic> manual di sisi Dart, tapi rule ini
# tetap dijaga untuk model internal SDK-nya sendiri).
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.firestore.** { *; }

# google-services / Play Services config
-keep class com.google.android.gms.common.** { *; }

# flutter_local_notifications — pakai GSON-style reflection untuk payload
# notifikasi terjadwal & receiver BroadcastReceiver-nya.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# in_app_purchase (Play Billing)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# flutter_svg (vector_graphics runtime)
-keep class dev.flutter.plugins.flutter_svg.** { *; }

# just_audio / ExoPlayer (androidx.media3)
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.ryanheise.just_audio.** { *; }

# Catatan: app ini pakai sqflite (bukan Isar/Drift-native-binding) untuk
# persistence lokal — tidak ada isar_flutter_libs/drift native binding di
# pubspec.yaml, jadi tidak ada rule khusus untuk itu di sini.
