# cmm-lsp

CMM (TRACE32 PRACTICE) language server for Claude Code, providing code intelligence for `.cmm` scripts used in Lauterbach TRACE32 debugger environments.

## Supported Extensions
`.cmm`

## Features

- **Completions** — TRACE32 commands (100+), PRACTICE functions (50+), macro names, with `.`, `&`, `/` triggers
- **Hover** — command and function documentation with syntax descriptions
- **Go to definition** — jump to label and macro definitions
- **Document symbols** — labels and macros as outline symbols
- **Diagnostics** — parse errors, undefined labels/macros, unreachable code, unused macros

## Installation

### Prerequisites
The Simple compiler binary (`bin/release/simple`) must be built first:

```bash
cd /path/to/simple
cargo build --profile bootstrap -p simple-driver --manifest-path src/compiler_rust/Cargo.toml
bin/simple build --release
```

### Install plugin
Copy the plugin to the Claude Code plugins cache:

```bash
mkdir -p ~/.claude/plugins/cache/cmm-lsp/cmm-lsp/local
cp -r tools/claude-plugin/cmm-lsp/.claude-plugin ~/.claude/plugins/cache/cmm-lsp/cmm-lsp/local/
cp tools/claude-plugin/cmm-lsp/README.md ~/.claude/plugins/cache/cmm-lsp/cmm-lsp/local/
```

Then create `~/.claude/plugins/cache/cmm-lsp/cmm-lsp/local/.lsp.json` with absolute paths:

```json
{
  "cmm": {
    "command": "/absolute/path/to/simple/bin/release/simple",
    "args": ["run", "/absolute/path/to/simple/examples/10_tooling/cmm_lsp/lsp_server.spl"],
    "extensionToLanguage": {
      ".cmm": "cmm"
    },
    "startupTimeout": 30000
  }
}
```

### Verify
Restart Claude Code and open a `.cmm` file. Hover and completion should work automatically.

## Architecture

The LSP server runs as a subprocess launched by Claude Code:
- **Protocol:** JSON-RPC 2.0 over stdio with Content-Length framing
- **In-process parsing:** CMM lexer, parser, and analyzer run in-process — no subprocesses
- **Command database:** 100+ TRACE32 commands with categories and documentation
- **Function database:** 50+ PRACTICE built-in functions with signatures

## More Information
- [TRACE32 Documentation](https://www.lauterbach.com/frames.html?home.html)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
