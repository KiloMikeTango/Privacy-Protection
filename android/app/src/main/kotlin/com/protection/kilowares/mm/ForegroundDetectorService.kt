package com.protection.kilowares.mm

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent

class ForegroundDetectorService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val pkg = event?.packageName?.toString()
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && pkg != null) {
            val intent = Intent(OverlayService.ACTION_TOP_CHANGED).apply {
                putExtra("package", pkg)
            }
            sendBroadcast(intent)
        }
    }

    override fun onInterrupt() {}
}
