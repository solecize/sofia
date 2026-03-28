# Repository Scope

This document defines what is and isn't part of a Sofia writing environment.

## Your Writing Repository

Your Sofia environment contains your writing projects. Treat it with care.

## What Your Repository Contains

| Directory | Contents |
|-----------|----------|
| `corpus/works/` | Your writing projects |
| `corpus/incoming/` | Raw imports waiting to be processed |
| `library/` | Prompt library (switches, variables, profiles) |
| `config/` | Your configuration and workspaces |
| `sessions/` | Session manifests and generated prompts |
| `scripts/` | Sofia CLI tools (sofia-work, sofia-wiki, etc.) |

## Work Structure

Each project in `corpus/works/<project>/` contains:

| Directory/File | Contents |
|----------------|----------|
| `chapters/` | Chapter files (01-chapter-one.md, etc.) |
| `notes/` | Chapter notes and working notebook |
| `notes/notebook.md` | Working hub for this project |
| `notes/<chapter>-notes.md` | Summary and reference links for each chapter |
| `reference/` | Characters, places, objects, events, themes |
| `manuscript.md` | Table of contents / compiled view |
| `orphans.md` | Unplaced prose |

## Protecting Your Work

Your writing is valuable. The AI assistant should:

- Never delete files without explicit approval
- Never push changes without explicit approval
- Always show what will change before acting
- Stay focused on organizing, not creating content

## Boundaries

### Stay Within This Repository

- Work only within the current Sofia environment
- Do not reference or access other repositories
- Do not copy files between different repositories
- If uncertain about a path, ask the user

### User's Writing

The user's creative work is valuable. Before any operation that modifies their writing:

1. Explain what will change
2. Ask for approval
3. Wait for explicit confirmation

## Demo Works

Sofia includes demo works for testing:

- `christmas-carol` - Public domain (Charles Dickens)
- `frankenstein` - Public domain (Mary Shelley)
- `origin-of-species` - Public domain (Charles Darwin)

These can be used to learn Sofia's features before working on your own projects.
