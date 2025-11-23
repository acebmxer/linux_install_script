#!/usr/bin/env bash
# ------------------------------------------------------------------
#  Bootstrap script for a fresh Ubuntu / Debian‑based VM
#
#  • Sets timezone to America/New_York
#  • Installs dotfiles once and runs its install script as user & root
#  • Changes default shell to zsh for both user & root
#  • Mounts the XCP‑NG Tools ISO, runs its installer
#  • Installs Topgrade (via the official .deb package)
#  • Installs Docker and adds the current user to the docker group
#  • Reboots the system
# ------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------
#  Helpers
# ------------------------------------------------------------------
log()  { printf '\e[1;32m[INFO]  \e[0m%s\n' "$*"; }
err()  { printf '\e[1;31m[ERROR] \e[0m%s\n' "$*" >&2; }

run_as_root() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

pkg_installed() { dpkg -s "$1" &>/dev/null; }

# ------------------------------------------------------------------
#  1. Time‑zone
# ------------------------------------------------------------------
log "Setting timezone to America/New_York…"
run_as_root timedatectl set-timezone America/New_York
log "Current system time:"
timedatectl

# ------------------------------------------------------------------
#  2. zsh
# ------------------------------------------------------------------
if ! command -v zsh &>/dev/null; then
  log "Installing zsh..."
  run_as_root apt-get update
  run_as_root apt-get install -y zsh
fi

# ------------------------------------------------------------------
#  3. Dotfiles
# ------------------------------------------------------------------
DOTFILES_DIR="$HOME/dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
  log "Cloning dotfiles repository into $DOTFILES_DIR…"
  git clone https://github.com/flipsidecreations/dotfiles.git "$DOTFILES_DIR"
else
  log "Dotfiles already cloned – pulling latest changes."
  (cd "$DOTFILES_DIR" && git pull)
fi

log "Running dotfiles installation script as current user…"
(cd "$DOTFILES_DIR" && ./install.sh)

log "Running dotfiles installation script as root…"
run_as_root bash -c "cd \"$DOTFILES_DIR\" && ./install.sh"

# ------------------------------------------------------------------
#  4. Default shell to zsh
# ------------------------------------------------------------------
ZSH_BIN="$(command -v zsh)"
log "Changing default shell to $ZSH_BIN for current user."
chsh -s "$ZSH_BIN"

log "Changing default shell to $ZSH_BIN for root."
run_as_root chsh -s "$ZSH_BIN" root

# ------------------------------------------------------------------
#  5. XCP‑NG Tools ISO
# ------------------------------------------------------------------
read -rp "Please insert the XCP‑NG Tools ISO and press [Enter] when ready…"

CDROM=${CDROM:-/dev/cdrom}
MNT_DIR="/mnt"

if [[ ! -e "$CDROM" ]]; then
  err "No CDROM device found at $CDROM. Exiting."
  exit 1
fi

log "Mounting CD-ROM to $MNT_DIR…"
run_as_root mkdir -p "$MNT_DIR"
run_as_root mount "$CDROM" "$MNT_DIR"

if [[ ! -d "$MNT_DIR/Linux" ]]; then
  err "XCP‑NG Tools ISO not found or not mounted correctly."
  run_as_root umount "$MNT_DIR"
  exit 1
fi

log "Running XCP‑NG Tools installation…"
run_as_root bash "$MNT_DIR/Linux/install.sh"
run_as_root umount "$MNT_DIR"

# ------------------------------------------------------------------
#  6. Topgrade
# ------------------------------------------------------------------
TOPGRADE_VERSION="v16.0.4"
TOPGRADE_DEB="topgrade_${TOPGRADE_VERSION#v}_amd64.deb"

if ! pkg_installed topgrade; then
  log "Downloading Topgrade ${TOPGRADE_VERSION}…"
  wget -q -O "$TOPGRADE_DEB" \
    "https://github.com/topgrade-rs/topgrade/releases/download/${TOPGRADE_VERSION}/$TOPGRADE_DEB"

  log "Installing Topgrade…"
  run_as_root apt-get update
  run_as_root apt-get install -y "./$TOPGRADE_DEB"

  # Clean up
  rm -f "$TOPGRADE_DEB"
else
  log "Topgrade already installed – skipping."
fi

log "Running Topgrade…"
topgrade

# ------------------------------------------------------------------
#  7. Docker
# ------------------------------------------------------------------
log "Installing Docker…"

run_as_root apt-get update
run_as_root apt-get install -y ca-certificates curl gnupg

run_as_root install -m 0755 -d /etc/apt/keyrings

DOCKER_GPG=/etc/apt/keyrings/docker.asc
if [[ ! -e "$DOCKER_GPG" ]]; then
  run_as_root curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$DOCKER_GPG"
  run_as_root chmod a+r "$DOCKER_GPG"
fi

DOCKER_LIST=/etc/apt/sources.list.d/docker.list
if [[ ! -e "$DOCKER_LIST" ]]; then
  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  run_as_root tee "$DOCKER_LIST" > /dev/null
fi

run_as_root apt-get update
run_as_root apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ensure docker group exists
if ! getent group docker > /dev/null; then
  run_as_root groupadd docker
fi

# Add current user to the docker group (if not already a member)
if ! id -nG "$USER" | grep -qw docker; then
  run_as_root usermod -aG docker "$USER"
  log "User '$USER' added to 'docker' group – you will need to log out / reboot."
fi

# ------------------------------------------------------------------
#  8. Reboot
# ------------------------------------------------------------------
log "All done – rebooting now."
run_as_root reboot
