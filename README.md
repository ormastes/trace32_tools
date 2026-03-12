# TRACE32 MCP Tools

MCP servers and development tools for [Lauterbach TRACE32](https://www.lauterbach.com/en/) hardware debuggers. Enables AI assistants (Claude, Copilot, etc.) to control debug sessions, analyze CMM scripts, and interact with embedded targets.

**Protocol:** [MCP 2025-06-18](https://modelcontextprotocol.io/) (JSON-RPC 2.0, stdio transport)

## Install

### Pre-built binaries

```bash
# One-line install (Linux x86_64)
curl -fsSL https://raw.githubusercontent.com/ormastes/simple/main/examples/10_tooling/trace32_tools/install.sh | bash
```

Or download from [GitHub Releases](https://github.com/ormastes/simple/releases?q=t32-v):

| Asset | Platform | Description |
|-------|----------|-------------|
| `t32-mcp-server` | Linux, Windows | TRACE32 debug session control — 20 MCP tools |
| `t32-lsp-mcp-server` | Linux, Windows | CMM language intelligence — 6 MCP tools |
| `cmm-lsp` | Linux, Windows | CMM Language Server executable (LSP over stdio) |
| `cmm-lsp-claude-plugin-${VERSION}.tar.gz` | Any | Claude Code plugin bundle data for marketplace-based installs from a repo checkout |
| `t32-cli` | Linux, Windows | Interactive TRACE32 CLI shell |

As of March 13, 2026:
- the latest intended T32 release is `t32-v0.1.2`
- the repo source is aligned to `0.1.2`
- release binaries should be verified with the smoke tests and a local MCP handshake after publish

Use the published binaries for experimentation, but prefer the source-backed
`bin/release/simple .../main.spl` commands below until `t32-v0.1.2` is
published and re-verified.

### Manual download

```bash
# Download specific binary
VERSION="0.1.2"
curl -fsSL -o t32-mcp-server \
  "https://github.com/ormastes/simple/releases/download/t32-v${VERSION}/t32-mcp-server-linux-x86_64"
chmod +x t32-mcp-server
```

```bash
# Download Claude Code plugin bundle data
VERSION="0.1.2"
curl -fsSL -O \
  "https://github.com/ormastes/simple/releases/download/t32-v${VERSION}/cmm-lsp-claude-plugin-${VERSION}.tar.gz"
tar -xzf "cmm-lsp-claude-plugin-${VERSION}.tar.gz"
```

The plugin tarball is config/package data, not a standalone runtime. It still
assumes a source checkout with:
- `bin/release/simple`
- `examples/10_tooling/trace32_tools/cmm_lsp/mod.spl`

As of March 13, 2026:
- that tarball is configured in repo and release workflow source
- it is expected in `t32-v0.1.2`
- current Claude Code CLI builds expect marketplace-based plugin installs, not `claude plugin install --dir`

### Build from source

Requires the [Simple](https://github.com/ormastes/simple) compiler:

```bash
git clone https://github.com/ormastes/simple.git
cd simple
# Build the compiler first (see main README)
bin/release/simple native-build \
  --source src --entry examples/10_tooling/trace32_tools/t32_mcp/main.spl \
  -o t32-mcp-server
```

---

## Setup

### Claude Code

Recommended local install from a repo checkout:

```bash
claude mcp add t32-mcp -- \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_mcp/main.spl

claude mcp add t32-lsp-mcp -- \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_lsp_mcp/main.spl
```

For the CMM LSP Claude plugin itself, use the checked-in marketplace:

```bash
claude plugin marketplace add tools/claude-plugin/marketplace
claude plugin install cmm-lsp@simple-local
```

For the Simple language plugin:

```bash
claude plugin marketplace add tools/claude-plugin/marketplace
claude plugin install simple-lsp@simple-local
```

Project `.mcp.json` is also valid:

```json
{
  "mcpServers": {
    "t32-mcp": {
      "command": "t32-mcp-server"
    },
    "t32-lsp-mcp": {
      "command": "t32-lsp-mcp-server"
    }
  }
}
```

> If a future standalone binary is in PATH, you can use `t32-mcp-server` and
> `t32-lsp-mcp-server` directly. Re-verify the published `t32-v0.1.2` Linux
> binaries with a local MCP handshake before relying on them in Claude Code.

### Claude Desktop

Add to `~/.config/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "t32-mcp": {
      "command": "/path/to/t32-mcp-server"
    },
    "t32-lsp-mcp": {
      "command": "/path/to/t32-lsp-mcp-server"
    }
  }
}
```

### Verify

```bash
# Check the server responds to MCP initialize
msg='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}'
printf 'Content-Length: %s\r\n\r\n%s' "${#msg}" "$msg" | \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_mcp/main.spl

# List available tools
msg='{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
printf 'Content-Length: %s\r\n\r\n%s' "${#msg}" "$msg" | \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_mcp/main.spl
```

---

## Tools

### T32 MCP Server (20 tools)

Controls live TRACE32 debug sessions. Requires a running TRACE32 PowerView instance.

| Category | Tools | Description |
|----------|-------|-------------|
| **Session** | `t32_sessions_list`, `t32_session_open`, `t32_session_resume`, `t32_session_close` | Connect to TRACE32 PowerView instances |
| **Core** | `t32_core_list`, `t32_core_select` | Multi-core target management |
| **Command** | `t32_cmd_run`, `t32_cmm_run`, `t32_eval` | Execute PRACTICE commands and scripts |
| **Window** | `t32_window_list`, `t32_window_open`, `t32_window_capture`, `t32_window_describe`, `t32_screenshot` | Capture register views, memory dumps, source listings |
| **Action** | `t32_action_invoke`, `t32_field_get`, `t32_field_set` | Named actions from SDN catalogs |
| **History** | `t32_history_tail`, `t32_resources_list`, `t32_resource_read` | Command history and MCP resources |

**Example workflow:**

```
1. t32_session_open(host: "localhost", port: "20000")
2. t32_cmd_run(command: "SYStem.Up")
3. t32_window_capture(window: "register_view")
4. t32_cmd_run(command: "Break.Set main")
5. t32_cmd_run(command: "Go")
6. t32_window_capture(window: "var_local")
```

### T32 LSP MCP Server (6 tools)

CMM (PRACTICE) script analysis. Standalone — no TRACE32 hardware needed.

| Tool | Description |
|------|-------------|
| `cmm_parse` | Parse CMM script, return AST summary |
| `cmm_diagnostics` | Errors, warnings, unused macros, unreachable code |
| `cmm_complete` | Auto-complete commands and PRACTICE functions |
| `cmm_hover` | Command/function documentation |
| `cmm_symbols` | Document symbols (labels, macros) |
| `cmm_validate_cli` | Validate CLI-mode converted scripts |

### CMM Language Server (LSP)

Full LSP implementation for `.cmm` files, for IDE integration:

- **Completions** — 100+ TRACE32 commands, 50+ PRACTICE functions, macro names
- **Hover** — Command documentation with syntax descriptions
- **Go to definition** — Jump to label and macro definitions
- **Document symbols** — Labels and macros as outline
- **Diagnostics** — Parse errors, undefined labels, unreachable code, unused macros

The release path currently has two different CMM LSP assets:
- `cmm-lsp` — the standalone executable
- `cmm-lsp-claude-plugin-${VERSION}.tar.gz` — the Claude Code plugin bundle (`.claude-plugin/` + `.lsp.json`) for repo-checkout marketplace installs

See [`cmm_lsp/README.md`](cmm_lsp/README.md) for IDE-specific setup.

### T32 Interactive CLI

Interactive shell for TRACE32 session management with SDN catalog support.

---

## Prompt Examples

Once the T32 MCP servers and CMM LSP plugin are installed, try these prompts in Claude Code:

### T32 MCP (live debug sessions)

```
> "Connect to TRACE32 on localhost:20000 and show the system state"

> "Set a breakpoint at main, run the target, and capture the register view"

> "Read 256 bytes of memory starting at 0x20000000"

> "Load my_firmware.elf onto the target and run to main"

> "List all active TRACE32 sessions and their core states"

> "Run this PRACTICE script: config/t32/stm32h7_gdb_start.cmm"

> "Capture a screenshot of the current TRACE32 PowerView window"

> "Show the local variables at the current breakpoint"
```

### T32 LSP MCP (CMM script analysis — no hardware)

```
> "Parse test_fixtures/stm32/stm32h7_gdb_setup.cmm and show the AST summary"

> "Check this CMM script for errors, unused macros, and unreachable code"

> "What completions are available after 'Data.LOAD.' in a CMM script?"

> "Show me the documentation for the Break.Set command"

> "List all symbols (labels and macros) in my CMM script"

> "Validate the CLI-mode conversion of this PRACTICE script"
```

### CMM LSP Plugin (IDE features for .cmm files)

```
> "Open config/t32/stm32h7_gdb_start.cmm — hover over Break.Set to see docs"

> "Go to the definition of the macro &settings in my CMM script"

> "What diagnostics does the CMM LSP report for this file?"

> "Auto-complete PRACTICE functions starting with 'STATE.'"
```

### Full Setup (All T32 Tools)

```bash
cd /path/to/simple

# 1. T32 MCP — live debug session control (20 tools)
claude mcp add t32-mcp -- \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_mcp/main.spl

# 2. T32 LSP MCP — CMM analysis (6 tools)
claude mcp add t32-lsp-mcp -- \
  /absolute/path/to/simple/bin/release/simple \
  /absolute/path/to/simple/examples/10_tooling/trace32_tools/t32_lsp_mcp/main.spl

# 3. CMM LSP plugin — IDE features for .cmm files
claude plugin marketplace add tools/claude-plugin/marketplace
claude plugin install cmm-lsp@simple-local
```

**Binary full paths:**
- T32 MCP: `bin/release/simple examples/10_tooling/trace32_tools/t32_mcp/main.spl`
- T32 LSP MCP: `bin/release/simple examples/10_tooling/trace32_tools/t32_lsp_mcp/main.spl`
- CMM LSP: `bin/release/simple examples/10_tooling/trace32_tools/cmm_lsp/mod.spl --lsp`

---

## Requirements

| Tool | TRACE32 Required | Notes |
|------|:---:|-------|
| t32-mcp-server | Yes | Needs running PowerView instance with Remote API enabled |
| t32-lsp-mcp-server | No | Pure CMM analysis, no hardware needed |
| cmm-lsp | No | Pure CMM analysis |
| t32-cli | Yes | Interactive session management |

**TRACE32 setup:** Enable the Remote API in PowerView: `RCL.Port 20000` or set `RCL=NETASSIST` in your `config.t32`.

---

## Directory Structure

```
trace32_tools/
├── cmm_lsp/           # CMM Language Server (LSP over stdio)
├── t32_mcp/           # TRACE32 Control MCP Server
├── t32_lsp_mcp/       # CMM Intelligence MCP Server
├── t32_cli/           # Interactive T32 CLI Shell
├── config/            # T32 configuration & catalogs
│   └── catalogs/      # Action, field, window definitions (SDN)
├── test_fixtures/     # CMM script test corpus (29 scripts)
│   ├── riscv/         # RISC-V platform scripts
│   ├── stm32/         # STM32 platform scripts (real hardware)
│   ├── web/           # Various SoC platform scripts
│   └── expected_cli/  # CLI-mode conversions (batch-friendly)
├── install.sh         # One-line installer
└── README.md          # This file
```

## Test Fixtures

29 CMM scripts across three platform families:

- **RISC-V** (8 scripts) — BL602, CH32V307, ESP32-C3, SiFive E31
- **STM32** (6 scripts) — Real hardware scripts for STM32H7 and STM32WB
- **Web/SoC** (15 scripts) — EDK2/UEFI, i.MX6, PolarFire, R-Car3, QNX

Plus 18 CLI batch-mode conversions under `test_fixtures/expected_cli/`.

---

## CI/CD

Binaries are built automatically on every push to `main` that touches `trace32_tools/`:

- **Build workflow:** [`.github/workflows/t32-tools-build.yml`](../../.github/workflows/t32-tools-build.yml) — builds + smoke tests
- **Release workflow:** [`.github/workflows/t32-tools-release.yml`](../../.github/workflows/t32-tools-release.yml) — publishes to GitHub Releases on `t32-v*` tags

Platforms: Linux x86_64 (primary), Windows MinGW x86_64 (cross-compiled).

---

## License

Part of the [Simple](https://github.com/ormastes/simple) project.
