+++
tool = "shared"
type = "switch"
switch = "-html"
help = "Process HTML input files; extract content and convert to Markdown during organization."
aliases = ["-from-html"]
tags = ["format", "input", "html", "shared"]
version = 1
id = "shared.html"
+++

# Shared Switch: -html

Instructs the LLM to handle HTML input files (e.g., ChatGPT exports).

```prompt
The input files may be in HTML format. When processing HTML:

1. **Extract meaningful content**: Ignore boilerplate (navigation, scripts, styles, metadata). Focus on the conversation or note content.

2. **Preserve structure**: Convert HTML headings to Markdown headings, lists to Markdown lists, code blocks to fenced code blocks.

3. **Handle ChatGPT exports specifically**:
   - User messages and assistant responses are typically in alternating divs or sections
   - Preserve the turn-by-turn structure
   - Mark speaker attribution clearly (e.g., "**User:**" and "**Assistant:**")

4. **Strip unnecessary markup**: Remove class attributes, inline styles, and non-semantic spans.

5. **Output as Markdown**: The result should be clean `.md` files following the naming policy.

6. **If conversion is ambiguous**: Note what was unclear in a comment block at the end of the file.
```
