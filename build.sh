#!/bin/bash
set -e

APP_NAME="DotCalendar"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Collect all Swift source files
SWIFT_FILES=$(find Sources -name '*.swift' -type f)

# Compile
swiftc \
    -O \
    -parse-as-library \
    -target arm64-apple-macos14.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    $SWIFT_FILES

# Copy Info.plist, icon, and about image
cp Info.plist "$APP_BUNDLE/Contents/"
cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/"
cp Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png "$APP_BUNDLE/Contents/Resources/"

# Compile asset catalog if actool is available
if command -v actool &>/dev/null || xcrun --find actool &>/dev/null 2>&1; then
    echo "Compiling asset catalog..."
    xcrun actool Resources/Assets.xcassets \
        --compile "$APP_BUNDLE/Contents/Resources" \
        --platform macosx \
        --minimum-deployment-target 14.0 \
        --app-icon AppIcon \
        --output-partial-info-plist /dev/null \
        2>/dev/null || echo "Asset catalog compilation skipped (actool warning)"
fi

# Ad-hoc sign
codesign --force --sign - "$APP_BUNDLE"

echo ""
echo "Build successful: $APP_BUNDLE"

# Create DMG
echo ""
echo "Creating DMG..."

DMG_DIR="$BUILD_DIR/dmg"
rm -rf "$DMG_DIR" "$BUILD_DIR/$DMG_NAME"
mkdir -p "$DMG_DIR"
cp -r "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$BUILD_DIR/$DMG_NAME" \
    -quiet

rm -rf "$DMG_DIR"

echo "DMG created: $BUILD_DIR/$DMG_NAME"
echo ""
echo "To install: open $BUILD_DIR/$DMG_NAME and drag to Applications"
