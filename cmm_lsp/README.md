# cmm-lsp

CMM (TRACE32 PRACTICE) language server for Claude Code, providing code intelligence for `.cmm` scripts used in Lauterbach TRACE32 debugger environments.

## Supported Extensions
`.cmm`

## Features

- **Completions** — TRACE32 commands (100+), PRACTICE functions (50+), macro names, with `.`, `&`, `/` triggers
- **Hover** — command and function documentation with syntax descriptions
- **Go to definition** — jump to label and macro definitions
- **Document symbols** — labels and macros as outline symbols
- **Diagnostics** — parse errors, undefined labels/macros, unreachable code, unused macros, duplicate dialog labels

## Installation

### Prerequisites
The Simple compiler binary (`bin/release/simple`) must be built first:

```bash
cd /path/to/simple
cargo build --profile bootstrap -p simple-driver --manifest-path src/compiler_rust/Cargo.toml
bin/simple build --release
```

### Install plugin
The Claude Code plugin is a bundle/package, not a separate executable.
It wraps the checked-in `cmm-lsp` entrypoint and lives in the TRACE32 tools
submodule.

Current Claude Code CLI builds install plugins from marketplaces, not from a
local `--dir` path. Use the checked-in marketplace:

```bash
claude plugin marketplace add tools/claude-plugin/marketplace
claude plugin install cmm-lsp@simple-local
```

Release asset:

```text
cmm-lsp-claude-plugin-0.1.2.tar.gz
```

Current limitation:
- the release tarball is not self-contained
- as of March 12, 2026, the latest published T32 release does not include the plugin tarball yet
- the checked-in `.lsp.json` still expects a repo checkout containing `bin/release/simple` and this `cmm_lsp/` source tree

The bundled `.lsp.json` already points at the checked-in CMM LSP entrypoint via
the workspace-relative path `examples/10_tooling/trace32_tools/cmm_lsp/mod.spl --lsp`.
The actual executable/runtime remains `bin/release/simple`.

### Verify
Restart Claude Code and open a `.cmm` file. Hover and completion should work automatically.

## Architecture

The LSP server runs as a subprocess launched by Claude Code:
- **Protocol:** JSON-RPC 2.0 over stdio with Content-Length framing
- **In-process parsing:** CMM lexer, parser, and analyzer run in-process — no subprocesses
- **Command database:** 100+ TRACE32 commands with categories and documentation
- **Function database:** 50+ PRACTICE built-in functions with signatures

## Dialog Analysis

The parser and analyzer understand dialog modifiers and widget metadata more completely now:
- `DIALOG (&+)`, `DIALOG (&-)`, and related modifiers are preserved in the parsed dialog block
- unlabeled `EDIT`, `CHECKBOX`, `CHOOSEBOX`, `PULLDOWN`, `BUTTON`, and `DEFBUTTON` items are still surfaced to tooling
- duplicate explicit dialog labels produce analyzer warnings

This metadata is shared with the T32 MCP dialog tools so parse-time capabilities and runtime validation stay aligned.

## Common CMM Mistakes & Gotchas

The LSP server detects many of these as diagnostics.

### Lexer Ambiguities

| Pattern | Trap | Correct Interpretation |
|---------|------|----------------------|
| `&name` vs `&0xFF` | `&` is both macro ref AND bitwise AND | `&` + letter = macro; `&` + digit = AND + hex literal |
| `*` wildcard vs multiply | `&a*&b` is multiply; `Data.LOAD.auto *` is wildcard | Trailing `*` (before `)`, `,`, EOL) = wildcard |
| `/Word` vs `path/file` | `/` is both option flag AND path separator | After tilde/string context = path; after command = option |
| `%val%100` vs `%LE` | `%` is both modulo AND format specifier | `%` + uppercase word = format spec; `%` + value = modulo |
| `\` continuation vs address | `"text"+\` joins lines; `main\34` is module\line | After `+` in string context = continuation |

### Statement-Level Gotchas

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| `&cmd` on its own line | Executes macro value as command (not assignment!) | Use `&cmd="value"` for assignment |
| `ON ERROR` without action | Clears the error handler (not an error!) | Add `GOTO`/`GOSUB` if you want a handler |
| Empty args in comma list | `cmd 1,,,4` is valid (3 empty args) | Intentional in PRACTICE — each `,` is a separator |
| `ENTRY &x %LINE &y` | `%LINE` can appear between params | Valid syntax — reads rest of line into `&y` |
| Missing `ENDDO` | Script runs past intended end | Always end scripts with `ENDDO` |
| `GOTO` without target | Clears GOTO target (not an error) | Add label: `GOTO mylabel` |

### Numeric Literal Traps

| Literal | Value | Trap |
|---------|-------|------|
| `100` | Depends on radix! | Plain numbers follow current `RADIX` setting (default decimal) |
| `100.` | Always decimal | Trailing dot forces decimal interpretation |
| `0xFF00` | Hex | Always hex regardless of radix |
| `0y10110` | Binary (22) | `0y` prefix for binary (not `0b`!) |
| `0xFFXX` | Hex mask | `X` = don't-care nibble (for address matching) |
| `10s` | 10 seconds | Time literal (also: `ms`, `us`, `ns`) |

### Expression Gotchas

| Mistake | Fix |
|---------|-----|
| Wrong operator precedence (13 levels!) | Use parentheses to be explicit |
| Using `&&` for AND | Use `&&` (logical AND) or `&` (bitwise AND) — both valid but different |
| Classic `:A:` `:O:` `:X:` operators | Still valid in real files — means AND/OR/XOR respectively |
| `{D:0x1000}` looks like a block | It's a braced constant (freezes address value) |
| Access class `D:0x1000` vs label `label:` | Colon after known access class (D, P, C, etc.) = access; after unknown word = label |

### Macro Pitfalls

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| Using undefined macro | Silent empty string substitution | Check with `SYMBOL.EXIST.MACRO()` |
| `&x` vs `&&x` | `&x` is value; `&&x` is address/reference | Use `&&` when passing by reference to subroutine |
| Macro in string `"&name"` | Gets substituted! | Use `CONV.CHAR()` to prevent, or single quotes if supported |
| No typed variables | All macros are text substitution | Cast explicitly: `VAR.VALUE(&x)` for numeric context |

### Common Command Mistakes

| Mistake | Fix |
|---------|-----|
| `Data.Set` without access class | Specify: `Data.Set D:0x1000 %Long 0xFF` |
| `Break.Set` on wrong address type | Use `P:` for program addresses: `Break.Set P:main` |
| Forgetting `WAIT` after async commands | Add `WAIT 1s` or poll with `STATE.RUN()` |
| Path without quotes when it has spaces | Quote paths: `Data.LOAD.auto "my file.elf"` |

## More Information
- [TRACE32 Documentation](https://www.lauterbach.com/frames.html?home.html)
- [LSP Specification](https://microsoft.github.io/language-server-protocol/)
