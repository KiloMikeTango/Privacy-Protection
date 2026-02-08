package com.protection.kilowares.mm

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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "privacy_protection"
    private val prefsName = "privacy_protection_prefs"
    private val keyProtected = "protected_packages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableOverlay" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
                        startActivity(intent)
                        result.success(false)
                    } else {
                        if (Build.VERSION.SDK_INT >= 33) {
                            val granted = checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                            if (!granted) {
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
                    val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
                    val resolveInfos = pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    val list = resolveInfos.map { ri ->
                        val pkg = ri.activityInfo.packageName
                        val appName = ri.loadLabel(pm).toString()
                        val iconDrawable = ri.loadIcon(pm)
                        val bmp = Bitmap.createBitmap(
                            iconDrawable.intrinsicWidth.coerceAtLeast(1),
                            iconDrawable.intrinsicHeight.coerceAtLeast(1),
                            Bitmap.Config.ARGB_8888
                        )
                        val canvas = Canvas(bmp)
                        iconDrawable.setBounds(0, 0, canvas.width, canvas.height)
                        iconDrawable.draw(canvas)
                        val baos = ByteArrayOutputStream()
                        bmp.compress(Bitmap.CompressFormat.PNG, 100, baos)
                        val b64 = Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
                        mapOf("packageName" to pkg, "appName" to appName, "iconBase64" to b64)
                    }
                    result.success(list)
                }
                "saveProtectedApps" -> {
                    val packages = (call.arguments as? List<*>)?.map { it.toString() } ?: emptyList()
                    val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                    prefs.edit().putStringSet(keyProtected, packages.toSet()).apply()
                    result.success(true)
                }
                "getProtectedApps" -> {
                    val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
                    val set = prefs.getStringSet(keyProtected, emptySet()) ?: emptySet()
                    result.success(set.toList())
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
}
