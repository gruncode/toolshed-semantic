#!/bin/bash
# toolshed installer — copies scripts to ~/.local/bin/ and sets up config
set -eu

INSTALL_DIR="${1:-${HOME}/.local/bin}"
CONFIG_DIR="${HOME}/.config/toolshed"
DATA_DIR="${HOME}/.local/share/toolshed"

echo "toolshed installer"
echo "─────────────────────────"
echo "  scripts → $INSTALL_DIR"
echo "  config  → $CONFIG_DIR"
echo "  data    → $DATA_DIR"
echo

# Check dependencies
missing=()
command -v fzf    >/dev/null 2>&1 || missing+=("fzf (required — fuzzy picker)")
command -v python3 >/dev/null 2>&1 || missing+=("python3 (required for MCP scanning and discover)")
if command -v batcat >/dev/null 2>&1 || command -v bat >/dev/null 2>&1; then
  : # ok
else
  missing+=("bat/batcat (recommended — syntax-highlighted preview)")
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo "Missing dependencies:"
  for m in "${missing[@]}"; do
    echo "  - $m"
  done
  echo
  echo "Install on Debian/Ubuntu: sudo apt install fzf bat python3"
  echo "Install on macOS:         brew install fzf bat python3"
  echo "Install on Fedora:        sudo dnf install fzf bat python3"
  echo
  read -rp "Continue anyway? [y/N] " ans
  case "${ans,,}" in
    y|yes) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# Create directories
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$DATA_DIR"

# Copy scripts
SCRIPT_DIR="$(cd "$(dirname "$0")/bin" && pwd)"
for script in toolshed toolshed-index toolshed-discover toolshed-preview toolshed-edit toolshed-yank toolshed-view; do
  if [ -f "$SCRIPT_DIR/$script" ]; then
    cp "$SCRIPT_DIR/$script" "$INSTALL_DIR/$script"
    chmod 755 "$INSTALL_DIR/$script"
    echo "  installed: $INSTALL_DIR/$script"
  else
    echo "  warning: $SCRIPT_DIR/$script not found"
  fi
done

# Create default config if not exists
if [ ! -f "$CONFIG_DIR/config" ]; then
  cp "$(dirname "$0")/config.example" "$CONFIG_DIR/config"
  echo "  created:   $CONFIG_DIR/config"
else
  echo "  exists:    $CONFIG_DIR/config (not overwritten)"
fi

echo
echo "Done! Next steps:"
echo
echo "  1. Make sure $INSTALL_DIR is in your PATH:"
echo "     export PATH=\"$INSTALL_DIR:\$PATH\""
echo
echo "  2. Edit your config:"
echo "     \$EDITOR $CONFIG_DIR/config"
echo
echo "  3. Build the catalog:"
echo "     toolshed-index"
echo
echo "  4. Browse your tools:"
echo "     toolshed"
echo
echo "Optional — enable semantic search:"
echo "  pip install cohere numpy"
echo "  export COHERE_API_KEY=\"your-key\"  # free at dashboard.cohere.com"
echo "  toolshed-index                     # rebuilds with embeddings"
echo "  toolshed --ask \"find files\"        # natural-language search"
