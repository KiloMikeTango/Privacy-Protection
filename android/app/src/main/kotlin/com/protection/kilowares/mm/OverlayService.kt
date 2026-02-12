package com.protection.kilowares.mm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

class OverlayService : Service() {
    companion object {
        const val CHANNEL_ID = "privacy_protection_overlay"
        const val NOTIFICATION_ID = 1001
        @Volatile
        var isOverlayShowing: Boolean = false
        @Volatile
        var isServiceActive: Boolean = false
    }

    private var wm: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var monitorRunnable: Runnable? = null
    private var launcherPackages: Set<String> = emptySet()
    private var lastTopPackage: String? = null
    private var protectedPackages: Set<String> = emptySet()
    private lateinit var prefs: SharedPreferences
    private val prefsName = "privacy_protection_prefs"
    private val keyProtected = "protected_packages"
    private val keySecretPattern = "secret_tap_pattern"
    private var secretPattern: List<Int> = listOf(0, 1, 2, 3)
    private val currentTapSequence = mutableListOf<Int>()
    private var tempUnlockUntil: Long = 0
    
    private val screenReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    stopMonitoring()
                    currentTapSequence.clear()
                    tempUnlockUntil = 0 // Reset unlock on screen off
                }
                Intent.ACTION_SCREEN_ON -> startMonitoring()
            }
        }
    }

    private val prefListener = SharedPreferences.OnSharedPreferenceChangeListener { sharedPreferences, key ->
        if (key == keyProtected) {
            protectedPackages = sharedPreferences.getStringSet(keyProtected, emptySet()) ?: emptySet()
        } else if (key == keySecretPattern) {
            secretPattern = loadSecretPattern()
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        isServiceActive = true
        prefs = securePrefs()
        prefs.registerOnSharedPreferenceChangeListener(prefListener)
        protectedPackages = prefs.getStringSet(keyProtected, emptySet()) ?: emptySet()
        secretPattern = loadSecretPattern()
        launcherPackages = queryLauncherPackages()
        
        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(screenReceiver, filter)
        
        startMonitoring()
    }

    private fun loadSecretPattern(): List<Int> {
        val s = prefs.getString(keySecretPattern, "") ?: ""
        if (s.isEmpty()) return listOf(0, 1, 2, 3)
        return s.split(",").mapNotNull { it.toIntOrNull() }
    }

    private fun securePrefs(): SharedPreferences {
        return try {
            val keyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            EncryptedSharedPreferences.create(
                prefsName,
                keyAlias,
                this,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (_: Throwable) {
            getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Monitoring will decide when to show/hide the overlay
        return START_STICKY
    }

    override fun onDestroy() {
        hideOverlay()
        isServiceActive = false
        stopMonitoring()
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {}
        try {
            prefs.unregisterOnSharedPreferenceChangeListener(prefListener)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startMonitoring() {
        if (monitorRunnable != null) return
        monitorRunnable = Runnable {
            try {
                if (System.currentTimeMillis() < tempUnlockUntil) {
                    // Temporarily unlocked
                    return@Runnable
                }
                
                val newTop = getTopPackage()
                if (newTop != null) {
                    lastTopPackage = newTop
                }
                val top = lastTopPackage
                // Use cached protectedPackages
                val shouldShow = top != null &&
                        top != packageName &&
                        isClickableApp(top) &&
                        !launcherPackages.contains(top) &&
                        protectedPackages.contains(top)
                if (shouldShow) {
                    showOverlay()
                } else if (top != null) {
                    hideOverlay()
                }
            } catch (_: Exception) {
                // Ignore for PoC
            } finally {
                handler.postDelayed(monitorRunnable!!, 500)
            }
        }
        handler.post(monitorRunnable!!)
    }

    private fun stopMonitoring() {
        monitorRunnable?.let { handler.removeCallbacks(it) }
        monitorRunnable = null
    }

    private fun getTopPackage(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val begin = end - 60_000
            val events = usm.queryEvents(begin, end)
            var lastPkg: String? = null
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                    event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    lastPkg = event.packageName
                }
            }
            return lastPkg
        }
        return null
    }

    private fun isClickableApp(pkg: String): Boolean {
        return try {
            packageManager.getLaunchIntentForPackage(pkg) != null
        } catch (_: Exception) { false }
    }

    private fun queryLauncherPackages(): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
        }
        val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfos.mapNotNull { it.activityInfo?.packageName }.toSet()
    }

    private fun showOverlay() {
        if (isOverlayShowing) return
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            android.graphics.PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START

        val view = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#FFFFFF"))
            setOnTouchListener { v, event ->
                if (event.action == MotionEvent.ACTION_DOWN) {
                    val w = v.width
                    val h = v.height
                    val x = event.x
                    val y = event.y
                    val col = if (x < w / 2) 0 else 1
                    val row = if (y < h / 2) 0 else 1
                    val quadrant = row * 2 + col // 0=TL, 1=TR, 2=BL, 3=BR
                    
                    currentTapSequence.add(quadrant)
                    while (currentTapSequence.size > secretPattern.size) {
                        currentTapSequence.removeAt(0)
                    }
                    
                    if (currentTapSequence == secretPattern) {
                        performTempUnlock()
                        currentTapSequence.clear()
                    }
                }
                true
            }
        }

        overlayView = view
        wm?.addView(view, params)
        isOverlayShowing = true
    }
    
    private fun performTempUnlock() {
        tempUnlockUntil = System.currentTimeMillis() + 60_000 // 1 minute unlock
        hideOverlay()
    }

    fun hideOverlay() {
        if (!isOverlayShowing) return
        overlayView?.let {
            wm?.removeView(it)
        }
        overlayView = null
        isOverlayShowing = false
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, OverlayService::class.java).apply {
            // Action can be used if you extend to handle control actions
        }
        val pendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
            .setContentTitle("Privacy Protection")
            .setContentText("Overlay Active")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Privacy Protection Overlay",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Shows overlay while service is active"
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }
}
