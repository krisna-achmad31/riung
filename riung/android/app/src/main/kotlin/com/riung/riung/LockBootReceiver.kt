package com.riung.riung

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Settings

/**
 * Nyalakan lagi pemantau kunci setelah perangkat restart / app diperbarui,
 * setelah task Riung dihapus dari recents, dan dari watchdog berkala.
 */
class LockBootReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_RESTART = "com.riung.riung.action.RESTART_LOCK"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val config = LockConfig.load(context) ?: return
        if (config.enabled && config.entries.isNotEmpty() && Settings.canDrawOverlays(context)) {
            AppLockService.start(context)
        }
    }
}
