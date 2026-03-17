#!/bin/bash
set -e # Exit if any command fails

echo "--- Starting Andrew Arcade Setup ---"

# 1. Install Dependencies
apt update
apt install -y sudo cage seatd xwayland box64 libwayland-client0 libwayland-cursor0 \
libwayland-egl1 libxfixes3 libxi6 libxkbcommon0 libfontconfig1 libx11-6 libxcursor1 \
libxinerama1 libxrandr2 libvulkan1 libasound2

# 2. Create Arcade User (Non-interactive)
if ! id "arcade" &>/dev/null; then
    useradd -m -s /bin/bash arcade
    echo "arcade:arcade" | chpasswd
fi

# 3. Setup Groups
groupadd -f seat
usermod -aG video,audio,input,render,seat arcade

# 4. Setup Sudoers (The "No Password" trick)
# We put this in a separate file in sudoers.d so it's safe and persistent
echo "arcade ALL=(ALL) NOPASSWD: /andrewarcade/driver/scripts/launch.sh" > /etc/sudoers.d/arcade

# 5. Set DietPi Autostart (Custom Script Mode)
# 14 = Custom script, foreground, with autologin
sed -i 's/^AUTO_SETUP_AUTOSTART_TARGET_INDEX=.*/AUTO_SETUP_AUTOSTART_TARGET_INDEX=14/' /boot/dietpi.txt
sed -i 's/^AUTO_SETUP_AUTOSTART_LOGIN_USER=.*/AUTO_SETUP_AUTOSTART_LOGIN_USER=arcade/' /boot/dietpi.txt

# Create the DietPi autostart pointer
mkdir -p /var/lib/dietpi/dietpi-autostart/
echo "sudo /andrewarcade/driver/scripts/launch.sh" > /var/lib/dietpi/dietpi-autostart/custom.sh
chmod +x /var/lib/dietpi/dietpi-autostart/custom.sh

# 6. Enable KMS Driver (RPi 5 Requirement)
if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
    echo "dtoverlay=vc4-kms-v3d" >> /boot/config.txt
fi

echo "--- Setup Complete! Rebooting in 5 seconds ---"
sleep 5
reboot