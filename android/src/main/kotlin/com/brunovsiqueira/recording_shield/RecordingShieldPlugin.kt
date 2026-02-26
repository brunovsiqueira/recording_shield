package com.brunovsiqueira.recording_shield

import android.app.Activity
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import androidx.annotation.RequiresApi
import io.flutter.BuildConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.function.Consumer

/** RecordingShieldPlugin */
class RecordingShieldPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var recordingStateChannel: EventChannel
    private lateinit var screenshotChannel: EventChannel

    private var recordingStateEventSink: EventChannel.EventSink? = null
    private var screenshotEventSink: EventChannel.EventSink? = null

    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // API 35+ recording callback
    private var screenRecordingCallback: Consumer<Int>? = null

    // Cached recording state (updated by callback)
    @Volatile
    private var currentRecordingState: Int = -1  // -1 means unknown/not initialized

    // API 34+ screenshot callback
    private var screenCaptureCallback: Activity.ScreenCaptureCallback? = null

    // FLAG_SECURE state
    private var isSecureModeEnabled: Boolean = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "recording_shield")
        methodChannel.setMethodCallHandler(this)

        recordingStateChannel = EventChannel(flutterPluginBinding.binaryMessenger, "recording_shield/recording_state")
        recordingStateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                recordingStateEventSink = events
                printDebug("Recording state event sink connected")
            }

            override fun onCancel(arguments: Any?) {
                recordingStateEventSink = null
                printDebug("Recording state event sink disconnected")
            }
        })

        screenshotChannel = EventChannel(flutterPluginBinding.binaryMessenger, "recording_shield/screenshots")
        screenshotChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                screenshotEventSink = events
                printDebug("Screenshot event sink connected")
            }

            override fun onCancel(arguments: Any?) {
                screenshotEventSink = null
                printDebug("Screenshot event sink disconnected")
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        recordingStateChannel.setStreamHandler(null)
        screenshotChannel.setStreamHandler(null)
        cleanup()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setup" -> setup(call, result)
            "checkRecordingState" -> checkRecordingState(result)
            "enableSecureMode" -> enableSecureMode(result)
            "disableSecureMode" -> disableSecureMode(result)
            "dispose" -> dispose(result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Method Implementations

    private fun setup(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val detectScreenshots = args?.get("detectScreenshots") as? Boolean ?: true

        setupObservers(detectScreenshots)
        printDebug("Setup completed")
        result.success(null)
    }

    private fun setupObservers(detectScreenshots: Boolean) {
        val currentActivity = activity ?: return

        // API 35+ Screen Recording Detection
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            setupScreenRecordingCallback(currentActivity)
        } else {
            printDebug("Screen recording detection not supported (requires API 35+)")
        }

        // API 34+ Screenshot Detection
        if (detectScreenshots && Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            setupScreenCaptureCallback(currentActivity)
        }
    }

    @Suppress("NewApi")
    @RequiresApi(35)
    private fun setupScreenRecordingCallback(currentActivity: Activity) {
        try {
            val windowManager = currentActivity.getSystemService(Activity.WINDOW_SERVICE) as WindowManager
            screenRecordingCallback = Consumer { state ->
                // Update cached state
                currentRecordingState = state
                mainHandler.post {
                    val stateStr = when (state) {
                        WindowManager.SCREEN_RECORDING_STATE_VISIBLE -> "recording"
                        WindowManager.SCREEN_RECORDING_STATE_NOT_VISIBLE -> "notRecording"
                        else -> "unknown"
                    }
                    printDebug("Screen recording state changed: $stateStr")
                    recordingStateEventSink?.success(mapOf("state" to stateStr))
                }
            }
            // addScreenRecordingCallback returns the initial state
            val initialState = windowManager.addScreenRecordingCallback(currentActivity.mainExecutor, screenRecordingCallback!!)
            currentRecordingState = initialState
            printDebug("Registered screen recording callback (API 35+), initial state: $initialState")
        } catch (e: Exception) {
            printDebug("Failed to register screen recording callback: ${e.message}")
        }
    }

    @Suppress("NewApi")
    @RequiresApi(34)
    private fun setupScreenCaptureCallback(currentActivity: Activity) {
        try {
            screenCaptureCallback = Activity.ScreenCaptureCallback {
                mainHandler.post {
                    printDebug("Screenshot detected")
                    screenshotEventSink?.success(emptyMap<String, Any>())
                }
            }
            currentActivity.registerScreenCaptureCallback(currentActivity.mainExecutor, screenCaptureCallback!!)
            printDebug("Registered screen capture callback (API 34+)")
        } catch (e: Exception) {
            printDebug("Failed to register screen capture callback: ${e.message}")
        }
    }

    private fun checkRecordingState(result: Result) {
        val currentActivity = activity

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && currentActivity != null) {
            val stateStr = getScreenRecordingState(currentActivity)
            result.success(stateStr)
        } else {
            printDebug("Recording state check not supported (requires API 35+)")
            result.success("unsupported")
        }
    }

    @Suppress("NewApi")
    @RequiresApi(35)
    private fun getScreenRecordingState(currentActivity: Activity): String {
        // Use cached state from callback registration
        val state = currentRecordingState
        val stateStr = when (state) {
            WindowManager.SCREEN_RECORDING_STATE_VISIBLE -> "recording"
            WindowManager.SCREEN_RECORDING_STATE_NOT_VISIBLE -> "notRecording"
            -1 -> "unknown"  // Not initialized
            else -> "unknown"
        }
        printDebug("Checked recording state: $stateStr (raw: $state)")
        return stateStr
    }

    private fun enableSecureMode(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            printDebug("Cannot enable secure mode: no activity")
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        if (isSecureModeEnabled) {
            printDebug("Secure mode already enabled")
            result.success(null)
            return
        }

        mainHandler.post {
            try {
                currentActivity.window.setFlags(
                    WindowManager.LayoutParams.FLAG_SECURE,
                    WindowManager.LayoutParams.FLAG_SECURE
                )
                isSecureModeEnabled = true
                printDebug("Secure mode enabled (FLAG_SECURE)")
                result.success(null)
            } catch (e: Exception) {
                printDebug("Failed to enable secure mode: ${e.message}")
                result.error("SECURE_MODE_ERROR", e.message, null)
            }
        }
    }

    private fun disableSecureMode(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            printDebug("Cannot disable secure mode: no activity")
            result.success(null)
            return
        }

        if (!isSecureModeEnabled) {
            printDebug("Secure mode not enabled")
            result.success(null)
            return
        }

        mainHandler.post {
            try {
                currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                isSecureModeEnabled = false
                printDebug("Secure mode disabled (FLAG_SECURE cleared)")
                result.success(null)
            } catch (e: Exception) {
                printDebug("Failed to disable secure mode: ${e.message}")
                result.error("SECURE_MODE_ERROR", e.message, null)
            }
        }
    }

    private fun dispose(result: Result) {
        // Disable secure mode before disposing
        if (isSecureModeEnabled) {
            activity?.let { currentActivity ->
                mainHandler.post {
                    try {
                        currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        isSecureModeEnabled = false
                    } catch (_: Exception) {}
                }
            }
        }
        cleanup()
        printDebug("Disposed")
        result.success(null)
    }

    private fun cleanup() {
        val currentActivity = activity

        // Remove screen recording callback (API 35+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && currentActivity != null) {
            removeScreenRecordingCallback(currentActivity)
        }

        // Remove screen capture callback (API 34+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && currentActivity != null) {
            removeScreenCaptureCallback(currentActivity)
        }
    }

    @Suppress("NewApi")
    @RequiresApi(35)
    private fun removeScreenRecordingCallback(currentActivity: Activity) {
        screenRecordingCallback?.let { callback ->
            try {
                val windowManager = currentActivity.getSystemService(Activity.WINDOW_SERVICE) as WindowManager
                windowManager.removeScreenRecordingCallback(callback)
                printDebug("Removed screen recording callback")
            } catch (e: Exception) {
                printDebug("Failed to remove screen recording callback: ${e.message}")
            }
        }
        screenRecordingCallback = null
        currentRecordingState = -1
    }

    @Suppress("NewApi")
    @RequiresApi(34)
    private fun removeScreenCaptureCallback(currentActivity: Activity) {
        screenCaptureCallback?.let { callback ->
            try {
                currentActivity.unregisterScreenCaptureCallback(callback)
                printDebug("Removed screen capture callback")
            } catch (e: Exception) {
                printDebug("Failed to remove screen capture callback: ${e.message}")
            }
        }
        screenCaptureCallback = null
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        printDebug("Attached to activity")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        cleanup()
        activity = null
        printDebug("Detached from activity for config changes")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        printDebug("Reattached to activity for config changes")
    }

    override fun onDetachedFromActivity() {
        cleanup()
        activity = null
        printDebug("Detached from activity")
    }

    // MARK: - Debug Helpers

    private fun printDebug(message: String) {
        if (BuildConfig.DEBUG) {
            Log.d("RecordingShield", message)
        }
    }
}
