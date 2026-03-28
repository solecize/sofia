+++
type = "profile-template"
id = "profile.memoir"
name = "Memoir"
description = "Personal narrative, autobiography, and life writing"
version = 1
+++

# Profile Template: Memoir

Default configuration for personal and autobiographical works.

```toml
[entities]
# Primary entity categories for memoir
categories = ["people", "places", "events", "periods", "reflections"]

# Keywords for people in the narrative
character_keywords = [
    "family", "friend", "mentor", "colleague",
    "narrator", "self", "relationship", "influence"
]

# Keywords for meaningful places
place_keywords = [
    "home", "childhood", "neighborhood", "city",
    "country", "workplace", "school", "landmark"
]

# Keywords for life events
event_keywords = [
    "memory", "moment", "turning-point", "milestone",
    "loss", "achievement", "discovery", "transition"
]

# Custom categories for memoir
custom_categories = ["reflection", "lesson", "emotion", "growth"]

[prompts]
# How to summarize notes
summarize_style = "narrative"  # narrative | analytical | bullet

# How to order consolidated information
consolidation_priority = "chronological"  # chronological | thematic | character

# Wiki structure preference
wiki_structure = "chronological"  # character-centric | plot-centric | thematic | chronological

# Level of detail in extractions
extraction_depth = "standard"  # minimal | standard | exhaustive

[goals]
# Current phase of the work
current_phase = "first-draft"  # research | outline | first-draft | revision | polish

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = ["memory-gathering", "emotional-truth", "narrative-arc"]

[vars]
# Work-specific variables
narrator = ""
time_span = ""
central_theme = ""
themes = []
genre_tags = ["memoir", "personal"]
key_periods = []

[previous_names]
# Map old/variant names to canonical names for auto-alignment
# Example: "Mom" = "Margaret Chen"
```

## Usage

This template is applied when creating a new memoir:

```bash
sofia-work init my-memoir --template memoir
```

Override any values in your work's `.sofia/profile.md`.
