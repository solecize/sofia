# Notator: A Tool in the Sofia Framework for Prompt-Driven LLM Workflows

## Overview

**Notator** is the first tool in the **Sofia** collection—a framework of natural-language prompt composers built to manage and process written work. Sofia tools invert the typical user–LLM relationship: rather than asking a language model for creative output, they issue **structured, curated instructions** for organizing, formatting, and processing text. Notator focuses specifically on **note processing**.

Notator behaves like a CLI-styled assistant, but instead of performing file manipulations itself, it **generates LLM-ready instructions**—precise, composable, natural-language prompts. These are passed to any LLM interpreter (such as **Windsurf**) capable of executing natural language actions.

Notator outputs are readable, inspectable, and repeatable, allowing users to maintain full control while automating the repetitive, mechanical work of writing projects.

---


## Quick Start: Sofia Notator (MVP)

Use this to list switches, run a basic processing flow, and interpret the Echo JSON and session manifest.

### Requirements
- Python 3.11+
- Run from repo root: /Users/jdfrey/Documents/sofia

### TL;DR Commands
- List switches:
  ```
  python3 tooling/sofia.py notator-list
  ```
- Run default brief report via process (includes rename, events ledger):
  ```
  python3 tooling/sofia.py notator-run -process
  ```
- Override report detail to verbose:
  ```
  python3 tooling/sofia.py notator-run -process -report-verbose
  ```
- Disable commits for the run:
  ```
  python3 tooling/sofia.py notator-run -process -no-commit
  ```
- Preview mode (annotates dry run in prompts):
  ```
  python3 tooling/sofia.py notator-run -process -preview
  ```

### What you’ll see
- Echo JSON printed to stdout:
  - ui: one-line description.
  - ask: interactive hint block.
  - data.requestedSwitches: switches you asked for.
  - data.includedSwitches: switches pulled in by includes (e.g., -report-brief from -process).
  - data.resolvedSwitches: final order after includes and exclusive-group resolution.
  - data.selectedGroups: chosen variant and source for each exclusive group.
  - data.composedPrompts: final prompts (with variables substituted).
  - data.sourceFiles: where each switch came from.
  - data.report: report kind and intended output path.
  - data.git: commit-policy outcome and source (defaults vs cli).
  - data.events: empty in MVP; reserved for future event objects.
  - warnings: conflicts (e.g., dropping -report-brief when -report-verbose is selected).
- Session manifest written to sessions/YYYYMMDD-HHMMSSZ/manifest.json.

### Precedence rules (current)
- CLI > tool include > global defaults > registry default

Example:
- -process includes -report-brief → report-detail.source="tool".
- Adding -report-verbose on CLI overrides to source="cli".

### Notes
- All behavior is prompt-only in MVP (no filesystem or git side effects).
- Git-by-default policy: default -git via config defaults; override with -no-commit.

## Workspaces (profiles)

Goal: Maintain stable, selectable sets of switches, group defaults, and variables (e.g., “meeting-notes” vs “fiction-notes”), and enable “reset to default” regardless of library growth.

### Workspace files
- Location: `config/workspaces/{name}.md`
- Front matter example:
  ```toml
  type = "workspace"
  id = "workspace.name"
  name = "Name"
  description = "Profile description"
  # optional inheritance
  extends = "base"
  ```
- TOML contents may include:
  - `[groups]` global variants for exclusive groups
  - `[tools.notator.groups]` tool-scoped variants
  - `[vars.report]`, `[vars.paths]`, etc. to override variables
  - Optional `[pins]` to lock `switch id -> version` for reproducible sets
  - Optional `[visibility]` to filter `notator-list` by tags/allowlist

### CLI support
- `--workspace <name>` for `notator-run` (and optionally `notator-list`).

### Precedence with workspace
- CLI > tool include > workspace tool-group default > workspace global-group default > global defaults > registry default

### Echo JSON additions
- `data.workspace = { name, path, source: "cli" }`
- `selectedGroups.*.source` may be `"workspace"` when chosen by workspace


## Notator’s Role within Sofia

Sofia is designed around three core principles:

1. **Prompt-as-output**: Tools generate structured prompts to instruct the LLM.
2. **LLM-as-agent**: Execution is handled by a language model, not the user.
3. **User-defined logic**: All behaviors are editable via Markdown and config files.

Notator embodies these principles:

