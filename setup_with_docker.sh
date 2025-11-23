#!/usr/bin/env bash
# =============================================================================
#  ──────  BOOTSTRAP SCRIPT  ──────
#  Installs:
#   • zsh (for the current user + root)
#   • dotfiles (once)
#   • XCP‑NG Tools (conflict‑free)
#   • Topgrade (download + install)
#   • Docker
#   • (Optional) Reboot
# =============================================================================

set -euo pipefail

# --------------------------------------------------------------------------- #
# Helper functions
# --------------------------------------------------------------------------- #

log()   { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
info()  { printf '    \e[32m%s\e[0m\n' "$*"; }
warn()  { printf '    \e[33m%s\e[0m\n' "$*"; }
error() { printf '    \e[31m%s\e[0m\n' "$*"; }

# Run a command with root privileges; if we are already root it just runs.
run_as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# --------------------------------------------------------------------------- #
# 1️⃣  Timezone
# --------------------------------------------------------------------------- #
info "Setting timezone to America/New_York …"
run_as_root ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
run_as_root dpkg-reconfigure -f noninteractive tzdata

# --------------------------------------------------------------------------- #
# 2️⃣  Basic packages
# --------------------------------------------------------------------------- #
info "Updating APT cache …"
run_as_root apt-get update -y
info "Installing required packages …"
run_as_root apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg2 \
    lsb-release \
    sudo

# --------------------------------------------------------------------------- #
# 3️⃣  Dotfiles – install once
# --------------------------------------------------------------------------- #
DOTFILES_DIR="$HOME/dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Cloning dotfiles repository …"
    run_as_root git clone --depth 1 https://github.com/your-username/dotfiles.git "$DOTFILES_DIR"
    run_as_root chown -R "$USER":"$USER" "$DOTFILES_DIR"
else
    info "Dotfiles already present – skipping clone"
fi

info "Running dotfiles installer (once) …"
run_as_root bash "$DOTFILES_DIR/install.sh" --once

# --------------------------------------------------------------------------- #
# 4️⃣  Shell – zsh for user and root
# --------------------------------------------------------------------------- #
info "Setting shell to zsh for the current user …"
chsh -s "$(command -v zsh)" "$USER"

info "Setting shell to zsh for root …"
run_as_root usermod -s "$(command -v zsh)" root

# --------------------------------------------------------------------------- #
# 5️⃣  XCP‑NG Tools – conflict‑free install
# --------------------------------------------------------------------------- #
info "Installing XCP‑NG Tools …"
run_as_root bash -c '
    # Grab the latest .deb package name from the XCP‑NG release page
    XCP_REPO="https://github.com/xcp-ng/xcp-ng-tools/releases/latest"
    DEB="$(wget -qO- "$XCP_REPO" | grep -oP "href=\"\\K[^\".]*\\.deb\"")"
    DEB="${DEB#*href=\x22}"
    DEB="${DEB%\"}"
    wget -qO /tmp/xcp_ng_latest.deb "$XCP_REPO/$DEB" || exit 1
    apt-get update
    apt-get install -y "/tmp/xcp_ng_latest.deb"
    apt-mark auto xcp-ng-tools
'

# --------------------------------------------------------------------------- #
# 6️⃣  Topgrade – download & install
# --------------------------------------------------------------------------- #
TOPGRADE_VERSION="v16.0.4"
TOPGRADE_DEB="topgrade_${TOPGRADE_VERSION#v}_1_amd64.deb"
TOPGRADE_URL="https://github.com/topgrade-rs/topgrade/releases/download/${TOPGRADE_VERSION}/${TOPGRADE_DEB}"
TOPGRADE_DEST="/tmp/${TOPGRADE_DEB}"

download_topgrade() {
    info "Downloading Topgrade ($TOPGRADE_DEB) …"
    if [[ -f "$TOPGRADE_DEST" ]]; then
        warn "Topgrade .deb already present – skipping download"
    else
        run_as_root wget -q --show-progress -O "$TOPGRADE_DEST" "$TOPGRADE_URL" || error "Failed to download Topgrade" && exit 1
        info "Topgrade downloaded to $TOPGRADE_DEST"
    fi
}

install_topgrade() {
    local deb="$1"
    info "Installing Topgrade from $deb …"
    run_as_root apt-get update
    run_as_root apt-get install -y "./$deb"
    run_as_root apt-mark auto topgrade
    info "Topgrade installed and auto‑marked for upgrades"
}

download_topgrade
install_topgrade "$TOPGRADE_DEST"

# --------------------------------------------------------------------------- #
# 7️⃣  Docker – install & enable
# --------------------------------------------------------------------------- #
info "Installing Docker …"
run_as_root apt-get install -y \
    docker.io \
    docker-compose

run_as_root usermod -aG docker "$USER"
run_as_root systemctl enable docker

# --------------------------------------------------------------------------- #
# 8️⃣  Summary
# --------------------------------------------------------------------------- #
info "─────────────────────────────────────────────────────────────────────"
info "Bootstrap finished successfully."
info " • Timezone        : America/New_York"
info " • Dotfiles        : $DOTFILES_DIR"
info " • Shell           : zsh (current user & root)"
info " • XCP‑NG Tools    : installed"
info " • Topgrade        : installed (auto‑marked)"
info " • Docker          : installed & enabled for current user"
info "─────────────────────────────────────────────────────────────────────"

# --------------------------------------------------------------------------- #
# 9️⃣  Optional reboot
# --------------------------------------------------------------------------- #
# Uncomment the following lines if you want an automatic reboot after
# all installations finish.  Commented out by default so you can inspect
# the system before rebooting.

# warn "Rebooting in 5 seconds…"
# sleep 5
# run_as_root reboot

# EOF
