# Vars: naming

+++
type = "vars"
namespace = "naming"
+++

```toml
# Human-readable description used in prompts
kebab_case = "lowercase, hyphen-separated, ASCII-only; remove punctuation; collapse repeated hyphens; trim edges"

# Default extension applied when not specified elsewhere
default_extension = "md"

# Normalization settings (for prompt guidance)
ascii_fold = true
keep_digits = true
strip_punctuation = true

# Collision suffix styles by variant (prompt guidance)
collision_suffix_kebab = "-{n}"
collision_suffix_camel = "{n}"
collision_suffix_pascal = "{n}"

# Idempotency: do not re-append suffix if already present
idempotent_suffix = true
```
