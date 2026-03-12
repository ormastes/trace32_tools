#!/usr/bin/env bash
# T32 MCP Tools Installer
# Downloads pre-built binaries from GitHub Releases
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ormastes/simple/main/examples/10_tooling/trace32_tools/install.sh | bash
#   curl -fsSL ... | bash -s -- --version 0.1.2 --dir ~/.local/bin
#
set -euo pipefail

REPO="ormastes/simple"
INSTALL_DIR="${HOME}/.local/bin"
VERSION="latest"
TOOLS="t32-mcp-server t32-lsp-mcp-server cmm-lsp t32-cli"

# ── Parse arguments ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) VERSION="$2"; shift 2 ;;
    --dir|-d)     INSTALL_DIR="$2"; shift 2 ;;
    --tools|-t)   TOOLS="$2"; shift 2 ;;
    --help|-h)
      echo "T32 MCP Tools Installer"
      echo ""
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --version, -v VERSION   Release version (default: latest)"
      echo "  --dir, -d DIR           Install directory (default: ~/.local/bin)"
      echo "  --tools, -t 'TOOLS'     Space-separated tool list"
      echo "  --help, -h              Show this help"
      echo ""
      echo "Available tools:"
      echo "  t32-mcp-server      TRACE32 debug session control (20 MCP tools)"
      echo "  t32-lsp-mcp-server  CMM language intelligence (6 MCP tools)"
      echo "  cmm-lsp             CMM Language Server (LSP over stdio)"
      echo "  t32-cli             Interactive TRACE32 CLI shell"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Detect platform ──────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  PLATFORM="linux" ;;
  Darwin) echo "Error: macOS builds not yet available. Build from source:"; echo "  https://github.com/ormastes/simple/tree/main/examples/10_tooling/trace32_tools"; exit 1 ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *)      echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH="x86_64" ;;
  *)            echo "Error: Unsupported architecture: $ARCH (only x86_64 supported)"; exit 1 ;;
esac

# ── Resolve version ──────────────────────────────────────────────────────
echo "T32 MCP Tools Installer"
echo "======================"
echo ""

if [ "$VERSION" = "latest" ]; then
  echo "Resolving latest release..."
  TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases" \
    | grep '"tag_name"' | grep 't32-v' | head -1 | sed 's/.*"t32-v\([^"]*\)".*/\1/')
  if [ -z "$TAG" ]; then
    echo "Error: No T32 tools release found. Check https://github.com/${REPO}/releases"
    exit 1
  fi
  VERSION="$TAG"
fi

RELEASE_TAG="t32-v${VERSION}"
RELEASE_URL="https://github.com/${REPO}/releases/download/${RELEASE_TAG}"

echo "Version:  ${VERSION}"
echo "Platform: ${PLATFORM}-${ARCH}"
echo "Install:  ${INSTALL_DIR}"
echo ""

# ── Create install directory ─────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

# ── Download and install ─────────────────────────────────────────────────
INSTALLED=0
FAILED=0

for tool in $TOOLS; do
  if [ "$PLATFORM" = "windows" ]; then
    BINARY="${tool}-${PLATFORM}-${ARCH}.exe"
    TARGET="${INSTALL_DIR}/${tool}.exe"
  else
    BINARY="${tool}-${PLATFORM}-${ARCH}"
    TARGET="${INSTALL_DIR}/${tool}"
  fi

  URL="${RELEASE_URL}/${BINARY}"
  echo -n "Downloading ${tool}... "

  if curl -fsSL -o "$TARGET" "$URL" 2>/dev/null; then
    chmod +x "$TARGET"
    echo "OK ($(wc -c < "$TARGET" | tr -d ' ') bytes)"
    INSTALLED=$((INSTALLED + 1))
  else
    echo "SKIP (not available for ${PLATFORM}-${ARCH})"
    rm -f "$TARGET"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "Installed: ${INSTALLED} tools"
if [ "$FAILED" -gt 0 ]; then
  echo "Skipped:   ${FAILED} tools"
fi

# ── Verify PATH ──────────────────────────────────────────────────────────
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  echo ""
  echo "Add to your shell profile:"
  echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
fi

# ── Print setup instructions ─────────────────────────────────────────────
echo ""
echo "Setup for Claude Code"
echo "---------------------"
echo "Current recommendation:"
echo "  Prefer the repo-backed Simple entrypoints for Claude/Codex MCP until"
echo "  a release has been verified with framed MCP handshake tests."
echo ""
echo "Add to your project's .mcp.json:"
echo ""
echo '{'
echo '  "mcpServers": {'
echo '    "t32-mcp": {'
echo "      \"command\": \"${INSTALL_DIR}/t32-mcp-server\""
echo '    },'
echo '    "t32-lsp-mcp": {'
echo "      \"command\": \"${INSTALL_DIR}/t32-lsp-mcp-server\""
echo '    }'
echo '  }'
echo '}'
echo ""
echo "If you have a Simple repo checkout available, this is the more reliable form:"
echo "  claude mcp add t32-mcp -- /path/to/simple/bin/release/simple /path/to/simple/examples/10_tooling/trace32_tools/t32_mcp/main.spl"
echo "  claude mcp add t32-lsp-mcp -- /path/to/simple/bin/release/simple /path/to/simple/examples/10_tooling/trace32_tools/t32_lsp_mcp/main.spl"
echo ""
echo "Verify:"
echo "  msg='{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"capabilities\":{}}}'"
echo "  printf 'Content-Length: %s\\r\\n\\r\\n%s' \"\${#msg}\" \"\$msg\" | t32-mcp-server"
echo "  printf 'Content-Length: %s\\r\\n\\r\\n%s' \"\${#msg}\" \"\$msg\" | t32-lsp-mcp-server"
echo ""
echo "Documentation: https://github.com/${REPO}/tree/main/examples/10_tooling/trace32_tools"
