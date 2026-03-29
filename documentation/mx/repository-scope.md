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

### Environment Lock

Sofia Monitor can lock an environment to enforce repository boundaries. When locked:

1. **Lock file exists:** `.sofia/environment.lock` contains the locked path
2. **Rules updated:** `.windsurfrules` contains explicit path restriction

**AI assistants should:**
- Check for `.sofia/environment.lock` at session start
- If present, read `locked_path` and refuse to access files outside it
- Run `sofia-mx status` to see current lock state

### Stay Within This Repository

- Work only within the current Sofia environment
- Do not reference or access other repositories
- Do not copy files between different repositories
- If uncertain about a path, ask the user
- **If `.sofia/environment.lock` exists, NEVER access files outside the locked path**

### User's Writing

The user's creative work is valuable. Before any operation that modifies their writing:

1. Explain what will change
2. Ask for approval
3. Wait for explicit confirmation

## Demo Content

Sofia includes public domain texts for learning:

- `corpus/incoming/tutorial/christmas-carol-raw.md` - Charles Dickens
- `corpus/incoming/tutorial/frankenstein-raw.md` - Mary Shelley  
- `corpus/incoming/tutorial/origin-of-species-raw.md` - Charles Darwin

Run `./scripts/sofia-tutorial` to process these into full works and learn Sofia's features.
