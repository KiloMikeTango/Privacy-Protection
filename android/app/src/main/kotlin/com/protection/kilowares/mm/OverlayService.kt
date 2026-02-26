package com.protection.kilowares.mm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.content.SharedPreferences
import android.util.Log
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
        const val TAG = "OverlayService"
        const val CHANNEL_ID = "privacy_protection_overlay"
        const val NOTIFICATION_ID = 1001
        const val ACTION_UPDATE_CONFIG = "com.protection.kilowares.UPDATE_CONFIG"
        const val ACTION_TOP_CHANGED = "com.protection.kilowares.TOP_CHANGED"
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
    private var unlockedPackage: String? = null
    
    private val screenReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    stopMonitoring()
                    currentTapSequence.clear()
                    unlockedPackage = null // Relock immediately on screen off
                }
                Intent.ACTION_SCREEN_ON -> startMonitoring()
                ACTION_UPDATE_CONFIG -> reloadConfig()
                ACTION_TOP_CHANGED -> {
                    val pkg = intent.getStringExtra("package")
                    onTopPackageChanged(pkg)
                }
            }
        }
    }

    private val prefListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == keyProtected || key == keySecretPattern) {
            reloadConfig()
        }
    }

    private fun reloadConfig() {
        protectedPackages = prefs.getStringSet(keyProtected, emptySet()) ?: emptySet()
        secretPattern = loadSecretPattern()
        Log.d(TAG, "Config reloaded. Protected packages count: ${protectedPackages.size}")
        Log.d(TAG, "Protected packages: $protectedPackages")
        // Reset any temporary unlock so newly protected apps lock immediately
        unlockedPackage = null
        
        // Ensure monitoring is active after config reload
        startMonitoring()
        // Apply changes immediately based on current foreground app
        try {
            checkForegroundApp()
        } catch (_: Exception) {}
    }

    private fun onTopPackageChanged(pkg: String?) {
        Log.d(TAG, "Top via accessibility: $pkg")
        lastTopPackage = pkg
        val top = lastTopPackage
        if (top != null) {
            if (top == unlockedPackage) {
                hideOverlay()
                return
            } else {
                unlockedPackage = null
            }
            if (top != packageName &&
                !launcherPackages.contains(top) &&
                protectedPackages.contains(top)) {
                showOverlay()
            } else {
                hideOverlay()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, buildNotification())
            }
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            stopSelf()
            return
        }
        wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        isServiceActive = true
        prefs = securePrefs()
        prefs.registerOnSharedPreferenceChangeListener(prefListener)
        reloadConfig()
        launcherPackages = queryLauncherPackages()
        
        val filter = android.content.IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(ACTION_UPDATE_CONFIG)
            addAction(ACTION_TOP_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        
        startMonitoring()
    }

    private fun loadSecretPattern(): List<Int> {
        val s = prefs.getString(keySecretPattern, "") ?: ""
        if (s.isEmpty()) return listOf(0, 1, 2, 3)
        return s.split(",").mapNotNull { it.toIntOrNull() }
    }

    private fun securePrefs(): SharedPreferences {
        // Fallback to regular SharedPreferences if EncryptedSharedPreferences fails (e.g. due to ProGuard or key issues)
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
        if (intent?.action == ACTION_UPDATE_CONFIG) {
            reloadConfig()
        }
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
        if (monitorRunnable != null) {
            Log.d(TAG, "Monitoring already active")
            return
        }
        Log.d(TAG, "Starting monitoring loop")
        monitorRunnable = Runnable {
            try {
                Log.d(TAG, "Monitoring tick")
                checkForegroundApp()
            } catch (e: Exception) {
                Log.e(TAG, "Error in monitoring loop", e)
            } finally {
                handler.postDelayed(monitorRunnable!!, 100)
            }
        }
        handler.post(monitorRunnable!!)
    }

    private fun checkForegroundApp() {
        val usageAllowed = hasUsageAccess()
        if (!usageAllowed) {
            Log.e(TAG, "Usage Access not granted; cannot detect foreground app")
        }
        var newTop = getTopPackage()
        
        // If queryEvents failed to return a package (e.g. long duration), try fallback immediately
        if (newTop == null) {
            newTop = getTopPackageFromUsageStats()
        }

        if (newTop != null) {
            lastTopPackage = newTop
        } else if (lastTopPackage == null) {
             // If everything failed, try one last resort: standard UsageStats
             lastTopPackage = getTopPackageFromUsageStats()
        }
        
        val top = lastTopPackage
        Log.d(TAG, "Current top package: $top")
        
        // Logic:
        // 1. If we are in the unlocked app -> Stay unlocked (Hide overlay)
        // 2. If we switched apps -> Reset unlock status
        // 3. If new app is protected -> Show overlay
        // 4. Otherwise -> Hide overlay

        if (top != null) {
            // Log.d(TAG, "Checking package: $top. Is protected: ${protectedPackages.contains(top)}")
            
            if (top == unlockedPackage) {
                // Currently using the unlocked app
                hideOverlay()
                return
            } else {
                // Switched to a different app (or launcher), so re-lock
                unlockedPackage = null
            }
            
            // Check protection status
            if (top != packageName && 
                !launcherPackages.contains(top) && 
                protectedPackages.contains(top)) {
                Log.d(TAG, "Protected app detected: $top. Showing overlay.")
                showOverlay()
            } else {
                Log.d(TAG, "Top app not protected or is launcher/self: $top")
                hideOverlay()
            }
        } else {
            Log.d(TAG, "No top package detected.")
        }
    }

    private fun stopMonitoring() {
        monitorRunnable?.let { handler.removeCallbacks(it) }
        monitorRunnable = null
    }

    private fun getTopPackageFromUsageStats(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val begin = end - 1000 * 60 * 60 * 24 // 24 hours
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, begin, end)
            if (stats != null && stats.isNotEmpty()) {
                val sorted = stats.sortedByDescending { it.lastTimeUsed }
                return sorted.firstOrNull()?.packageName
            }
        }
        return null
    }

    private fun getTopPackage(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            // Look back 15 minutes to catch recent app switches; still inexpensive
            val begin = end - 1000 * 60 * 15 
            val events = usm.queryEvents(begin, end)
            var lastPkg: String? = null
            var lastTime: Long = 0
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if ((event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                    event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) && event.timeStamp >= lastTime) {
                    lastPkg = event.packageName
                    lastTime = event.timeStamp
                }
            }
            if (lastPkg == null) {
                // Fallback to UsageStats if no event is found in the short window
                // This is useful if the user has been in the same app for a long time
                return getTopPackageFromUsageStats()
            }
            return lastPkg
        }
        return null
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
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
        Log.d(TAG, "showOverlay called")
        
        // Check if we have permission to draw overlays
        if (!android.provider.Settings.canDrawOverlays(this)) {
            Log.e(TAG, "Overlay permission not granted, cannot show overlay")
            return
        }

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
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_SECURE, // Prevent screenshots/recording
            android.graphics.PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            params.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }

        // Ensure we're running on the main thread for UI operations
        handler.post {
            try {
                if (overlayView == null) {
                    val view = FrameLayout(this).apply {
                        // Stealth Mode: Use a solid color to mimic a frozen or blank screen
                        // Using a slightly off-white (#F5F7FA) makes it look like the app tried to load but failed
                        setBackgroundColor(Color.parseColor("#F5F7FA"))
                        
                        // Invisible touch area for pattern input
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
                    view.fitsSystemWindows = false
                    view.systemUiVisibility =
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    overlayView = view
                    wm?.addView(view, params)
                    isOverlayShowing = true
                    Log.d(TAG, "Overlay view added successfully")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error adding overlay view", e)
                isOverlayShowing = false
                overlayView = null
            }
        }
    }
    
    private fun performTempUnlock() {
        // Unlock only the current app
        unlockedPackage = lastTopPackage
        hideOverlay()
    }

    fun hideOverlay() {
        if (!isOverlayShowing) return
        Log.d(TAG, "hideOverlay called")
        handler.post {
            try {
                overlayView?.let {
                    wm?.removeView(it)
                }
                overlayView = null
                isOverlayShowing = false
                Log.d(TAG, "Overlay view removed successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error removing overlay view", e)
            }
        }
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
            // Disguise as System Service
            .setContentTitle("Android System")
            .setContentText("Background Service")
            .setSmallIcon(android.R.drawable.stat_sys_warning) // Generic warning/system icon
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_MIN) // Minimized visibility for pre-Oreo
            .setCategory(Notification.CATEGORY_SERVICE)
        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "System Services", // Generic name in settings
                NotificationManager.IMPORTANCE_MIN // Silent, minimized
            )
            channel.description = "Core system functionality"
            channel.setShowBadge(false)
            channel.lockscreenVisibility = Notification.VISIBILITY_SECRET // Hide on lockscreen
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }
}
