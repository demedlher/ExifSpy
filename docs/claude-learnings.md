# Claude Learnings - dmd EXIF Viewer

How Claude can work more efficiently in this codebase.

## Project Structure

- **Build system**: Swift Package Manager (not Xcode project)
- **Entry point**: `Sources/dmdEXIFviewer/dmdEXIFviewerApp.swift`
- **Main UI**: `Sources/dmdEXIFviewer/ContentView.swift`
- **Release build**: Run `./build.sh` to create DMG

## Key Directories

- `Sources/dmdEXIFviewer/` - All Swift source code
- `Resources/Assets.xcassets/` - App icons and assets
- `screenshots/` - README screenshots
- `dmg_build/` - DMG packaging template (gitignored contents)

## Development Workflow

```bash
# Debug build and run
swift build && ./.build/debug/dmdEXIFviewer

# Release DMG
./build.sh
```

## Screenshot Generation & macOS UI Automation

This approach can be used for generating documentation screenshots and potentially for frontend testing.

### Prerequisites

1. **cliclick** - Mouse automation tool (install via `brew install cliclick`)
2. **Swift compiler** - For compiling helper tools

### Key Techniques

#### 1. Getting Window IDs with Swift/Quartz

macOS `screencapture -l<windowID>` captures a specific window without background. To get the window ID:

```swift
// Compile: swiftc -o /tmp/getwindowid getwindowid.swift
import Cocoa
import Quartz

let options = CGWindowListOption([.optionOnScreenOnly])
guard let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

for window in windowListInfo {
    if let ownerName = window[kCGWindowOwnerName as String] as? String,
       ownerName == "dmdEXIFviewer",
       let windowID = window[kCGWindowNumber as String] as? Int {
        print(windowID)
        exit(0)
    }
}
```

Usage:
```bash
WINDOW_ID=$(/tmp/getwindowid)
screencapture -l$WINDOW_ID -o screenshot.png  # -o removes shadow
```

#### 2. Window Positioning with AppleScript

Get window position and size:
```bash
osascript << 'EOF'
tell application "System Events"
    tell process "dmdEXIFviewer"
        set frontWindow to window 1
        set winPos to position of frontWindow
        set winSize to size of frontWindow
        return {item 1 of winPos, item 2 of winPos, item 1 of winSize, item 2 of winSize}
    end tell
end tell
EOF
```

Bring app to front (without launching a different version):
```bash
osascript << 'EOF'
tell application "System Events"
    tell process "dmdEXIFviewer"
        set frontmost to true
    end tell
end tell
EOF
```

#### 3. Simulating Drag-and-Drop with cliclick

```bash
# Open Finder to folder and select file
osascript << 'EOF'
tell application "Finder"
    set testFile to POSIX file "/path/to/file.jpg" as alias
    reveal testFile
    activate
    select testFile
end tell
EOF

# Get source coordinates (file in Finder) and target (app window center)
# Then drag:
cliclick dd:SOURCE_X,SOURCE_Y du:TARGET_X,TARGET_Y
```

### Complete Screenshot Workflow

```bash
# 1. Kill any existing instances
pkill -9 -f dmdEXIFviewer

# 2. Build and launch fresh
swift build
/full/path/to/.build/debug/dmdEXIFviewer &
sleep 2

# 3. Capture drop zone
WINDOW_ID=$(/tmp/getwindowid)
screencapture -l$WINDOW_ID -o screenshots/drop-zone.png

# 4. Load test image via drag-and-drop
osascript -e 'tell application "Finder" to reveal POSIX file "/path/to/test.jpg"'
sleep 0.5
cliclick dd:FINDER_X,FINDER_Y du:APP_X,APP_Y
sleep 1

# 5. Capture metadata view
WINDOW_ID=$(/tmp/getwindowid)
screencapture -l$WINDOW_ID -o screenshots/metadata-view.png
```

### Gotchas

1. **Multiple app versions**: If the app is installed elsewhere (e.g., `/Applications/`), `open -a AppName` or `tell application "AppName" to activate` may launch the wrong version. Always use full paths and `System Events` to control specific processes.

2. **Window IDs change**: After loading content or resizing, the window ID may change. Re-fetch it before each screenshot.

3. **Drag-and-drop coordinates**: Use AppleScript to get dynamic positions rather than hardcoded coordinates.

4. **Timing**: Add `sleep` delays between operations to allow UI to update.

### Future: Automated UI Testing

This same approach could be extended for automated UI testing:

```bash
# Test workflow
launch_app
capture_screenshot "initial_state"
drag_test_image
capture_screenshot "loaded_state"
compare_screenshots "expected/" "actual/"
```

Tools to consider:
- **XCTest + XCUITest** - Apple's native UI testing (requires Xcode project)
- **Playwright** - For web-based UIs
- **Custom Swift tool** - Using Accessibility APIs for more complex interactions

## Code Patterns

- SwiftUI with AppKit integration for native macOS feel
- Uses `CGImageSource` (ImageIO) for metadata extraction
- GPS coordinates link to Apple Maps and Google Maps

## Git Workflow

- Trunk-based development on `main`
- Small, focused commits
- Push directly to main
