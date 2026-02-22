+++
tool = "notator"
type = "switch"
switch = "-no-commit"
aliases = ["-nocommit"]
help = "Disable commits for this run; emit a notify event instead of git actions."
includes = ["-events-ledger"]
tags = ["git", "commit", "shared", "events", "no-commit"]
exclusive_group = "commit-policy"
version = 1
id = "notator.no_commit"
+++

# Notator Shared: -no-commit

```prompt
Disable Git commits for this run.

- Commit behavior:
  - Do not emit `git.add` or `git.commit` events.
  - Emit a `notify` event with:
    - summary: "commits disabled for this run"
    - data: { reason: "commit-policy:no-commit" }
  - If any downstream logic expects commit outputs, annotate accordingly in the report.

- Echo alignment:
  - data.git.policy = "none" when this variant is selected.
  - data.git.source reflects the selection source (typically "cli").
```
