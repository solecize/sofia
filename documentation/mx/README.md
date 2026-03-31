# Model Experience (MX)

MX is the practice of making systems legible to AI models. This documentation defines how AI assistants should help organize writing with Sofia.

## Core Principle

**Safety and explicit user approval take priority over speed.**

## Why MX Exists

AI assistants are powerful but can cause harm when they:
- Act without explicit approval on destructive operations
- Assume context that doesn't exist
- Prioritize efficiency over safety
- Cross boundaries between repositories or projects

MX documentation prevents these issues by providing clear, unambiguous guidance that AI assistants can follow.

## MX Documentation Index

| Document | Purpose |
|----------|---------|
| [terminology.md](terminology.md) | Definitions for corpus, works, notes, reference |
| [safety.md](safety.md) | STOP, NEVER, and VERIFY rules |
| [repository-scope.md](repository-scope.md) | What is and isn't part of this repository |
| [commit-protocol.md](commit-protocol.md) | Step-by-step process for git operations |
| [cli.md](cli.md) | Sofia MX CLI commands |

## Your Role as an AI Assistant

When helping a user with Sofia, your job is to:

1. **Organize writing** using Sofia's CLI tools
2. **Stay focused** on the user's writing projects
3. **Ask before acting** on anything that modifies files
4. **Use Sofia commands** rather than improvising raw operations

## Sofia CLI Tools

| Tool | Purpose |
|------|--------|
| `sofia-work` | Manuscript management (init, ingest, surface, checkin, checkout) |
| `sofia-refresh` | Regenerate work-level notebook and manuscript sections |
| `sofia-wiki` | Entity extraction and continuity tracking |
| `sofia notator` | Note organization and processing |
| `sofia mx` | System state and guidance |

## SofiaMonitor Helper App

Build and install from command line (no Xcode required):

```bash
cd SofiaMonitor && ./build.sh --install
```

The app provides environment locking, writing mode, and auto-commit features. See `documentation/sofia-monitor.md` for details.

## Custom Refresh Sections

AI assistants can generate custom sections for work notebooks. When a work has `.sofia/sections/*.md` files with `type = "prompt"`:

1. Read the section definition (TOML frontmatter + prompt)
2. Read the relevant work content (chapters, reference files)
3. Generate the section content following the prompt instructions
4. Write it between `<!-- sofia:marker -->` fences in the target file
5. **Ask for user approval before writing** (per MX safety rules)

Run `sofia-refresh <work> --list-sections` to see available sections.

## For AI Assistants

If you are an AI assistant reading this:

1. Use Sofia CLI commands to help organize writing
2. Read the safety rules in `safety.md`
3. Check `.sofia/sections/` for prompt-based sections to generate
4. When in doubt, ask the user rather than assuming
5. Prioritize the user's writing over efficiency
