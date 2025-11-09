+++
tool = "shared"
type = "switch"
switch = "-filename"
help = "Standardize filenames across tools using kebab-case and consistent rules."
aliases = ["-name", "-filenames", "-filename-kebab"]
tags = ["naming", "shared", "conventions"]
exclusive_group = "filename-policy"
default = true
version = 1
id = "shared.filename"
+++

# Shared Switch: -filename

```notes
About CLI switches and includes:
- Use this switch from any tool to apply the same naming rules.
- Example: `sofia notator run -process -filename`.
- Switch composition is deterministic. A switch can include others via front matter, e.g.:
  `includes = ["-filename"]` to reuse this naming policy.
- MVP is prompt-as-output; tools should not perform file I/O. The LLM uses this prompt to decide names.
```

```prompt
Apply a consistent filename policy:
- Use {naming.kebab_case} for all filenames.
- Derive the base name from the provided title/topic.
- Normalize input: ASCII-fold; remove punctuation and symbols; keep digits.
- Convert to lowercase; replace whitespace with single hyphens; collapse repeated hyphens; trim leading/trailing hyphens.
- Use the .{naming.default_extension} extension unless otherwise specified by the calling context.
- Do not include directory paths in the filename, only the basename with extension.
- If a collision would occur, append a numeric suffix beginning at `-2`.
- Idempotent rule: if the appropriate suffix is already present, do not append another.
- Do not add summaries or prose to the filename output.
- Output only the filename string.
```

```examples
Input title: "A Note About Trees" → Output filename: "a-note-about-trees.md"
Input title: "Intro: Setup & Install" → Output filename: "intro-setup-install.md"
```
