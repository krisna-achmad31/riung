package com.riung.riung

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity (bukan FlutterActivity) — wajib untuk local_auth
// (JurnalPINScreen opsi biometrik) karena BiometricPrompt Android butuh
// FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private val appUsageChannel = AppUsageMethodChannel(this, this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appUsageChannel.attach(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appUsageChannel.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
