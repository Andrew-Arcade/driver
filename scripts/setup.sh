#!/bin/bash

echo "---------- Setting Up Andrew Arcade ----------"
echo "Launcher script v0.1"

# 1. PACKAGES
echo "Installing required packages..."
apt update && apt install -y \
    git sudo cage seatd xwayland box64 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libxfixes3 libxi6 libxkbcommon0 libfontconfig1 \
    libx11-6 libxcursor1 libxinerama1 libxrandr2 \
    libvulkan1 libasound2 alsa-utils mesa-vulkan-drivers

# 2. USER
USER="arcade"
if id "$USER" &>/dev/null; then
    echo "User '$USER' already exists."
else
    echo "Creating user '$USER'..."
    useradd -m -s /bin/bash "$USER"
    echo "$USER:$USER" | chpasswd
fi

# Add user to required hardware groups
usermod -aG video,audio,input,render,seat "$USER"

# 3. PERMISSIONS
echo "Setting up sudoers bypass..."
echo "$USER ALL=(ALL) NOPASSWD: /andrewarcade/driver/scripts/launch.sh" > /etc/sudoers.d/arcade

# 4. DIETPI AUTOSTART
echo "Configuring DietPi autostart..."
# Set DietPi to use Custom Script (14) and our user
sed -i 's/^AUTO_SETUP_AUTOSTART_TARGET_INDEX=.*/AUTO_SETUP_AUTOSTART_TARGET_INDEX=14/' /boot/dietpi.txt
echo "$USER" > /var/lib/dietpi/dietpi-autostart/target_user

# Set the custom launch command
chmod +x "/andrewarcade/driver/scripts/launch.sh"
echo "sudo /andrewarcade/driver/scripts/launch.sh" > /var/lib/dietpi/dietpi-autostart/custom.sh
chmod +x /var/lib/dietpi/dietpi-autostart/custom.sh

# 5. DIRECTORY OWNERSHIP
# Make sure the arcade user owns the driver folder so it can update itself
chown -R "$USER:$USER" /andrewarcade

# END
echo "---------- SETUP COMPLETE ----------"
echo "The system will reboot and launch the driver automatically."
echo "Restarting in 5 seconds..."
sleep 5
reboot