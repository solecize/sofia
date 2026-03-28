#!/bin/bash
# Build SofiaMonitor without Xcode
# Usage: ./build.sh [--run]

set -e

cd "$(dirname "$0")"

echo "Building SofiaMonitor..."

swiftc -o SofiaMonitorApp \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  SofiaMonitor/SofiaMonitorApp.swift \
  SofiaMonitor/Models/Environment.swift \
  SofiaMonitor/Models/Work.swift \
  SofiaMonitor/Views/MenuBarView.swift \
  SofiaMonitor/Views/PreferencesView.swift \
  SofiaMonitor/Services/GitService.swift \
  SofiaMonitor/Services/StatsService.swift \
  SofiaMonitor/Services/FileWatcher.swift

echo "Build complete: SofiaMonitorApp"

if [ "$1" = "--run" ]; then
    echo "Starting SofiaMonitor..."
    ./SofiaMonitorApp &
    echo "SofiaMonitor running (PID: $!)"
fi
