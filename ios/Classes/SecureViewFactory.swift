import Flutter
import UIKit

/// Factory for creating SecureView platform views
class SecureViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return SecureView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// A platform view that uses the isSecureTextEntry hack to prevent content
/// from appearing in screen recordings and screenshots.
///
/// This works by embedding the content inside a UITextField's secure layer,
/// which iOS automatically excludes from screen captures.
class SecureView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    private var secureTextField: UITextField
    private var secureContainer: UIView?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear

        // Create the secure text field
        secureTextField = UITextField()
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        secureTextField.backgroundColor = .clear

        super.init()

        setupSecureLayer()
    }

    func view() -> UIView {
        return containerView
    }

    private func setupSecureLayer() {
        // Add the text field to the container to initialize its layer hierarchy
        containerView.addSubview(secureTextField)
        secureTextField.frame = containerView.bounds
        secureTextField.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Force layout to ensure the secure layer exists
        secureTextField.layoutIfNeeded()

        // Find the secure canvas layer inside the text field
        // The _UITextLayoutCanvasView is the secure container in iOS
        if let secureCanvasView = findSecureCanvasView(in: secureTextField) {
            secureContainer = secureCanvasView

            // The container view's layer should be added to the secure canvas
            // This makes the container inherit the secure properties
            secureCanvasView.addSubview(containerView)
            containerView.frame = secureCanvasView.bounds
            containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            #if DEBUG
            print("[RecordingShield] SecureView: Successfully set up secure layer")
            #endif
        } else {
            // Fallback: use layer manipulation
            setupSecureLayerFallback()
        }
    }

    private func findSecureCanvasView(in view: UIView) -> UIView? {
        for subview in view.subviews {
            let className = String(describing: type(of: subview))
            if className.contains("TextLayoutCanvasView") || className.contains("_UITextLayoutCanvasView") {
                return subview
            }
            if let found = findSecureCanvasView(in: subview) {
                return found
            }
        }
        return nil
    }

    private func setupSecureLayerFallback() {
        // Alternative approach using layer manipulation
        guard let secureLayer = secureTextField.layer.sublayers?.first else {
            #if DEBUG
            print("[RecordingShield] SecureView: Could not find secure layer, falling back to basic container")
            #endif
            return
        }

        // Move container's layer to be a sublayer of the secure layer
        secureLayer.addSublayer(containerView.layer)

        #if DEBUG
        print("[RecordingShield] SecureView: Using fallback layer manipulation")
        #endif
    }

    deinit {
        #if DEBUG
        print("[RecordingShield] SecureView: Deallocated")
        #endif
    }
}