* Its job is to **organize, clean, and route notes** without introducing new prose.
* It **repeats its core prompt throughout each session**, reinforcing task context.
* It adds variables and instructions into modular prompt templates that are **user-editable**, supporting full transparency and control.

Example session (natural language):

```
User: "please use notator to organize my notes in the incoming folder and move them to the preview folder"
```

Which translates to:

```
LLM: Runs Notator with the following switches
-process -preview
```

And Notator returns:

```
"You are an editing assistant that can organize notes without inserting any additional prose, and your primary focus is to segregate and match notes to their appropriate categories. Please {organize} my notes in the incoming folder and {move} them to the preview folder using the standard {fileName} {fileType} and {markdownNotesTemplateformat}. Once complete {git} the new files in the preview folder and {notify} the user that the process is complete."
```

Each `{variable}` is resolved from the prompt library, providing granular, reusable building blocks that can be nested and extended.

---

## Core Goals

### 1. Prompt-as-output pattern

* Prompts are returned, not executed.
* Enables human oversight and LLM-driven automation.
* Supports testing, chaining, nesting.

### 2. Extensible CLI-like interface

* Switches like `-process`, `-wiki`, `-rename` behave like CLI commands.
* Each one maps to a curated natural-language instruction.
* Instructions can include variables and links to other instructions.

### 3. External config via `note-instructions.md`

* Users define their own prompt logic.
* Markdown format keeps it lightweight and readable.
* Prompts, help strings, variables, and default behaviors all live here.

### 4. Variable and nested prompt substitution

* Supports structured logic without scripting.
* Enables compound prompts and reuse of shared logic.
* DSL-like behavior without actual DSL overhead.

---

## Considerations and Enhancements

* **Session memory tracking**: Track `{current_prompt}`, filenames, tags via manifest (e.g., JSON).
* **Prompt groups**: Organize prompt sets thematically (e.g., -scene, -research, -meeting).
* **Dry-run mode**: Preview prompts before sending them to LLM.
* **Prompt fallback**: Validate prompts and warn on failure (e.g., malformed or broken links).
* **Block prompt support**: Use fenced blocks for complex or multiline instructions.

---

## Instruction Flow

### Purpose and Behavior

* Notator is an *editing assistant*. It **does not create prose**, only organizes.
* Repeats its core context prompt with every instruction to remind the LLM of its role.

### Input Examples

```
notator -process -preview
```

Triggers an output like:

```
"You are an editing assistant that can organize notes without inserting any additional prose..."
```

### Prompt Config Example (`note-instructions.md`):

```markdown
-switch: -summarize
help: Summarize a note and tag it with action items.
prompt: "Summarize the following notes into an outline and tag any action items."
```

### Nested Prompt Example:

```markdown
-switch: -event
prompt: "Convert the note using {current_prompt} and log it as an event in the wiki using -wiki."
```

---

## State Tracking

* Track all processed notes
* Record filenames, tags, and LLM responses
* Output session logs in JSON or Markdown

---

## Prompt Patterns

| Operation | Prompt                                                         |
| --------- | -------------------------------------------------------------- |
| Summarize | "Summarize this note in 2–3 lines. Include tone and priority." |
| Tag       | "Extract 3–5 thematic tags from the note."                     |
| Rename    | "Rename file using kebab-case based on topic."                 |
| Move      | "Move this file from {incoming} to {preview}."                 |
| Archive   | "Mark this as processed and move to archive folder."           |

---

## Completion Loop

* Confirm action
* Offer options: continue, revise, export

---

## Linking and Modularity

* Prompts call other prompts
* Variables populate in real time
* User controls scope and nesting

---

## Optional Extensions

* Mode toggles: markdown, screenplay, outline
* Batch mode
* LLM audit explanations (e.g., why was this tag added?)

---

## Summary

**Notator is the first executable tool in Sofia.**

It converts user intent into precise instructions for organizing notes. Rather than editing text, it builds well-scaffolded prompts for AI agents to follow. Its modular structure, variable-based prompt logic, and editable CLI-style design make it a scalable foundation for other Sofia tools.

By keeping the LLM in a bounded role—and the user in control—Notator ensures transparency, repeatability, and freedom for the writer to focus on writing.

---

**Next Steps:**

* Scaffold `note-instructions.md`
* Draft example prompt groups (e.g., -scene, -journal)
* Create sample `session-manifest.json`
* Add a Sofia README linking Notator and other tools
