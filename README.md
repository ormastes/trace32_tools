# trace32_tools

TRACE32 development tools — CMM Language Server, MCP servers, and interactive CLI shell.

Written in [Simple](https://github.com/ormastes/simple) — a self-hosted programming language.

## Tools Overview

| Tool | Directory | Description |
|------|-----------|-------------|
| CMM Language Server | `cmm_lsp/` | LSP for `.cmm` files — completions, hover, diagnostics, go-to-definition |
| T32 MCP Server | `t32_mcp/` | Direct TRACE32 control via MCP — session, window capture, actions |
| T32 LSP MCP Server | `t32_lsp_mcp/` | CMM language intelligence exposed as MCP tools — parse, diagnose, complete |
| T32 Interactive CLI | `t32_cli/` | Interactive TRACE32 shell with session management |

## Directory Structure

```
trace32_tools/
├── cmm_lsp/           # CMM Language Server (LSP over stdio)
├── t32_mcp/           # TRACE32 Control MCP Server
├── t32_lsp_mcp/       # CMM Intelligence MCP Server
├── t32_cli/           # Interactive T32 CLI Shell
├── config/            # T32 configuration & catalogs
│   └── catalogs/      # Action, field, window definitions (SDN)
├── test_fixtures/     # CMM script test corpus
│   ├── riscv/         # RISC-V platform scripts
│   ├── stm32/         # STM32 platform scripts (real hardware)
│   ├── web/           # Various SoC platform scripts
│   └── expected_cli/  # CLI-mode conversions (batch-friendly)
└── doc/               # Documentation
```

## Requirements

- Simple compiler (`bin/release/simple` from [ormastes/simple](https://github.com/ormastes/simple))
- For T32 MCP/CLI: Lauterbach TRACE32 installation (tested with Power Debug II + STM32H7/WB)

## Quick Start

```bash
# CMM LSP Server (for IDE integration)
bin/release/simple run cmm_lsp/lsp_server.spl

# T32 MCP Server (for Claude Code / AI tools)
bin/release/simple run t32_mcp/main.spl

# T32 LSP MCP Server (CMM intelligence via MCP)
bin/release/simple run t32_lsp_mcp/main.spl

# T32 Interactive CLI
bin/release/simple run t32_cli/mod.spl
```

## Test Fixtures

The `test_fixtures/` directory contains 29 CMM scripts across three platform families:

- **RISC-V** (8 scripts) — BL602, CH32V307, ESP32-C3, SiFive E31, and others
- **STM32** (6 scripts) — Real hardware scripts for STM32H7 and STM32WB targets
- **Web/SoC** (15 scripts) — EDK2/UEFI, i.MX6, PolarFire, R-Car3, QNX, and others

An additional 18 CLI batch-mode conversions are provided under `test_fixtures/expected_cli/`. These conversions include `SCREEN.OFF`, AREA channel setup, `ON ERROR` handlers, structured text output, and metadata headers for headless/CI execution.

## CMM LSP Features

The CMM Language Server implements LSP over stdio with Content-Length framing (JSON-RPC 2.0):

- **Completions** — 100+ TRACE32 commands, 50+ PRACTICE functions, macro names, with `.`, `&`, `/` triggers
- **Hover** — Command and function documentation with syntax descriptions
- **Go to definition** — Jump to label and macro definitions
- **Document symbols** — Labels and macros as outline symbols
- **Diagnostics** — Parse errors, undefined labels/macros, unreachable code, unused macros

See `cmm_lsp/README.md` for IDE installation instructions.

## T32 MCP Tools

The T32 MCP Server exposes 20 tools over MCP (protocol version 2025-06-18, Content-Length framing with JSON-Lines auto-detect):

**Session management:**
- `t32_sessions_list` — List all open TRACE32 sessions
- `t32_session_open` — Open a new debug session
- `t32_session_resume` — Resume an existing session
- `t32_session_close` — Close a session

**Core control:**
- `t32_core_list` — List available cores in a session
- `t32_core_select` — Select active core

**Command execution:**
- `t32_cmd_run` — Execute a TRACE32 command
- `t32_cmm_run` — Run a CMM script
- `t32_eval` — Evaluate a PRACTICE expression

**Window management:**
- `t32_window_list` — List open windows
- `t32_window_open` — Open a window
- `t32_window_capture` — Capture window content as text
- `t32_window_describe` — Describe window layout and fields
- `t32_screenshot` — Take a screenshot

**Actions and fields:**
- `t32_action_invoke` — Invoke a named action from the catalog
- `t32_field_get` — Read a field value
- `t32_field_set` — Write a field value

**History and resources:**
- `t32_history_tail` — Get recent command history
- `t32_resources_list` — List available resources
- `t32_resource_read` — Read a resource

## T32 LSP MCP Tools

The T32 LSP MCP Server exposes CMM language intelligence as 6 MCP tools:

- `cmm_parse` — Parse a CMM script and return the AST
- `cmm_diagnostics` — Run diagnostics on a CMM script (errors, warnings)
- `cmm_complete` — Get completions at a given position
- `cmm_hover` — Get hover information at a given position
- `cmm_symbols` — Extract document symbols (labels, macros)
- `cmm_validate_cli` — Validate a CLI-mode converted script

## License

Part of the [Simple](https://github.com/ormastes/simple) project.
