# Notator: Design Document (MVP)

## 1) Purpose & Scope

- Notator converts user intent into structured prompts for organizing notes.
- It is an editing assistant: does not create new prose; focuses on sorting, renaming, and routing notes.
- Prompt-as-output only (no side effects in MVP). Always emit an echo JSON control block.

---

## 2) Minimal Switches

- `-process` (library/notator/switches/process.md)
  - Organize notes from incoming → preview; enforce naming rules.
  - Includes: `-rename`, `-report-brief`.
- `-rename` (library/notator/switches/rename.md)
  - Rename files using kebab-case based on note topic.
  - Typically includes `-filename` (shared) to enforce global naming policy.
- `-preview` (library/notator/switches/preview.md)
  - Annotate output as a dry-run/preview.
- `-git` (library/notator/shared/git.md)
  - Stage and commit changes using a conventional commit message.
- `-notify` (library/notator/shared/notify.md)
  - Notify the user with a summary of operations or any conflicts.
- `-filename` (alias to `-filename-kebab`) (library/shared/switches/filename-kebab.md)
  - Global shared switch; standardize filenames across tools (kebab-case, collision rule).
  - Can be used directly (`sofia notator run -process -filename-kebab` or alias `-filename`) or included by `-rename`.
- `-report-brief` (alias `-report`) (library/shared/switches/report-brief.md)
  - Render a brief Markdown report from the events ledger (summary lines) to `{report.dir}/{report.brief_filename}`.
- `-report-verbose` (library/shared/switches/report-verbose.md)
  - Render a verbose Markdown report with detailed lines to `{report.dir}/{report.verbose_filename}`.
- `-events-ledger` (library/shared/switches/events-ledger.md)
  - Maintain a JSONL events ledger during runs; other switches emit typed events.
 - `-no-commit` (alias `-nocommit`) (design-only in MVP)
   - Disable auto commits; when present, do not emit `git.add`/`git.commit` events and emit a `notify` that commits are disabled.

---

## 3) Prompt Library Mapping (Markdown)

- Front matter: TOML delimited by `+++`.
  - `type = "switch" | "vars" | "group"`
  - For switches: `tool`, `switch`, `help`, optional `aliases`, `includes`, `tags`.
  - For vars: `namespace` and a fenced `toml` block for key/values.
- Prompt text: first fenced block labeled `prompt`.
- Variables: referenced as `{namespace.key}`, e.g., `{paths.incoming}`.
- Includes: deterministic composition via `includes = ["-other-switch"]`.

