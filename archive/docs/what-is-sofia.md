Sofia is a collection of tools for managing and processing written works, with a focus on extensibility and automation. It is a **natural-language prompt composer** for language models– inverting typical the relationship between a user and the environment LLM. It provides a set of CLI-styled assistants (tools) that build structured, constrained prompts based on user-defined logic, allowing precise, repeatable, LLM-driven workflows. Its outputs are readable, inspectable, and can be executed by a model inside Windsurf or any other AI pipeline in any LLM-supported language.

In turn, compiled tools for Sofia are designed to be executed by any LLM in an environment that allows for LLM app or command line execution, such as Windsurf or any other AI pipeline.

This empowers the user to stay in control of each action, audit outcomes, and iteratively refine workflows without modifying notes directly or relying on unpredictable AI behavior, bulky prompts, or ad-hoc vibes.

Sofia guides the LLM to focus on organizing and managing bodies of text so the writer can focus on writing. Default prompts in Sofia tools are designed to be repeated throughout each session to build context and allow the LLM to focus on the task at hand, leaving the creative to the writer. 

For example, Notator, the first Sofia tool repeats it's core prompt throughout each session. This notation prompt is designed to continually remind the LLM of the context, in this case organizing notes. Part of that context is could be "You are an editing assistant that can organize notes without inserting any additional prose, and your primary focus is to segregate and match notes to their appropriate categories." Notator will begin each turn with this promt contextually adding variables and links into a set of other prompts in the extensible and user editable prompt library. Each tool has a specific prompt set designed for the task at hand, along with shared prompts for tasks common to all tools, such as instruction on naming conventions, markdown formatting templates, and instructions on where to move files.

A simple example of this prompt style would be:

User: "please use notator to organize my notes in the incoming folder and move them to the preview folder"

LLM: Runs Notator with the following switches 

-process -preview

Notator returns: "You are an editing assistant that can organize notes without inserting any additional prose, and your primary focus is to segregate and match notes to their appropriate categories. Please {organize} my notes in the incoming folder and {move} them to the preview folder using the standard {fileName} {fileType} and {markdownNotesTemplateformat}. Once complete {git} the new files in the preview folder and {notify} the user that the process is complete."

In the above example the {variables} are replaced with the appropriate values from the prompt library giving the LLM a clear instruction on what to do. The {organize} and {move} are common prompts specifing how files should be organized and moved. The {fileName} {fileType} and {markdownNotesTemplateformat} are variables that tell what to create and how to format it. The {git} and {notify} are common prompts specifing specific actions to take for adding the files to git and notifying the user. Those variables in turn could include additional variables, such as {gitPush} to make the repository public or {gitNotify} to notify the user of a conflict or error with the git process.

Variables enable users to build robust, repeatable workflows.

You can find more information about Notator in the what-is-notator.md file.

## Switch metadata: TOML front matter

Sofia stores each CLI-style switch in a Markdown file with a TOML front matter block delimited by `+++` on its own line at the start and end of the block. The front matter describes how the switch is registered and used by the CLI and composer.

Example:

```
+++
tool = "shared"
type = "switch"
switch = "-filename"
help = "Standardize filenames across tools using kebab-case and consistent rules."
aliases = ["-name", "-filenames"]
tags = ["naming", "shared", "conventions"]
version = 1
id = "shared.filename"
+++
```

Field meanings:

- **tool**: Logical namespace. `shared` means the switch is reusable across tools (e.g., Notator and others).
- **type**: Declares the Markdown file’s role. One of `switch`, `vars`, or `group`.
- **switch**: Canonical CLI flag users can pass (e.g., `-filename`).
- **help**: Short description shown by `list` commands and docs.
- **aliases**: Alternate flags that resolve to the same switch.
- **tags**: Free-form labels for grouping/filtering in docs or UI.
- **version**: Integer revision for tracking semantic changes over time.
- **id**: Stable identifier used internally; remains constant even if filenames or flags change.