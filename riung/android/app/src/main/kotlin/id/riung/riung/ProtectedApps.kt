package id.riung.riung

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Telephony
import android.telecom.TelecomManager

/**
 * Aplikasi yang tidak pernah boleh dibekukan: jalur komunikasi, penunjuk
 * jalan, keuangan, kesehatan, dan bagian penting HP. Satu-satunya sumber
 * daftar ini; pemilih di Flutter membacanya lewat [installedApps], dan
 * [LockEngine] memeriksanya lagi supaya data lama pun tidak bisa mengunci.
 */
object ProtectedApps {
    private const val COMMUNICATION = "communication"
    private const val NAVIGATION = "navigation"
    private const val FINANCE = "finance"
    private const val HEALTH = "health"
    private const val SYSTEM = "system"

    private val KNOWN = mapOf(
        COMMUNICATION to setOf(
            "com.android.dialer", "com.google.android.dialer", "com.samsung.android.dialer",
            "com.android.contacts", "com.google.android.contacts", "com.samsung.android.app.contacts",
            "com.android.mms", "com.google.android.apps.messaging", "com.samsung.android.messaging",
            "com.whatsapp", "com.whatsapp.w4b", "org.telegram.messenger", "org.thoughtcrime.securesms",
            "jp.naver.line.android", "com.facebook.orca", "com.google.android.apps.meetings",
            "com.google.android.apps.tachyon", "us.zoom.videomeetings",
        ),
        NAVIGATION to setOf("com.google.android.apps.maps", "com.waze"),
        FINANCE to setOf(
            "com.bca", "com.bca.mybca.omni.android", "id.co.bri.brimo", "id.bmri.livin", "src.com.bni",
            "com.jago.digitalBanking", "id.co.bankbkemobile.digitalbank", "id.dana", "ovo.id",
            "com.gojek.gopay", "com.shopeepay.id", "com.telkom.mwallet",
            "com.google.android.apps.walletnfcrel",
        ),
        HEALTH to setOf(
            "com.google.android.apps.fitness", "com.sec.android.app.shealth", "com.linkdokter.halodoc.android",
            "com.alodokter.android", "com.telkom.tracencare", "app.bpjs.mobile",
        ),
        SYSTEM to setOf(
            "com.android.settings", "com.google.android.calendar", "com.samsung.android.calendar",
            "com.google.android.deskclock", "com.sec.android.app.clockpackage",
        ),
    )

    /** Alasan [pkg] dilindungi, atau null kalau boleh dibekukan. */
    fun reason(context: Context, pkg: String): String? {
        if (pkg == context.packageName) return SYSTEM
        KNOWN.entries.firstOrNull { pkg in it.value }?.let { return it.key }
        val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
        if (pkg == telecom?.defaultDialerPackage || pkg == Telephony.Sms.getDefaultSmsPackage(context)) return COMMUNICATION
        val category = try {
            context.packageManager.getApplicationInfo(pkg, 0).category
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }
        return if (category == ApplicationInfo.CATEGORY_MAPS) NAVIGATION else null
    }

    /** Semua aplikasi yang muncul di launcher, sudah diberi label alasan. */
    fun installedApps(context: Context): List<Map<String, Any?>> {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(launcher, 0)
            .distinctBy { it.activityInfo.packageName }
            .filter { it.activityInfo.packageName != context.packageName }
            .map {
                val pkg = it.activityInfo.packageName
                mapOf("package" to pkg, "name" to it.loadLabel(pm).toString(), "protected" to reason(context, pkg))
            }
            .sortedBy { (it["name"] as String).lowercase() }
    }
}
