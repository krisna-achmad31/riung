package com.riung.riung

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Konfigurasi kunci Aplikasi Beku — didorong dari Flutter tiap kali berubah
 * (lihat `AppBekuNotifier`), disimpan di SharedPreferences native supaya
 * service pemantau tetap jalan walau UI Flutter tidak aktif.
 *
 * Batas efektif = batas harian + menit ekstra yang dibeli HARI INI. Menit
 * ekstra hanya berlaku kalau [date] == hari ini, jadi setelah lewat tengah
 * malam batas kembali ke nilai dasar walau Flutter belum sempat sinkron.
 */
class LockConfig(
    val enabled: Boolean,
    val date: String,
    val entries: Map<String, Entry>,
    val notifTitle: String,
    val notifBody: String,
) {
    class Entry(val baseMinutes: Int, val extraMinutes: Int)

    fun limitMinutes(pkg: String, today: String): Int? {
        val entry = entries[pkg] ?: return null
        return entry.baseMinutes + if (date == today) entry.extraMinutes else 0
    }

    fun toJson(): String {
        val root = JSONObject()
        root.put("enabled", enabled)
        root.put("date", date)
        root.put("notifTitle", notifTitle)
        root.put("notifBody", notifBody)
        val arr = JSONArray()
        for ((pkg, e) in entries) {
            arr.put(JSONObject().put("pkg", pkg).put("base", e.baseMinutes).put("extra", e.extraMinutes))
        }
        root.put("entries", arr)
        return root.toString()
    }

    companion object {
        private const val PREFS = "riung_lock"
        private const val KEY = "config"
        private const val KEY_PENDING = "pending_package"

        fun load(context: Context): LockConfig? {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
            return try {
                val root = JSONObject(raw)
                val arr = root.getJSONArray("entries")
                val map = mutableMapOf<String, Entry>()
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    map[o.getString("pkg")] = Entry(o.getInt("base"), o.optInt("extra", 0))
                }
                LockConfig(
                    root.optBoolean("enabled", false),
                    root.optString("date", ""),
                    map,
                    root.optString("notifTitle", "Aplikasi Beku"),
                    root.optString("notifBody", ""),
                )
            } catch (_: Exception) {
                null
            }
        }

        fun save(context: Context, config: LockConfig) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, config.toJson()).apply()
        }

        /** Package yang barusan diblokir — dibaca (dan dihapus) Flutter saat Riung dibuka. */
        fun setPending(context: Context, pkg: String?) {
            val edit = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            if (pkg == null) edit.remove(KEY_PENDING) else edit.putString(KEY_PENDING, pkg)
            edit.apply()
        }

        fun consumePending(context: Context): String? {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val pkg = prefs.getString(KEY_PENDING, null)
            if (pkg != null) prefs.edit().remove(KEY_PENDING).apply()
            return pkg
        }
    }
}
