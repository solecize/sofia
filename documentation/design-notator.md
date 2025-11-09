# Notator: Design Document (MVP)

## 1) Purpose & Scope

- Notator converts user intent into structured prompts for organizing notes.
- It is an editing assistant: does not create new prose; focuses on sorting, renaming, and routing notes.
- Prompt-as-output only (no side effects in MVP). Always emit an echo JSON control block.

---

## 2) Minimal Switches

- `-process` (library/notator/switches/process.md)
  - Organize notes from incoming → preview; enforce naming rules.
  - Includes: `-rename`.
- `-rename` (library/notator/switches/rename.md)
  - Rename files using kebab-case based on note topic.
  - Typically includes `-filename` (shared) to enforce global naming policy.
- `-preview` (library/notator/switches/preview.md)
  - Annotate output as a dry-run/preview.
- `-git` (library/notator/shared/git.md)
  - Stage and commit changes using a conventional commit message.
- `-notify` (library/notator/shared/notify.md)
  - Notify the user with a summary of operations or any conflicts.
- `-filename` (library/shared/switches/filename.md)
  - Global shared switch; standardize filenames across tools (kebab-case, collision rule).
  - Can be used directly (`sofia notator run -process -filename`) or included by `-rename`.

---

## 3) Prompt Library Mapping (Markdown)

- Front matter: TOML delimited by `+++`.
  - `type = "switch" | "vars" | "group"`
  - For switches: `tool`, `switch`, `help`, optional `aliases`, `includes`, `tags`.
  - For vars: `namespace` and a fenced `toml` block for key/values.
- Prompt text: first fenced block labeled `prompt`.
- Variables: referenced as `{namespace.key}`, e.g., `{paths.incoming}`.
- Includes: deterministic composition via `includes = ["-other-switch"]`.

Shared switch example (`-filename`):

````markdown
+++
tool = "shared"
type = "switch"
switch = "-filename"
help = "Standardize filenames across tools using kebab-case and consistent rules."
aliases = ["-name", "-filenames"]
tags = ["naming", "shared", "conventions"]
version = 1
id = "shared.filename"
+++

```prompt
Apply a consistent filename policy:
- Use {naming.kebab_case} for all filenames.
- Derive the base name from the provided title/topic; remove punctuation and symbols.
- Convert to lowercase; replace whitespace with single hyphens; collapse repeated hyphens; trim edges.
- Preserve the `.md` extension unless otherwise specified by the calling context.
- If a collision would occur, append a numeric suffix beginning at `-2`.
- Output only the filename string.
```
````

### Variants and exclusive groups

- Mutually-exclusive variants (e.g., filename policies) share an `exclusive_group`.
- Declare variants via front matter. Example for filename policies:
  - `exclusive_group = "filename-policy"`
  - `default = true` on the default variant (e.g., kebab-case)
  - Other variants: `-filename-camel`, `-filename-pascal` (same `exclusive_group`).
- `-filename` can be an alias to the default (kebab) for convenience.
- Precedence:
  1. CLI-requested variant (last CLI wins; warn on multiple).
  2. Else, group default.
  3. Else, first included variant.
  4. Conflicting included variants → keep first; warn (CLI still overrides).
- Ordering/dedup: expand in CLI order with pre-order includes; deduplicate globally; place the chosen group variant where the group first appears.

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
    - Explicit: `sofia notator run -process -filename -preview`
    - Via includes: `sofia notator run -process -preview` (resolves `-rename` → `-filename`).
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
    "includedSwitches": ["-rename", "-filename"],
    "resolvedSwitches": ["-process", "-rename", "-filename", "-preview"],
    "variables": {"paths.incoming": "notes/incoming", "paths.preview": "notes/preview"},
    "composedPrompts": ["...fully resolved prompt text..."],
    "sourceFiles": {"-process": "library/notator/switches/process.md", "-filename": "library/shared/switches/filename.md"},
    "selectedGroups": {"filename-policy": {"chosen": "-filename", "source": "default"}},
    "warnings": ["CLI requested -filename-camel overrides included -filename"]
  },
  "next": {"cmd": "notator.run", "args": {"apply": false}}
}
```

---

## 7) Acceptance Criteria (MVP)

- `notator list` shows `-process`, `-rename`, `-preview`, `-git`, `-notify`, `-filename` with help and source paths.
- `notator run -process -preview` resolves includes, substitutes variables, emits echo JSON, and writes a `sessions/.../manifest.json`.
- Errors are actionable (missing switch/include/variable) and reference source files.
