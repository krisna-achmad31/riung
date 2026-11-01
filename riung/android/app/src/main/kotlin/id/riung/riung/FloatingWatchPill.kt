package id.riung.riung

import android.accessibilityservice.AccessibilityService
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale

/**
 * Pil melayang saat aplikasi beku terbuka: kepala monster + sisa waktu.
 * Hanya informasi: tidak bisa disentuh dan tidak fokus, jadi tidak pernah
 * menghalangi aplikasi di bawahnya. Pemiliknya [LockEngine], yang
 * menyembunyikannya begitu aplikasi itu tidak lagi di depan.
 */
class FloatingWatchPill(private val context: Context) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var root: View? = null
    private var label: TextView? = null
    private var bob: ObjectAnimator? = null

    fun show(remainingMillis: Long) {
        if (root == null) attach()
        // Dibulatkan ke atas supaya 00:00 tidak tampil selagi waktu masih ada.
        val seconds = (remainingMillis + 999L) / 1000L
        val text = if (seconds >= 3600L) {
            String.format(Locale.US, "%d:%02d:%02d", seconds / 3600L, seconds / 60L % 60L, seconds % 60L)
        } else {
            String.format(Locale.US, "%02d:%02d", seconds / 60L, seconds % 60L)
        }
        label?.text = text
    }

    fun hide() {
        bob?.cancel()
        bob = null
        root?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: IllegalArgumentException) {
                // Jendela sudah dilepas sistem.
            }
        }
        root = null
        label = null
    }

    private fun attach() {
        val pill = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(5), dp(5), dp(14), dp(5))
            background = GradientDrawable().apply {
                setColor(PILL_COLOR)
                cornerRadius = dp(24).toFloat()
            }
            elevation = dp(6).toFloat()
        }
        monsterHead()?.let { head ->
            pill.addView(
                ImageView(context).apply {
                    setImageBitmap(head)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(HEAD_BACKDROP)
                    }
                    setPadding(dp(3), dp(3), dp(3), dp(3))
                    outlineProvider = object : ViewOutlineProvider() {
                        override fun getOutline(view: View, outline: Outline) = outline.setOval(0, 0, view.width, view.height)
                    }
                    clipToOutline = true
                },
                LinearLayout.LayoutParams(dp(34), dp(34)).apply { marginEnd = dp(8) },
            )
        }
        val countdown = TextView(context).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            fontFeatureSettings = "tnum"
        }
        pill.addView(countdown)

        // Ruang transparan di sekeliling pil untuk ayunan & bayangan.
        val frame = FrameLayout(context).apply {
            setPadding(dp(10), dp(8), dp(10), dp(12))
            clipChildren = false
            clipToPadding = false
            addView(pill)
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = dp(TOP_OFFSET_DP)
        }
        windowManager.addView(frame, params)
        root = frame
        label = countdown
        bob = ObjectAnimator.ofFloat(pill, View.TRANSLATION_Y, -dp(3).toFloat(), dp(3).toFloat()).apply {
            duration = BOB_MS
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            interpolator = AccelerateDecelerateInterpolator()
            start()
        }
    }

    private fun overlayType(): Int = when {
        // Lewat AccessibilityService tidak perlu izin overlay terpisah.
        context is AccessibilityService -> WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else -> @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
    }

    /** Potongan kepala dari art monster bawaan, di-decode kecil supaya hemat memori. */
    private fun monsterHead(): Bitmap? = try {
        context.assets.open(HEAD_ASSET).use { input ->
            val art = BitmapFactory.decodeStream(input, null, BitmapFactory.Options().apply { inSampleSize = 3 }) ?: return null
            val r = Rect((art.width * 0.07f).toInt(), (art.height * 0.02f).toInt(), (art.width * 0.93f).toInt(), (art.height * 0.88f).toInt())
            Bitmap.createBitmap(art, r.left, r.top, r.width(), r.height())
        }
    } catch (_: Exception) {
        null
    }

    private fun dp(value: Int): Int = (value * context.resources.displayMetrics.density).toInt()

    private companion object {
        const val HEAD_ASSET = "flutter_assets/assets/monsters/3d/hakim_liar.webp"
        const val TOP_OFFSET_DP = 34
        const val BOB_MS = 1500L
        val PILL_COLOR = Color.parseColor("#E61F2A2B")
        val HEAD_BACKDROP = Color.parseColor("#33FFFFFF")
    }
}
