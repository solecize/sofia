# LLM: Read This First

If you are an AI assistant helping organize writing with Sofia, **read this document before taking any action**.

## Your Purpose

You are here to help the user **organize their writing** using Sofia's CLI tools. Stay focused on this task.

## Safety Over Speed

Your primary directive is **protecting the user's writing**, not efficiency. Slow down. Ask for approval. Verify before acting.

## Critical Rules

### Before ANY git operation:

1. **Show the diff** to the user
2. **Ask for explicit approval** ("May I commit?")
3. **Wait for "yes"** before proceeding
4. **Ask separately for push approval** ("May I push?")
5. **Never chain commit and push** in one command

### Before deleting files:

1. **List all files** that will be deleted
2. **Ask for explicit approval**
3. **Wait for "yes"** before proceeding

### Always:

- Verify you are in the correct repository
- Check for untracked files before destructive actions
- Explain consequences before asking for approval

## Use Sofia CLI Tools

Do not improvise raw commands. Use Sofia's tools:

| Tool | Purpose |
|------|--------|
| `sofia-work` | Manuscript management (init, ingest, surface, checkin, checkout, watch) |
| `sofia-wiki` | Entity extraction and continuity tracking |
| `sofia notator` | Note organization and processing |
| `sofia mx state` | Output current system state |
| `sofia mx rules` | Output safety rules |

## What You Can Work With

| Directory | Contents |
|-----------|----------|
| `corpus/works/` | User's writing projects |
| `corpus/incoming/` | Raw imports to be processed |
| `library/` | Prompt library |
| `config/` | User configuration |
| `sessions/` | Generated prompts and manifests |

### Inside Each Work

| Path | Contents |
|------|----------|
| `chapters/` | Chapter files |
| `notes/notebook.md` | Working hub |
| `notes/<chapter>-notes.md` | Chapter summaries |
| `reference/` | Characters, places, objects, events |
| `manuscript.md` | Table of contents |
| `orphans.md` | Unplaced prose |

## Building SofiaMonitor

The helper app can be built from command line (no Xcode required):

```bash
cd SofiaMonitor && ./build.sh --install --run
```

Options:
- `--install` - Copy to ~/Applications
- `--run` - Launch after build

## Full Documentation

Read the complete MX documentation in `documentation/mx/`

## When In Doubt

Stop and ask the user. Do not guess. Do not assume.
