#!/bin/bash
# revanced-magisk/build-version.sh

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Examples:"
    echo "  $0 20.21.37"
    echo "  $0 auto"
    exit 1
fi

echo "Building YouTube version: $VERSION"

# Backup original config
cp "$ROOT_DIR/config.toml" "$ROOT_DIR/config.toml.backup"

# Replace version in config - handle both auto and specific versions
if [ "$VERSION" = "auto" ]; then
    sed -i 's/version = "[^"]*"/version = "auto"/' "$ROOT_DIR/config.toml"
else
    # First check if version line exists, if not add it after [Youtube]
    if ! grep -q "^version = " "$ROOT_DIR/config.toml"; then
        sed -i '/^\[Youtube\]/a version = "'"$VERSION"'"' "$ROOT_DIR/config.toml"
    else
        sed -i 's/version = "[^"]*"/version = "'"$VERSION"'"/' "$ROOT_DIR/config.toml"
    fi
fi

# Run build
"$ROOT_DIR/build.sh"

# Restore original config
mv "$ROOT_DIR/config.toml.backup" "$ROOT_DIR/config.toml"

echo "Build complete! Original config restored."
