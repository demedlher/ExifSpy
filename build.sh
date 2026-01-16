#!/bin/bash

# Exit on error
set -e

echo "Building ExifSpy v2.1..."

# Clean previous builds
rm -rf .build
rm -f ExifSpy.dmg
rm -rf ExifSpy.app

# Build the app in release mode
echo "Compiling release build..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p ExifSpy.app/Contents/{MacOS,Resources}

# Copy the executable
cp .build/release/ExifSpy ExifSpy.app/Contents/MacOS/

# Copy the icon
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns ExifSpy.app/Contents/Resources/
    echo "Icon added to app bundle"
fi

# Create Info.plist
cat > ExifSpy.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ExifSpy</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.demed.ExifSpy</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ExifSpy</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.1</string>
    <key>CFBundleVersion</key>
    <string>3</string>
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
cp -r ExifSpy.app temp/
ln -s /Applications temp/Applications

# Create the DMG
hdiutil create -volname "ExifSpy" -srcfolder temp -ov -format UDZO ExifSpy.dmg

# Clean up
echo "Cleaning up..."
rm -rf temp
rm -rf ExifSpy.app

# Done
echo ""
echo "Build complete!"
echo "DMG ready at: ExifSpy.dmg"
ls -lh ExifSpy.dmg
