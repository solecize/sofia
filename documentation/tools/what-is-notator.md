# Notator: A Tool in the Sofia Framework for Prompt-Driven LLM Workflows

## Overview

**Notator** is the first tool in the **Sofia** collection—a framework of natural-language prompt composers built to manage and process written work. Sofia tools invert the typical user–LLM relationship: rather than asking a language model for creative output, they issue **structured, curated instructions** for organizing, formatting, and processing text. Notator focuses specifically on **note processing**.

Notator behaves like a CLI-styled assistant, but instead of performing file manipulations itself, it **generates LLM-ready instructions**—precise, composable, natural-language prompts. These are passed to any LLM interpreter (such as **Windsurf**) capable of executing natural language actions.

Notator outputs are readable, inspectable, and repeatable, allowing users to maintain full control while automating the repetitive, mechanical work of writing projects.

---

## Notator’s Role within Sofia

Sofia is designed around three core principles:

1. **Prompt-as-output**: Tools generate structured prompts to instruct the LLM.
2. **LLM-as-agent**: Execution is handled by a language model, not the user.
3. **User-defined logic**: All behaviors are editable via Markdown and config files.

Notator embodies these principles:

* Its job is to **organize, clean, and route notes** without introducing new prose.
* It **repeats its core prompt throughout each session**, reinforcing task context.
* It adds variables and instructions into modular prompt templates that are **user-editable**, supporting full transparency and control.

Example session (natural language):

```
User: "please use notator to organize my notes in the incoming folder and move them to the preview folder"
```

Which translates to:

```
LLM: Runs Notator with the following switches
-process -preview
```

And Notator returns:

```
"You are an editing assistant that can organize notes without inserting any additional prose, and your primary focus is to segregate and match notes to their appropriate categories. Please {organize} my notes in the incoming folder and {move} them to the preview folder using the standard {fileName} {fileType} and {markdownNotesTemplateformat}. Once complete {git} the new files in the preview folder and {notify} the user that the process is complete."
```

Each `{variable}` is resolved from the prompt library, providing granular, reusable building blocks that can be nested and extended.

---

## Core Goals

### 1. Prompt-as-output pattern

* Prompts are returned, not executed.
* Enables human oversight and LLM-driven automation.
* Supports testing, chaining, nesting.

### 2. Extensible CLI-like interface

* Switches like `-process`, `-wiki`, `-rename` behave like CLI commands.
* Each one maps to a curated natural-language instruction.
* Instructions can include variables and links to other instructions.

### 3. External config via `note-instructions.md`

* Users define their own prompt logic.
* Markdown format keeps it lightweight and readable.
* Prompts, help strings, variables, and default behaviors all live here.

### 4. Variable and nested prompt substitution

* Supports structured logic without scripting.
* Enables compound prompts and reuse of shared logic.
* DSL-like behavior without actual DSL overhead.

---

## Considerations and Enhancements

* **Session memory tracking**: Track `{current_prompt}`, filenames, tags via manifest (e.g., JSON).
* **Prompt groups**: Organize prompt sets thematically (e.g., -scene, -research, -meeting).
* **Dry-run mode**: Preview prompts before sending them to LLM.
* **Prompt fallback**: Validate prompts and warn on failure (e.g., malformed or broken links).
* **Block prompt support**: Use fenced blocks for complex or multiline instructions.

---

## Instruction Flow

### Purpose and Behavior

* Notator is an *editing assistant*. It **does not create prose**, only organizes.
* Repeats its core context prompt with every instruction to remind the LLM of its role.

### Input Examples

```
notator -process -preview
```

Triggers an output like:

```
"You are an editing assistant that can organize notes without inserting any additional prose..."
```

### Prompt Config Example (`note-instructions.md`):

```markdown
-switch: -summarize
help: Summarize a note and tag it with action items.
prompt: "Summarize the following notes into an outline and tag any action items."
```

### Nested Prompt Example:

```markdown
-switch: -event
prompt: "Convert the note using {current_prompt} and log it as an event in the wiki using -wiki."
```

---

## State Tracking

* Track all processed notes
* Record filenames, tags, and LLM responses
* Output session logs in JSON or Markdown

---

## Prompt Patterns

| Operation | Prompt                                                         |
| --------- | -------------------------------------------------------------- |
| Summarize | "Summarize this note in 2–3 lines. Include tone and priority." |
| Tag       | "Extract 3–5 thematic tags from the note."                     |
| Rename    | "Rename file using kebab-case based on topic."                 |
| Move      | "Move this file from {incoming} to {preview}."                 |
| Archive   | "Mark this as processed and move to archive folder."           |

---

## Completion Loop

* Confirm action
* Offer options: continue, revise, export

---

## Linking and Modularity

* Prompts call other prompts
* Variables populate in real time
* User controls scope and nesting

---

## Optional Extensions

* Mode toggles: markdown, screenplay, outline
* Batch mode
* LLM audit explanations (e.g., why was this tag added?)

---

## Summary

**Notator is the first executable tool in Sofia.**

It converts user intent into precise instructions for organizing notes. Rather than editing text, it builds well-scaffolded prompts for AI agents to follow. Its modular structure, variable-based prompt logic, and editable CLI-style design make it a scalable foundation for other Sofia tools.

By keeping the LLM in a bounded role—and the user in control—Notator ensures transparency, repeatability, and freedom for the writer to focus on writing.

---

**Next Steps:**

* Scaffold `note-instructions.md`
* Draft example prompt groups (e.g., -scene, -journal)
* Create sample `session-manifest.json`
* Add a Sofia README linking Notator and other tools
