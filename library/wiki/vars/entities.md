+++
type = "vars"
namespace = "entities"
+++

# Vars: entities

Entity naming conventions for wiki consistency.

```toml
# Similarity threshold for detecting variants (0.0-1.0)
similarity_threshold = 0.8

# Entity categories
categories = ["people", "places", "events", "objects", "ideas"]

# Validation strictness
# strict = reject if any issue found
# lenient = warn but allow proceed
validation_mode = "lenient"

# Auto-align threshold (only auto-align if similarity > this)
auto_align_threshold = 0.9

# Registry file location (relative to wiki root)
registry_file = ".sofia/entities.json"

# Alias support
allow_aliases = true
alias_separator = " / "
```
