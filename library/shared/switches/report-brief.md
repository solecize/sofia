+++
tool = "shared"
type = "switch"
switch = "-report-brief"
help = "Render a brief human-readable report from the events ledger (summary lines)."
aliases = ["-report"]
tags = ["report", "shared"]
exclusive_group = "report-detail"
version = 1
id = "shared.report.brief"
+++

# Shared Switch: -report-brief (alias: -report)

```prompt
Render a brief Markdown report from the events ledger using summary templates.
- Input: the JSON Lines events ledger accumulated during the run.
- Use the `summary_template` mappings to convert each event to one line.
- Unknown event types: use the event's `summary` field; if absent, pretty-print the minimal `type` and `data`.
- Sort lines by event timestamp ascending.
- Output path intent: {report.dir}/{report.brief_filename} (do not perform file I/O in MVP; print the report body).
- Include a short title and date header.
```
