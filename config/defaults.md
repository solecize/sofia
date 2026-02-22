# Sofia Global Defaults

+++
type = "defaults"
id = "defaults.global"
name = "Sofia global defaults"
+++

```toml
[groups.filename-policy]
# Canonical default variant for filename policy
# Note: "-filename" remains an alias to "-filename-kebab" for CLI ergonomics
default = "-filename-kebab"

[groups.commit-policy]
# Default commit behavior for tools (auto stage + commit)
default = "-git"

[groups.report-detail]
# Default report detail level
default = "-report-brief"

# Optional per-tool defaults (uncomment to specialize)
# [tools.notator.groups.filename-policy]
# default = "-filename-kebab"
# [tools.notator.groups.commit-policy]
# default = "-git"
# [tools.notator.groups.report-detail]
# default = "-report-brief"
