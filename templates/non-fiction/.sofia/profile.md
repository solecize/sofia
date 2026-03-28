+++
type = "work-profile"
template = "non-fiction"
created = ""
modified = ""
version = 1
+++

# Work Profile: Non-Fiction

This profile is optimized for analytical non-fiction (essays, research, memoirs).

```toml
[entities]
# Primary entity categories for non-fiction
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal person-related content
character_keywords = ["author", "subject", "figure", "expert", "source"]

# Keywords for setting and location
place_keywords = ["location", "region", "institution", "organization"]

# Keywords for events and developments
event_keywords = ["development", "discovery", "event", "milestone", "change"]

# Custom categories specific to non-fiction
custom_categories = ["arguments", "sources", "evidence", "methodology"]

[prompts]
# Analytical style for non-fiction
summarize_style = "analytical"

# Thematic ordering for argument flow
consolidation_priority = "thematic"

# Thematic reference structure
reference_structure = "thematic"

# Detailed extraction for research
extraction_depth = "detailed"

[goals]
# Current phase of the work
current_phase = "research"

# Key milestones to track
milestones = []

# Focus areas for this phase
focus = ["research", "argument-structure", "evidence"]

[vars]
# Work-specific variables
protagonist = ""
setting_era = ""
setting_location = ""
themes = []
genre_tags = ["non-fiction"]
```

## Non-Fiction-Specific Notes

- **Summarize style**: Analytical summaries focus on arguments and evidence
- **Consolidation**: Thematic ordering groups related ideas together
- **Reference**: Thematic structure for tracking arguments and sources
