package com.riung.riung

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Calendar

/**
 * Jembatan native buat Aplikasi Beku (M6) — baca menit pemakaian aplikasi
 * lain hari ini lewat UsageStatsManager, dan cek/minta izin "Akses data
 * penggunaan" (PACKAGE_USAGE_STATS, app-op khusus yang cuma bisa
 * diaktifkan lewat halaman Settings, bukan dialog izin biasa).
 */
class AppUsageMethodChannel(private val context: Context, private val activity: android.app.Activity? = null) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.riung.riung/app_usage"
    }

    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "openUsageAccessSettings" -> {
                openUsageAccessSettings()
                result.success(null)
            }
            "getUsageMinutesToday" -> {
                @Suppress("UNCHECKED_CAST")
                val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                result.success(getUsageMinutesToday(packageNames))
            }
            "hasOverlayAccess" -> result.success(Settings.canDrawOverlays(context))
            "hasAccessibilityAccess" -> result.success(AppLockAccessibilityService.isEnabled(context))
            "openAccessibilitySettings" -> {
                openAccessibilitySettings()
                result.success(null)
            }
            "openOverlaySettings" -> {
                openOverlaySettings()
                result.success(null)
            }
            "syncLockConfig" -> {
                syncLockConfig(call)
                result.success(null)
            }
            "consumeLockPackage" -> result.success(LockConfig.consumePending(context))
            "goHome" -> {
                goHome()
                result.success(null)
            }
            "moveToBack" -> {
                activity?.moveTaskToBack(true)
                result.success(null)
            }
            "isLockServiceRunning" -> result.success(isLockServiceRunning())
            else -> result.notImplemented()
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            // Beberapa OEM tidak punya layar ini di lokasi yang sama —
            // fallback ke detail app sendiri.
            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            fallback.data = Uri.parse("package:" + context.packageName)
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallback)
        }
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            val fallback = Intent(Settings.ACTION_SETTINGS)
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallback)
        }
    }

    private fun openOverlaySettings() {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + context.packageName))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            fallback.data = Uri.parse("package:" + context.packageName)
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallback)
        }
    }

    /** Simpan konfigurasi kunci dari Flutter, lalu nyalakan/matikan service pemantau. */
    private fun syncLockConfig(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val date = call.argument<String>("date") ?: ""
        val notifTitle = call.argument<String>("notifTitle") ?: "Aplikasi Beku"
        val notifBody = call.argument<String>("notifBody") ?: ""
        @Suppress("UNCHECKED_CAST")
        val raw = call.argument<List<Map<String, Any>>>("entries") ?: emptyList()
        val entries = mutableMapOf<String, LockConfig.Entry>()
        for (e in raw) {
            entries[e["package"] as String] = LockConfig.Entry((e["base"] as Number).toInt(), (e["extra"] as Number).toInt())
        }
        val config = LockConfig(enabled, date, entries, notifTitle, notifBody)
        LockConfig.save(context, config)
        // Penjaga utama = AccessibilityService (kalau sudah diaktifkan pengguna);
        // dia hanya perlu diberi tahu daftar package terbaru.
        AppLockAccessibilityService.instance?.applyPackages()
    }

    /** Kembali ke layar utama (launcher) — dipakai tombol "Kembali"/"Tutup" saat app dikunci. */
    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    @Suppress("DEPRECATION")
    private fun isLockServiceRunning(): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        return am.getRunningServices(Int.MAX_VALUE).any { it.service.className == AppLockService::class.java.name }
    }

    /** Menit pemakaian tiap package sejak tengah malam waktu perangkat. */
    private fun getUsageMinutesToday(packageNames: List<String>): Map<String, Int> {
        if (!hasUsageAccess() || packageNames.isEmpty()) return packageNames.associateWith { 0 }
        return UsageCalculator.minutesToday(context, packageNames)
    }
}
