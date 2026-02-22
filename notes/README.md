# Notes Workflow

This directory structure is where Sofia processes your content.

## Directories

### `incoming/`
**Put raw content here.** ChatGPT exports, voice transcriptions, quick captures—anything that needs organizing.

Example: Export a ChatGPT conversation as markdown and drop it here.

### `preview/`
**Staging area.** When you run Sofia with `-preview`, proposed changes appear here for review before committing.

### `wiki/`
**Organized notes.** Final destination for processed, categorized content.

### `archive/`
**Completed work.** Notes that have been fully processed and are kept for reference.

## Typical Workflow

```bash
# 1. Drop a ChatGPT export into incoming/
cp ~/Downloads/chatgpt-session.md notes/incoming/

# 2. Preview what Sofia would do
./bin/sofia notator run -process -preview

# 3. If satisfied, run without preview (future: -apply flag)
./bin/sofia notator run -process

# 4. Review results in preview/, move to wiki/ when ready
```

## What Sofia Does

Sofia doesn't move files itself (MVP is prompt-only). It generates instructions for an LLM to:

1. Read notes from `incoming/`
2. Determine appropriate filenames (kebab-case by default)
3. Propose splits if a note covers multiple topics
4. Output organized content to `preview/`
5. Log all actions to the events ledger

The LLM (in Windsurf or your pipeline) executes these instructions while Sofia ensures consistency and tracks state.
