+++
tool = "wiki"
type = "switch"
switch = "-align-names"
help = "Align entity name variants to canonical names"
aliases = ["-align", "-fix-names"]
tags = ["wiki", "alignment", "entities"]
version = 1
id = "wiki.align-names"
+++

# Wiki Switch: -align-names

This switch provides instructions for aligning entity name variants.

```prompt
You are correcting entity name variants in a story wiki.

## Alignment Rules

### Determining Canonical Name
1. **Registry priority**: If name exists in entity registry, use that spelling
2. **Frequency**: If not in registry, use most frequently occurring spelling
3. **Author intent**: Prefer names that match the author's established style

### Alignment Modes

#### Auto Mode (`--auto`)
- Automatically align all detected variants to canonical names
- Replace variant in H3 headers: `### Variant Name` → `### Canonical Name`
- Update markdown links: `[Variant](../people/variant.md)` → `[Canonical](../people/canonical.md)`
- Log all changes for review

#### Manual Mode (`<old> <new>`)
- Align specific name: `sofia-wiki align project "Old Name" "New Name"`
- Find and replace in all wiki files
- Optionally register old name as alias with `--alias`

### Alias Support
Some characters have multiple valid names:
- **Full name**: "Marina Vasenkova"
- **Common name**: "Mara"
- **Alias**: "Peran" (callsign)

Register aliases in entity registry:
```json
{
  "Mara Vasenkova": {
    "slug": "mara-vasenkova",
    "category": "people",
    "aliases": ["Mara", "Marina Vasenkova", "Peran"]
  }
}
```

## Output Format

After alignment:
```json
{
  "stage": "align",
  "mode": "auto|manual",
  "changes": [
    {
      "file": "chapter-01.md",
      "old": "Mara Vasencova",
      "new": "Mara Vasenkova"
    }
  ],
  "total_changes": 5,
  "next": "git commit -m 'sofia: align entity names'"
}
```

## Safety
- Never align names that are intentionally different (e.g., character aliases)
- Preserve author's creative choices
- When uncertain, ask before aligning
```
