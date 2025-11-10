# Notator Switch: -preview
 
 +++
 tool = "notator"
 type = "switch"
 switch = "-preview"
 help = "Annotate output as a dry-run/preview; describe actions without performing them."
 tags = ["preview", "dry-run"]
 version = 1
 id = "notator.preview"
 +++
 
```prompt
 Annotate all outputs as a dry run (preview).
 - Use language like "would rename", "would create", "would move".
 - Do not perform any file I/O or shell commands (MVP is prompt-as-output only).
 - Clearly separate proposed actions from rationale.
 - Summarize proposed changes at the end (counts by action type).
 ```
