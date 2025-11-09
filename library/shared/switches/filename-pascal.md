+++
tool = "shared"
type = "switch"
switch = "-filename-pascal"
help = "Standardize filenames using PascalCase."
tags = ["naming", "shared", "conventions"]
exclusive_group = "filename-policy"
version = 1
id = "shared.filename.pascal"
+++

# Shared Switch: -filename-pascal

```prompt
Apply a consistent filename policy:
- Use PascalCase for all filenames.
- Start each word with an uppercase letter.
- Normalize input: ASCII-fold; remove punctuation and symbols; keep digits.
- Join words without separators.
- Use the .{naming.default_extension} extension unless otherwise specified by the calling context.
- Do not include directory paths in the filename, only the basename with extension.
- If a collision would occur, append a numeric suffix beginning at `2` (e.g., `MyFile2.md`).
- Idempotent rule: if the appropriate suffix is already present, do not append another.
- Output only the filename string.
```

```examples
Input title: "A Note About Trees" → "ANoteAboutTrees.md"
Input title: "Intro: Setup & Install" → "IntroSetupInstall.md"
```
