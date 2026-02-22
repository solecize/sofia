+++
tool = "shared"
type = "switch"
switch = "-convert"
help = "Convert input files to Markdown using pandoc before processing."
aliases = ["-pandoc", "-to-md"]
tags = ["format", "convert", "pandoc", "shared"]
version = 1
id = "shared.convert"
+++

# Shared Switch: -convert

Use pandoc to convert non-Markdown files to Markdown before organizing.

```prompt
Before processing, convert input files to Markdown using pandoc:

1. **Detect file type**: Check the extension (.html, .docx, .rtf, .txt, etc.)

2. **Run pandoc conversion**:
   - For HTML: `pandoc -f html -t markdown --wrap=none <input> -o <output.md>`
   - For DOCX: `pandoc -f docx -t markdown <input> -o <output.md>`
   - For other formats: use pandoc's auto-detection

3. **Preserve the original**: Keep the source file; create a new .md file alongside it or in {paths.preview}.

4. **Handle conversion errors**: If pandoc fails, log a warning event and skip the file (do not halt the run).

5. **Post-conversion**: The resulting .md file is then processed normally by other switches (rename, organize, etc.)

6. **Emit events**:
   - type: "convert"
   - summary: "converted {from} to {to}"
   - data: {from: <original>, to: <markdown>, format: <source format>}
   - switch: "-convert"
```
