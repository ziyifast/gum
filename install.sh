#!/usr/bin/env bash
#
# gum installer - Git User Manager
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

GUM_INSTALL_DIR="${GUM_INSTALL_DIR:-$HOME/.gum}"
GUM_BIN_DIR="$GUM_INSTALL_DIR/bin"

echo ""
echo -e "${BOLD}${PURPLE}  Installing gum (Git User Manager)...${NC}"
echo -e "${DIM}  ─────────────────────────────────────────${NC}"
echo ""

# Create directories
mkdir -p "$GUM_INSTALL_DIR/profiles"
mkdir -p "$GUM_BIN_DIR"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy main script
cp "$SCRIPT_DIR/gum.sh" "$GUM_BIN_DIR/gum"
chmod +x "$GUM_BIN_DIR/gum"

echo -e "  ${GREEN}✓${NC} Installed gum to ${GUM_BIN_DIR}/gum"

# Detect shell and config file
SHELL_NAME=$(basename "$SHELL")
SHELL_CONFIG=""

case "$SHELL_NAME" in
    zsh)
        SHELL_CONFIG="$HOME/.zshrc"
        ;;
    bash)
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    *)
        SHELL_CONFIG="$HOME/.profile"
        ;;
esac

# Add to PATH if not already there
PATH_EXPORT="export PATH=\"\$HOME/.gum/bin:\$PATH\""
GUM_MARKER="# gum (Git User Manager)"

if [[ -f "$SHELL_CONFIG" ]] && grep -q "$GUM_MARKER" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "  ${DIM}PATH already configured in ${SHELL_CONFIG}${NC}"
else
    echo "" >> "$SHELL_CONFIG"
    echo "$GUM_MARKER" >> "$SHELL_CONFIG"
    echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
    echo -e "  ${GREEN}✓${NC} Added PATH to ${SHELL_CONFIG}"
fi

echo ""
echo -e "${GREEN}  ✓ Installation complete!${NC}"
echo ""
echo -e "  ${DIM}To start using gum, either:${NC}"
echo -e "    ${BOLD}source ${SHELL_CONFIG}${NC}"
echo -e "  ${DIM}or open a new terminal.${NC}"
echo ""
echo -e "  ${DIM}Then create your first profile:${NC}"
echo -e "    ${BOLD}gum create personal${NC}"
echo ""
echo -e "  ${DIM}Run 'gum help' for all available commands.${NC}"
echo ""
