#!/bin/bash

echo "---------- Setting Up Andrew Arcade ----------"
echo "Setup script v0.1"

# 1. PACKAGES
echo "Installing required packages..."
apt update && apt install -y \
    dbus git sudo cage seatd xwayland box64 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libxfixes3 libxi6 libxkbcommon0 libfontconfig1 \
    libx11-6 libxcursor1 libxinerama1 libxrandr2 \
    libvulkan1 libasound2 alsa-utils mesa-vulkan-drivers

# Check kernel has GPU module available
if ! modinfo v3d &>/dev/null; then
    echo "WARNING: v3d kernel module not found. Run: dietpi-update"
fi

# Enable seatd so cage can access DRM/input devices
groupadd -f seat
systemctl enable seatd
systemctl start seatd

# 2. DIRECTORY & REPO MANAGEMENT
# This ensures the folder exists and the code is present before we try to chmod it.
mkdir -p /andrewarcade

if [ ! -d "/andrewarcade/driver" ]; then
    echo "Directory /andrewarcade/driver not found. Cloning from main..."
    git clone https://github.com/Andrew-Arcade/driver.git /andrewarcade/driver
else
    echo "Driver folder exists. Pulling latest from main..."
    cd /andrewarcade/driver && git pull origin main
fi

# 3. USER
USER="arcade"
if id "$USER" &>/dev/null; then
    echo "User '$USER' already exists."
else
    echo "Creating user '$USER'..."
    useradd -m -s /bin/bash "$USER"
    # Sets default password to 'arcade'
    echo "$USER:$USER" | chpasswd
fi

# Add user to required hardware groups for graphics/input
usermod -aG video,audio,input,render,seat "$USER"

# 4. PERMISSIONS
echo "Setting up sudoers bypass..."
# This allows the arcade user to run the launch script as root without a password
echo "$USER ALL=(ALL) NOPASSWD: /andrewarcade/driver/scripts/launch.sh" > /etc/sudoers.d/arcade

# 5. DIETPI AUTOSTART
echo "Configuring DietPi autostart..."

# Ensure the script is executable now that the repo is cloned

if [ -f "/andrewarcade/driver/scripts/launch.sh" ]; then
    chmod +x "/andrewarcade/driver/scripts/launch.sh"
    # Create custom.sh before calling dietpi-autostart to avoid editor prompt
    mkdir -p /var/lib/dietpi/dietpi-autostart
    echo "sudo /andrewarcade/driver/scripts/launch.sh" > /var/lib/dietpi/dietpi-autostart/custom.sh
    chmod +x /var/lib/dietpi/dietpi-autostart/custom.sh
    # Set autologin user to arcade (dietpi-autostart reads this from dietpi.txt)
    sed -i 's/^AUTO_SETUP_AUTOSTART_LOGIN_USER=.*/AUTO_SETUP_AUTOSTART_LOGIN_USER=arcade/' /boot/dietpi.txt
    # Set DietPi to use Custom Script foreground with autologin (Index 17)
    /boot/dietpi/dietpi-autostart 17
else
    echo "ERROR: launch.sh not found! Please check your repo structure."
    exit 1
fi

# Detect Pi model and apply correct KMS overlay
PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "unknown")
echo "Detected board: $PI_MODEL"

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
    # Remove any conflicting vc4 KMS overlay before adding the correct one
    sed -i '/^dtoverlay=vc4-.*kms-v3d/d' "$BOOT_CONFIG"
    echo "Enabling KMS overlay: $REQUIRED_OVERLAY"
    echo "dtoverlay=${REQUIRED_OVERLAY}" >> "$BOOT_CONFIG"
fi

# Bump GPU memory from DietPi's default 16MB (too low for rendering)
sed -i 's/^gpu_mem_256=16/gpu_mem_256=64/' "$BOOT_CONFIG"
sed -i 's/^gpu_mem_512=16/gpu_mem_512=64/' "$BOOT_CONFIG"
sed -i 's/^gpu_mem_1024=16/gpu_mem_1024=64/' "$BOOT_CONFIG"

# Ensure v3d module is loaded at boot (needed for GPU rendering)
if ! grep -q "^v3d$" /etc/modules 2>/dev/null; then
    echo "Adding v3d to /etc/modules for boot loading..."
    echo "v3d" >> /etc/modules
fi

# 6. DIRECTORY OWNERSHIP
# Give the arcade user control over the folder so the driver can manage cabinets
chown -R "$USER:$USER" /andrewarcade
# Ensure arcade can execute the autostart wrapper
chown arcade:arcade /var/lib/dietpi/dietpi-autostart/custom.sh

# END
echo "---------- SETUP COMPLETE ----------"
echo "The system will reboot and launch the driver automatically."
echo "Restarting in 5 seconds..."
sleep 5
reboot