#!/bin/bash

echo "---------- Setting Up Andrew Arcade ----------"

# PACKAGES
echo "Installing required packages"

apt update && apt install -y \
    git sudo cage seatd xwayland box64 \
    libwayland-client0 libwayland-cursor0 libwayland-egl1 \
    libxfixes3 libxi6 libxkbcommon0 libfontconfig1 \
    libx11-6 libxcursor1 libxinerama1 libxrandr2 \
    libvulkan1 libasound2 alsa-utils mesa-vulkan-drivers

# USER
USER="arcade"

echo "Creating user: '$USER'..."

if id "$USER" &>/dev/null; then
    echo "User '$USER' already exists."
else
    echo "User '$USER' does not exist. Creating..."
    
    sudo useradd -m "$USER"
    
    if [ $? -eq 0 ]; then
        echo "User '$USER' created successfully."
    else
        echo "Failed to create user '$USER'."
        exit 1
    fi
fi

echo "Auto start as user: '$USER'..."

echo 'arcade' | sudo tee /var/lib/dietpi/dietpi-autostart/target_user

# LAUNCH
echo "Auto start launch script..."

chmod +x "/andrewarcade/driver/scripts/launch.sh"

echo "/andrewarcade/driver/scripts/launch.sh" | sudo tee /var/lib/dietpi/dietpi-autostart/custom.sh

# END
echo "---------- SETUP COMPLETE ----------"
echo "Restarting in 5 seconds..."
sleep 5
reboot
