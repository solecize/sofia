+++
type = "profile-template"
id = "profile.fiction"
name = "Fiction"
description = "Novel, short story, and narrative fiction projects"
version = 1
+++

# Profile Template: Fiction

Default configuration for character-driven narrative works.

```toml
[entities]
# Primary entity categories for fiction
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal character-related content
character_keywords = [
    "protagonist", "antagonist", "narrator", "hero", "villain",
    "character", "personality", "motivation", "arc", "backstory",
    "dialogue", "relationship", "conflict"
]

# Keywords for setting and location
place_keywords = [
    "setting", "location", "scene", "world", "city", "house",
    "landscape", "atmosphere", "environment"
]

# Keywords for plot and events
event_keywords = [
    "plot", "scene", "chapter", "climax", "resolution",
    "conflict", "twist", "revelation", "confrontation"
]

# Custom categories specific to this genre
custom_categories = []

[prompts]
# How to summarize notes
summarize_style = "narrative"  # narrative | analytical | bullet

# How to order consolidated information
consolidation_priority = "chronological"  # chronological | thematic | character

# Wiki structure preference
wiki_structure = "character-centric"  # character-centric | plot-centric | thematic

# Level of detail in extractions
extraction_depth = "standard"  # minimal | standard | exhaustive

[goals]
# Current phase of the work
current_phase = "first-draft"  # research | outline | first-draft | revision | polish

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = ["character-development", "plot-structure"]

[vars]
# Work-specific variables (override in per-work profile)
# These are placeholders - set actual values in .sofia/profile.md
protagonist = ""
setting_era = ""
setting_location = ""
themes = []
genre_tags = ["fiction"]

[previous_names]
# Map old/variant names to canonical names for auto-alignment
# Example: "Jon Snow" = "Jon Stark"
```

## Usage

This template is applied when creating a new fiction work:

```bash
sofia-work init my-novel --template fiction
```

Override any values in your work's `.sofia/profile.md`.
