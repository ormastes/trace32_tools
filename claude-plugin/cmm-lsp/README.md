# cmm-lsp Claude Plugin

Claude Code plugin bundle for the TRACE32 PRACTICE/CMM language server.
This is not a separate binary. The executable is `cmm-lsp` or the checked-in
Simple runtime path that the plugin launches.

## Install

Current Claude Code CLI builds install plugins from marketplaces, not from a
local `--dir` path. Use the checked-in marketplace:

```bash
claude plugin marketplace add tools/claude-plugin/marketplace
claude plugin install cmm-lsp@simple-local
```

Release package:

```text
cmm-lsp-claude-plugin-0.9.2.tar.gz
```

Current limitation:
- the checked-in bundle is intended for use from a repo checkout
- the release tarball is not published in the latest public T32 release as of March 12, 2026
- the checked-in `.lsp.json` still launches the workspace-relative Simple source entrypoint

## Runtime

The checked-in plugin launches:

```bash
bin/release/simple examples/10_tooling/trace32_tools/cmm_lsp/mod.spl --lsp
```

from the workspace root.

## Common CMM Mistakes

See the full [CMM LSP README](../../cmm_lsp/README.md#common-cmm-mistakes--gotchas) for a comprehensive list. Key traps:

- **`&` overloading** — `&name` is macro ref; `&0xFF` is bitwise AND + hex
- **Plain numbers are radix-dependent** — `100` may be hex! Use `100.` for decimal or `0x64` for hex
- **`0y` for binary** — not `0b` like other languages
- **Missing `ENDDO`** — script runs past intended end
- **Macros are text substitution** — `&x` in strings gets substituted; no typed variables
- **`ON ERROR` alone clears handler** — not an error, intentional syntax
- **13-level operator precedence** — use parentheses to be safe

## Files

- `.claude-plugin/plugin.json` — plugin metadata
- `.lsp.json` — CMM file extension mapping and launch command
