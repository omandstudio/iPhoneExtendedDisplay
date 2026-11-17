#!/bin/bash
# ==============================================================================
# iPhone Extended Display - Automated Build Script
# Author: YoiKut.com (https://yoikut.com)
# Repository: https://github.com/omandstudio/iPhoneExtendedDisplay
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="iPhone Extended Display"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=========================================================="
echo "  🛠️  Building ${APP_NAME} for macOS"
echo "  Author: YoiKut.com"
echo "  Repo: omandstudio/iPhoneExtendedDisplay"
echo "=========================================================="

# Create App bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.yoikut.iPhoneExtendedDisplay</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>iPhone Extended Display membutuhkan izin merekam layar untuk menampilkan monitor Mac ke iPhone Anda.</string>
</dict>
</plist>
EOF

echo "==> Compiling Swift sources..."
swiftc \
    macOS/main.swift \
    macOS/AppDelegate.swift \
    macOS/ControlWindow.swift \
    macOS/ExtendedDisplayService.swift \
    macOS/WebServer.swift \
    macOS/WebClientHTML.swift \
    macOS/ScreenCaptureManager.swift \
    macOS/VirtualDisplayManager.swift \
    macOS/InputInjector.swift \
    macOS/NetworkServer.swift \
    macOS/H264Encoder.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ScreenCaptureKit \
    -framework CoreGraphics \
    -framework VideoToolbox \
    -framework CoreMedia \
    -framework Network \
    -parse-as-library \
    -O \
    -o "${MACOS_DIR}/${APP_NAME}"

echo "==> Setting executable permissions..."
chmod +x "${MACOS_DIR}/${APP_NAME}"
chmod +x "Start-iPhoneExtendedDisplay.command"

echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=========================================================="
echo "  ✅ Build complete: ${APP_BUNDLE}"
echo "  You can launch the app directly or via Start-iPhoneExtendedDisplay.command"
echo "=========================================================="
