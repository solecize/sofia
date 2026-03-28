# Templates

Work templates for `sofia-work init`.

## Usage

```bash
# Create a new work with default template
sofia-work init my-novel

# Create with a specific template
sofia-work init my-novel --template fiction
sofia-work init my-essay --template non-fiction
```

## Available Templates

| Template | Description |
|----------|-------------|
| `default` | Minimal template with no genre assumptions |
| `fiction` | Narrative focus (chronological, character-centric) |
| `non-fiction` | Analytical focus (thematic, evidence-based) |

## Template Structure

### default/

Full work structure copied for every new work:

```
default/
├── chapters/           # Chapter files
├── notes/
│   └── notebook.md     # Working hub
├── reference/          # Wiki-style reference
│   ├── people/
│   ├── places/
│   ├── objects/
│   ├── events/
│   └── themes/
├── .sofia/
│   └── profile.md      # Work profile
├── manuscript.md       # Table of contents
└── orphans.md          # Unplaced prose
```

### Genre Templates (fiction/, non-fiction/)

Genre templates only contain `.sofia/profile.md` with customized defaults:

- **fiction**: `summarize_style = "narrative"`, `consolidation_priority = "chronological"`
- **non-fiction**: `summarize_style = "analytical"`, `consolidation_priority = "thematic"`

When using `--template fiction`, the default structure is copied first, then the genre's `profile.md` replaces the default one.

## Creating Custom Templates

1. Create a new directory in `templates/`
2. Add `.sofia/profile.md` with your customizations
3. Use with `sofia-work init my-work --template your-template`

Custom templates can include any files - they will be merged with the default structure.
