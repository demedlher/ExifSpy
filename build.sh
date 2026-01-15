#!/bin/bash

# Exit on error
set -e

echo "Building dmdEXIFviewer v2.0..."

# Clean previous builds
rm -rf .build
rm -f dmdEXIFviewer.dmg
rm -rf dmdEXIFviewer.app

# Build the app in release mode
echo "Compiling release build..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p dmdEXIFviewer.app/Contents/{MacOS,Resources}

# Copy the executable
cp .build/release/dmdEXIFviewer dmdEXIFviewer.app/Contents/MacOS/

# Copy the icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns dmdEXIFviewer.app/Contents/Resources/
    echo "Icon added to app bundle"
fi

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.demed.dmdEXIFviewer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>dmd EXIF Viewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Create DMG
echo "Creating DMG installer..."
mkdir -p temp
cp -r dmdEXIFviewer.app temp/
ln -s /Applications temp/Applications

# Create the DMG
hdiutil create -volname "dmd EXIF Viewer" -srcfolder temp -ov -format UDZO dmdEXIFviewer.dmg

# Clean up
echo "Cleaning up..."
rm -rf temp
rm -rf dmdEXIFviewer.app

# Done
echo ""
echo "Build complete!"
echo "DMG ready at: dmdEXIFviewer.dmg"
ls -lh dmdEXIFviewer.dmg
