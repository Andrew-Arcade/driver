#!/bin/bash

# Colors
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'
BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

info()    { echo -e "\n${BLUE}${BOLD}:: ${1}${NC}"; }
success() { echo -e "${GREEN}   ✓ ${1}${NC}"; }
warn()    { echo -e "${YELLOW}   ! ${1}${NC}"; }
error()   { echo -e "${RED}   ✗ ${1}${NC}"; }
dim()     { while IFS= read -r line; do echo -e "${DIM}   ${line}${NC}"; done; }

echo -e "\n${BOLD}Andrew Arcade — Setup${NC}\n"

# Packages — system dependencies for Wayland, GPU, audio, and emulation
info "Installing packages"
apt update && apt install -y \
    dbus git sudo cage seatd xwayland box64 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libxfixes3 libxi6 libxkbcommon0 libfontconfig1 \
    libx11-6 libxcursor1 libxinerama1 libxrandr2 \
    libvulkan1 libasound2 alsa-utils mesa-vulkan-drivers 2>&1 | dim
success "Packages installed"

if ! modinfo v3d &>/dev/null; then
    warn "v3d kernel module not found — run: dietpi-update"
fi

groupadd -f seat
systemctl enable seatd 2>&1 | dim
systemctl start seatd 2>&1 | dim
success "seatd enabled"

# Repository — clone or update the driver
info "Setting up repository"
mkdir -p /andrewarcade

if [ ! -d "/andrewarcade/driver" ]; then
    git clone https://github.com/Andrew-Arcade/driver.git /andrewarcade/driver 2>&1 | dim
    success "Repository cloned"
else
    cd /andrewarcade/driver && git pull origin main 2>&1 | dim
    chown -R arcade:arcade /andrewarcade/driver 2>/dev/null
    success "Repository updated"
fi

# User — create arcade user with hardware group access
info "Configuring user"
USER="arcade"
if id "$USER" &>/dev/null; then
    success "User '$USER' already exists"
else
    useradd -m -s /bin/bash "$USER"
    echo "$USER:$USER" | chpasswd
    success "User '$USER' created"
fi

usermod -aG video,audio,input,render,seat "$USER"
success "Hardware groups assigned"

# GPU config — KMS overlay, memory, and kernel module
info "Configuring GPU"

PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "unknown")
success "Detected board: $PI_MODEL"

if echo "$PI_MODEL" | grep -qi "pi 5"; then
    REQUIRED_OVERLAY="vc4-kms-v3d-pi5"
else
    REQUIRED_OVERLAY="vc4-kms-v3d"
fi

# DietPi uses /boot/firmware/config.txt, Raspberry Pi OS uses /boot/config.txt
if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
else
    BOOT_CONFIG="/boot/config.txt"
fi

if ! grep -qE "dtoverlay=${REQUIRED_OVERLAY}" "$BOOT_CONFIG"; then
    sed -i '/^dtoverlay=vc4-.*kms-v3d/d' "$BOOT_CONFIG"
    echo "dtoverlay=${REQUIRED_OVERLAY}" >> "$BOOT_CONFIG"
    success "KMS overlay enabled: $REQUIRED_OVERLAY"
else
    success "KMS overlay already set"
fi

# DietPi defaults gpu_mem to 16MB — too low for rendering
sed -i 's/^gpu_mem_256=16/gpu_mem_256=64/' "$BOOT_CONFIG"
sed -i 's/^gpu_mem_512=16/gpu_mem_512=64/' "$BOOT_CONFIG"
sed -i 's/^gpu_mem_1024=16/gpu_mem_1024=64/' "$BOOT_CONFIG"
success "GPU memory bumped to 64MB"

# Load v3d at boot for GPU rendering
if ! grep -q "^v3d$" /etc/modules 2>/dev/null; then
    echo "v3d" >> /etc/modules
    success "v3d added to /etc/modules"
else
    success "v3d already in /etc/modules"
fi

# Permissions — allow arcade user to launch and reboot without a password
info "Setting up permissions"
cat > /etc/sudoers.d/arcade << SUDOERS
$USER ALL=(ALL) NOPASSWD: /andrewarcade/driver/scripts/launch.sh
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl reboot
$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl poweroff
SUDOERS
success "Sudoers configured"

# Autostart — DietPi custom script boot mode
info "Configuring autostart"

if [ -f "/andrewarcade/driver/scripts/launch.sh" ]; then
    chmod +x "/andrewarcade/driver/scripts/launch.sh"
    mkdir -p /var/lib/dietpi/dietpi-autostart
    echo "sudo /andrewarcade/driver/scripts/launch.sh" > /var/lib/dietpi/dietpi-autostart/custom.sh
    chmod +x /var/lib/dietpi/dietpi-autostart/custom.sh
    sed -i 's/^AUTO_SETUP_AUTOSTART_LOGIN_USER=.*/AUTO_SETUP_AUTOSTART_LOGIN_USER=arcade/' /boot/dietpi.txt
    /boot/dietpi/dietpi-autostart 17
    success "Autostart configured (mode 17)"
else
    error "launch.sh not found — check repo structure"
    exit 1
fi

# Ownership — give arcade user control for managing cabinets
info "Setting ownership"
mkdir -p /andrewarcade/cabinets
chown -R "$USER:$USER" /andrewarcade
chown arcade:arcade /var/lib/dietpi/dietpi-autostart/custom.sh
sudo -u "$USER" git config --global --add safe.directory '*'
success "Ownership set"

echo -e "\n${GREEN}${BOLD}Setup complete!${NC}"
echo -e "The system will reboot and launch the driver automatically."
echo -e "Restarting in 5 seconds...\n"
sleep 5
reboot
