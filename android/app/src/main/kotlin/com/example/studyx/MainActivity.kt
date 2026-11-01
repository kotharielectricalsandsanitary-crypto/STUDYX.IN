
package com.example.studyx

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "studyx/distraction_blocker"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // -------------------------------------------------
                // Open Android Accessibility Settings
                // -------------------------------------------------
                "openAccessibilitySettings" -> {

                    try {
                        val intent = Intent(
                            Settings.ACTION_ACCESSIBILITY_SETTINGS
                        )

                        startActivity(intent)

                        result.success(true)

                    } catch (e: Exception) {
                        result.error(
                            "ACCESSIBILITY_SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // -------------------------------------------------
                // Check whether StudyX Accessibility Service
                // is enabled
                // -------------------------------------------------
                "hasAccessibilityAccess" -> {

                    result.success(
                        isAccessibilityServiceEnabled()
                    )
                }

                // -------------------------------------------------
                // Start blocker
                // -------------------------------------------------
                "startBlocker" -> {

                    val limit =
                        call.argument<Int>("limitMinutes")
                            ?: call.argument<Int>("limit")
                            ?: 30

                    val safeLimit =
                        limit.coerceIn(20, 40)

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    prefs.edit()
                        .putBoolean(
                            "enabled",
                            true
                        )
                        .putInt(
                            "limit_minutes",
                            safeLimit
                        )
                        .putLong(
                            "session_start",
                            System.currentTimeMillis()
                        )
                        .apply()

                    result.success(true)
                }

                // -------------------------------------------------
                // Stop blocker
                // -------------------------------------------------
                "stopBlocker" -> {

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    prefs.edit()
                        .putBoolean(
                            "enabled",
                            false
                        )
                        .remove("session_start")
                        .apply()

                    result.success(true)
                }

                // -------------------------------------------------
                // Backwards compatibility with your old Flutter
                // code
                // -------------------------------------------------
                "enableBlocker" -> {

                    val limit =
                        call.argument<Int>("limit")
                            ?: call.argument<Int>("limitMinutes")
                            ?: 30

                    val safeLimit =
                        limit.coerceIn(20, 40)

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    prefs.edit()
                        .putBoolean(
                            "enabled",
                            true
                        )
                        .putInt(
                            "limit_minutes",
                            safeLimit
                        )
                        .putLong(
                            "session_start",
                            System.currentTimeMillis()
                        )
                        .apply()

                    result.success(true)
                }

                // -------------------------------------------------
                // Backwards compatibility
                // -------------------------------------------------
                "disableBlocker" -> {

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    prefs.edit()
                        .putBoolean(
                            "enabled",
                            false
                        )
                        .remove("session_start")
                        .apply()

                    result.success(true)
                }

                // -------------------------------------------------
                // Check blocker status
                // -------------------------------------------------
                "isBlockerEnabled" -> {

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    result.success(
                        prefs.getBoolean(
                            "enabled",
                            false
                        )
                    )
                }

                // -------------------------------------------------
                // Get current limit
                // -------------------------------------------------
                "getBlockerLimit" -> {

                    val prefs =
                        getSharedPreferences(
                            "studyx_distraction",
                            MODE_PRIVATE
                        )

                    result.success(
                        prefs.getInt(
                            "limit_minutes",
                            30
                        )
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // -------------------------------------------------------------
    // Checks Android Accessibility Settings to see whether
    // StudyX's accessibility service is enabled.
    // -------------------------------------------------------------
    private fun isAccessibilityServiceEnabled(): Boolean {

        val accessibilityManager =
            getSystemService(
                Context.ACCESSIBILITY_SERVICE
            ) as AccessibilityManager

        val enabledServices =
            accessibilityManager
                .getEnabledAccessibilityServiceList(
                    AccessibilityServiceInfo.FEEDBACK_ALL_MASK
                )

        val expectedComponent =
            ComponentName(
                this,
                DistractionBlockerService::class.java
            )

        return enabledServices.any { serviceInfo ->

            val serviceComponent =
                ComponentName(
                    serviceInfo.resolveInfo.serviceInfo.packageName,
                    serviceInfo.resolveInfo.serviceInfo.name
                )

            serviceComponent == expectedComponent
        }
    }
}
