# ExifSpy

A native macOS application for viewing EXIF metadata and image properties. Simply drag and drop any image or video file to instantly see all embedded metadata.

## Features

- **Drag-and-drop interface** - Drop any image or video file to view its metadata
- **Comprehensive metadata extraction** - Reads EXIF, TIFF, GPS, IPTC, PNG, and JFIF properties
- **Image preview** - Displays a scaled preview alongside metadata
- **File statistics** - Shows file name, path, size, dimensions, and aspect ratio
- **Smart formatting** - GPS coordinates, lens specs, and complex data types are human-readable
- **"Where was this photo taken?"** - One-click buttons to open GPS coordinates in Apple Maps or Google Maps
- **Copy to clipboard** - Right-click any field, section, or use "Copy All Metadata" button
- **Native macOS app** - Full dock presence, proper menu handling, SwiftUI interface

## Who is this for?

- **Photographers** who need to check what metadata is embedded in their photos
- **Divers** who want to extract GPS coordinates from a photo to log a dive site in apps like Subsurface
- **Hikers** who need to pull location data from a photo to identify a spot in their trail navigation app
- **Anyone else** who might need to spy into the EXIF info of their photos!

## Screenshots

| Drop Zone | Metadata View |
|:---------:|:-------------:|
| ![Drop Zone](screenshots/dropzone.png) | ![Metadata View](screenshots/metadata-view-and-copy.png) |
| *Drag and drop any image or video* | *View metadata with right-click copy support* |

## Requirements

- macOS 11.0 (Big Sur) or later
- Apple Silicon (arm64) for release builds

## Installation

### Option 1: Download Release

Download the latest `.dmg` from the [Releases](https://github.com/demedlher/ExifSpy/releases) page, open it, and drag the app to Applications.

> **macOS Security Notice**: This app is not signed with an Apple Developer certificate, so macOS will quarantine it by default. If you trust this app, remove the quarantine attribute by running:
> ```bash
> xattr -cr /Applications/ExifSpy.app
> ```

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/demedlher/ExifSpy.git
cd ExifSpy

# Build and run (debug)
swift build
./.build/debug/ExifSpy

# Or build release DMG
./build.sh
```

## Usage

1. Launch the application
2. Drag and drop an image or video file onto the window
3. View extracted metadata in organized sections:
   - **Image Properties** - Dimensions, DPI, color model, bit depth
   - **EXIF Details** - Camera settings, exposure, ISO, date taken
   - **TIFF Properties** - Make, model, software
   - **GPS Data** - Latitude, longitude, altitude (with buttons to view location in Apple Maps or Google Maps)
   - **IPTC Information** - Copyright, captions, keywords
   - **PNG/JFIF Properties** - Format-specific metadata
4. Right-click any field to copy its value, or use "Copy All Metadata" at the bottom

## Supported Formats

Any image format supported by macOS ImageIO, including:
- JPEG, PNG, HEIC, TIFF, GIF, BMP, WebP
- RAW formats (CR2, NEF, ARW, etc.)
- Video files (metadata only)

## Project Structure

```
ExifSpy/
├── Package.swift              # Swift Package Manager manifest
├── build.sh                   # Release build script (creates DMG)
├── Sources/
│   └── ExifSpy/
│       ├── ExifSpyApp.swift       # App entry point and delegate
│       ├── Models/                # Data models (ExifEntry, ExifSectionData, etc.)
│       ├── Views/                 # SwiftUI views
│       └── Services/              # Metadata extraction service
├── Resources/
│   └── AppIcon.icns           # App icon
└── screenshots/               # README screenshots
```

## Technical Details

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI with AppKit integration
- **Build System**: Swift Package Manager
- **Metadata API**: Apple ImageIO (`CGImageSource`)
- **Dependencies**: None (uses only Apple frameworks)

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Author

Demed L'Her ([@demedlher](https://github.com/demedlher))
