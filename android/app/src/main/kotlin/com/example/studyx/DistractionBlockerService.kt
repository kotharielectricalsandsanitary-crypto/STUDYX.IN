package com.example.studyx

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class DistractionBlockerService : AccessibilityService() {

    companion object {
        const val ACTION_BLOCK = "com.example.studyx.BLOCK_APP"

        private val BLOCKED_PACKAGES = setOf(
            "com.instagram.android",
            "com.snapchat.android",
            "com.google.android.youtube"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        if (!BLOCKED_PACKAGES.contains(packageName)) {
            return
        }

        val prefs = getSharedPreferences(
            "studyx_distraction",
            MODE_PRIVATE
        )

        val enabled = prefs.getBoolean("enabled", false)

        if (!enabled) {
            return
        }

        val limitMinutes = prefs.getInt("limit_minutes", 30)

        val sessionStart = prefs.getLong("session_start", 0L)

        if (sessionStart == 0L) {
            prefs.edit()
                .putLong(
                    "session_start",
                    System.currentTimeMillis()
                )
                .apply()

            return
        }

        val elapsedMinutes =
            (System.currentTimeMillis() - sessionStart) / 60000L

        if (elapsedMinutes >= limitMinutes) {
            openBlockScreen(packageName)
        }
    }

    private fun openBlockScreen(packageName: String) {
        val intent = Intent(
            this,
            BlockedAppActivity::class.java
        )

        intent.putExtra(
            "blocked_package",
            packageName
        )

        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
        )

        startActivity(intent)
    }

    override fun onInterrupt() {
        // Accessibility service interrupted.
    }
}