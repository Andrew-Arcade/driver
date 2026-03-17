#!/bin/bash
echo "Launch script v0.1"

# 1. FIX VOLATILE DIRECTORIES
# These are wiped on every reboot. We recreate them and set permissions.
sudo mkdir -p /run/user/1001
sudo chown arcade:arcade /run/user/1001
sudo chmod 700 /run/user/1001

# 2. FIX HARDWARE ACCESS
# Ensure the seatd socket is accessible for hardware input/output
sudo chown root:seat /run/seatd.sock
sudo chmod 770 /run/seatd.sock

# 3. ENVIRONMENT VARIABLES
export XDG_RUNTIME_DIR=/run/user/1001
export WLR_BACKEND=drm
export WLR_RENDERER=gles2
export GODOT_PLATFORM=wayland

# 4. PATHS
# Use absolute paths so the script works from any location
DRIVER_DIR="/andrewarcade/driver/builds/0.1"
BINARY_NAME="driver 0.1 linux-arm64.arm64"

# 5. LAUNCH
# -d: Hide the mouse cursor
# -s: Allow the compositor to handle server tasks (useful for Pi)
echo "Launching Andrew Arcade Driver..."
cd "$DRIVER_DIR"
/usr/bin/cage -d -s -- "./$BINARY_NAME"