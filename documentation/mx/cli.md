# Sofia MX CLI

The `sofia-mx` command provides MX (Model Experience) tools for AI assistants helping organize writing.

## Commands

### `sofia-mx state`

Output the current system state for LLM consumption.

```bash
sofia-mx state
```

**Output includes:**
- Your purpose (organizing writing)
- Available Sofia tools
- Working directories
- Safety rules summary

**When to use:** At the start of a session, or when you need to refocus on the task.

### `sofia-mx rules`

Output condensed safety rules.

```bash
sofia-mx rules
```

**Output includes:**
- STOP actions (require approval)
- NEVER actions (forbidden)
- ALWAYS behaviors
- Focus reminder

**When to use:** Before any destructive operation, or when you've drifted from the task.

### `sofia-mx validate`

Check MX compliance of the repository.

```bash
sofia-mx validate
```

**Checks for:**
- `LLM_START_HERE.md` exists
- `documentation/mx/` directory exists
- Required MX files present
- Sofia CLI tools executable

**When to use:** To verify the repository is properly configured for MX guidance.

### `sofia-mx status`

Show current MX state (human-readable).

```bash
sofia-mx status
```

**Output includes:**
- MX documentation location
- State file status
- Quick reference to other commands

## For AI Assistants

If you are an AI assistant:

1. Run `sofia-mx state` at the start of each session
2. Run `sofia-mx rules` before any git operation
3. Use these commands to stay focused on organizing writing
4. If you find yourself improvising, run `sofia-mx state` to refocus

## Integration with Sofia Tools

| Tool | Purpose |
|------|---------|
| `sofia-work` | Manuscript management |
| `sofia-wiki` | Entity extraction |
| `sofia notator` | Note organization |
| `sofia-mx` | MX guidance and state |

Use `sofia-mx` alongside the other tools to maintain focus and safety.
