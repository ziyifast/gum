#!/usr/bin/env bash
#
# gum remote installer - one-line install via curl
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ziyifast/gum/main/packaging/install-remote.sh | bash
#
# Or with custom version:
#   curl -fsSL https://raw.githubusercontent.com/ziyifast/gum/main/packaging/install-remote.sh | bash -s -- v1.1.0
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

GUM_REPO="ziyifast/gum"
GUM_VERSION="${1:-main}"
GUM_INSTALL_DIR="${GUM_INSTALL_DIR:-$HOME/.gum}"
GUM_BIN_DIR="$GUM_INSTALL_DIR/bin"

echo ""
echo -e "${BOLD}${PURPLE}  Installing gum (Git User Manager)...${NC}"
echo -e "${DIM}  ─────────────────────────────────────────${NC}"
echo ""

# Check requirements
for cmd in git curl bash; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}✖${NC} Missing required command: ${cmd}"
        exit 1
    fi
done

# Determine download URL
if [[ "$GUM_VERSION" == "main" ]]; then
    SOURCE_URL="https://raw.githubusercontent.com/${GUM_REPO}/main/gum.sh"
else
    # Strip leading "v" if present
    VERSION_TAG="${GUM_VERSION#v}"
    SOURCE_URL="https://raw.githubusercontent.com/${GUM_REPO}/v${VERSION_TAG}/gum.sh"
fi

echo -e "  ${DIM}Source: ${SOURCE_URL}${NC}"
echo ""

# Create directories
mkdir -p "$GUM_INSTALL_DIR/profiles"
mkdir -p "$GUM_BIN_DIR"

# Download gum.sh
TMP_FILE="$(mktemp)"
if curl -fsSL "$SOURCE_URL" -o "$TMP_FILE"; then
    install -m 755 "$TMP_FILE" "$GUM_BIN_DIR/gum"
    rm -f "$TMP_FILE"
    echo -e "  ${GREEN}✓${NC} Installed gum to ${GUM_BIN_DIR}/gum"
else
    echo -e "${RED}✖${NC} Failed to download gum.sh from ${SOURCE_URL}"
    rm -f "$TMP_FILE"
    exit 1
fi

# Detect shell config
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    zsh)   SHELL_CONFIG="$HOME/.zshrc" ;;
    bash)
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        ;;
    *) SHELL_CONFIG="$HOME/.profile" ;;
esac

# Add to PATH if not already configured
PATH_EXPORT='export PATH="$HOME/.gum/bin:$PATH"'
GUM_MARKER="# gum (Git User Manager)"

if [[ -f "$SHELL_CONFIG" ]] && grep -q "$GUM_MARKER" "$SHELL_CONFIG" 2>/dev/null; then
    echo -e "  ${DIM}PATH already configured in ${SHELL_CONFIG}${NC}"
else
    {
        echo ""
        echo "$GUM_MARKER"
        echo "$PATH_EXPORT"
    } >> "$SHELL_CONFIG"
    echo -e "  ${GREEN}✓${NC} Added PATH to ${SHELL_CONFIG}"
fi

echo ""
echo -e "${GREEN}  ✓ Installation complete!${NC}"
echo ""
echo -e "  ${DIM}Reload your shell:${NC}"
echo -e "    ${BOLD}source ${SHELL_CONFIG}${NC}"
echo ""
echo -e "  ${DIM}Then run:${NC}"
echo -e "    ${BOLD}gum init${NC}"
echo ""
