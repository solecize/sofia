# Notator Shared: notify

++
tool = "notator"
type = "switch"
switch = "-notify"
help = "Notify the user about outcomes, conflicts, or next steps; emit notify events (no real notifications in MVP)."
includes = ["-events-ledger"]
tags = ["notify", "events", "shared"]
version = 1
id = "notator.notify"
++ 

# Notator Shared: -notify

```prompt
Notify the user with a concise summary of operations, conflicts, or required decisions.

- MVP behavior: do not perform actual notifications; instead, emit a `notify` event.
- Event shape: `{ type: "notify", summary, data: { message, channels?: ["cli"|"email"|"slack"], level?: "info"|"warn"|"error" } }`.
- Use clear, actionable language; include counts or filenames when helpful.
- Align with report content when both are present.
```
