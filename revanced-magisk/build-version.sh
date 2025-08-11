#!/bin/bash
VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Examples:"
    echo "  $0 20.21.37"
    echo "  $0 auto"
    exit 1
fi

echo "Building YouTube version: $VERSION"

# Backup original config
cp config.toml config.toml.backup

# Replace version in config - handle both auto and specific versions
if [ "$VERSION" = "auto" ]; then
    sed -i 's/version = "[^"]*"/version = "auto"/' config.toml
else
    # First check if version line exists, if not add it after [Youtube]
    if ! grep -q "^version = " config.toml; then
        sed -i '/^\[Youtube\]/a version = "'"$VERSION"'"' config.toml
    else
        sed -i 's/version = "[^"]*"/version = "'"$VERSION"'"/' config.toml
    fi
fi

# Run build
./build.sh

# Restore original config
mv config.toml.backup config.toml

echo "Build complete! Original config restored."