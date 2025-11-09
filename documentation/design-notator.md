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
- `-preview` (library/notator/switches/preview.md)
  - Annotate output as a dry-run/preview.
- `-git` (library/notator/shared/git.md)
  - Stage and commit changes using a conventional commit message.
- `-notify` (library/notator/shared/notify.md)
  - Notify the user with a summary of operations or any conflicts.

---

## 3) Prompt Library Mapping (Markdown)

- Front matter: TOML delimited by `+++`.
  - `type = "switch" | "vars" | "group"`
  - For switches: `tool`, `switch`, `help`, optional `aliases`, `includes`, `tags`.
  - For vars: `namespace` and a fenced `toml` block for key/values.
- Prompt text: first fenced block labeled `prompt`.
- Variables: referenced as `{namespace.key}`, e.g., `{paths.incoming}`.
- Includes: deterministic composition via `includes = ["-other-switch"]`.

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
    "resolvedSwitches": ["-process", "-rename", "-preview"],
    "variables": {"paths.incoming": "notes/incoming", "paths.preview": "notes/preview"},
    "composedPrompts": ["...fully resolved prompt text..."],
    "sourceFiles": {"-process": "library/notator/switches/process.md"}
  },
  "next": {"cmd": "notator.run", "args": {"apply": false}}
}
```

---

## 7) Acceptance Criteria (MVP)

- `notator list` shows `-process`, `-rename`, `-preview`, `-git`, `-notify` with help and source paths.
- `notator run -process -preview` resolves includes, substitutes variables, emits echo JSON, and writes a `sessions/.../manifest.json`.
- Errors are actionable (missing switch/include/variable) and reference source files.
