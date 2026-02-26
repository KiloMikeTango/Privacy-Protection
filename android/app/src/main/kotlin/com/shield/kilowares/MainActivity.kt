package com.shield.kilowares

import android.Manifest
import android.content.SharedPreferences
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.content.pm.PackageManager
import android.app.AppOpsManager
import android.content.Context
import android.provider.Settings
import android.util.Base64
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import android.util.Log
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.protection.kilowares.mm.OverlayService

class MainActivity : FlutterActivity() {
    companion object {
        const val TAG = "MainActivity"
    }
    private val channelName = "privacy_protection"
    private val prefsName = "privacy_protection_prefs"
    private val keyProtected = "protected_packages"
    private val keySecretPattern = "secret_tap_pattern"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            when (call.method) {
                "enableOverlay" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                        startActivity(intent)
                        result.success(false)
                    } else {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                                result.success(false)
                                return@setMethodCallHandler
                            }
                        }
                        
                        if (!hasUsageAccess()) {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        val serviceIntent = Intent(this, OverlayService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    }
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "openAppDetails" -> {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }
                "disableOverlay" -> {
                    val serviceIntent = Intent(this, OverlayService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                "isOverlayActive" -> {
                    result.success(OverlayService.isServiceActive)
                }
                "getInstalledLaunchableApps" -> {
                    val pm = packageManager
                    val apps = pm.getInstalledApplications(0)
                    val list = mutableListOf<Map<String, String>>()
                    for (ai in apps) {
                        val pkg = ai.packageName
                        val launchIntent = pm.getLaunchIntentForPackage(pkg)
                        if (launchIntent != null) {
                            val appName = ai.loadLabel(pm).toString()
                            val iconDrawable = ai.loadIcon(pm)
                            val width = iconDrawable.intrinsicWidth.takeIf { it > 0 } ?: 48
                            val height = iconDrawable.intrinsicHeight.takeIf { it > 0 } ?: 48
                            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            val canvas = Canvas(bmp)
                            iconDrawable.setBounds(0, 0, canvas.width, canvas.height)
                            iconDrawable.draw(canvas)
                            val baos = ByteArrayOutputStream()
                            bmp.compress(Bitmap.CompressFormat.PNG, 100, baos)
                            val b64 = Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
                            list.add(mapOf("packageName" to pkg, "appName" to appName, "iconBase64" to b64))
                        }
                    }
                    result.success(list)
                }
                "checkPermissions" -> {
                    val overlay = Settings.canDrawOverlays(this)
                    val usage = hasUsageAccess()
                    val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    val accessibility = isAccessibilityEnabled()
                    val map = mapOf(
                        "overlay" to overlay,
                        "usage" to usage,
                        "notification" to notification,
                        "accessibility" to accessibility
                    )
                    result.success(map)
                }
                "saveProtectedApps" -> {
                    val packages = (call.arguments as? List<*>)?.map { it.toString() } ?: emptyList()
                    val prefs = securePrefs()
                    prefs.edit().putStringSet(keyProtected, packages.toSet()).apply()
                    // Notify service to reload
                    sendBroadcast(Intent(OverlayService.ACTION_UPDATE_CONFIG))
                    // Auto re-enable: if service is not active but permissions are granted, start it
                    if (!OverlayService.isServiceActive) {
                        val overlayOk = Settings.canDrawOverlays(this)
                        val usageOk = hasUsageAccess()
                        if (overlayOk && usageOk) {
                            val serviceIntent = Intent(this, OverlayService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(serviceIntent)
                            } else {
                                startService(serviceIntent)
                            }
                        }
                    }
                    result.success(true)
                }
                "getProtectedApps" -> {
                    val prefs = securePrefs()
                    val set = prefs.getStringSet(keyProtected, emptySet()) ?: emptySet()
                    result.success(set.toList())
                }
                "saveSecretPattern" -> {
                    val pattern = (call.arguments as? List<*>)?.mapNotNull { it.toString().toIntOrNull() } ?: emptyList()
                    val s = pattern.joinToString(",")
                    val prefs = securePrefs()
                    prefs.edit().putString(keySecretPattern, s).apply()
                    // Notify service to reload
                    sendBroadcast(Intent(OverlayService.ACTION_UPDATE_CONFIG))
                    result.success(true)
                }
                "getSecretPattern" -> {
                    val prefs = securePrefs()
                    val s = prefs.getString(keySecretPattern, "") ?: ""
                    val list = if (s.isEmpty()) listOf(0, 1, 2, 3) else s.split(",").mapNotNull { it.toIntOrNull() }
                    result.success(list)
                }
                else -> result.notImplemented()
            }
        }
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

    private fun isAccessibilityEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabled = am.isEnabled
        if (!enabled) return false
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: ""
        val target = "$packageName/com.protection.kilowares.mm.ForegroundDetectorService"
        return enabledServices.contains(target)
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
}
