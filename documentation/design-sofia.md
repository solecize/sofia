# Sofia: Design Document (MVP)

## 1) Purpose and Goals

- Compose structured, constrained prompts (prompt-as-output) that LLMs execute as agents.
- First tool: Notator — organizes notes; does not create prose.
- Outputs are readable prompts plus a structured echo JSON block for orchestration.

### Goals
- Human-editable prompt library in Markdown.
- Deterministic prompt composition via CLI-style switches.
- Variable substitution, includes, and grouping.
- Always emit echo JSON (`ui`, `ask`, `data`, `next`).
- Minimal dependencies to start (stdlib-first).

### Non-goals (MVP)
- No file-moving or repo-modifying side effects (prompts/logging only).
- No DB schema (JSON sessions first).
- No TUI (Rich) or advanced templating (Jinja2) at start.

---

## 2) Guiding Principles

- Prompt-as-output
- LLM-as-agent
- Human control and transparency
- Minimal first; grow by need
- Plain Markdown and TOML, stdlib-first

---

## 3) High-Level Architecture (MVP)

- CLI (`sofia`) with subcommand `notator`.
- Markdown prompt library on disk (versioned).
- Loader parses front matter and fenced blocks.
- Composer resolves variables + includes into final prompts.
- Echo emitter prints the structured control block.
- Session manifest logger stores run metadata in JSON.

---

## 4) Minimal Stack

- Python 3.11 stdlib
  - CLI: `argparse` (MVP). Option: adopt Typer later for nicer ergonomics.
  - Config: `tomllib` (parse TOML front matter)
  - Echo JSON + logging: `dataclasses`, `json`, `datetime`, `pathlib`
- Optional later: Typer, Pydantic, sqlite3, Jinja2, Rich

---

## 5) Repository Layout (relevant to MVP)

- documentation/
  - design-sofia.md
  - design-notator.md
- library/
  - notator/
    - switches/
      - process.md
      - rename.md
      - preview.md
    - shared/
      - git.md
      - notify.md
  - vars/
    - paths.md
    - naming.md
  - groups/
    - core.md
- sessions/
  - 2025-11-09T15-30-00Z/manifest.json (example)

---

## 6) Markdown Prompt Library Spec

### Front Matter
- Delimiter: `+++` TOML (stdlib `tomllib`).
- Common keys:
  - `tool` (e.g., "notator")
  - `type`: "switch" | "vars" | "group"
  - `id` (stable identifier, optional but recommended)
  - `version` (int, optional)
  - `tags` (array, optional)

### Switch files
- Required: `type = "switch"`, `switch = "-name"`, `help = "..."`.
- Optional: `aliases = ["-n"]`, `includes = ["-other-switch"]`.
- Body: first fenced block labeled `prompt` is canonical instruction.

Example:

````markdown
+++
tool = "notator"
type = "switch"
switch = "-process"
help = "Process incoming notes and prepare for preview."
includes = ["-rename"]
tags = ["core"]
version = 1
id = "notator.process"
+++

```prompt
You are an editing assistant that organizes notes without adding prose.
Move files from {paths.incoming} to {paths.preview}.
Apply {naming.kebab_case}. Do not invent content.
```
````

### Variables files
- Required: `type = "vars"`, `namespace = "paths"` (or similar).
- Body: fenced `toml` block with key/values.

````markdown
+++
type = "vars"
namespace = "paths"
+++

```toml
incoming = "notes/incoming"
preview  = "notes/preview"
wiki     = "notes/wiki"
archive  = "notes/archive"
```
````

### Group files (optional in MVP)
- Required: `type = "group"`, `name = "core"`, `includes = ["-process", "-rename", "-preview"]`.

### Placeholders
- Variable syntax: `{namespace.key}` (e.g., `{paths.preview}`, `{naming.kebab_case}`).
- Only variables are substituted inside prompt text; prompt composition uses `includes`.

### Shared prompts
- Shared “switches” (e.g., `-git`, `-notify`) live alongside switches; referenced via `includes`.

---

## 7) Composition Semantics

- Input: requested switches (e.g., `["-process", "-preview"]`).
- Resolve aliases → canonical switch names.
- Build a DAG from `includes`. Detect cycles; max depth guard (e.g., 8).
- Order: topological; remove duplicates while preserving first occurrence.
- Prompt assembly: concatenate `prompt` texts with `\n\n` (configurable later).
- Variable substitution: replace `{namespace.key}` with merged vars; error on missing variable.

Warnings & Errors:
- Missing switch → error (with suggestions).
- Unknown include → error pointing to source file.
- Missing variable → list unresolved tokens.
- Include cycle → error with minimal cycle path.

---

## 8) CLI Behavior

- `sofia notator list`
  - Outputs available switches (name, help, source file).
- `sofia notator run [switches...] [--dry-run/--apply]`
  - Default `--dry-run` (MVP does not perform I/O beyond logging).
  - Composes prompts, substitutes variables, emits echo JSON, writes session manifest.

Future:
- `sofia init` to scaffold library/config.
- `sofia manifest` to view/merge manifests.

---

## 9) Echo JSON (Control Block)

Schema (MVP):

```json
{
  "ui": "Human-readable summary of what will happen.",
  "ask": { "confirm": { "default": true, "options": ["continue", "revise", "cancel"] } },
  "data": {
    "tool": "notator",
    "requestedSwitches": ["-process", "-preview"],
    "resolvedSwitches": ["-process", "-rename", "-preview"],
    "variables": { "paths.incoming": "notes/incoming", "paths.preview": "notes/preview" },
    "composedPrompts": ["...resolved prompt text segments..."],
    "sourceFiles": { "-process": "library/notator/switches/process.md" },
    "warnings": []
  },
  "next": { "cmd": "notator.run", "args": { "apply": false } }
}
```

---

## 10) Session Logging

- One directory per run in `sessions/YYYYMMDD-HHMMSS/`.
- `manifest.json` contains: sessionId, timestamps, tool, switches, variables, composed prompts, echo block, errors/warnings.
- Phase 2: sqlite schema for continuity queries.

---

## 11) Implementation Plan (MVP)

1. Loader: discover Markdown, parse TOML front matter, extract fenced blocks.
2. Registry: build maps for `switches`, `aliases`, `vars`, `groups`.
3. Composer: resolve `includes`, detect cycles, substitute variables.
4. CLI: `list`, `run` with `--dry-run`/`--apply` (apply is a no-op in MVP).
5. Echo + Logging: emit echo JSON; write `sessions/.../manifest.json`.
6. Tests: unit tests for loader, composer, and a sample run.

---

## 12) Future Work

- Markdown DSL refinements (examples, notes blocks).
- sqlite continuity store; ingest/chunker/nugget pipeline.
- Rich TUI previews; Jinja2 templating; Pydantic schemas.
- Demo dataset (works/the-wonderful-wizard-of-oz).
- Additional tools beyond Notator.

---

## 13) Acceptance Criteria (MVP)

- `sofia notator list` lists `-process`, `-rename`, `-preview`, `-git`, `-notify`.
- `sofia notator run -process -preview` produces:
  - Resolved includes (`-rename`) and variable substitution.
  - Echo JSON block printed to stdout.
  - `sessions/.../manifest.json` written with run metadata.
- Errors are actionable and reference source files.
