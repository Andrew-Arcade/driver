#!/usr/bin/env bash

PROJECT_DIR="./godot-project"
GODOT="godot"

# Read project name and version from project.godot
GAME_NAME=$(grep "config/name" $PROJECT_DIR/project.godot | cut -d'"' -f2)
VERSION=$(grep "config/version" $PROJECT_DIR/project.godot | cut -d'"' -f2)

BUILD_DIR="$(pwd)/builds/$VERSION"

mkdir -p "$BUILD_DIR"

echo "Building $GAME_NAME version $VERSION"

# Get preset names from export_presets.cfg
PRESETS=$(grep "name=" $PROJECT_DIR/export_presets.cfg | cut -d'"' -f2)

for PRESET in $PRESETS
do
    OUTPUT="$BUILD_DIR/$GAME_NAME $VERSION $PRESET"

    case "$PRESET" in
        linux-arm64)
            OUTPUT="$OUTPUT.arm64"
            ;;
        linux-x86_64)
            OUTPUT="$OUTPUT.x86_64"
            ;;
    esac

    echo "Exporting: $PRESET -> $OUTPUT"

    $GODOT --headless --path "$PROJECT_DIR" --export-release "$PRESET" "$OUTPUT"
done

echo "Builds finished."