package com.riung.riung

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

/**
 * Hitung pemakaian aplikasi hari ini dari event UsageStats (RESUMED/PAUSED),
 * bukan dari `queryUsageStats` — yang terakhir baru memperbarui waktu app
 * yang sedang di depan setelah app itu keluar, jadi menit yang sedang
 * berjalan tidak ikut terhitung. Pakai event, kita tahu persis kapan tiap
 * app mulai dipakai dan bisa menghitung sesi yang masih terbuka.
 */
object UsageCalculator {
    /** Hasil hitung: milidetik tertutup per package + app yang sedang di depan. */
    class Snapshot(
        val closedMillis: Map<String, Long>,
        val foregroundPackage: String?,
        val foregroundSince: Long,
    ) {
        /** Total milidetik untuk [pkg] sampai [now], termasuk sesi yang masih terbuka. */
        fun millisAt(pkg: String, now: Long): Long {
            val closed = closedMillis[pkg] ?: 0L
            return if (pkg == foregroundPackage) closed + (now - foregroundSince).coerceAtLeast(0L) else closed
        }
    }

    fun startOfDay(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    fun snapshot(context: Context, packages: Collection<String>): Snapshot {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(startOfDay(), now)
        val event = UsageEvents.Event()
        val closed = mutableMapOf<String, Long>()
        val openSince = mutableMapOf<String, Long>()
        val wanted = packages.toHashSet()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    if (!openSince.containsKey(pkg)) openSince[pkg] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.ACTIVITY_STOPPED -> {
                    val start = openSince.remove(pkg)
                    if (start != null && (wanted.isEmpty() || pkg in wanted)) {
                        closed[pkg] = (closed[pkg] ?: 0L) + (event.timeStamp - start).coerceAtLeast(0L)
                    }
                }
                UsageEvents.Event.DEVICE_SHUTDOWN -> openSince.clear()
            }
        }
        // Yang paling baru dibuka dan belum di-pause = yang sedang di depan.
        val fg = openSince.maxByOrNull { it.value }
        return Snapshot(closed, fg?.key, fg?.value ?: now)
    }

    /** Apakah ada perpindahan aplikasi (RESUMED/PAUSED) sejak [since] — murah, dipakai tiap detik. */
    fun hasActivityEventsSince(context: Context, since: Long): Boolean {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(since, System.currentTimeMillis())
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED || event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) return true
        }
        return false
    }

    /** Menit pemakaian hari ini per package (dipakai rekap di Flutter). */
    fun minutesToday(context: Context, packages: List<String>): Map<String, Int> {
        val snap = snapshot(context, packages)
        val now = System.currentTimeMillis()
        return packages.associateWith { (snap.millisAt(it, now) / 60000L).toInt() }
    }
}
