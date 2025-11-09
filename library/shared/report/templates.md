# Report Templates

+++
type = "templates"
id = "shared.report.templates"
name = "Shared report templates"
+++

```toml
[summary_template]
rename = "renamed and converted {data.from} to {data.to}"
move   = "moved {data.from} to {data.to}"
create = "created {data.path}"
delete = "deleted {data.path}"
"git.commit" = "git committed: {data.message}"
"git.init" = "initialized repo at {data.path}"
"git.add" = "staged {data.count} files"
notify = "notified user: {data.message}"

[verbose_template]
rename = "- type: rename; from: {data.from}; to: {data.to}; extChanged: {data.extChanged}"
move   = "- type: move; from: {data.from}; to: {data.to}"
create = "- type: create; path: {data.path}"
delete = "- type: delete; path: {data.path}"
"git.commit" = "- type: git.commit; message: {data.message}; files: {data.files}"
"git.init" = "- type: git.init; path: {data.path}"
"git.add" = "- type: git.add; count: {data.count}; paths: {data.paths}"
notify = "- type: notify; message: {data.message}; channels: {data.channels}"

# Fallbacks used when a template for an event type is missing
[defaults]
summary_fallback = "{type}: {summary}"
verbose_fallback = "- type: {type}; data: {data}"
