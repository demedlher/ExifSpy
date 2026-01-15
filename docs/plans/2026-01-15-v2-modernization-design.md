# dmd EXIF Viewer v2.0 - Modernization Design

**Date:** 2026-01-15
**Status:** Approved

## Overview

Modernize the macOS app to align with Apple HIG guidelines while maintaining its simple drag-and-drop widget nature. Structure code for future iOS support.

## Requirements

### Functional
- Remove dotted rounded border around app
- Add image zoom: click to expand in modal overlay
- Scrollable EXIF list (verify native List behavior)
- Resizable split panes
- Minimal toolbar with clear/reset button

### Non-Functional
- Follow Apple Human Interface Guidelines
- Use system materials and native styling
- Structure code for future iOS (share sheet + photo picker)

## Architecture

```
Sources/dmdEXIFviewer/
├── Models/
│   ├── ExifEntry.swift         # Data models (shared)
│   ├── ExifSectionData.swift
│   └── FileStats.swift
├── Services/
│   └── MetadataExtractor.swift # ImageIO logic (shared)
├── Views/
│   ├── Shared/
│   │   ├── ExifListView.swift      # Metadata display (shared)
│   │   └── ImagePreviewView.swift  # Preview component (shared)
│   └── macOS/
│       ├── ContentView.swift       # Main macOS view
│       ├── DropZoneView.swift      # Drop zone UI
│       └── ImageZoomOverlay.swift  # Modal zoom view
└── dmdEXIFviewerApp.swift      # App entry point
```

**Rationale:** Models and Services are pure Swift, reusable on iOS. Views split into Shared (cross-platform SwiftUI) and platform-specific folders.

## Visual Design

### Window & Chrome
- No border - clean window edges
- Hidden title bar with inline toolbar
- Single toolbar button: `xmark.circle` SF Symbol to clear/reset
- System background color, no manual padding/overlay

### Materials & Surfaces
- Drop zone: Subtle visual effect with `.hudWindow` material
- Left pane: Standard window background
- Right pane: Native `List` with `.inset(alternatesRowBackgrounds: true)`
- Resizable split via `HSplitView`

### Spacing & Typography
- Apple HIG spacing: 20pt margins, 12pt between elements
- System fonts: `.headline`, `.body`, `.caption`
- Native List section headers (no custom styled boxes)

### Drop Zone State
- Centered icon + text, no border
- Drag hover: System accent color at 10% opacity background

## Image Zoom Overlay

### Trigger
- Click on image preview
- Cursor shows magnifying glass on hover

### Behavior
- Dark backdrop: `.black.opacity(0.85)` covers window
- Image scales to fit with 20pt padding
- Maintains aspect ratio
- 0.25s ease-in-out animation

### Dismissal
- Click backdrop
- Press Escape
- Press Space

### Implementation
```swift
struct ImageZoomOverlay: View {
    let image: NSImage
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(20)
        }
        .onExitCommand { onDismiss() }
    }
}
```

## Split Pane & Scrolling

### Split View
- `HSplitView` for resizable panes
- Left pane: min 200pt, default 280pt, max 400pt
- Right pane: remaining space, min 300pt
- Draggable divider

### EXIF List
- Native `List` with automatic scrolling
- `.listStyle(.inset(alternatesRowBackgrounds: true))`
- Sticky section headers

### Left Pane
- Image preview: flexible height, max 50% of pane
- File info below
- ScrollView wrapper for small windows

### Window Size
- Minimum: 600 x 400 (reduced from 750 x 550)
- Responsive content scaling

## Migration Summary

| v1.0 | v2.0 |
|------|------|
| Dotted border | No border |
| Custom section headers | Native List styling |
| Fixed layout | Resizable HSplitView |
| No image interaction | Click to zoom overlay |
| Monolithic ContentView | Split Models/Services/Views |
| macOS only | iOS-ready structure |

## Future iOS Considerations

When adding iOS support:
1. Add `Views/iOS/` folder with platform-specific views
2. Implement share sheet extension
3. Add photo picker using PHPickerViewController
4. Reuse Models and Services unchanged
