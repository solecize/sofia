# Sofia Monitor

A native macOS menu bar app for real-time file monitoring, auto-commit, and multi-environment management.

## Overview

Sofia Monitor runs in your menu bar and watches your Sofia environments for changes. It auto-commits edits, tracks offline changes, and provides quick access to your works and preferred editor.

## Features

| Feature | Description |
|---------|-------------|
| **Multi-environment** | Monitor multiple Sofia instances (e.g., `sofia`, `writelab`) |
| **File watching** | FSEvents-based monitoring of `corpus/works/` |
| **Auto-commit** | Commit changes automatically with timestamps |
| **Change queue** | Review pending commits in a changelog view |
| **Offline detection** | Detect and commit changes made while app was closed |
| **Editor integration** | Open environments in Windsurf, Cursor, or VS Code |

## Menu Bar Interface

```
┌─────────────────────────────┐
│ ● Sofia Monitor             │
├─────────────────────────────┤
│ Environments                │
│   ● sofia (last used)       │
│   ○ writelab                │
├─────────────────────────────┤
│ Works (sofia)               │
│   origin-of-species  ✓ 2m   │
│   frankenstein       ● 5s   │
│   christmas-carol    ✓ 1h   │
├─────────────────────────────┤
│ 3 changes pending review    │
│ [Review Changes...]         │
├─────────────────────────────┤
│ Open in [Editor] ▸          │
│ Open Dashboard              │
│ Preferences...              │
│ Quit                        │
└─────────────────────────────┘
```

### Status Indicators

| Icon | Meaning |
|------|---------|
| ● (green) | Idle, all changes committed |
| ● (yellow) | Syncing or changes pending |
| ● (blue) | Changes pending review |

### Work Status

| Symbol | Meaning |
|--------|---------|
| ✓ | All changes committed |
| ● | Recent change (within last minute) |
| ⚠ | Uncommitted changes |

## Environment Management

Sofia Monitor can track multiple Sofia installations simultaneously.

### Adding an Environment

1. Click **Preferences...** in the menu
2. Click **Add Environment**
3. Select the Sofia project root (the folder containing `corpus/`)
4. Give it a name (e.g., "writelab")

### Switching Environments

Click an environment name in the menu to switch the active context. The works list updates to show that environment's projects.

### Last Used Tracking

The app remembers which environment you accessed most recently and marks it with "(last used)" in the menu.

## Editor Integration

Sofia Monitor routes files to different editors based on type:

| File Type | Extensions | Default |
|-----------|------------|--------|
| **Environment** | Directories, `.swift`, `.sh`, `.json`, `.py`, etc. | Windsurf |
| **Document** | `.md`, `.txt`, `.rtf` | OS Default |

### Configuring Editors

Open **Preferences → Editors** to set your preferred editors:

**Environment Editor** (for code and directories):
- Windsurf, Cursor, VS Code
- OS Default (uses Finder's default)

**Document Editor** (for prose and markdown):
- Typora, iA Writer, Obsidian
- OS Default (uses Finder's default for `.md` files)

The "OS Default" option respects your Finder settings. If you've set BBEdit, TextWrangler, or any other app as your default handler for `.md` files, Sofia Monitor will use it.

### Open in Editor Menu

The **Open in [Editor] ▸** submenu provides quick access to:

- Environment roots (e.g., `sofia/`, `writelab/`)
- Recent work directories

The menu label updates to show your selected environment editor.

## Auto-Commit Behavior

### Real-Time Commits

When you save a file in `corpus/works/`, Sofia Monitor:

1. Detects the change via FSEvents
2. Waits 2 seconds for additional changes (debounce)
3. Commits with message: `auto: project file @ HH:MM:SS`
4. Adds to changelog for review

### Offline Changes

When the app launches or wakes from sleep:

1. Scans all environments for uncommitted changes
2. Auto-commits with: `offline: project file @ HH:MM:SS`
3. Shows notification: "Sofia detected X changes while offline"
4. Queues commits for review

## Change Review

Click **Review Changes...** to see recent commits:

- Commit message and timestamp
- Files changed
- Diff preview
- Option to revert or amend

## Configuration

Settings are stored in:
```
~/Library/Application Support/SofiaMonitor/
├── environments.json    # Environment registry
├── preferences.json     # App settings
└── changelog.json       # Pending review queue
```

### environments.json

```json
{
  "environments": [
    {
      "name": "sofia",
      "path": "/Users/you/Documents/sofia",
      "lastUsed": "2026-03-21T10:30:00Z"
    }
  ],
  "isLocked": false,
  "lockedEnvironmentId": null
}
```

Editor preferences are stored separately in UserDefaults:
- `environmentEditor`: Selected environment editor (e.g., "windsurf", "system")
- `documentEditor`: Selected document editor (e.g., "typora", "system")

## Requirements

- macOS 13.0+ (Ventura or later)
- Git installed and configured
- At least one Sofia environment

## Installation

1. Download `SofiaMonitor.app`
2. Move to `/Applications/`
3. Launch and add your first environment
4. (Optional) Enable "Launch at Login" in Preferences
