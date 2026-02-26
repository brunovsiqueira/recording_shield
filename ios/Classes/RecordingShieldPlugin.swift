import Flutter
import UIKit

public class RecordingShieldPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var recordingStateEventSink: FlutterEventSink?
    private var screenshotEventSink: FlutterEventSink?
    private var secureTextField: UITextField?
    private var isSecureModeEnabled: Bool = false

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

        // Register the secure platform view factory
        let factory = SecureViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "recording_shield/secure_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setup":
            setup(call, result: result)
        case "checkRecordingState":
            checkRecordingState(result: result)
        case "enableSecureMode":
            enableSecureMode(result: result)
        case "disableSecureMode":
            disableSecureMode(result: result)
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

    private func enableSecureMode(result: @escaping FlutterResult) {
        guard !isSecureModeEnabled else {
            printDebug("Secure mode already enabled")
            result(nil)
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let window = self.getKeyWindow() else {
                self.printDebug("Could not find key window")
                result(FlutterError(code: "NO_WINDOW", message: "Could not find key window", details: nil))
                return
            }

            // Create a secure text field
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.isUserInteractionEnabled = false
            textField.backgroundColor = .clear
            textField.frame = window.bounds
            textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Add to window temporarily to create the layer hierarchy
            window.addSubview(textField)
            textField.layoutIfNeeded()

            // Move the window's content layer into the secure text field's layer
            if let secureLayer = self.findSecureLayer(in: textField) {
                // Move all existing sublayers to the secure layer
                if let windowLayer = window.layer.sublayers?.first {
                    secureLayer.addSublayer(windowLayer)
                }
                self.secureTextField = textField
                self.isSecureModeEnabled = true
                self.printDebug("Secure mode enabled successfully")
            } else {
                // Fallback approach: use layer manipulation
                self.setupSecureModeFallback(textField: textField, window: window)
            }

            result(nil)
        }
    }

    private func findSecureLayer(in textField: UITextField) -> CALayer? {
        // Find the _UITextLayoutCanvasView's layer which has the secure properties
        for subview in textField.subviews {
            let className = String(describing: type(of: subview))
            if className.contains("TextLayoutCanvasView") {
                return subview.layer
            }
        }
        return nil
    }

    private func setupSecureModeFallback(textField: UITextField, window: UIWindow) {
        // Alternative approach using layer.superlayer manipulation
        if let superlayer = window.layer.superlayer {
            superlayer.addSublayer(textField.layer)
            if let textFieldLayer = textField.layer.sublayers?.last {
                textFieldLayer.addSublayer(window.layer)
            }
        }
        self.secureTextField = textField
        self.isSecureModeEnabled = true
        printDebug("Secure mode enabled with fallback approach")
    }

    private func disableSecureMode(result: @escaping FlutterResult) {
        guard isSecureModeEnabled else {
            printDebug("Secure mode not enabled")
            result(nil)
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove the secure text field and restore normal layer hierarchy
            if let textField = self.secureTextField {
                textField.isSecureTextEntry = false
                textField.removeFromSuperview()
                self.secureTextField = nil
            }

            self.isSecureModeEnabled = false
            self.printDebug("Secure mode disabled")
            result(nil)
        }
    }

    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }

    private func dispose(result: @escaping FlutterResult) {
        NotificationCenter.default.removeObserver(self)
        // Disable secure mode on dispose
        if isSecureModeEnabled {
            disableSecureMode(result: { _ in })
        }
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
