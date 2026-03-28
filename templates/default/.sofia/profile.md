+++
type = "work-profile"
template = "default"
created = ""
modified = ""
version = 1
+++

# Work Profile

This profile controls how Sofia processes notes for this work.
Edit the values below to customize extraction, summarization, and goals.

```toml
[entities]
# Primary entity categories
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal character-related content
character_keywords = []

# Keywords for setting and location
place_keywords = []

# Keywords for plot and events
event_keywords = []

# Custom categories specific to this work
custom_categories = []

[prompts]
# How to summarize notes: narrative | analytical | bullet
summarize_style = "bullet"

# How to order consolidated information: chronological | thematic | character
consolidation_priority = "thematic"

# Reference structure preference: character-centric | event-centric | thematic
reference_structure = "thematic"

# Level of detail in extractions: minimal | standard | detailed
extraction_depth = "standard"

[goals]
# Current phase of the work: research | outline | first-draft | revision | polish
current_phase = "first-draft"

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = []

[vars]
# Work-specific variables
protagonist = ""
setting_era = ""
setting_location = ""
themes = []
genre_tags = []
```

## Work-Specific Overrides

*Add notes about this specific work here.*
