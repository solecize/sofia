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
  - shared/
    - switches/
      - filename-kebab.md
      - filename-camel.md
      - filename-pascal.md
      - events-ledger.md
      - report-brief.md
      - report-verbose.md
    - report/
      - templates.md
  - config/
    - defaults.md
  - vars/
    - paths.md
    - naming.md
    - report.md
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

### Variants and exclusive groups

- Some concerns are mutually exclusive and come in variants (e.g., filename policies).
- Use front matter to declare a category with variants:
  - `exclusive_group = "filename-policy"`
  - `default = true` on the default variant (e.g., kebab-case)
  - Provide other variants, e.g., `-filename-camel`, `-filename-pascal` with the same `exclusive_group`.
- Aliases can map convenience flags to variants (e.g., `-filename` → kebab by default).
- Precedence and selection:
  1. CLI-requested variant in the group (if multiple, last CLI wins; emit a warning).
  2. Else, global defaults (from `config/defaults.md`) if present.
  3. Else, the group’s `default = true` variant (if declared in the switch front matter).
  4. Else, if a parent includes a variant, use that included variant.
  5. If multiple included variants conflict, keep the first; emit a warning (CLI still overrides).
- Ordering and dedup:
  - Expand in CLI order with pre-order includes. Deduplicate globally while preserving the first position where the group was introduced.
  - Includes and CLI flags are both resolved through the alias map (aliases are valid in either location).

### Naming policy details (shared)

- Normalization: ASCII-fold to basic Latin; remove punctuation/symbols; keep digits; trim whitespace.
- Kebab-case: lowercase tokens joined by `-`; collapse repeated hyphens; trim edges.
- CamelCase: first token lowercase; subsequent tokens TitleCase; join w/o separators.
- PascalCase: all tokens TitleCase; join w/o separators.
- Extension: default `.{naming.default_extension}` ("md").
- Collisions: kebab appends `-2`, `-3`, …; camel/pascal append `2`, `3`, …; idempotent (don’t re-append).
- Filters (shared vars): `filters.ignore_hidden=true`; `filters.ignore_patterns=[".DS_Store","Thumbs.db","~*","*.tmp","*.swp"]`.

### Reporting (events ledger and templates)

- Events ledger: JSON Lines (one object per line) appended during a run with fields:
  - `ts` (ISO8601), `tool`, `type`, `summary`, `data` (object), `switch`, optional `severity`, optional `id` (idempotency)
- Templates: `library/shared/report/templates.md` maps `summary_template` and `verbose_template` by event `type`.
- Report detail (exclusive group: `report-detail`):
  - `-report-brief` (alias: `-report`) → renders to `{report.dir}/{report.brief_filename}`
  - `-report-verbose` → renders to `{report.dir}/{report.verbose_filename}`
- Vars: `library/vars/report.md` defines `dir`, `brief_filename`, `verbose_filename`.
- Optional shared switch: `-events-ledger` instructs emitting events consistently; include it where core actions occur.

### Git policy (default auto-commit)

- Exclusive group: `commit-policy`.
- Variants:
  - `-git` (default): auto stage and commit changes.
  - `-no-commit` (alias `-nocommit`): disable commits; still emit non-git events and a `notify` noting commits are disabled.
- Default granularity: single commit per run.
- Auto-escalation: if actions structurally transform inputs to outputs (e.g., split/merge, cross-directory renames, or produce multiple derived files), emit two commits instead of one:
  1. Baseline snapshot: add originals in `{paths.incoming}` and commit with `notator: snapshot incoming before processing`.
  2. Outputs commit: add changed/new files and commit with `notator: process {N} notes`.
- If a report is rendered, include it in the outputs commit; message: `notator: add report ({report.kind})` if committed separately.
- Event shapes:
  - `git.init`: `{ path }`
  - `git.add`: `{ paths: [...], count }`
  - `git.commit`: `{ message, files: [...] }`
- Echo JSON: record `data.git = { policy: "auto" | "none", source: "tool" | "cli" }` and track `selectedGroups.commit-policy`.

 

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
- Global shared switches (e.g., `-filename`) live under `library/shared/switches` and can be used by all tools.
- Tool-local shared switches (e.g., `-git`, `-notify` for Notator) live under `library/notator/shared`.

Shared example:

````markdown
+++
tool = "shared"
type = "switch"
switch = "-filename-kebab"
help = "Standardize filenames across tools using kebab-case and consistent rules."
aliases = ["-filename", "-name", "-filenames"]
tags = ["naming", "shared", "conventions"]
version = 1
id = "shared.filename.kebab"
+++

```prompt
Apply a consistent filename policy:
- Use {naming.kebab_case} for all filenames.
- Derive the base name from the provided title/topic; remove punctuation and symbols.
- Convert to lowercase; replace whitespace with single hyphens; collapse repeated hyphens; trim edges.
- Preserve the `.{naming.default_extension}` extension unless otherwise specified by the calling context.
- If a collision would occur, append a numeric suffix beginning at `-2`.
- Output only the filename string.
```
````

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
  - Composes prompts, resolves includes and exclusive groups (CLI > tool include > global defaults > group default > includes), substitutes variables, emits echo JSON, writes session manifest.

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
    "includedSwitches": ["-rename", "-filename-kebab", "-report-brief"],
    "resolvedSwitches": ["-process", "-rename", "-filename-kebab", "-git", "-report-brief", "-preview"],
    "variables": { "paths.incoming": "notes/incoming", "paths.preview": "notes/preview" },
    "composedPrompts": ["...resolved prompt text segments..."],
    "sourceFiles": { "-process": "library/notator/switches/process.md", "-filename-kebab": "library/shared/switches/filename-kebab.md", "-git": "library/notator/shared/git.md", "-report-brief": "library/shared/switches/report-brief.md" },
    "selectedGroups": { "filename-policy": { "chosen": "-filename-kebab", "source": "tool" }, "report-detail": { "chosen": "-report-brief", "source": "cli" }, "commit-policy": { "chosen": "-git", "source": "defaults" } },
    "events": [
      { "ts": "2025-11-09T18:45:12Z", "tool": "notator", "type": "rename", "summary": "renamed and converted character.interaction.doc to character-interaction.md", "data": { "from": "character.interaction.doc", "to": "character-interaction.md", "extChanged": true }, "switch": "-rename" }
    ],
    "report": { "kind": "brief", "intendedPath": "reports/brief.md" },
    "git": { "policy": "auto", "source": "defaults" },
    "warnings": ["CLI requested -filename-camel overrides included -filename-kebab"]
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

- `sofia notator list` lists `-process`, `-rename`, `-preview`, `-git`, `-notify`, `-filename`.
- `sofia notator run -process -preview` produces:
  - Resolved includes (`-rename`) and variable substitution.
  - Echo JSON block printed to stdout.
  - `sessions/.../manifest.json` written with run metadata.
- Errors are actionable and reference source files.
