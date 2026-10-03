package com.riung.riung

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Pemantau Aplikasi Beku (mode "kunci"): service foreground yang tiap detik
 * mengecek aplikasi di depan. Kalau itu aplikasi yang dibekukan dan menit
 * pakainya hari ini sudah melewati batas, Riung dibuka di depannya (layar
 * interstisial Flutter: napas 1 menit gratis, atau buka waktu dengan koin).
 *
 * Membuka Activity dari background di Android 10+ hanya boleh kalau app
 * punya izin "Tampil di atas aplikasi lain" (SYSTEM_ALERT_WINDOW) — itu
 * sebabnya izin itu diminta. Service ini TIDAK menggambar overlay apa pun,
 * dan hanya berjalan selama user menyalakan kunci; mematikannya di
 * Pengaturan Aplikasi Beku menghentikan service seketika.
 */
class AppLockService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var snapshot: UsageCalculator.Snapshot? = null
    private var lastSnapshotAt = 0L
    private var lastEventCheckAt = 0L
    private var lastLaunchAt = 0L

    private val tick = object : Runnable {
        override fun run() {
            try {
                check()
            } catch (_: Throwable) {
                // Jangan pernah membuat service crash-loop gara-gara satu tick gagal.
            }
            handler.postDelayed(this, TICK_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val config = LockConfig.load(this)
        if (config == null || !config.enabled || config.entries.isEmpty() || !canRun()) {
            stopSelf()
            return START_NOT_STICKY
        }
        startInForeground(config)
        handler.removeCallbacks(tick)
        handler.post(tick)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tick)
        super.onDestroy()
    }

    /**
     * User menggeser Riung dari recents: sebagian OEM (mis. XOS) langsung
     * mematikan prosesnya beserta service ini tanpa menghidupkannya lagi.
     * Jadwalkan restart sebentar lagi; izin SYSTEM_ALERT_WINDOW (yang memang
     * diperlukan kunci) membolehkan foreground service dimulai dari background.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        scheduleRestart(this, delayMs = 1500L)
        super.onTaskRemoved(rootIntent)
    }

    private fun canRun(): Boolean = Settings.canDrawOverlays(this)

    private fun startInForeground(config: LockConfig) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Aplikasi Beku", NotificationManager.IMPORTANCE_MIN),
            )
        }
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL_ID) else Notification.Builder(this)
        val notification = builder
            .setContentTitle(config.notifTitle)
            .setContentText(config.notifBody)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(open)
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val type = if (Build.VERSION.SDK_INT >= 34) ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
            startForeground(NOTIF_ID, notification, type)
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }

    private fun check() {
        val config = LockConfig.load(this)
        if (config == null || !config.enabled || config.entries.isEmpty() || !canRun()) {
            stopSelf()
            return
        }
        val now = System.currentTimeMillis()
        // Hitung ulang penuh kalau ada perpindahan aplikasi sejak cek terakhir
        // (murah), atau tiap 30 detik sebagai jaring pengaman.
        var snap = snapshot
        val switched = snap != null && UsageCalculator.hasActivityEventsSince(this, lastEventCheckAt)
        lastEventCheckAt = now
        if (snap == null || switched || now - lastSnapshotAt > SNAPSHOT_MS) {
            snap = UsageCalculator.snapshot(this, config.entries.keys)
            snapshot = snap
            lastSnapshotAt = now
        }
        val fg = snap.foregroundPackage ?: return
        if (fg == packageName) return
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
        val limit = config.limitMinutes(fg, today) ?: return
        val usedMinutes = (snap.millisAt(fg, now) / 60000L).toInt()
        if (usedMinutes < limit) return
        if (now - lastLaunchAt < RELAUNCH_MS) return
        lastLaunchAt = now
        block(fg)
    }

    private fun block(pkg: String) {
        LockConfig.setPending(this, pkg)
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_LOCK_PACKAGE, pkg)
        }
        startActivity(intent)
        // Snapshot lama masih menganggap app itu di depan — paksa hitung ulang.
        snapshot = null
    }

    companion object {
        const val CHANNEL_ID = "appbeku_lock"
        const val NOTIF_ID = 4101
        const val EXTRA_LOCK_PACKAGE = "appbeku_lock_package"
        private const val TICK_MS = 1000L
        private const val SNAPSHOT_MS = 30000L
        private const val RELAUNCH_MS = 3000L

        private const val WATCHDOG_INTERVAL_MS = 15 * 60 * 1000L

        /** Hidupkan lagi service (kalau kunci masih aktif) setelah [delayMs]. */
        fun scheduleRestart(context: Context, delayMs: Long) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, LockBootReceiver::class.java).setAction(LockBootReceiver.ACTION_RESTART)
            val pi = PendingIntent.getBroadcast(
                context, 7, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            alarms.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + delayMs, pi)
        }

        /** Jaring pengaman: cek berkala apakah service masih hidup, kalau mati hidupkan lagi. */
        fun scheduleWatchdog(context: Context) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, LockBootReceiver::class.java).setAction(LockBootReceiver.ACTION_RESTART)
            val pi = PendingIntent.getBroadcast(
                context, 8, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            alarms.setInexactRepeating(
                android.app.AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + WATCHDOG_INTERVAL_MS,
                WATCHDOG_INTERVAL_MS,
                pi,
            )
        }

        fun cancelWatchdog(context: Context) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, LockBootReceiver::class.java).setAction(LockBootReceiver.ACTION_RESTART)
            val pi = PendingIntent.getBroadcast(
                context, 8, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            alarms.cancel(pi)
        }

        fun start(context: Context) {
            scheduleWatchdog(context)
            val intent = Intent(context, AppLockService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent) else context.startService(intent)
        }

        fun stop(context: Context) {
            cancelWatchdog(context)
            context.stopService(Intent(context, AppLockService::class.java))
        }
    }
}
