# Agents and Execution Architecture

This document describes how Open Agent executes missions after the per-workspace
harness refactor ("ralph" plan). The core change: **OpenCode and Claude Code run
inside the target workspace**, so native bash and file effects are scoped to the
correct environment. The host proxy bash tools are no longer required for normal
missions.

## High-level flow

1. User creates a mission with a workspace + agent (backend).
2. Open Agent prepares a **per-mission workspace directory** and syncs Library
   content (skills/tools/rules).
3. Open Agent writes **per-workspace config files** (`opencode.json`,
   `.opencode/opencode.json`, `.claude/settings.local.json`, `CLAUDE.md`).
4. The mission runner launches the chosen harness **inside the workspace** using
   a workspace-aware execution layer (host, chroot, or SSH).
5. The harness streams JSON events; Open Agent converts these into a unified
   event stream for the UI.

## Execution model (per-workspace)

Open Agent uses a workspace execution layer to spawn processes in the correct
execution context:

- **Host workspace**: process runs directly on the host with the mission working
  directory as `cwd`.
- **Chroot workspace**: process runs inside the container via `systemd-nspawn`.
- **Remote workspace**: process runs via SSH in the remote working directory.

This guarantees that built-in bash (OpenCode `bash` / Claude Code `Bash`) executes
**inside the workspace**. File creation, git operations, and shell commands land
in the correct workspace without a host-proxy tool.

## Harnesses

### OpenCode

- Runs **per workspace** using the CLI (via `oh-my-opencode run`).
- Spawns an embedded OpenCode server inside the workspace.
- Reads configuration from:
  - `opencode.json` at the workspace root
  - `.opencode/opencode.json`
  - `.opencode/oh-my-opencode.json` (synced from the Library)
- Built-in bash is **enabled** in per-workspace configs.

### Claude Code

- Runs **per workspace** using the Claude CLI.
- Configuration is written to each workspace:
  - `.claude/settings.local.json` (MCP servers + permissions)
  - `CLAUDE.md` (generated from Library skills)
- Built-in `Bash` is **enabled** in the permissions allowlist.

## Tool policy

- **Built-in bash is the default** for both OpenCode and Claude Code.
- Legacy MCP tool namespaces (`workspace_*`, `desktop_*`) are **disabled by
  default** in per-workspace OpenCode configs.
- Desktop/Playwright tools remain available as optional MCPs when needed.

If a mission truly requires MCP tools, re-enable them per workspace or per
backend in configuration. The default is to avoid host-proxy tooling.

## Configuration sources

Per-workspace config is generated from three sources:

1. **Library** (git-backed) for agents, skills, tools, rules, and MCP definitions.
2. **Backend Settings** (UI) for CLI paths or backend-specific overrides.
3. **Workspace Settings** for env vars and per-workspace overrides.

Files written per mission workspace:

- `opencode.json` and `.opencode/opencode.json`
- `.opencode/oh-my-opencode.json` (for OpenCode agents)
- `.claude/settings.local.json` (for Claude Code)
- `CLAUDE.md` (skill-based context)

## Observability

Open Agent streams structured tool events and text deltas from the harnesses.
The UI receives:

- tool calls/results
- thinking deltas
- final completion

This preserves the UI experience while keeping execution isolated per workspace.

## Operational notes

- Central OpenCode servers are **optional** for mission execution.
- Per-workspace execution eliminates host-to-container network issues.
- For remote workspaces, SSH execution keeps bash/tooling on the remote host.

## Quick validation

Recommended smoke tests after changes:

1. **Claude Code (isolated)**: create a file and verify it exists inside the
   container workspace directory.
2. **OpenCode (isolated)**: create a file and verify it exists inside the
   container workspace directory.
3. **Claude Code (host)**: create a file in the host workspace.
4. **OpenCode (host)**: create a file in the host workspace.

If files appear in the wrong place, the harness is not running inside the
workspace execution context.
