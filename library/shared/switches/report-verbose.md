+++
tool = "shared"
type = "switch"
switch = "-report-verbose"
help = "Render a verbose human-readable report from the events ledger (detailed lines)."
tags = ["report", "shared"]
exclusive_group = "report-detail"
version = 1
id = "shared.report.verbose"
+++

# Shared Switch: -report-verbose

```prompt
Render a verbose Markdown report from the events ledger using verbose templates.
- Input: the JSON Lines events ledger accumulated during the run.
- Use the `verbose_template` mappings to convert each event to a detailed line including paths/locations when available.
- Unknown event types: pretty-print `type` and the `data` object in a readable bullet.
- Sort lines by event timestamp ascending.
- Output path intent: {report.dir}/{report.verbose_filename} (do not perform file I/O in MVP; print the report body).
- Include a title, date header, and a short summary of counts by event type at the end.
```
