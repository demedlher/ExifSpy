import SwiftUI
import AppKit // Required for NSApplication and AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func showAboutPanel() {
        let creditsText = """
        © 2025 Demed L'Her – Dedicated-Labs.com
        MIT License

        View EXIF metadata from images and videos.
        Native macOS app with no external dependencies.

        https://github.com/demedlher/ExifSpy
        """

        let credits = NSAttributedString(
            string: creditsText,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )

        NSApplication.shared.orderFrontStandardAboutPanel(options: [
            .applicationName: "ExifSpy",
            .applicationVersion: AppVersion.version,
            .version: AppVersion.versionWithBuild,
            .credits: credits
        ])
    }
}

@main
struct ExifSpyApp: App {
    // Use NSApplicationDelegateAdaptor to connect our AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Try to load custom icon from bundle resources, fall back to SF Symbol
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let appIcon = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = appIcon
        } else if let appIcon = NSImage(systemSymbolName: "camera.aperture", accessibilityDescription: "ExifSpy") {
            appIcon.isTemplate = true
            NSApplication.shared.applicationIconImage = appIcon
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ExifSpy") {
                    appDelegate.showAboutPanel()
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .saveItem) {}
        }
    }
}