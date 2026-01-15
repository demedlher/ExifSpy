#!/bin/bash

# Exit on error
set -e

# Clean previous builds
rm -rf .build
rm -f dmdEXIFviewer.dmg
rm -rf dmdEXIFviewer.app

# Build the app in release mode
swift build -c release

# Create app bundle structure
mkdir -p dmdEXIFviewer.app/Contents/{MacOS,Resources}

# Copy the executable
cp .build/release/dmdEXIFviewer dmdEXIFviewer.app/Contents/MacOS/

# Create Info.plist
cat > dmdEXIFviewer.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>dmdEXIFviewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.demed.dmdEXIFviewer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>dmdEXIFviewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Create DMG
mkdir -p temp
cp -r dmdEXIFviewer.app temp/

# Create the DMG
hdiutil create -volname "dmdEXIFviewer" -srcfolder temp -ov -format UDZO dmdEXIFviewer.dmg

# Clean up
echo "Cleaning up..."
rm -rf temp
rm -rf dmdEXIFviewer.app

# Done
echo "Build complete. App is ready at dmdEXIFviewer.dmg"
