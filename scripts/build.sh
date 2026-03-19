#!/usr/bin/env bash

# Colors
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "\n${BLUE}${BOLD}:: ${1}${NC}"; }
success() { echo -e "${GREEN}   ✓ ${1}${NC}"; }
warn()    { echo -e "${YELLOW}   ! ${1}${NC}"; }
error()   { echo -e "${RED}   ✗ ${1}${NC}"; }
dim()     { while IFS= read -r line; do echo -e "${DIM}   ${line}${NC}"; done; }

echo -e "\n${BOLD}Andrew Arcade — Build${NC}\n"

PROJECT_DIR="./godot-project"
GODOT="godot"

# Auto-set version to current timestamp
VERSION_STRING=$(date +'%-y.%-m.%-d.%-H-%-M')
sed -i "s|config/version=\".*\"|config/version=\"$VERSION_STRING\"|" "$PROJECT_DIR/project.godot"

# Read project name and version from project.godot
GAME_NAME=$(grep "config/name" $PROJECT_DIR/project.godot | cut -d'"' -f2)
VERSION=$(grep "config/version" $PROJECT_DIR/project.godot | cut -d'"' -f2)

BUILD_DIR="$(pwd)/builds/release"
mkdir -p "$BUILD_DIR"

info "Building $GAME_NAME v$VERSION"

# Get preset names from export_presets.cfg
PRESETS=$(grep "name=" $PROJECT_DIR/export_presets.cfg | cut -d'"' -f2)

for PRESET in $PRESETS
do
    OUTPUT="$BUILD_DIR/$GAME_NAME $PRESET"

    case "$PRESET" in
        linux-arm64)
            OUTPUT="$OUTPUT.arm64"
            ;;
        linux-x86_64)
            OUTPUT="$OUTPUT.x86_64"
            ;;
    esac

    info "Exporting $PRESET"
    if $GODOT --headless --path "$PROJECT_DIR" --export-release "$PRESET" "$OUTPUT" 2>&1 | dim; then
        success "$PRESET exported"
    else
        error "$PRESET failed"
    fi
done

echo -e "\n${GREEN}${BOLD}Build complete!${NC}"

# Commit builds and push
info "Pushing build"
git add builds/
git commit -m "build"
git push
success "Pushed"
