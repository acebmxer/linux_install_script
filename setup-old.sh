#!/bin/bash

# Function to pause and prompt for VMware Tools ISO insertion
pause_for_vmtools() {
    echo "Please insert the XCP-NG Tools ISO and press [Enter] when ready..."
    read -r
    mount /dev/cdrom /mnt
    if [[ ! -d "/mnt" ]]; then
        echo "Error: XCP-NG Tools ISO not found. Please insert the ISO and try again."
        exit 1
    fi
}

# Set system timezone to New York
echo "Setting timezone to America/New_York..."
sudo timedatectl set-timezone America/New_York
echo "Current system time:"
timedatectl

# Clone dotfiles repository and run install script
echo "Cloning dotfiles repository..."
git clone https://github.com/flipsidecreations/dotfiles.git
cd dotfiles || exit
echo "Running dotfiles installation script..."
./install.sh

# Change default shell to zsh
echo "Changing default shell to zsh..."
chsh -s /bin/zsh
cd

# Switch to root user to repeat process
echo "Switching to root user to repeat setup..."
sudo -i
git clone https://github.com/flipsidecreations/dotfiles.git
cd dotfiles || exit
echo "Running dotfiles installation script as root..."
./install.sh

# Change default shell to zsh again as root
echo "Changing default shell to zsh for root..."
chsh -s /bin/zsh
cd

# Pause and prompt for VMware Tools ISO if not already inserted
pause_for_vmtools

# Run VMware Tools installation
echo "Running VMware Tools installation..."
bash -c "bash /mnt/Linux/install.sh && umount /mnt"

# Exit root session
exit

# Download and install topgrade
echo "Downloading and installing topgrade..."
wget https://github.com/topgrade-rs/topgrade/releases/download/v16.0.4/topgrade_16.0.4-1_amd64.deb
sudo apt install ./topgrade_16.0.4-1_amd64.deb

# Run topgrade
echo "Running topgrade..."
topgrade

# Reboot system
echo "Rebooting system..."
sudo reboot
