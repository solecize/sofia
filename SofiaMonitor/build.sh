#!/bin/bash
# Build SofiaMonitor as a proper .app bundle
# Usage: ./build.sh [--run] [--install]

set -e

cd "$(dirname "$0")"

APP_NAME="SofiaMonitor"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Clean previous build
rm -rf "${APP_BUNDLE}"

# Create .app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile the binary
swiftc -o "${MACOS_DIR}/${APP_NAME}" \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  -framework ServiceManagement \
  -sdk "$(xcrun --show-sdk-path)" \
  -target arm64-apple-macosx14.0 \
  SofiaMonitor/SofiaMonitorApp.swift \
  SofiaMonitor/Models/Environment.swift \
  SofiaMonitor/Models/Work.swift \
  SofiaMonitor/Views/MenuBarView.swift \
  SofiaMonitor/Views/PreferencesView.swift \
  SofiaMonitor/Services/GitService.swift \
  SofiaMonitor/Services/StatsService.swift \
  SofiaMonitor/Services/FileWatcher.swift

# Copy Info.plist
cp Info.plist "${CONTENTS_DIR}/"

# Copy icon if it exists
if [ -f "resources/sofia.iconset/icon_512x512.png" ]; then
    # Create icns from iconset if iconutil is available
    if [ -d "resources/sofia.iconset" ]; then
        iconutil -c icns -o "${RESOURCES_DIR}/AppIcon.icns" resources/sofia.iconset 2>/dev/null || true
    fi
fi

# Ad-hoc code sign the app
echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Build complete: ${APP_BUNDLE}"

# Install to ~/Applications if requested
if [ "$1" = "--install" ] || [ "$2" = "--install" ]; then
    echo "Installing to ~/Applications..."
    mkdir -p ~/Applications
    rm -rf ~/Applications/"${APP_BUNDLE}"
    cp -R "${APP_BUNDLE}" ~/Applications/
    echo "Installed: ~/Applications/${APP_BUNDLE}"
fi

# Run if requested
if [ "$1" = "--run" ] || [ "$2" = "--run" ]; then
    echo "Starting ${APP_NAME}..."
    open "${APP_BUNDLE}"
fi
