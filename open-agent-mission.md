Your job is to continue Open Agent, a simple dashboard to manage your agents. It has two responsibilities:

1. Starting missions on a remote machine (selecting an 'isolated' remote execution target called a workspace).

2. Syncing and managing a standardized configuration repository so my preferred local agents (e.g., Codex, Claude Code) as well as my remote agents (Open Code) all consume consistent, easy to synchronize configs. This is the 'Library'.

## Architecture

- One web dashboard (Next.js application), hosted on Vercel
- One iOS dashboard (with core features, allowing interaction and monitoring of missions)
- One backend hosted on a dedicated server running Ubuntu (which will create chroots & start Open Code instances)

## How it works

A user can define workspaces (chroots) with their own config (distro, shared folders), preinstalled MCPs, in a user-friendly way.

He can also define agents: a subset of MCP configurations, skills and commands from the library.

Then he can start a mission: an instance of an agent, running in a specified workspace, with potential hooks (like ralph-wiggum allowing it to keep running forever).

## Deliverables

### Web Dashboard (test each feature using Playwright)

**Library section (dedicated page per use case):**
- Upload, create and edit skills in the format supported by Open Code
- Upload, create and edit prompts (aka /commands for Open Code & Claude)
- Add, create and edit MCP server configurations, allowing different configurations for the same kind of MCP server

**Separate pages:**
- Agents page: create and edit agents where user can choose a model (between supported ones according to settings)
- Workspace page: create workspaces with simple configuration and defaults (Linux distro, share X display, pre-install software and MCPs, mount folders)
- Mission page (top nav): create new mission or load existing ones, switch between multiple, choose workspace (or create new) and agent and hooks
- Overview page: connected to actual data (total cost), hero component shows actual metrics (beautiful activity graphs similar to gotop UI with RAM usage, CPU usage, etc)

**Settings:**
- User can easily connect Claude Code, Codex & OpenRouter API keys to Open Code

### iOS Dashboard (test using iOS Simulator)
- Similar features to web dashboard
- Start a mission requiring desktop work, agent does it, view result in picture-in-picture
- Mission started on iOS shows status on web dashboard
- Mission started on web dashboard shows status on iOS

## Testing Requirements

Brainstorm many missions to try the agent with, launch them and see if they succeed or fail. Example missions to test:

1. 'Create a Python script that generates a PDF report'
2. 'Clone a GitHub repo and run its tests'
3. 'Open Firefox, navigate to a URL, take a screenshot'
4. 'Install and configure a Node.js project'
5. 'Use filesystem MCP to organize files in a directory'
6. 'Create a React component with unit tests'
7. 'Run a long data processing task' (test hooks)
8. 'Build and run a Docker container'
9. 'Create a GUI app and screenshot it' (test PiP on iOS)
10. 'Parallel missions' (test resource isolation)

If a mission fails for reasons due to the architecture that could be fixed elegantly, fix them. Document all test results in MISSION_TESTS.md.

## Completion Criteria

- [ ] Backend API functional with chroot management
- [ ] Web dashboard all pages implemented
- [ ] Playwright tests passing for all web features
- [ ] iOS app running in simulator
- [ ] Cross-platform sync working (iOS <-> Web)
- [ ] 10+ test missions executed and documented
- [ ] Architectural issues discovered during testing are fixed

When all criteria are met, output <promise>OPEN_AGENT_COMPLETE</promise>

If blocked after 100 iterations, document all blockers in BLOCKERS.md and output <promise>OPEN_AGENT_COMPLETE</promise> anyway.
" --max-iterations 150 --completion-promise "OPEN_AGENT_COMPLETE
