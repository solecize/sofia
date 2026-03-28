+++
type = "work-profile"
template = "fiction"
created = ""
modified = ""
version = 1
+++

# Work Profile: Fiction

This profile is optimized for narrative fiction (novels, short stories, novellas).

```toml
[entities]
# Primary entity categories for fiction
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal character-related content
character_keywords = ["protagonist", "antagonist", "character", "hero", "villain"]

# Keywords for setting and location
place_keywords = ["setting", "location", "scene", "world"]

# Keywords for plot and events
event_keywords = ["plot", "conflict", "climax", "resolution", "scene"]

# Custom categories specific to fiction
custom_categories = ["plot-points", "character-arcs", "themes"]

[prompts]
# Narrative style for fiction
summarize_style = "narrative"

# Chronological ordering for story flow
consolidation_priority = "chronological"

# Character-centric reference structure
reference_structure = "character-centric"

# Standard extraction depth
extraction_depth = "standard"

[goals]
# Current phase of the work
current_phase = "first-draft"

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = ["character-development", "plot-structure", "dialogue"]

[vars]
# Work-specific variables
protagonist = ""
setting_era = ""
setting_location = ""
themes = []
genre_tags = ["fiction"]
```

## Fiction-Specific Notes

- **Summarize style**: Narrative summaries preserve voice and tone
- **Consolidation**: Chronological ordering follows story timeline
- **Reference**: Character-centric structure for tracking arcs and relationships
