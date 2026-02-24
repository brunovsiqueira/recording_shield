package com.brunovsiqueira.recording_shield

import android.app.Activity
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
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

    // API 34+ screenshot callback
    private var screenCaptureCallback: Activity.ScreenCaptureCallback? = null

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
            try {
                val windowManager = currentActivity.getSystemService(Activity.WINDOW_SERVICE) as WindowManager
                screenRecordingCallback = Consumer { state ->
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
                windowManager.addScreenRecordingCallback(currentActivity.mainExecutor, screenRecordingCallback!!)
                printDebug("Registered screen recording callback (API 35+)")
            } catch (e: Exception) {
                printDebug("Failed to register screen recording callback: ${e.message}")
            }
        } else {
            printDebug("Screen recording detection not supported (requires API 35+)")
        }

        // API 34+ Screenshot Detection
        if (detectScreenshots && Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
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
    }

    private fun checkRecordingState(result: Result) {
        val currentActivity = activity

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && currentActivity != null) {
            try {
                val windowManager = currentActivity.getSystemService(Activity.WINDOW_SERVICE) as WindowManager
                val state = windowManager.screenRecordingState
                val stateStr = when (state) {
                    WindowManager.SCREEN_RECORDING_STATE_VISIBLE -> "recording"
                    WindowManager.SCREEN_RECORDING_STATE_NOT_VISIBLE -> "notRecording"
                    else -> "unknown"
                }
                printDebug("Checked recording state: $stateStr")
                result.success(stateStr)
            } catch (e: Exception) {
                printDebug("Failed to check recording state: ${e.message}")
                result.success("unknown")
            }
        } else {
            printDebug("Recording state check not supported (requires API 35+)")
            result.success("unsupported")
        }
    }

    private fun dispose(result: Result) {
        cleanup()
        printDebug("Disposed")
        result.success(null)
    }

    private fun cleanup() {
        val currentActivity = activity

        // Remove screen recording callback (API 35+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM && currentActivity != null) {
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
        }

        // Remove screen capture callback (API 34+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && currentActivity != null) {
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
