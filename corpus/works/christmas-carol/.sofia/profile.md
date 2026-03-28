+++
type = "work-profile"
template = "fiction"
created = "2026-03-15T23:00:00Z"
modified = "2026-03-15T23:00:00Z"
version = 1
+++

# Work Profile: Christmas Carol

This profile controls how Sofia processes notes for this work.
Edit the values below to customize extraction, summarization, and goals.

```toml
[entities]
# Primary entity categories for fiction
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal character-related content
character_keywords = [
    "Scrooge", "Marley", "ghost", "spirit",
    "Cratchit", "Tiny Tim", "Fred", "Belle"
]

# Keywords for setting and location
place_keywords = [
    "London", "counting-house", "bedchamber",
    "Cratchit home", "graveyard", "streets"
]

# Keywords for plot and events
event_keywords = [
    "visitation", "haunting", "Christmas",
    "transformation", "redemption", "charity"
]

# Custom categories specific to this work
custom_categories = ["moral-lesson", "social-commentary", "supernatural"]

[prompts]
# How to summarize notes
summarize_style = "narrative"

# How to order consolidated information
consolidation_priority = "chronological"

# Wiki structure preference
wiki_structure = "character-centric"

# Level of detail in extractions
extraction_depth = "standard"

[goals]
# Current phase of the work
current_phase = "manuscript-revision"

# Key milestones to track
milestones = ["ghost-visits", "transformation-arc", "redemption"]

# Focus areas for this phase
focus = ["character-transformation", "social-themes", "holiday-spirit"]

[vars]
# Work-specific variables
protagonist = "Ebenezer Scrooge"
setting_era = "Victorian England"
setting_location = "London"
themes = ["redemption", "charity", "family", "social-responsibility"]
genre_tags = ["fiction", "novella", "christmas", "ghost-story"]
```

## Work-Specific Overrides

Dickens's Christmas novella with supernatural frame. Key elements:
- **Structure**: Five staves (musical term) like a Christmas carol
- **Ghosts**: Past, Present, Yet to Come - each reveals different truths
- **Social commentary**: poverty, workhouses, class divide
