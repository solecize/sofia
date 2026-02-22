# Sofia Architecture

This document consolidates the technical design for Sofia and its first tool, Notator.

## Overview

Sofia is a **prompt composer**—it builds structured, deterministic prompts from a human-editable library of markdown files. The composed prompts are executed by an LLM (in Windsurf or any pipeline), not by Sofia itself.

### Core Principles

1. **Prompt-as-output**: Sofia returns prompts, not results
2. **LLM-as-agent**: Execution is delegated to a language model
3. **Human control**: All behaviors are editable via Markdown and config
4. **Minimal dependencies**: C99 with vendored TOML parser

---

## Components

### CLI (`src/sofia.c`)

Entry point with subcommands:

```
sofia notator list              # List available switches
sofia notator run <switches>    # Compose and emit prompts
```

### Library Loader

Scans `library/` for markdown files with TOML front matter. Extracts:
- Switch definitions (name, help, includes, aliases, exclusive_group)
- Variable namespaces (key-value pairs)
- Prompt text from fenced `prompt` blocks

### Registry

In-memory maps built during load:
- `switches[]`: canonical switch definitions
- `aliases[]`: alias → canonical name mapping
- `groups[]`: exclusive group → variant list
- `vars[]`: flattened `namespace.key` → value

### Composer

Resolves requested switches:
1. Normalize aliases to canonical names
2. Expand `includes` via DFS (with cycle detection, max depth 8)
3. Resolve exclusive groups with precedence: CLI > tool include > workspace > defaults > registry
4. Substitute `{namespace.key}` variables in prompt text

### Echo Emitter

Outputs structured JSON:
- `ui`: Human-readable summary
- `ask`: Confirmation options
- `data`: Full resolution details (switches, variables, prompts, warnings)
- `next`: Suggested follow-up command

### Session Logger

Writes `sessions/YYYYMMDD-HHMMSSZ/manifest.json` for each run.

---

## Markdown Library Spec

### Front Matter

TOML delimited by `+++`:

```toml
+++
tool = "notator"
type = "switch"
switch = "-process"
help = "Process incoming notes and prepare for preview."
includes = ["-rename", "-report-brief"]
tags = ["core"]
version = 1
id = "notator.process"
+++
```

**Common fields:**
- `type`: `"switch"` | `"vars"` | `"workspace"` | `"defaults"`
- `tool`: Namespace (`"notator"`, `"shared"`)
- `id`: Stable identifier (survives renames)
- `version`: Integer for tracking changes

**Switch-specific:**
- `switch`: Canonical CLI flag (e.g., `-process`)
- `help`: Short description
- `aliases`: Alternate flags
- `includes`: Switches to pull in
- `exclusive_group`: Group name for mutual exclusion
- `default`: `true` if this is the group's default variant

### Prompt Blocks

First fenced block labeled `prompt` is the canonical instruction:

````markdown
```prompt
You are an editing assistant that organizes notes without adding prose.
Move files from {paths.incoming} to {paths.preview}.
Apply {naming.kebab_case}. Do not invent content.
```
````

### Variable Files

```toml
+++
type = "vars"
namespace = "paths"
+++
```

```toml
incoming = "notes/incoming"
preview  = "notes/preview"
```

Variables are referenced as `{namespace.key}` in prompts.

---

## Exclusive Groups

Mutually exclusive switches share an `exclusive_group`:

| Group | Variants | Default |
|-------|----------|---------|
| `filename-policy` | `-filename-kebab`, `-filename-camel`, `-filename-pascal` | `-filename-kebab` |
| `report-detail` | `-report-brief`, `-report-verbose` | `-report-brief` |
| `commit-policy` | `-git`, `-no-commit` | `-git` |

### Resolution Precedence

1. **CLI**: Explicit user request (last wins if multiple)
2. **Tool include**: Switch pulled in by another switch
3. **Workspace**: Profile-specific override
4. **Defaults**: Global config (`config/defaults.md`)
5. **Registry**: `default = true` flag in switch definition

Conflicts emit warnings; the higher-precedence choice wins.

---

## Workspaces

Profiles stored in `config/workspaces/<name>.md`:

```toml
+++
type = "workspace"
id = "workspace.meeting_notes"
name = "Meeting Notes"
+++
```

```toml
[groups]
commit-policy = "-no-commit"

[tools.notator.groups]
report-detail = "-report-verbose"

[vars.report]
dir = "reports/meetings"
```

Usage:
```bash
sofia notator run --workspace meeting-notes -process
```

---

## Echo JSON Schema

```json
{
  "ui": "Human-readable summary",
  "ask": {
    "confirm": {
      "default": true,
      "options": ["continue", "revise", "cancel"]
    }
  },
  "data": {
    "tool": "notator",
    "requestedSwitches": ["-process", "-preview"],
    "includedSwitches": ["-rename", "-filename-kebab"],
    "resolvedSwitches": ["-filename-kebab", "-rename", "-process", "-preview"],
    "variables": {"paths.incoming": "notes/incoming", ...},
    "composedPrompts": ["...resolved prompt text..."],
    "sourceFiles": {"-process": "library/notator/switches/process.md", ...},
    "selectedGroups": {
      "filename-policy": {"chosen": "-filename-kebab", "source": "tool"}
    },
    "events": [],
    "report": {"kind": "brief", "intendedPath": "reports/brief.md"},
    "git": {"policy": "auto", "source": "defaults"},
    "warnings": [],
    "workspace": {"name": "meeting-notes", "path": "config/workspaces/meeting-notes.md", "source": "cli"}
  },
  "next": {"cmd": "notator.run", "args": {"apply": false}}
}
```

---

## Notator: First Tool

Notator organizes notes without creating prose. Core switches:

| Switch | Purpose | Includes |
|--------|---------|----------|
| `-process` | Organize incoming → preview | `-rename`, `-report-brief` |
| `-rename` | Apply filename policy | `-filename-kebab`, `-events-ledger` |
| `-preview` | Dry-run annotation | — |
| `-git` | Auto-commit changes | `-events-ledger` |
| `-no-commit` | Disable commits | — |
| `-notify` | Emit user notifications | — |

### Naming Policy

- **Normalization**: ASCII-fold, remove punctuation, keep digits
- **Kebab**: `lowercase-hyphen-separated`
- **Camel**: `firstWordLowerThenTitleCase`
- **Pascal**: `AllWordsTitleCase`
- **Collisions**: Append `-2`, `-3` (kebab) or `2`, `3` (camel/pascal)
- **Extension**: Default `.md`

### Git Policy

- Default: Single commit per run
- Auto-escalate to two commits for structural changes (splits, cross-directory moves)
- Commit messages: `notator: process {N} notes`, `notator: snapshot incoming before processing`

### Events Ledger

JSON Lines format:
```json
{"ts": "2025-11-09T18:45:12Z", "tool": "notator", "type": "rename", "summary": "renamed foo.txt to bar.md", "data": {"from": "foo.txt", "to": "bar.md"}, "switch": "-rename"}
```

---

## Future Work

- Additional tools beyond Notator
- SQLite continuity store for cross-session queries
- Jinja2 templating for complex prompt composition
- TUI preview mode
- Demo dataset (works/the-wonderful-wizard-of-oz)
