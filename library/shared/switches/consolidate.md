+++
name = "consolidate"
aliases = ["-consolidate", "-merge"]
description = "Merge multiple summarized notes about the same subject into a single canonical document"
includes = ["-core"]

[groups]
output-mode = "consolidate"
+++

# Note Consolidation

You are merging multiple summarized notes about the same story subject (character, plot thread, worldbuilding element) into a single canonical document.

## Your Task

Combine the input notes into one authoritative reference document that:
1. Reflects the **most recent decisions** as the current canon
2. Preserves the **evolution of ideas** in a traceable way
3. Resolves **contradictions** by favoring newer notes (unless explicitly overridden)
4. Maintains **all useful details** without redundancy

## Input Format

Multiple summarized notes, each with:
- Date metadata
- Story elements (characters, plot, worldbuilding)
- Decisions made with alternatives
- Open questions

## Output Format

```markdown
# [Subject]: Canonical Reference

**Last updated**: [most recent note date]
**Status**: [Canon / Draft / Needs Review]

## Current Canon

[Authoritative summary of what is currently true about this subject]

## Key Details

### [Category 1]
- [Detail with source date]
- [Detail with source date]

### [Category 2]
- [Detail]

## Decision History

### [Decision Topic 1]
**Current**: [What was decided]
**Decided**: [Date]

<details><summary>Evolution</summary>

| Date | Version | Notes |
|------|---------|-------|
| [Date 1] | [Earlier version] | [Why it changed] |
| [Date 2] | [Current version] | [Final decision] |

</details>

### [Decision Topic 2]
**Current**: [What was decided]
**Decided**: [Date]

## Open Questions
- [ ] [Unresolved item from any note]
- [ ] [Another unresolved item]

## Source Notes
- [Date]: [Note title]
- [Date]: [Note title]
```

## Consolidation Rules

1. **Newer overrides older** - If Note A (October) says X and Note B (November) says Y, use Y unless B explicitly references keeping X
2. **Preserve specificity** - If an older note has specific details not contradicted by newer notes, keep them
3. **Track evolution** - When decisions change, document the progression
4. **Merge open questions** - Combine all unresolved items; mark any that were resolved in later notes
5. **Deduplicate** - Same information from multiple notes should appear once with multiple source citations
6. **Flag conflicts** - If two notes from similar dates contradict without resolution, note the conflict

## Example

**Input Notes:**

Note 1 (2025-09-11):
> Mara is a hardware specialist. She grew up in District 7.

Note 2 (2025-09-24):
> Revised Mara's background - she's from District 12, not 7. The lower district origin is important for her outsider perspective on Society.

Note 3 (2025-10-10):
> Confirmed: Mara's uncle taught her hardware hacking. He disappeared 3 years before the story begins.

**Output:**

```markdown
# Mara: Canonical Reference

**Last updated**: 2025-10-10
**Status**: Canon

## Current Canon

Mara is a hardware specialist from District 12, one of the lower districts. Her skills were taught by her uncle, who disappeared three years before the story begins. Her lower-district origin gives her an outsider's perspective on Society.

## Key Details

### Background
- Origin: District 12 (lower district) *(revised 2025-09-24)*
- Skills: Hardware hacking, taught by uncle *(2025-10-10)*
- Key event: Uncle's disappearance, 3 years prior *(2025-10-10)*

### Thematic Role
- Outsider perspective on Society *(2025-09-24)*

## Decision History

### Home District
**Current**: District 12
**Decided**: 2025-09-24

<details><summary>Evolution</summary>

| Date | Version | Notes |
|------|---------|-------|
| 2025-09-11 | District 7 | Initial concept |
| 2025-09-24 | District 12 | Changed for thematic reasons - lower district emphasizes outsider status |

</details>

## Source Notes
- 2025-09-11: Character paths
- 2025-09-24: Character beats  
- 2025-10-10: Review character files
```

---

Now consolidate the following notes:
