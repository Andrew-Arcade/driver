#!/bin/bash

echo "Launch script v1"

# 1. FIX VOLATILE DIRECTORIES
# These are wiped on every reboot. We recreate them and set permissions.
sudo mkdir -p /run/user/1001
sudo chown arcade:arcade /run/user/1001
sudo chmod 700 /run/user/1001

# 2. FIX HARDWARE ACCESS
# Ensure the seatd socket is accessible for hardware input/output
if [ -S /run/seatd.sock ]; then
    sudo chown root:seat /run/seatd.sock
    sudo chmod 770 /run/seatd.sock
fi

# 2.5. SELF-UPDATE
# Pull latest changes so the driver stays up to date
echo "Updating driver..."
cd /andrewarcade/driver && git pull origin main

# 3. PATHS
# Use absolute paths so the script works from any location
DRIVER_DIR="/andrewarcade/driver/builds/0.1"
BINARY_NAME="driver 0.1 linux-arm64.arm64"

# 4. DIAGNOSTICS
echo "=== Andrew Arcade Diagnostics ==="
echo "--- DRM devices ---"
ls -la /dev/dri/ 2>&1 || echo "  /dev/dri/ does not exist!"
echo "--- GPU kernel modules ---"
lsmod | grep -iE "v3d|vc4|drm|rp1" 2>&1 || echo "  No GPU modules loaded"
echo "--- dmesg GPU errors (last 15) ---"
dmesg | grep -iE "drm|v3d|vc4|rp1|gpu" | tail -15 2>&1
echo "--- Pi model ---"
cat /proc/device-tree/model 2>/dev/null; echo
echo "--- seatd ---"
systemctl is-active seatd 2>&1
echo "=== End Diagnostics ==="

# 5. LAUNCH
# Run cage as the arcade user (not root) for proper DRM/seatd access
# -d: Hide the mouse cursor
# -s: Allow the compositor to handle server tasks (useful for Pi)
echo "Launching Andrew Arcade Driver..."
cd "$DRIVER_DIR"
runuser -u arcade -- env \
    XDG_RUNTIME_DIR=/run/user/1001 \
    WLR_BACKEND=drm \
    WLR_RENDERER=gles2 \
    GODOT_PLATFORM=wayland \
    /usr/bin/cage -d -s -- "./$BINARY_NAME"