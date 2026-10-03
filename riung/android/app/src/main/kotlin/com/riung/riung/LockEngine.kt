package com.riung.riung

import android.content.Context
import android.content.Intent
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Inti keputusan kunci Aplikasi Beku, dipakai oleh service pemantau mana pun
 * (AccessibilityService = utama, foreground service = cadangan). Tiap [tick]
 * memeriksa aplikasi di depan lewat event UsageStats; kalau itu aplikasi
 * beku yang sudah melewati batas efektifnya hari ini, Riung dibuka di
 * depannya (layar jeda Flutter). TIDAK menggambar overlay apa pun.
 */
class LockEngine(private val context: Context) {
    private var snapshot: UsageCalculator.Snapshot? = null
    private var lastSnapshotAt = 0L
    private var lastEventCheckAt = 0L
    private var lastLaunchAt = 0L

    /** Package yang dipantau saat ini (kosong = kunci mati). */
    fun monitoredPackages(): Set<String> {
        val config = LockConfig.load(context) ?: return emptySet()
        return if (config.enabled) config.entries.keys else emptySet()
    }

    /** Paksa hitung ulang di tick berikutnya (mis. konfigurasi berubah). */
    fun invalidate() {
        snapshot = null
    }

    /** @return false kalau kunci tidak aktif lagi (pemanggil boleh berhenti). */
    fun tick(): Boolean {
        val config = LockConfig.load(context)
        if (config == null || !config.enabled || config.entries.isEmpty()) return false
        val now = System.currentTimeMillis()
        var snap = snapshot
        val switched = snap != null && UsageCalculator.hasActivityEventsSince(context, lastEventCheckAt)
        lastEventCheckAt = now
        if (snap == null || switched || now - lastSnapshotAt > SNAPSHOT_MS) {
            snap = UsageCalculator.snapshot(context, config.entries.keys)
            snapshot = snap
            lastSnapshotAt = now
        }
        val fg = snap.foregroundPackage ?: return true
        if (fg == context.packageName) return true
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
        val limit = config.limitMinutes(fg, today) ?: return true
        val usedMinutes = (snap.millisAt(fg, now) / 60000L).toInt()
        if (usedMinutes < limit) return true
        if (now - lastLaunchAt < RELAUNCH_MS) return true
        lastLaunchAt = now
        block(fg)
        return true
    }

    private fun block(pkg: String) {
        LockConfig.setPending(context, pkg)
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_LOCK_PACKAGE, pkg)
        }
        context.startActivity(intent)
        snapshot = null
    }

    companion object {
        const val EXTRA_LOCK_PACKAGE = "appbeku_lock_package"
        private const val SNAPSHOT_MS = 30000L
        private const val RELAUNCH_MS = 3000L
    }
}
