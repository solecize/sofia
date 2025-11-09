+++
tool = "shared"
type = "switch"
switch = "-events-ledger"
help = "Maintain a JSON Lines events ledger for actions during a run."
tags = ["report", "events", "shared"]
version = 1
id = "shared.events.ledger"
+++

# Shared Switch: -events-ledger

```notes
Use a structured, append-only JSON Lines (JSONL) ledger to record actions.
This enables rendering brief/verbose reports and machine auditing.
```

```prompt
Maintain a JSON Lines (one JSON object per line) events ledger as actions are performed.
- Strict JSON: no trailing commas; one compact object per line.
- Fields per event:
  - ts: ISO8601 UTC timestamp (e.g., 2025-11-09T18:45:12Z)
  - tool: the active tool name (e.g., "notator")
  - type: event type (e.g., "rename", "move", "create", "delete", "git.commit", "notify")
  - summary: short human-readable description
  - data: object with type-specific fields (e.g., {from, to, path, extChanged})
  - switch: triggering switch (e.g., "-rename")
  - severity: "info" | "warn" | "error" (optional)
  - id: optional unique identifier for idempotency
- Idempotency: if an event with the same id appears again, do not duplicate it.
- Echo: include the appended events in the Echo JSON under data.events (JSONL string or array of objects).
```
