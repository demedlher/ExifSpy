import SwiftUI
import AppKit

/// Full-window overlay for zoomed image view
struct ImageZoomOverlay: View {
    let image: NSImage
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dark backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Zoomed image
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(20)
        }
        .overlay(
            KeyEventHandler(onKeyPress: { keyCode in
                // Escape = 53, Return = 36, Space = 49
                if keyCode == 53 || keyCode == 36 || keyCode == 49 {
                    onDismiss()
                    return true
                }
                return false
            })
        )
    }
}

/// NSViewRepresentable to capture keyboard events
struct KeyEventHandler: NSViewRepresentable {
    let onKeyPress: (UInt16) -> Bool

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyPress = onKeyPress
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onKeyPress = onKeyPress
    }
}

/// Custom NSView that captures key events but allows mouse clicks through
class KeyCaptureView: NSView {
    var onKeyPress: ((UInt16) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let handler = onKeyPress, handler(event.keyCode) {
            return
        }
        super.keyDown(with: event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    // Allow mouse events to pass through to views below
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}
