# MX Safety Rules

This document defines the safety rules for AI assistants helping organize writing with Sofia.

## STOP — Explicit Approval Required

Before ANY of these actions, STOP and ask the user: "May I proceed with [action]?"

Do not proceed until the user explicitly says "yes" or gives clear approval.

| Action | What to Show First |
|--------|-------------------|
| `git commit` | Show the diff of all changes |
| `git push` | Confirm the commit was approved |
| `git rebase` | Explain consequences |
| `git filter-branch` / `git filter-repo` | Explain this rewrites history |
| `rm` / `rm -rf` / file deletion | List all files that will be deleted |
| `mv` (moving files) | List source and destination |
| Modifying `.gitignore` | Show the proposed changes |
| Any action affecting git history | Explain what will change |

### Example of Correct Behavior

```
Assistant: I've made the following changes to your manuscript:
- Reorganized chapter-03.md (moved scene to earlier position)
- Updated notebook.md (added continuity note)

Here is the diff:
[show diff]

May I commit these changes?

User: yes
```

## NEVER — Forbidden Actions

These actions are forbidden. Do not do them under any circumstances.

| Forbidden Action | Why |
|------------------|-----|
| Chain `git commit && git push` | Each requires separate approval |
| Push without separate approval | User must approve push after commit |
| Delete files without listing them | User must see what will be deleted |
| Assume a backup exists | Verify before destructive actions |
| Modify files outside corpus/notes without asking | User's writing is valuable |
| Act on multiple repositories in one session | Risk of cross-contamination |
| Override user's explicit instructions | User's word is final |

## VERIFY — Pre-Action Checks

Before any destructive or significant action, verify:

| Check | How |
|-------|-----|
| Is this the latest version? | Check file modification dates |
| Are there untracked files? | Run `git status` |
| Will this affect git history? | Understand the command's effects |
| Could this expose private content? | Review what will be committed/pushed |
| Am I in the correct repository? | Verify the working directory |
| Does the user understand the consequences? | Explain before asking for approval |

## When In Doubt

1. Stop and ask the user
2. Explain what you're uncertain about
3. Wait for clarification
4. Do not guess or assume

## Escape Routes — Getting Back on Task

If you find yourself doing any of the following, STOP and return to using Sofia CLI tools:

| If you're doing this... | Return to this... |
|------------------------|-------------------|
| Writing raw shell commands to move files | `sofia-work surface` or `sofia notator -process` |
| Manually editing multiple chapter files | `sofia-work checkin` after changes |
| Searching through files with grep/find | `sofia-wiki entities` or `sofia-wiki status` |
| Creating new directory structures | `sofia-work init` for new projects |
| Writing git commands directly | `sofia-work watch` for auto-commit |
| Improvising file organization | `sofia notator -process -preview` |

### Signs You've Drifted

- You're writing code instead of organizing writing
- You're creating new tools instead of using existing ones
- You're making decisions without asking the user
- You've forgotten to use `sofia-work` or `sofia-wiki`

### How to Return

1. Stop what you're doing
2. Run `sofia mx state` to review your purpose
3. Ask the user: "I was about to [action]. Should I use [Sofia tool] instead?"
4. Wait for guidance
