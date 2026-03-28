+++
type = "work-profile"
template = "non-fiction"
created = "2026-03-15T23:00:00Z"
modified = "2026-03-15T23:00:00Z"
version = 1
+++

# Work Profile: Origin Of Species

This profile controls how Sofia processes notes for this work.
Edit the values below to customize extraction, summarization, and goals.

```toml
[entities]
# Primary entity categories for non-fiction
categories = ["people", "places", "events", "concepts", "sources"]

# Keywords for people and figures
character_keywords = [
    "naturalist", "scientist", "species", "specimen",
    "Darwin", "Malthus", "Lyell", "Wallace"
]

# Keywords for locations and settings
place_keywords = [
    "habitat", "region", "island", "continent",
    "Galápagos", "Beagle", "Down House"
]

# Keywords for events and occurrences
event_keywords = [
    "voyage", "discovery", "observation", "experiment",
    "publication", "correspondence"
]

# Custom categories for this work
custom_categories = ["species", "mechanism", "evidence", "theory"]

[prompts]
# How to summarize notes
summarize_style = "analytical"

# How to order consolidated information
consolidation_priority = "thematic"

# Wiki structure preference
wiki_structure = "topic-centric"

# Level of detail in extractions
extraction_depth = "exhaustive"

[goals]
# Current phase of the work
current_phase = "research"

# Key milestones to track
milestones = ["notebook-analysis", "theory-development", "evidence-gathering"]

# Focus areas for this phase
focus = ["natural-selection", "variation", "struggle-for-existence"]

[vars]
# Work-specific variables
thesis = "Species evolve through natural selection"
subject_area = "evolutionary biology"
time_period = "1830s-1859"
themes = ["natural selection", "variation", "adaptation", "common descent"]
genre_tags = ["non-fiction", "science", "natural history"]
primary_sources = ["Notebook B", "Notebook C", "Notebook D", "1842 Sketch", "1844 Essay"]
```

## Work-Specific Overrides

This is Darwin's foundational work on evolution. Key entities to track:
- **Mechanisms**: natural selection, sexual selection, divergence
- **Evidence types**: fossils, biogeography, embryology, homology
- **Key figures**: Malthus, Lyell, Hooker, Wallace
