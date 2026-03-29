> **AI Assistants:** Read [LLM_START_HERE.md](LLM_START_HERE.md) before helping organize writing.

# Sofia

<p align="center">
  <img src="assets/sofia-01.png" alt="Sofia" width="200">
</p>

**A prompt composer for writers who need to organize, not improvise.**

Sofia is a CLI tool that generates structured, repeatable prompts for LLM-driven writing workflows. Instead of asking an AI to create content, Sofia instructs it to *organize your content*—sorting notes, enforcing naming conventions, and tracking changes without creative interference.

## The Problem

Writers accumulate notes everywhere: voice memos transcribed by Whisper, quick captures in apps, scattered markdown files. When you ask an LLM to help organize this mess, it tends to:

- Add its own prose and "helpful" summaries
- Make creative decisions you didn't ask for
- Behave inconsistently across sessions
- Lose track of what it already processed

## The Solution

Sofia inverts the typical LLM relationship. Instead of prompting the model and hoping for the best, Sofia:

1. **Composes deterministic prompts** from a human-editable library
2. **Repeats core instructions every turn** to keep the model on task
3. **Tracks state via session manifests** so nothing gets lost
4. **Emits structured JSON** for orchestration and auditing

The model becomes an executor of your rules, not a creative collaborator.

## Quick Start

```bash
# List available switches
sofia notator list

# Run with switches
sofia notator run -process -preview

# Manage manuscripts
sofia-work init my-novel
sofia-work status my-novel
```

## Example

```
User: "organize my notes in incoming and move them to preview"

Sofia composes:
  -process -preview

Output prompt:
  "You are an editing assistant that organizes notes without adding prose.
   Move files from corpus/incoming to corpus/works/.
   Apply kebab-case naming. Do not invent content.
   Annotate all outputs as a dry run (preview)..."
```

The prompt is built from modular, version-controlled markdown files. You can edit them, add your own switches, and customize behavior without touching code.

## Core Concepts

### Prompt-as-Output

Sofia doesn't execute actions—it generates prompts. The LLM (in Windsurf, Claude, or any pipeline) reads the prompt and performs the work. This keeps humans in the loop and makes every action auditable.

### Switches

CLI-style flags that map to prompt fragments:

| Switch | Purpose |
|--------|---------|
| `-process` | Organize notes from incoming → preview |
| `-rename` | Apply filename policy (kebab-case default) |
| `-preview` | Dry-run mode; describe without executing |
| `-git` | Stage and commit changes |
| `-report-brief` | Generate summary report |

Switches can include other switches. `-process` includes `-rename` and `-report-brief` automatically.

### Exclusive Groups

Some switches are mutually exclusive:

- **filename-policy**: `-filename-kebab`, `-filename-camel`, `-filename-pascal`
- **report-detail**: `-report-brief`, `-report-verbose`
- **commit-policy**: `-git`, `-no-commit`

Sofia resolves conflicts with clear precedence: CLI > tool include > workspace > defaults.

### Variables

Prompts use `{namespace.key}` placeholders:

```
{paths.incoming}     → corpus/incoming
{naming.kebab_case}  → "lowercase, hyphen-separated..."
{report.dir}         → reports
```

Variables live in `library/vars/*.md` and can be overridden per workspace.

### Workspaces

Profiles for different contexts (e.g., meeting notes vs. fiction):

```bash
./scripts/sofia-work status
```

Workspaces override group defaults and variables without modifying the core library.

## Project Structure

```
sofia/
├── corpus/
│   ├── works/              # Your writing projects
│   │   └── <project>/
│   │       ├── chapters/   # Chapter files
│   │       ├── notes/      # Notebook and chapter notes
│   │       ├── reference/  # Characters, places, objects, events
│   │       ├── manuscript.md
│   │       └── orphans.md
│   └── incoming/           # Raw imports
├── library/                # Prompt library (customizable)
├── config/                 # Configuration and workspaces
├── sessions/               # Generated prompts and manifests
├── scripts/                # CLI tools
└── documentation/          # User guides
```

## Echo JSON

Every run emits a structured control block:

```json
{
  "ui": "Organize notes: -process, -rename, -preview",
  "ask": {"confirm": {"default": true, "options": ["continue", "revise", "cancel"]}},
  "data": {
    "tool": "notator",
    "requestedSwitches": ["-process", "-preview"],
    "includedSwitches": ["-rename", "-filename-kebab", "-report-brief"],
    "resolvedSwitches": [...],
    "composedPrompts": [...],
    "selectedGroups": {"filename-policy": {"chosen": "-filename-kebab", "source": "tool"}},
    "git": {"policy": "auto", "source": "defaults"},
    "warnings": []
  }
}
```

This enables:
- **Orchestration**: Chain Sofia with other tools
- **Auditing**: See exactly what was composed and why
- **Debugging**: Trace switch resolution and variable substitution

## Design Philosophy

1. **No creative insertion**: The LLM organizes your ideas; it doesn't add its own.
2. **Repeatability**: Same inputs → same prompts → predictable behavior.
3. **Transparency**: Every decision is logged and traceable.
4. **Human control**: You edit the prompt library; Sofia just composes it.

## Installation

See [BUILDING.md](BUILDING.md) for build instructions.

## License

MIT

## Tools

### Notator
Organize notes without adding prose. Moves files, applies naming conventions, tracks changes.

### Sofia Work
Manage manuscripts with chapter organization, versioning, and wiki sync.

```bash
sofia-work init origin-of-species
sofia-work ingest origin-of-species manuscript.md
sofia-work watch origin-of-species    # Auto-commit on save
sofia-work checkin origin-of-species  # Version bump
```

### Sofia Wiki
Extract entities and track continuity across chapters.

See [documentation/](documentation/) for full details.

## Status

MVP complete. Notator, Sofia Work, and Sofia Wiki are functional.
