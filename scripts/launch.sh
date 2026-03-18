#!/bin/bash

# Colors
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "\n${BLUE}${BOLD}:: ${1}${NC}"; }
success() { echo -e "${GREEN}   ✓ ${1}${NC}"; }
warn()    { echo -e "${YELLOW}   ! ${1}${NC}"; }
error()   { echo -e "${RED}   ✗ ${1}${NC}"; }
dim()     { while IFS= read -r line; do echo -e "${DIM}   ${line}${NC}"; done; }

echo -e "\n${BOLD}Andrew Arcade — Launch${NC}\n"

# Runtime directories — wiped on every reboot, must be recreated
info "Runtime directories"
sudo mkdir -p /run/user/1001
sudo chown arcade:arcade /run/user/1001
sudo chmod 700 /run/user/1001
success "XDG_RUNTIME_DIR ready"

# Self-update — keep the driver current on every boot
info "Self-update"
cd /andrewarcade/driver && sudo -u arcade git pull origin main 2>&1 | dim
success "Driver up to date"

# Hardware access — ensure seatd socket is accessible for input/output
info "Hardware access"
if [ -S /run/seatd.sock ]; then
    sudo chown root:seat /run/seatd.sock
    sudo chmod 770 /run/seatd.sock
    success "seatd socket configured"
else
    warn "seatd socket not found"
fi

DRIVER_DIR="/andrewarcade/driver/builds/0.1"
BINARY_NAME="driver 0.1 linux-arm64.arm64"

# Launch — cage compositor with Godot
info "Launching driver"
cd "$DRIVER_DIR"
runuser -u arcade -- env \
    XDG_RUNTIME_DIR=/run/user/1001 \
    WLR_BACKEND=drm \
    WLR_RENDERER=gles2 \
    GODOT_PLATFORM=wayland \
    /usr/bin/cage -d -s -- "./$BINARY_NAME"
