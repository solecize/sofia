+++
type = "profile-template"
id = "profile.non-fiction"
name = "Non-Fiction"
description = "Essays, journalism, and expository writing projects"
version = 1
+++

# Profile Template: Non-Fiction

Default configuration for argument-driven and informational works.

```toml
[entities]
# Primary entity categories for non-fiction
categories = ["people", "places", "events", "concepts", "sources"]

# Keywords for people and figures
character_keywords = [
    "author", "subject", "expert", "witness", "source",
    "figure", "leader", "scientist", "historian"
]

# Keywords for locations and settings
place_keywords = [
    "location", "region", "country", "institution",
    "organization", "site", "venue"
]

# Keywords for events and occurrences
event_keywords = [
    "event", "discovery", "development", "breakthrough",
    "incident", "period", "era", "movement"
]

# Custom categories for non-fiction
custom_categories = ["evidence", "argument", "counterpoint"]

[prompts]
# How to summarize notes
summarize_style = "analytical"  # narrative | analytical | bullet

# How to order consolidated information
consolidation_priority = "thematic"  # chronological | thematic | character

# Wiki structure preference
wiki_structure = "topic-centric"  # character-centric | plot-centric | thematic | topic-centric

# Level of detail in extractions
extraction_depth = "exhaustive"  # minimal | standard | exhaustive

[goals]
# Current phase of the work
current_phase = "research"  # research | outline | first-draft | revision | polish

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = ["source-gathering", "argument-structure"]

[vars]
# Work-specific variables
thesis = ""
subject_area = ""
time_period = ""
themes = []
genre_tags = ["non-fiction"]
primary_sources = []

[previous_names]
# Map old/variant names to canonical names for auto-alignment
# Example: "C. Darwin" = "Charles Darwin"
```

## Usage

This template is applied when creating a new non-fiction work:

```bash
sofia-work init my-essay --template non-fiction
```

Override any values in your work's `.sofia/profile.md`.
