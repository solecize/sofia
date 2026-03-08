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

# Previous names auto-alignment
auto_align_previous = true
```

## Entity Registry Schema

```json
{
  "version": "1.0",
  "entities": {
    "people/mara-vasenkova": {
      "name": "Mara Vasenkova",
      "aliases": ["Mara", "Peran"],
      "category": "people"
    }
  },
  "previous_names": {
    "Mara Ivanova": {
      "canonical": "Mara Vasenkova",
      "deprecated": "2026-03-08",
      "reason": "Author spelling change"
    }
  }
}
```

## Concepts

### Aliases vs Previous Names

| Field | Purpose | Behavior |
|-------|---------|----------|
| `aliases` | Valid in-story names (nicknames, callsigns) | Preserved as-is |
| `previous_names` | Outdated author names | Auto-converted on import |

### Examples

- **Alias**: "Peran" is Mara's callsign — valid in story, keep as-is
- **Previous name**: "Mara Ivanova" was old spelling — auto-convert to "Mara Vasenkova"
