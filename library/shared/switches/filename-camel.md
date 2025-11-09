+++
tool = "shared"
type = "switch"
switch = "-filename-camel"
help = "Standardize filenames using camelCase."
tags = ["naming", "shared", "conventions"]
exclusive_group = "filename-policy"
version = 1
id = "shared.filename.camel"
+++

# Shared Switch: -filename-camel

```prompt
Apply a consistent filename policy:
- Use camelCase for all filenames.
- Start with a lowercase letter; remove punctuation and symbols.
- Join words without separators; capitalize the first letter of subsequent words.
- Preserve the `.md` extension unless otherwise specified by the calling context.
- Do not include directory paths in the filename, only the basename with extension.
- If a collision would occur, append a numeric suffix beginning at `2` (e.g., `myFile2.md`).
- Output only the filename string.
```

```examples
Input title: "A Note About Trees" → "aNoteAboutTrees.md"
Input title: "Intro: Setup & Install" → "introSetupInstall.md"
```
