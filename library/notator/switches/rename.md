# Notator Switch: -rename

+++
tool = "notator"
type = "switch"
switch = "-rename"
help = "Provide guidance for renaming notes using the global filename policy."
includes = ["-filename-kebab", "-events-ledger"]
tags = ["naming", "rename"]
id = "notator.rename"
version = 1
+++

```prompt
Rename each note file according to the global filename policy.
- Prefer the title or first-level heading as the basis for the filename.
- If a specific topic or slug is provided, prefer that.
- Do not add or invent prose; do not include directory paths; output guidance only.
- Apply the policy included via `-filename` (default kebab-case) unless the user selects another filename variant.
- After determining each rename, append a JSON line to the events ledger with:
  - type: "rename"
  - summary: "renamed and converted {from} to {to}"
  - data: {from: <original name>, to: <new name>, extChanged: <true|false>}
  - switch: "-rename"
```
