package com.riung.riung

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent

/**
 * Penjaga kunci Aplikasi Beku berbasis Aksesibilitas. Dipilih karena sistem
 * Android sendiri yang menjaga service ini tetap hidup dan mengikatnya lagi
 * setelah proses mati (mis. Riung digeser dari recents), sesuatu yang tidak
 * bisa dijamin foreground service biasa di sebagian OEM (XOS, MIUI, dll).
 *
 * BATAS PRIVASI (sengaja sempit):
 *  - `canRetrieveWindowContent="false"`: TIDAK bisa membaca isi layar apa pun.
 *  - Hanya menerima event perpindahan jendela (TYPE_WINDOW_STATE_CHANGED)
 *    dan, lewat [applyPackages], HANYA dari aplikasi yang dibekukan pengguna.
 *  - Yang dibaca cuma nama package aplikasi yang terbuka; keputusan memakai
 *    menit pemakaian dari UsageStats. Tidak ada data yang dikirim ke mana pun.
 */
class AppLockAccessibilityService : AccessibilityService() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var engine: LockEngine

    private val tick = object : Runnable {
        override fun run() {
            try {
                engine.tick()
            } catch (_: Throwable) {
                // Satu tick gagal tidak boleh menjatuhkan service.
            }
            handler.postDelayed(this, TICK_MS)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        engine = LockEngine(this)
        instance = this
        applyPackages()
        handler.removeCallbacks(tick)
        handler.post(tick)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        // Masuk ke aplikasi beku: cek segera, tidak menunggu tick berikutnya.
        try {
            engine.invalidate()
            engine.tick()
        } catch (_: Throwable) {
            // diabaikan, tick berikutnya mencoba lagi
        }
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        handler.removeCallbacks(tick)
        if (instance === this) instance = null
        return super.onUnbind(intent)
    }

    /** Batasi event hanya dari aplikasi yang dibekukan (tanpa itu: hanya Riung sendiri). */
    fun applyPackages() {
        val pkgs = engine.monitoredPackages()
        val info = serviceInfo ?: return
        info.packageNames = if (pkgs.isEmpty()) arrayOf(packageName) else pkgs.toTypedArray()
        serviceInfo = info
        engine.invalidate()
    }

    companion object {
        private const val TICK_MS = 1000L

        @Volatile
        var instance: AppLockAccessibilityService? = null

        /** Apakah pengguna sudah mengaktifkan Riung di Pengaturan > Aksesibilitas. */
        fun isEnabled(context: Context): Boolean {
            val expected = ComponentName(context, AppLockAccessibilityService::class.java).flattenToString()
            val setting = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: return false
            return setting.split(':').any { it.equals(expected, ignoreCase = true) }
        }
    }
}
