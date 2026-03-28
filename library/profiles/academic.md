+++
type = "profile-template"
id = "profile.academic"
name = "Academic"
description = "Research papers, dissertations, and scholarly works"
version = 1
+++

# Profile Template: Academic

Default configuration for citation-heavy scholarly writing.

```toml
[entities]
# Primary entity categories for academic work
categories = ["authors", "works", "concepts", "methods", "findings"]

# Keywords for scholars and researchers
character_keywords = [
    "author", "researcher", "scholar", "theorist",
    "contributor", "critic", "reviewer"
]

# Keywords for institutions and venues
place_keywords = [
    "university", "institution", "journal", "conference",
    "laboratory", "department", "field"
]

# Keywords for academic events
event_keywords = [
    "study", "experiment", "publication", "discovery",
    "debate", "symposium", "review"
]

# Custom categories for academic work
custom_categories = ["citation", "methodology", "hypothesis", "conclusion"]

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
focus = ["literature-review", "methodology", "citation-management"]

[vars]
# Work-specific variables
thesis = ""
field = ""
methodology = ""
themes = []
genre_tags = ["academic", "research"]
citation_style = "chicago"  # chicago | mla | apa | harvard
key_sources = []

[previous_names]
# Map old/variant names to canonical names for auto-alignment
# Example: "Smith et al." = "Smith, Jones, and Brown (2024)"
```

## Usage

This template is applied when creating a new academic work:

```bash
sofia-work init my-dissertation --template academic
```

Override any values in your work's `.sofia/profile.md`.
