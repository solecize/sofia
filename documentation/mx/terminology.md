# Sofia Terminology

Definitions for key terms used in Sofia.

## Directory Structure

| Term | Location | Purpose |
|------|----------|---------|
| **corpus/** | `/corpus/` | All user content (writing projects and imports) |
| **works/** | `/corpus/works/` | Individual writing projects |
| **incoming/** | `/corpus/incoming/` | Raw imports waiting to be processed |

## Inside a Work

Each project in `corpus/works/<project>/` contains:

| Term | Location | Purpose |
|------|----------|---------|
| **chapters/** | `<work>/chapters/` | Chapter files (01-chapter-one.md, etc.) |
| **notes/** | `<work>/notes/` | Chapter notes and working notebook |
| **notebook.md** | `<work>/notes/notebook.md` | Working hub for this project (stats, links, quick reference) |
| **chapter notes** | `<work>/notes/<chapter>-notes.md` | Summary and reference links for each chapter |
| **reference/** | `<work>/reference/` | Wiki-style reference files (not prose) |
| **manuscript.md** | `<work>/manuscript.md` | Table of contents / compiled view |
| **orphans.md** | `<work>/orphans.md` | Unplaced prose not yet assigned to chapters |

## Reference Categories

The `reference/` directory contains wiki-style entries organized by type:

| Category | Contents |
|----------|----------|
| **people/** | Characters (protagonists, antagonists, supporting) |
| **places/** | Locations (cities, buildings, landscapes) |
| **objects/** | Significant items (artifacts, tools, symbols) |
| **events/** | Plot events (battles, meetings, discoveries) |
| **themes/** | Thematic elements (motifs, symbols, ideas) |

## Linking

- **Chapters** should have footnotes linking to reference entries
- **Chapter notes** should contain summaries and links to relevant references
- **Notebook** provides quick access to all project elements
- **Author dashboard** links across multiple works

## Not Used

| Term | Status |
|------|--------|
| `notes/` (top-level) | Deprecated - use `corpus/works/<project>/notes/` |
| `corpus/wiki/` | Deprecated - use per-work `reference/` |
| `corpus/canon/` | Deprecated - finished chapters live in `chapters/` |
