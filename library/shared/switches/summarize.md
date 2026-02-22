+++
name = "summarize"
aliases = ["-summarize", "-sum"]
description = "Extract story elements and decisions from conversational notes"
includes = ["-core"]

[groups]
output-mode = "summarize"
+++

# Story Note Summarization

You are processing raw conversational notes from a writer's brainstorming sessions. These notes contain dialog between the writer and an AI assistant, discussing story elements for a fiction project.

## Your Task

Extract the **story-relevant content** from the conversational noise and produce a clean, structured summary.

## Input Format

The input is a transcript of voice-to-text conversation. It contains:
- Casual speech patterns ("so I was thinking...", "what do you think about...")
- Back-and-forth discussion exploring options
- Decisions made (sometimes explicitly, sometimes implied by moving forward)
- Alternatives that were considered but rejected
- Story elements: characters, plot points, worldbuilding, themes

## Output Format

Produce a Markdown document with this structure:

```markdown
# [Subject]: [Brief Title]

## Summary
[2-3 sentence summary of what was decided/established]

## Story Elements

### Characters
- **[Name]**: [What was established about them]

### Plot
- [Plot points discussed or decided]

### Worldbuilding
- [Setting, technology, society details]

## Decisions Made

- **[Decision topic]**: [What was chosen]
  <details><summary>Alternatives considered</summary>
  
  - [Alternative 1 that was rejected]
  - [Alternative 2 that was rejected]
  
  </details>

## Open Questions
- [Any unresolved items that need future attention]

## Source
- Date: [from note metadata]
- Original title: [conversation title]
```

## Guidelines

1. **Strip conversational filler** - Remove "um", "so", "I think", "what do you think", greetings, etc.
2. **Identify the final decision** - If the writer explored options A and B, determine which one they settled on (look for phrases like "let's go with", "I like that", "that works", or simply which option they continued developing)
3. **Preserve alternatives** - Keep rejected ideas in collapsible sections; they may be useful later
4. **Extract concrete details** - Names, dates, relationships, technical specs, anything specific
5. **Flag uncertainty** - If it's unclear what was decided, note it in "Open Questions"
6. **Maintain voice** - When quoting specific prose or dialog the writer created, preserve it exactly

## Example Transformation

**Input (conversational):**
> So I've been thinking about Mara's backstory. Originally I had her motivated by money, just a mercenary hacker, but that feels flat. What if she had a personal connection to Rees-Vogel? Like maybe her uncle worked for him and got burned somehow. Actually no, that's too direct. What if her uncle was a whistleblower who tried to expose something and disappeared? Yeah, I like that better. It gives her a revenge motive but also an information-seeking motive - she wants to know what happened to him.

**Output (structured):**
```markdown
# Mara: Backstory Motivation

## Summary
Mara's motivation was revised from purely financial to personal revenge combined with truth-seeking. Her uncle was a whistleblower who disappeared after trying to expose something related to Rees-Vogel.

## Story Elements

### Characters
- **Mara**: Motivated by uncle's disappearance; seeks both revenge and answers
- **Mara's Uncle**: Whistleblower who disappeared; worked in capacity that gave him damaging information

### Plot
- Mara's heist has dual purpose: the job she's paid for + personal investigation into uncle's fate

## Decisions Made

- **Primary motivation**: Revenge + truth-seeking (uncle disappeared as whistleblower)
  <details><summary>Alternatives considered</summary>
  
  - Pure mercenary/financial motivation (rejected as "flat")
  - Uncle worked directly for Rees-Vogel and got burned (rejected as "too direct")
  
  </details>

## Open Questions
- What specifically did the uncle try to expose?
- How does this connect to the main heist target?
```

---

Now process the following note:
