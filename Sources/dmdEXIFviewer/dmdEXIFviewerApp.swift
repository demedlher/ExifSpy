import SwiftUI
import AppKit // Required for NSApplication and AppDelegate

// Define AppDelegate within the same file for simplicity for now
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app can become the active application and show its windows.
        // This is crucial for apps launched from the terminal.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        print("AppDelegate: applicationDidFinishLaunching - Activation policy set and app activated.")
    }

    // Optional: This makes the app quit when its last window is closed.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct dmdEXIFviewerApp: App {
    // Use NSApplicationDelegateAdaptor to connect our AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Set the app's icon using SF Symbol
        if #available(macOS 11.0, *) {
            if let appIcon = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "dmdEXIFviewer") {
                appIcon.isTemplate = true
                NSApplication.shared.applicationIconImage = appIcon
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .saveItem) {}
        }
    }
}