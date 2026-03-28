+++
type = "work-profile"
template = "fiction"
created = "2026-03-15T23:00:00Z"
modified = "2026-03-15T23:00:00Z"
version = 1
+++

# Work Profile: Frankenstein

This profile controls how Sofia processes notes for this work.
Edit the values below to customize extraction, summarization, and goals.

```toml
[entities]
# Primary entity categories for fiction
categories = ["people", "places", "events", "objects", "ideas"]

# Keywords that signal character-related content
character_keywords = [
    "Victor", "Frankenstein", "creature", "monster",
    "Elizabeth", "Clerval", "Walton", "Justine"
]

# Keywords for setting and location
place_keywords = [
    "Geneva", "Ingolstadt", "laboratory", "Arctic",
    "cottage", "Alps", "university"
]

# Keywords for plot and events
event_keywords = [
    "creation", "pursuit", "murder", "trial",
    "voyage", "confrontation", "death"
]

# Custom categories specific to this work
custom_categories = ["science", "moral-lesson", "gothic-element"]

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
milestones = ["frame-narrative", "creation-sequence", "pursuit-arc"]

# Focus areas for this phase
focus = ["character-development", "gothic-atmosphere", "moral-themes"]

[vars]
# Work-specific variables
protagonist = "Victor Frankenstein"
setting_era = "early-19th-century"
setting_location = "Geneva, Ingolstadt, Arctic"
themes = ["creation", "responsibility", "isolation", "nature-vs-nurture"]
genre_tags = ["fiction", "gothic", "science-fiction"]
```

## Work-Specific Overrides

Mary Shelley's gothic novel with frame narrative structure. Key elements:
- **Frame**: Walton's letters → Victor's narrative → Creature's narrative
- **Themes**: hubris, parental responsibility, isolation, revenge
- **Gothic elements**: sublime nature, death, the uncanny
