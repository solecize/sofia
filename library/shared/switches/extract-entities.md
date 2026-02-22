+++
name = "extract-entities"
aliases = ["-extract", "-entities"]
description = "Extract story entities (people, places, events, objects, ideas) from a chapter"
includes = ["-core"]

[groups]
output-mode = "extract-entities"
+++

# Story Entity Extraction

You are processing a chapter from a fiction manuscript. Extract all significant story entities and output them in a structured format for building a story wiki.

## Entity Categories

Extract entities in these categories:

### People (Characters)
- Named characters who appear or are mentioned
- Include: name, role/description, relationships, first appearance info

### Places
- Locations where scenes occur or that are referenced
- Include: name, type (city, building, ship, etc.), description, significance

### Events
- Significant plot events, historical events referenced, or backstory events
- Include: name, when it occurs (relative to story), participants, consequences

### Objects
- Significant items: technology, artifacts, documents, vehicles
- Include: name, type, description, who uses/owns it, significance

### Ideas
- Themes, concepts, political systems, cultural practices
- Include: name, description, how it manifests in the story

## Output Format

```markdown
# Chapter: [Chapter Title]

## Summary
[2-3 sentence plot summary of this chapter]

## People

### [Character Name]
- **Role**: [protagonist/antagonist/supporting/mentioned]
- **Description**: [physical, personality, occupation]
- **Relationships**: [connections to other characters]
- **In this chapter**: [what they do/what happens to them]

### [Next Character]
...

## Places

### [Place Name]
- **Type**: [city/building/vehicle/region/etc.]
- **Description**: [what it looks like, feels like]
- **Significance**: [why it matters to the story]

## Events

### [Event Name]
- **When**: [during chapter / backstory / future reference]
- **Participants**: [who is involved]
- **What happens**: [brief description]
- **Consequences**: [impact on plot/characters]

## Objects

### [Object Name]
- **Type**: [technology/weapon/document/vehicle/etc.]
- **Description**: [what it is, how it works]
- **Owner/User**: [who has it]
- **Significance**: [why it matters]

## Ideas

### [Concept Name]
- **Type**: [theme/political system/cultural practice/technology concept]
- **Description**: [what it is]
- **Manifestation**: [how it appears in this chapter]

## Connections
- [[people/character-name]] appears at [[places/location-name]]
- [[events/event-name]] involves [[objects/object-name]]
- [List key relationships between entities using wiki-link format]
```

## Guidelines

1. **Be thorough** - Extract every named entity, even minor ones
2. **Use consistent naming** - Same character should have same name across chapters
3. **Note first appearances** - Mark if this is the first time an entity appears
4. **Capture relationships** - How entities connect to each other
5. **Wiki-link format** - Use `[[category/entity-name]]` for cross-references
6. **Kebab-case for links** - `[[people/simon-wilde]]` not `[[people/Simon Wilde]]`

## Example

For a chapter introducing a journalist infiltrating a political organization:

```markdown
# Chapter: 0x00 //Above the Fold

## Summary
Simon Wilde, a journalist working undercover at the Commission on Reintegration of the Exodites (C.R.E.), prepares to steal data that will expose the Exodites' fraudulent population claims. He reflects on his two years of infiltration and his partnership with editor Mike Rich.

## People

### Simon Wilde
- **Role**: Protagonist
- **Description**: Journalist in his late 20s, cynical, methodical. Uses pseudonyms Derek Lowell (at C.R.E.) and Melvin Bryant (for payments).
- **Relationships**: Partner with [[people/mike-rich]], worked at [[places/urban-buzz]]
- **In this chapter**: Executing final data theft, reflecting on his mission

### Mike Rich (Michael Paul Rich)
- **Role**: Supporting (mentor)
- **Description**: Grumpy, greedy, old. Seasoned political journalist, Pol Editor at Urban Buzz. "Three first names."
- **Relationships**: Mentor to [[people/simon-wilde]], helped fake his identity
- **In this chapter**: Referenced as co-conspirator, not physically present

### Reiss Vogel
- **Role**: Antagonist (indirect)
- **Description**: Chief of Staff at C.R.E., modern business aristocrat, Society member. Left wife and Society ventures to work for Exodites.
- **Relationships**: Unknowingly trusts [[people/simon-wilde]], estranged from wife
- **In this chapter**: Mentioned as Simon's unwitting enabler

## Places

### Commission on Reintegration of the Exodites (C.R.E.)
- **Type**: Political organization / office
- **Description**: Bureaucratic office handling Exodite political campaign
- **Significance**: Simon's infiltration target, source of stolen data

### The Urban Buzz
- **Type**: News organization
- **Description**: Formerly gossip/conspiracy publication, transitioning to legitimate news
- **Significance**: Simon's true employer, will publish his exposé

## Events

### The Data Theft (current)
- **When**: During chapter
- **Participants**: [[people/simon-wilde]]
- **What happens**: Simon uses InfoRat tools to copy Exodite financial and political data
- **Consequences**: Will expose Exodite fraud, end Simon's cover

### WISH Massacre (backstory)
- **When**: Before story begins
- **Participants**: Simon's former hacker collective
- **What happens**: Group was destroyed, Simon's first love killed
- **Consequences**: Shaped Simon's isolation and mistrust

## Objects

### STAC / STACQ
- **Type**: Technology (communication device)
- **Description**: Personal communication device; STACQ is quantum-enabled version for direct Exodite communication
- **Owner/User**: C.R.E. staff, Simon has hidden one
- **Significance**: Simon's method for copying data

### InfoRat Tools
- **Type**: Technology (hacking software)
- **Description**: Programs for searching and copying files
- **Owner/User**: [[people/simon-wilde]]
- **Significance**: Illegal possession; key to the heist

## Ideas

### The 144 Voting Block
- **Type**: Political system
- **Description**: Global voting system, Exodites seeking to join with 10% of votes
- **Manifestation**: Stakes of the reintegration campaign

### Society (capital S)
- **Type**: Social class / culture
- **Description**: Dynasty-obsessed aristocrats, "SocKids" are their children
- **Manifestation**: Reiss Vogel is Society; C.R.E. staffed by Society Kids

## Connections
- [[people/simon-wilde]] infiltrated [[places/cre]] to expose [[people/reiss-vogel]]
- [[objects/stac]] enables [[events/data-theft]]
- [[ideas/society]] conflicts with [[ideas/144-voting-block]]
```

---

Now extract entities from the following chapter:
