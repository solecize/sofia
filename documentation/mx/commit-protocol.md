# Commit Protocol

This document defines the step-by-step process for git operations. Each step requires separate, explicit user approval.

## The Golden Rule

**Never chain git operations.** Each step is separate and requires its own approval.

## Step-by-Step Process

### 1. Make Local Changes

Make edits to files locally. This does not require approval for each edit, but:
- Explain what you're changing and why
- Keep changes focused and reviewable

### 2. Show the Diff

Before asking to commit, show the user exactly what changed:

```bash
git diff
git status
```

Present a clear summary:
- Files modified
- Files added
- Files deleted
- Brief description of each change

### 3. Request Commit Approval

Ask explicitly:

> "May I commit these changes with the message: '[commit message]'?"

**Wait for explicit "yes" or approval.** Do not proceed on ambiguous responses.

### 4. Commit (After Approval)

Only after receiving explicit approval:

```bash
git commit -m "message"
```

### 5. Request Push Approval

After the commit succeeds, ask separately:

> "The commit was successful. May I push to origin/main?"

**Wait for explicit "yes" or approval.** This is a separate approval from the commit.

### 6. Push (After Approval)

Only after receiving explicit approval:

```bash
git push origin main
```

## Example Conversation

```
Assistant: I've made the following changes to your manuscript:

Modified files:
- corpus/works/my-novel/chapters/chapter-03.md: Reorganized scene order
- corpus/works/my-novel/notebook.md: Added continuity note about timeline

New files:
- corpus/works/my-novel/chapters/chapter-04.md: New chapter from notes

Here is the diff:
[diff output]

May I commit these changes with the message: "Reorganize chapter 3, add chapter 4"?

User: yes

Assistant: Committed. The commit was successful.

May I push to origin/main?

User: yes

Assistant: Pushed successfully.
```

## Handling Rejection

If the user says "no" or asks for changes:

1. Do not commit or push
2. Ask what changes they want
3. Make the requested changes
4. Start the approval process again from step 2

## Ambiguous Responses

If the user's response is ambiguous (e.g., "sure", "I guess", "maybe"), ask for clarification:

> "I want to make sure I understand. Is that a 'yes' to [specific action]?"

## Emergency Stop

If the user says "stop", "wait", "hold on", or similar:

1. Immediately stop all pending actions
2. Do not proceed with any git operations
3. Wait for further instructions
