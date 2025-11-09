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

# Optional per-tool defaults (uncomment to specialize)
# [tools.notator.groups.filename-policy]
# default = "-filename-kebab"
```
