# sofia-refresh

Regenerate auto-generated sections in work-level documents while preserving author-written content.

## Usage

```bash
sofia-refresh <work-name>             # Refresh mechanical sections
sofia-refresh --all                   # Refresh all works
sofia-refresh <work> --dry-run        # Show what would change
sofia-refresh <work> --json           # JSON output for SofiaMonitor
sofia-refresh <work> --list-sections  # List all sections (built-in + custom)
```

## How It Works

`sofia-refresh` updates fenced sections in `notes/notebook.md` and `manuscript.md` using HTML comment markers. Content outside markers is never modified.

### Marker Format

```markdown
<!-- sofia:stats -->
## Quick Stats
| Metric | Value |
|--------|-------|
| Chapters | 53 |
| Words | 124,504 |
<!-- /sofia:stats -->
```

The script reads filesystem state (chapter counts, reference directories, etc.) and regenerates only the content between markers.

## Built-in Sections

| Section | Marker | Target | Source |
|---------|--------|--------|--------|
| Navigation | `sofia:navigation` | notebook.md | Scans for manuscript.md, chapters/, reference/, notes/ |
| Quick Stats | `sofia:stats` | notebook.md | chapters/*.md word/file count, .sofia/profile.md phase |
| Reference Index | `sofia:reference-index` | notebook.md | Scans reference/ subdirectories, extracts titles |
| Table of Contents | `sofia:toc` | manuscript.md | chapters/*.md filenames and first-line titles |

## Custom Sections

Users can define custom sections per-work or at the library level.

### Per-work sections

Create `.sofia/sections/<name>.md` inside a work directory:

```markdown
+++
id = "refresh.timeline"
target = "notebook"
marker = "timeline"
type = "prompt"
description = "Chronological event timeline from chapters"
+++

Read the chapters in this work and produce a chronological timeline.
Output as a markdown table with columns: Chapter, Event, Characters Involved.
```

### Library-level sections

Add to `library/refresh/sections/` for sections available to all works.

### Section definition fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `id` | Yes | `refresh.<name>` | Unique identifier |
| `target` | Yes | `notebook` or `manuscript` | Which file to inject into |
| `marker` | Yes | String | Marker name (→ `<!-- sofia:marker -->`) |
| `type` | Yes | `mechanical` or `prompt` | How content is generated |
| `description` | No | String | Human-readable description |

### Section types

**Mechanical** sections are generated automatically by `sofia-refresh` from filesystem state. No AI involvement needed.

**Prompt** sections contain instructions for an AI assistant. When the AI starts a session or the user requests a refresh:

1. The AI reads `.sofia/sections/*.md` definitions
2. Reads relevant work content (chapters, reference files)
3. Generates the section content following the prompt
4. Writes it between the `<!-- sofia:marker -->` fences
5. Asks for user approval before writing (per MX safety rules)

### Adding markers for custom sections

After creating a section definition, add the corresponding markers to your notebook or manuscript:

```markdown
<!-- sofia:timeline -->
*Timeline will be generated here.*
<!-- /sofia:timeline -->
```

## SofiaMonitor Integration

SofiaMonitor triggers `sofia-refresh` automatically:

```
File saved in corpus/works/<work>/
  → FileWatcher (2s debounce)
  → Auto-commit
  → sofia-dashboard       → corpus/index.md
  → sofia-refresh <work>  → notebook.md + manuscript.md
```

## Examples

### List available sections for a work

```bash
$ sofia-refresh error-correction --list-sections
Built-in mechanical sections:
  navigation       → notebook.md  (links to manuscript, chapters, reference)
  stats            → notebook.md  (chapter count, word count, phase)
  reference-index  → notebook.md  (reference directory entries)
  toc              → manuscript.md (table of contents from chapters/)

Custom sections (.sofia/sections/):
  timeline  → notebook.md  [prompt] Chronological event timeline
  cast      → notebook.md  [prompt] Character appearance tracker
```

### Dry run

```bash
$ sofia-refresh error-correction --dry-run
Dry run: error-correction
  Would update: <!-- sofia:navigation --> in notebook.md
  Would update: <!-- sofia:stats --> in notebook.md
  Would update: <!-- sofia:reference-index --> in notebook.md
  Would update: <!-- sofia:toc --> in manuscript.md
  4 section(s) would be updated
  2 prompt-based section(s) available for AI assistant
```
