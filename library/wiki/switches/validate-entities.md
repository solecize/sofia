+++
tool = "wiki"
type = "switch"
switch = "-validate-entities"
help = "Validate entity naming consistency across wiki chapters"
aliases = ["-validate", "-check-names"]
tags = ["wiki", "validation", "entities"]
version = 1
id = "wiki.validate-entities"
+++

# Wiki Switch: -validate-entities

This switch provides instructions for validating entity naming consistency.

```prompt
You are validating entity naming consistency in a story wiki.

## Validation Rules

### Entity Name Consistency
1. **Exact match required**: Entity names must match exactly across all chapters
2. **Case sensitive**: "Mara Vasenkova" ≠ "mara vasenkova"
3. **No partial names**: Use full canonical name, not nicknames (unless alias is registered)
4. **Consistent spelling**: Watch for typos like "Vasencova" vs "Vasenkova"

### Entity Categories
Check consistency within each category:
- **People**: Character names, titles, aliases
- **Places**: Location names, building names, regions
- **Events**: Historical events, plot events
- **Objects**: Technology, artifacts, vehicles
- **Ideas**: Themes, organizations, concepts

### Link Validation
1. All `[text](../category/slug.md)` links must resolve to existing files
2. Slug must match the kebab-case version of the entity name
3. Category must be correct (people, places, events, objects, ideas)

## Output Format

Report validation results as:

```json
{
  "status": "pass|fail|warn",
  "variants": [
    {
      "canonical": "Mara Vasenkova",
      "variants": ["Mara Vasencova", "Marina Vasenkova"],
      "files": ["chapter-01.md", "chapter-15.md"]
    }
  ],
  "broken_links": [
    {
      "file": "chapter-05.md",
      "link": "../people/unknown.md",
      "text": "Unknown Character"
    }
  ],
  "suggestions": [
    "Align 'Mara Vasencova' to 'Mara Vasenkova' in 2 files"
  ]
}
```

## Decision Points

When variants are found, ask:
- **align-all**: Automatically correct all variants to canonical names
- **review-each**: Review each variant individually
- **skip**: Leave variants as-is (may cause wiki inconsistency)
```
