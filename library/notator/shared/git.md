+++
tool = "notator"
type = "switch"
switch = "-git"
help = "Stage and commit changes with auto-commit policy (single-commit default; auto-escalate to two commits for structural changes)."
includes = ["-events-ledger"]
tags = ["git", "commit", "shared", "events"]
exclusive_group = "commit-policy"
version = 1
id = "notator.git"
+++

# Notator Shared: -git

```prompt
Apply Git commit policy for this run.

- Policy selection:
  - Commits are enabled by default (via config defaults selecting `-git`).
  - If the CLI selects `-no-commit`/`-nocommit`, treat commits as disabled for this run.

- When commits are disabled:
  - Do not emit `git.add` or `git.commit` events.
  - Emit a `notify` event: summary "commits disabled for this run" and data `{ reason: "commit-policy:no-commit" }`.

- When commits are enabled (default):
  - Preflight: if the repository is not initialized, propose `git init` and emit `git.init` with `{ path: "." }`.
  - Determine granularity:
    - Use a single commit by default.
    - Auto-escalate to two commits if actions structurally transform inputs to outputs, e.g.:
      - one-to-many splits (creates multiple new files from one),
      - cross-directory renames/moves (e.g., incoming → preview),
      - net new created files beyond simple renames.

  - Single-commit path:
    - Stage changes with a `git.add` event `{ paths: [ ... ], count }` including all changed/new files (and report files if rendered).
    - Commit with `git.commit` and message `notator: process {N} notes` (include `files: [...]`).

  - Two-commit path:
    1) Baseline snapshot: stage the original inputs (e.g., files in {paths.incoming}) with `git.add` and commit `notator: snapshot incoming before processing`.
    2) Outputs commit: stage changed/new files (and report outputs) with `git.add` and commit `notator: process {N} notes`.
    - If reports are committed separately, use message `notator: add report ({report.kind})`.

- Emit events to the JSONL events ledger for each step.
- Echo: include `data.git = { policy: "auto" | "none", source: "defaults" | "cli" }` reflecting whether commits are enabled and where the policy came from.
```
