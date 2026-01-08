---
name: library-management
description: Manage Open Agent library - create, update, delete skills, agents, commands, tools, rules, and MCPs via the Library API
---

# Open Agent Library Management

The Open Agent Library is a Git-backed configuration repository that stores reusable components for your agent system. Use the `library_*` tools to manage these components.

## Available Tools

Use these tools to manage the library. Tool names follow the pattern `<filename>_<export>`:

### Skills (library-skills.ts)
- `library-skills_list_skills` - List all skills with their descriptions
- `library-skills_get_skill` - Get full skill content by name
- `library-skills_save_skill` - Create or update a skill
- `library-skills_delete_skill` - Delete a skill

### Agents (library-agents.ts)
- `library-agents_list_agents` - List all library agents
- `library-agents_get_agent` - Get full agent configuration by name
- `library-agents_save_agent` - Create or update an agent
- `library-agents_delete_agent` - Delete an agent

### Commands (library-commands.ts)
- `library-commands_list_commands` - List all commands
- `library-commands_get_command` - Get full command content by name
- `library-commands_save_command` - Create or update a command
- `library-commands_delete_command` - Delete a command

### Tools (library-commands.ts)
- `library-commands_list_tools` - List all custom tools
- `library-commands_get_tool` - Get full tool code by name
- `library-commands_save_tool` - Create or update a tool
- `library-commands_delete_tool` - Delete a tool

### Rules (library-commands.ts)
- `library-commands_list_rules` - List all rules
- `library-commands_get_rule` - Get full rule content by name
- `library-commands_save_rule` - Create or update a rule
- `library-commands_delete_rule` - Delete a rule

### MCPs (library-git.ts)
- `library-git_get_mcps` - Get all MCP server configurations
- `library-git_save_mcps` - Save MCP server configurations

### Git Operations (library-git.ts)
- `library-git_status` - Get git status (branch, modified files, sync state)
- `library-git_sync` - Pull latest changes from remote
- `library-git_commit` - Commit all changes with a message
- `library-git_push` - Push commits to remote

---

## File Formats

### Skills (`skill/<name>/SKILL.md`)

```yaml
---
name: skill-name
description: What this skill does (required, 1-1024 chars)
license: MIT (optional)
compatibility: opencode (optional)
metadata:
  key: value (optional)
---

Skill instructions in markdown...
```

Name requirements:
- 1-64 characters
- Lowercase alphanumeric with single hyphen separators
- No leading/trailing hyphens, no consecutive hyphens

### Agents (`agent/<name>.md`)

```yaml
---
description: Agent description (required)
mode: primary | subagent
model: provider/model-id (e.g., anthropic/claude-sonnet-4-20250514)
hidden: true | false
color: "#44BA81" (optional hex color)
tools:
  "*": false
  "read": true
  "write": true
permission:
  edit: ask | allow | deny
  bash:
    "*": ask
    "git status": allow
rules:
  - rule-name-to-include
---

Agent system prompt in markdown...
```

### Commands (`command/<name>.md`)

```yaml
---
description: Command description
model: provider/model-id (optional, overrides default)
subtask: true | false (run as background task)
agent: agent-name (optional, use specific agent)
---

Command prompt template...

Use $ARGUMENTS for user-provided arguments.
```

### Tools (`tool/<name>.ts`)

```typescript
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Tool description",
  args: {
    param: tool.schema.string().describe("Parameter description"),
  },
  async execute(args, context) {
    // Tool implementation
    return "result"
  },
})
```

### Rules (`rule/<name>.md`)

```yaml
---
description: Rule description
---

Rule instructions in markdown...
Applied to agents that reference this rule.
```

### MCPs (`mcp/servers.json`)

```json
{
  "server-name": {
    "type": "local",
    "command": ["npx", "package-name"],
    "env": { "KEY": "value" },
    "enabled": true
  },
  "remote-server": {
    "type": "remote",
    "url": "https://mcp.example.com",
    "headers": { "Authorization": "Bearer token" },
    "enabled": true
  }
}
```

---

## Workflow Example

1. **List existing items**: Use `library_list_*` to see what exists
2. **Get current content**: Use `library_get_*` to read before modifying
3. **Make changes**: Use `library_save_*` with the full content
4. **Commit changes**: Use `library_commit` with a descriptive message
5. **Push to remote**: Use `library_push` to sync with the git remote

---

## Tips

- Always read existing content before updating to avoid overwriting changes
- Use descriptive commit messages explaining what changed and why
- Check `library_status` to see uncommitted changes before pushing
- Skills sync automatically to workspaces after saving
