# Sofia Monitor

A native macOS menu bar app for real-time file monitoring and multi-environment management.

## Features

- **Multi-environment support**: Monitor multiple Sofia instances (e.g., `sofia`, `writelab`)
- **File watching**: FSEvents-based monitoring of `corpus/works/`
- **Auto-commit**: Commit changes automatically with timestamps
- **Editor integration**: Open environments in Windsurf, Cursor, or VS Code
- **Offline detection**: Detect changes made while app was closed

## Building

Open `SofiaMonitor.xcodeproj` in Xcode 15+ and build.

```bash
# Or build from command line
xcodebuild -project SofiaMonitor.xcodeproj -scheme SofiaMonitor -configuration Release
```

## Project Structure

```
SofiaMonitor/
├── SofiaMonitorApp.swift      # App entry, menu bar setup
├── Models/
│   ├── Environment.swift      # Environment model
│   └── Work.swift             # Work model, change events
├── Services/
│   ├── FileWatcher.swift      # FSEvents wrapper
│   ├── GitService.swift       # Git operations
│   └── StatsService.swift     # Word count, chapter stats
├── Views/
│   ├── MenuBarView.swift      # Main menu content
│   └── PreferencesView.swift  # Settings window
└── Resources/
    └── (menu bar icons)
```

## Configuration

Settings are stored in:
```
~/Library/Application Support/SofiaMonitor/
├── environments.json    # Environment registry
└── preferences.json     # App settings
```

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 15+ (for building)
- Git installed

## Adding a Menu Bar Icon

1. Create icon assets in `Resources/Assets.xcassets`
2. Add `AppIcon` and menu bar icon variants
3. The app uses SF Symbols by default (`circle.fill`)

## License

Part of the Sofia project.