Shared switch example (`-filename-kebab`):

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
- Preserve the `.{naming.default_extension}` extension unless otherwise specified by the calling context.
- If a collision would occur, append a numeric suffix beginning at `-2`.
- Output only the filename string.
```
````

### Reporting (Notator)

- Notator switches that act (e.g., `-rename`) emit events to the shared JSONL ledger.
- Reporting switches render the ledger using shared templates:
  - Templates: `library/shared/report/templates.md` (`summary_template`, `verbose_template`).
  - Vars: `library/vars/report.md` (`dir`, `brief_filename`, `verbose_filename`).
  - Exclusive group: `report-detail` with `-report-brief` (alias `-report`) and `-report-verbose`.

### Git policy (default auto-commit)

- Exclusive group `commit-policy` with variants:
  - `-git` (default): auto stage and commit changes at defined boundaries.
  - `-no-commit` (alias `-nocommit`): disable commits for this run; still emit normal non-git events and a `notify` about disabled commits.
- Default behavior: single commit per run.
- Auto-escalation: when actions structurally transform inputs to outputs (e.g., splitting one file into many), use two commits:
  1. Baseline snapshot of originals in `{paths.incoming}` with message `notator: snapshot incoming before processing`.
  2. Outputs commit after renames/creates with message `notator: process {N} notes` (include `data.files`).
- If a report is rendered and committed separately, use `notator: add report ({report.kind})`.
- Echo JSON: include `data.git = { policy: "auto" | "none", source: "tool" | "cli" }` and `selectedGroups.commit-policy`.
 

### Variants and exclusive groups

- Mutually-exclusive variants (e.g., filename policies) share an `exclusive_group`.
- Declare variants via front matter. Example for filename policies:
  - `exclusive_group = "filename-policy"`
  - `default = true` on the default variant (e.g., kebab-case)
  - Other variants: `-filename-camel`, `-filename-pascal` (same `exclusive_group`).
- `-filename` can be an alias to the default (kebab) for convenience.
- Precedence:
  1. CLI-requested variant (last CLI wins; warn on multiple).
  2. Else, group default (or global defaults if defined in `config/defaults.md`).
  3. Else, first included variant.
  4. Conflicting included variants → keep first; warn (CLI still overrides).
- Ordering/dedup: expand in CLI order with pre-order includes; deduplicate globally; place the chosen group variant where the group first appears.
- Other example groups:
  - `commit-policy`: variants `-git` (default) and `-no-commit`.

Example (conceptual):

````markdown
+++
tool = "notator"
type = "switch"
switch = "-process"
help = "Process incoming notes and prepare for preview."
includes = ["-rename"]
+++

```prompt
You are an editing assistant that organizes notes without adding prose.
Move files from {paths.incoming} to {paths.preview}.
Apply {naming.kebab_case}. Do not invent content.
```
````

Variables example:

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

---

## 4) Composition (MVP)

- Resolve requested switches → expand `includes` (topological order, no cycles, max depth 8).
- Assemble prompts by concatenating resolved `prompt` blocks with `\n\n`.
- Substitute variables `{namespace.key}`; error on missing keys.

---

## 5) CLI Flows (MVP)

- `sofia notator list`
  - List available switches with help and source file.
- `sofia notator run [switches...] [--dry-run | --apply]`
  - Default `--dry-run` (no side effects in MVP).
  - Output composed prompts + echo JSON; write session manifest JSON.
  - Example usages:
    - Explicit: `sofia notator run -process -filename-kebab -report-verbose -preview` (switch to verbose report)
    - Via includes: `sofia notator run -process -preview` (includes `-rename` and `-report-brief`; CLI can override to `-report-verbose`)
  - Precedence: CLI overrides includes; last CLI variant wins within an exclusive group (emit a warning).

---

## 6) Echo JSON (MVP)

Minimal shape:

```json
{
  "ui": "Summary of actions (organize notes incoming → preview; rename kebab-case)",
  "ask": {"confirm": {"default": true, "options": ["continue", "revise", "cancel"]}},
  "data": {
    "tool": "notator",
    "requestedSwitches": ["-process", "-preview"],
    "includedSwitches": ["-rename", "-filename-kebab", "-report-brief"],
    "resolvedSwitches": ["-process", "-rename", "-filename-kebab", "-git", "-report-brief", "-preview"],
    "variables": {"paths.incoming": "notes/incoming", "paths.preview": "notes/preview"},
    "composedPrompts": ["...fully resolved prompt text..."],
    "sourceFiles": {"-process": "library/notator/switches/process.md", "-filename-kebab": "library/shared/switches/filename-kebab.md", "-git": "library/notator/shared/git.md", "-report-brief": "library/shared/switches/report-brief.md"},
    "selectedGroups": {"filename-policy": {"chosen": "-filename-kebab", "source": "tool"}, "report-detail": {"chosen": "-report-brief", "source": "tool"}, "commit-policy": {"chosen": "-git", "source": "defaults"}},
    "events": [
      {"ts":"2025-11-09T18:45:12Z","tool":"notator","type":"rename","summary":"renamed and converted character.interaction.doc to character-interaction.md","data":{"from":"character.interaction.doc","to":"character-interaction.md","extChanged":true},"switch":"-rename"}
    ],
    "report": {"kind":"brief","intendedPath":"reports/brief.md"},
    "git": {"policy":"auto","source":"defaults"},
    "warnings": ["CLI requested -filename-camel overrides included -filename-kebab"]
  },
  "next": {"cmd": "notator.run", "args": {"apply": false}}
}
```

---

## 7) Acceptance Criteria (MVP)

- `notator list` shows `-process`, `-rename`, `-preview`, `-git`, `-notify`, `-filename` with help and source paths.
- `notator run -process -preview` resolves includes, substitutes variables, emits echo JSON, and writes a `sessions/.../manifest.json`.
- `-process` includes `-report-brief` by default; CLI can select `-report-verbose`.
- Commit policy default is `-git` via config; `-no-commit` disables emitting git.add/commit events.
- Errors are actionable (missing switch/include/variable) and reference source files.
