import Flutter
import UIKit

public class RecordingShieldPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var recordingStateEventSink: FlutterEventSink?
    private var screenshotEventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "recording_shield",
            binaryMessenger: registrar.messenger()
        )

        let recordingStateChannel = FlutterEventChannel(
            name: "recording_shield/recording_state",
            binaryMessenger: registrar.messenger()
        )

        let screenshotChannel = FlutterEventChannel(
            name: "recording_shield/screenshots",
            binaryMessenger: registrar.messenger()
        )

        let instance = RecordingShieldPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        recordingStateChannel.setStreamHandler(instance)
        screenshotChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setup":
            setup(call, result: result)
        case "checkRecordingState":
            checkRecordingState(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Implementations

    private func setup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let detectScreenshots = args["detectScreenshots"] as? Bool ?? true

        // Setup observers
        setupObservers(detectScreenshots: detectScreenshots)

        printDebug("Setup completed")
        result(nil)
    }

    private func setupObservers(detectScreenshots: Bool) {
        // Remove any existing observers
        NotificationCenter.default.removeObserver(self)

        // Add observer for screen capture state changes (iOS 11+)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )

        // Add observer for screenshots if enabled
        if detectScreenshots {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenshotTaken),
                name: UIApplication.userDidTakeScreenshotNotification,
                object: nil
            )
        }

        printDebug("Observers setup complete")
    }

    @objc private func screenCaptureDidChange() {
        let isCaptured = UIScreen.main.isCaptured
        let state = isCaptured ? "recording" : "notRecording"

        printDebug("Screen capture state changed: \(state)")

        recordingStateEventSink?(["state": state])
    }

    @objc private func screenshotTaken() {
        printDebug("Screenshot detected")
        screenshotEventSink?([:])
    }

    private func checkRecordingState(result: @escaping FlutterResult) {
        let isCaptured = UIScreen.main.isCaptured
        let state = isCaptured ? "recording" : "notRecording"
        printDebug("Checking recording state: \(state)")
        result(state)
    }

    private func dispose(result: @escaping FlutterResult) {
        NotificationCenter.default.removeObserver(self)
        printDebug("Disposed")
        result(nil)
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Determine which channel is being listened to based on arguments or context
        // For simplicity, we use the fact that this method is called per channel
        // The Flutter side manages which sink to use

        // Check if this is the recording state channel or screenshot channel
        // by checking if we already have a recording state sink
        if recordingStateEventSink == nil {
            recordingStateEventSink = events
            printDebug("Recording state event sink connected")
        } else {
            screenshotEventSink = events
            printDebug("Screenshot event sink connected")
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Clear the appropriate sink
        if screenshotEventSink != nil {
            screenshotEventSink = nil
            printDebug("Screenshot event sink disconnected")
        } else {
            recordingStateEventSink = nil
            printDebug("Recording state event sink disconnected")
        }
        return nil
    }

    // MARK: - Debug Helpers

    private func printDebug(_ message: String) {
        #if DEBUG
        print("[RecordingShield] \(message)")
        #endif
    }
}
