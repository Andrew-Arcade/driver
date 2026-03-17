#!/bin/bash
# Re-build volatile /run paths if missing
sudo mkdir -p /run/user/1001
sudo chown arcade:arcade /run/user/1001
sudo chmod 700 /run/user/1001
sudo chown root:seat /run/seatd.sock
sudo chmod 770 /run/seatd.sock

# Environment
export XDG_RUNTIME_DIR=/run/user/1001
export WLR_BACKEND=drm
export WLR_RENDERER=gles2
export GODOT_PLATFORM=wayland

# Launch Cage (Absolute path to the binary in the same folder as this script)
# -d hides cursor
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cage -d -s -- "$SCRIPT_DIR/builds/0.1/driver 0.1 linux-arm64.arm64"