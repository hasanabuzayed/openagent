# Open Agent

A minimal autonomous coding agent with full machine access, implemented in Rust.

## Features

- **HTTP API** for task submission and monitoring
- **OpenCode backend** for task execution via Claude Max subscription
- **Full toolset**: Desktop automation, browser control, file operations
- **SSE streaming** for real-time task progress
- **Provider system** for model selection

## Quick Start

### Prerequisites

- Rust 1.70+ (install via [rustup](https://rustup.rs/))
- An [OpenCode](https://github.com/opencode-ai/opencode) server running locally
- Claude Max subscription (for Claude model access)

### Installation

```bash
git clone <repo-url>
cd open_agent
cargo build --release
```

### Running

```bash
# Optional: configure OpenCode server (defaults shown)
export OPENCODE_BASE_URL="http://127.0.0.1:4096"
export OPENCODE_AGENT="build"
export OPENCODE_PERMISSIVE="true"

# Start the server
cargo run --release
```

The server starts on `http://127.0.0.1:3000` by default.

## Architecture

Open Agent delegates all task execution to an OpenCode server, which handles LLM interactions via your Claude Max subscription.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Dashboard     │────▶│   Open Agent    │────▶│   OpenCode      │
│   (Next.js)     │     │   API (Rust)    │     │   Server        │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │   Anthropic API │
                                                │   (Claude Max)  │
                                                └─────────────────┘
```

### Module Map

```
src/
├── agents/           # Agent system
│   └── opencode.rs   # OpenCodeAgent (delegates to OpenCode server)
├── api/              # HTTP routes (axum)
│   ├── control.rs    # Mission control endpoints
│   ├── providers.rs  # Provider/model listing
│   └── routes.rs     # Route definitions
├── budget/           # Cost tracking, pricing
├── memory/           # Supabase + pgvector persistence
├── opencode/         # OpenCode client
├── tools/            # Desktop MCP tools
└── task/             # Task types + verification
```

## API Reference

### Submit a Task

```bash
curl -X POST http://localhost:3000/api/task \
  -H "Content-Type: application/json" \
  -d '{"task": "Create a Python script that prints Hello World"}'
```

Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "pending"
}
```

### Get Task Status

```bash
curl http://localhost:3000/api/task/{id}
```

### Stream Task Progress (SSE)

```bash
curl http://localhost:3000/api/task/{id}/stream
```

Events:
- `log` - Execution log entries (tool calls, results)
- `done` - Task completion with final status

### List Providers

```bash
curl http://localhost:3000/api/providers
```

Returns available providers and their models for the frontend model selector.

### Health Check

```bash
curl http://localhost:3000/api/health
```

## Available Models

Models are accessed via your Claude Max subscription:

| Model | Description |
|-------|-------------|
| `claude-opus-4-5-20251101` | Most capable, recommended for complex tasks |
| `claude-sonnet-4-20250514` | Good balance of speed and capability (default) |
| `claude-3-5-haiku-20241022` | Fastest, most economical |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_BASE_URL` | `http://127.0.0.1:4096` | OpenCode server URL |
| `OPENCODE_AGENT` | - | OpenCode agent name (build/plan/etc) |
| `OPENCODE_PERMISSIVE` | `true` | Auto-allow OpenCode permissions |
| `DEFAULT_MODEL` | `claude-sonnet-4-20250514` | Default LLM model |
| `WORKING_DIR` | `.` (dev) / `/root` (prod) | Working directory |
| `HOST` | `127.0.0.1` | Server bind address |
| `PORT` | `3000` | Server port |

### Production Auth

| Variable | Description |
|----------|-------------|
| `DEV_MODE` | `true` bypasses auth |
| `DASHBOARD_PASSWORD` | Password for dashboard login |
| `JWT_SECRET` | HMAC secret for JWT signing |

### Optional Services

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL (for memory) |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key |
| `OPENROUTER_API_KEY` | Only needed for memory embeddings |

## Desktop Automation (MCP)

Open Agent provides desktop automation tools via MCP (Model Context Protocol):

```json
// opencode.json
{
  "mcp": {
    "desktop": {
      "type": "local",
      "command": ["./target/release/desktop-mcp"],
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": ["npx", "@playwright/mcp@latest"],
      "enabled": true
    }
  }
}
```

Build the desktop MCP server:
```bash
cargo build --release --bin desktop-mcp
```

## Development

```bash
# Run with debug logging
RUST_LOG=debug cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Check for issues
cargo clippy
```

## Dashboard (Bun)

The dashboard lives in `dashboard/` and uses **Bun** as the package manager.

```bash
cd dashboard
bun install
PORT=3001 bun dev
```

## License

MIT
