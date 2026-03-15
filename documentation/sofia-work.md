# Sofia Work: Manuscript Management

Sofia Work is a CLI tool for managing manuscripts as structured projects with versioning, wiki integration, and prose surfacing.

## Overview

While Notator organizes notes, Sofia Work manages **manuscripts**—the canonical prose of a writing project. It provides:

- **Chapter management**: Split, organize, and track chapters
- **Versioning**: Git micro-commits + explicit version milestones
- **Wiki sync**: Auto-sync chapters to wiki and canon directories
- **Prose surfacing**: Classify and place prose from notes into chapters
- **Watch daemon**: Auto-commit on file save (for Typora/editor integration)

---

## Quick Start

```bash
# Initialize a new manuscript
sofia-work init prince-of-loves

# Import content
sofia-work ingest prince-of-loves manuscript.md

# Check status
sofia-work status prince-of-loves

# Edit with auto-save protection
sofia-work checkout prince-of-loves
sofia-work watch prince-of-loves      # Start auto-commit daemon

# ... edit in Typora or any editor ...

sofia-work watch prince-of-loves --stop
sofia-work checkin prince-of-loves    # Version bump
```

---

## Commands

### `init <project>`

Create a new manuscript structure:

```bash
sofia-work init prince-of-loves
```

Creates:
```
notes/works/prince-of-loves/
├── manuscript.md          # Table of contents
├── chapters/              # Chapter files
├── orphans.md             # Unplaced prose
├── .sofia/
│   └── work.json          # Metadata
└── versions/              # Snapshots
```

### `ingest <project> <source>`

Import content from various sources:

```bash
sofia-work ingest prince-of-loves manuscript.md
sofia-work ingest prince-of-loves chatgpt-export.html
sofia-work ingest prince-of-loves notes-folder/
```

**Supported formats:**
- `.md`, `.txt` — Markdown/plaintext (splits on `# Chapter` markers)
- `.html` — ChatGPT conversation exports (auto-detected)
- `.docx` — Word documents (via pandoc)
- Directories — Bulk import all supported files

**Post-ingest:**
- Regenerates table of contents
- Syncs chapters to `notes/canon/<project>/`
- Creates wiki chapter index at `notes/wiki/<project>/chapters/`

### `status [project]`

Show manuscript state:

```bash
sofia-work status                    # List all works
sofia-work status prince-of-loves    # Show specific work
```

Output:
```
Work: prince-of-loves
Version: 0.1.1
Modified: 2026-03-15T17:39:15Z
Status: Ready

Chapters: 12

Chapter List:
  01-synth-pop-sunday (95 lines)
  02-thief-delivers-a-song-of-simon (9 lines)
  ...
```

### `toc <project>`

Regenerate the table of contents in `manuscript.md`:

```bash
sofia-work toc prince-of-loves
```

### `checkout <project>`

Create a snapshot before editing:

```bash
sofia-work checkout prince-of-loves
```

- Creates timestamped snapshot in `versions/`
- Marks work as "checked out" in metadata
- Prevents concurrent checkouts

### `checkin <project>`

Complete editing session:

```bash
sofia-work checkin prince-of-loves
```

- Bumps version (0.1.1 → 0.1.2)
- Regenerates TOC
- Clears checkout lock
- Git commits changes

### `surface <project>`

Find and place prose from notes:

```bash
sofia-work surface prince-of-loves
sofia-work surface prince-of-loves --json  # LLM-assisted placement
```

**Process:**
1. Scans `notes/incoming/` and `notes/wiki/<project>/` for prose
2. Classifies content using `classify-prose` script
3. Places tagged content (e.g., `chapter: 01-opening`)
4. Generates LLM prompt for untagged content

**Tags recognized:**
- `chapter: <name>` — Place in specific chapter
- `scene: <name>` — Create working chapter
- `placement: orphan` — Add to orphans.md

### `watch <project> [--stop|--status]`

File-watching daemon for auto-commits:

```bash
sofia-work watch prince-of-loves          # Start daemon
sofia-work watch prince-of-loves --status # Check if running
sofia-work watch prince-of-loves --stop   # Stop daemon
```

**Behavior:**
- Monitors `chapters/*.md`, `orphans.md`, `manuscript.md`
- Auto-commits on save with 2-second debounce
- Commit format: `auto: prince-of-loves 01-synth-pop-sunday.md @ 14:05:04`
- Logs to `.sofia/watch.log`

**Requirements:** `fswatch` (`brew install fswatch`)

---

## Options

| Flag | Description |
|------|-------------|
| `--json` | Output JSON instruction blocks for LLM orchestration |
| `--dry-run` | Show what would be done without executing |
| `--no-commit` | Skip git commits |

---

## Directory Structure

```
notes/
├── works/<project>/           # Manuscript workspace
│   ├── manuscript.md          # TOC with chapter links
│   ├── chapters/              # Chapter files (01-*.md, WC-*.md)
│   ├── orphans.md             # Unplaced prose
│   ├── reference-notes.md     # Extracted notes/outlines
│   ├── .sofia/
│   │   ├── work.json          # Metadata, version, checkout
│   │   ├── placements.json    # Surfacing audit log
│   │   ├── watch.pid          # Daemon PID
│   │   └── watch.log          # Daemon log
│   └── versions/              # Milestone snapshots
│       └── pre-edit-YYYYMMDD-HHMMSS/
│
├── wiki/<project>/            # Wiki (synced from manuscript)
│   ├── chapters/index.md      # Chapter listing
│   ├── people/
│   ├── places/
│   └── ...
│
├── canon/<project>/           # Canonical chapters (read-only copy)
│   └── chapters/
│
└── incoming/                  # Raw imports
```

---

## work.json Schema

```json
{
  "project": "prince-of-loves",
  "version": "0.1.2",
  "created": "2026-03-15T17:38:29Z",
  "modified": "2026-03-15T18:45:00Z",
  "checkout": null,
  "chapters": [],
  "orphan_count": 0
}
```

---

## Workflow Example

### Initial Setup

```bash
# Create manuscript
sofia-work init prince-of-loves

# Import existing content
sofia-work ingest prince-of-loves ~/Documents/manuscript.md

# Split into chapters (if needed)
python3 scripts/split-manuscript.py
sofia-work toc prince-of-loves
```

### Daily Writing (with Typora)

```bash
# Start session
sofia-work checkout prince-of-loves
sofia-work watch prince-of-loves

# Open in Typora, enable autosave
# Every save → git micro-commit

# End session
sofia-work watch prince-of-loves --stop
sofia-work checkin prince-of-loves
```

### Surfacing Notes

```bash
# Add prose to notes with tags
echo "chapter: 01-opening" >> notes/incoming/new-scene.md

# Surface into manuscript
sofia-work surface prince-of-loves

# Or use LLM assistance
sofia-work surface prince-of-loves --json
```

---

## Integration with Sofia Wiki

Sofia Work syncs with `sofia-wiki` for entity extraction:

```bash
# After ingest, extract entities from chapters
sofia-wiki extract prince-of-loves 01-synth-pop-sunday

# Or batch process
sofia-wiki loop prince-of-loves --json
```

The wiki provides:
- Character/place/event tracking
- Cross-reference validation
- Continuity checking

---

## Related Scripts

| Script | Purpose |
|--------|---------|
| `scripts/sofia-work` | Main CLI |
| `scripts/sofia-watch` | File-watching daemon |
| `scripts/classify-prose` | Prose/note classifier |
| `scripts/parse-chatgpt-html` | ChatGPT export converter |
| `scripts/split-manuscript.py` | Chapter splitter utility |
