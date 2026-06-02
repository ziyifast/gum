#!/usr/bin/env bash
#
# Build a .deb package for gum
#
# Usage: bash packaging/deb/build.sh
#

set -e

# Determine project root (two levels up from this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

VERSION="1.1.0"
PKG_NAME="gum"
ARCH="all"
BUILD_DIR="$PROJECT_ROOT/build/${PKG_NAME}_${VERSION}_${ARCH}"
DEB_FILE="${PKG_NAME}_${VERSION}_${ARCH}.deb"

echo "Building $DEB_FILE..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Create directory structure
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/doc/gum"

# Copy control file
cp "$SCRIPT_DIR/DEBIAN/control" "$BUILD_DIR/DEBIAN/control"

# Install the binary
install -m 755 "$PROJECT_ROOT/gum.sh" "$BUILD_DIR/usr/bin/gum"

# Install docs
install -m 644 "$PROJECT_ROOT/README.md" "$BUILD_DIR/usr/share/doc/gum/README.md"
install -m 644 "$PROJECT_ROOT/LICENSE" "$BUILD_DIR/usr/share/doc/gum/copyright"
install -m 644 "$PROJECT_ROOT/CHANGELOG.md" "$BUILD_DIR/usr/share/doc/gum/changelog"

# Build the .deb
cd "$PROJECT_ROOT"
if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"
    echo ""
    echo "✓ Built: $PROJECT_ROOT/$DEB_FILE"
    echo ""
    echo "Install with:"
    echo "  sudo dpkg -i $DEB_FILE"
    echo ""
    echo "Uninstall with:"
    echo "  sudo dpkg -r gum"
else
    echo "Error: dpkg-deb is not installed."
    echo "On macOS: brew install dpkg"
    echo "On Debian/Ubuntu: apt-get install dpkg-dev"
    exit 1
fi
