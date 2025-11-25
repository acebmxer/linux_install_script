#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# 1️⃣ helpers – keep the same color‑coded log functions
# ------------------------------------------------------------------
run_as_root() { sudo -E "$@"; }
info()        { printf '\e[32m[INFO]\e[0m %s\n' "$*"; }
warn()        { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }
error()       { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2; }

# ------------------------------------------------------------------
# 2️⃣ idempotency helper
# ------------------------------------------------------------------
needs_update() {
    local flag_file="$1"
    [[ ! -f "$flag_file" ]] && return 0 || return 1
}

# ------------------------------------------------------------------
# 3️⃣ Timezone – only set if not already America/New_York
# ------------------------------------------------------------------
TARGET_TZ="/usr/share/zoneinfo/America/New_York"
LOCALTIME="/etc/localtime"
if [[ "$(readlink -f "$LOCALTIME")" != "$TARGET_TZ" ]]; then
    info "Setting timezone to America/New_York …"
    run_as_root ln -fs "$TARGET_TZ" "$LOCALTIME"
    run_as_root dpkg-reconfigure -f noninteractive tzdata
else
    info "Timezone already set to America/New_York – skipping."
fi

# ------------------------------------------------------------------
# 4️⃣ Ensure deb-get is installed
# ------------------------------------------------------------------
ensure_deb_get_installed() {
    if ! command -v deb-get >/dev/null 2>&1; then
        info "deb-get not found – installing prerequisites."
        run_as_root apt-get update
        run_as_root apt-get install -y curl lsb-release wget
        info "Installing deb-get."
        curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | \
             sudo -E bash -s install deb-get
    else
        info "deb-get is already installed."
    fi
}
ensure_deb_get_installed

# ------------------------------------------------------------------
# 5️⃣ Dotfiles – install for the regular user
# ------------------------------------------------------------------
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_FLAG="$DOTFILES_DIR/.installed"
info "Installing dotfiles for regular user…"

if [[ -d "$DOTFILES_DIR" ]]; then
    info "dotfiles directory already exists – pulling latest changes."
    git -C "$DOTFILES_DIR" pull --rebase
else
    git clone https://github.com/flipsidecreations/dotfiles.git "$DOTFILES_DIR"
fi

# Run the install script only if we haven’t run it before
if needs_update "$DOTFILES_FLAG"; then
    (cd "$DOTFILES_DIR" && ./install.sh)
    touch "$DOTFILES_FLAG"
    run_as_root chsh -s /bin/zsh
else
    info "Dotfiles already installed – skipping install.sh."
fi

# ------------------------------------------------------------------
# 6️⃣ Dotfiles – install for root (using the same logic)
# ------------------------------------------------------------------
ROOT_DOTFILES_DIR="/root/dotfiles"
ROOT_DOTFILES_FLAG="/root/.dotfiles_installed"
info "Installing dotfiles for root…"

if [[ -d "$ROOT_DOTFILES_DIR" ]]; then
    info "dotfiles directory already exists – pulling latest changes."
    run_as_root git -C "$ROOT_DOTFILES_DIR" pull --rebase
else
    run_as_root git clone https://github.com/flipsidecreations/dotfiles.git "$ROOT_DOTFILES_DIR"
fi

if [[ ! -f "$ROOT_DOTFILES_FLAG" ]]; then
    (cd "$ROOT_DOTFILES_DIR" && sudo ./install.sh)
    run_as_root touch "$ROOT_DOTFILES_FLAG"
    run_as_root chsh -s /bin/zsh
else
    info "Root dotfiles already installed – skipping install.sh."
fi

# ------------------------------------------------------------------
# 7️⃣ Ensure Topgrade is at the correct version
# ------------------------------------------------------------------
REQUIRED_TOPGRADE_VERSION="v16.0.4-1"
needs_topgrade_update() {
    if ! command -v topgrade >/dev/null 2>&1; then
        return 0
    fi
    local current
    current=$(topgrade --version | awk '{print $2}')
    [[ "$current" != "$REQUIRED_TOPGRADE_VERSION" ]] && return 0
    return 1
}
if needs_topgrade_update; then
    info "Installing/upgrading Topgrade to $REQUIRED_TOPGRADE_VERSION …"
    deb-get install topgrade="$REQUIRED_TOPGRADE_VERSION"   # <-- ASCII hyphen
else
    info "Topgrade already at $REQUIRED_TOPGRADE_VERSION – skipping."
fi

# ------------------------------------------------------------------
# 8️⃣ Install xen-guest-utilities
# ------------------------------------------------------------------
if ! dpkg -s xen-guest-utilities >/dev/null 2>&1; then
    info "Installing xen-guest-utilities."
    deb-get install xen-guest-utilities
else
    info "xen-guest-utilities already installed – skipping."
fi

# ------------------------------------------------------------------
# 9️⃣ Run Topgrade – it is idempotent on its own
# ------------------------------------------------------------------
info "Running Topgrade…"
topgrade

# ------------------------------------------------------------------
# 10️⃣ Optional reboot prompt
# ------------------------------------------------------------------
read -rp "Do you want to reboot now? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] && run_as_root reboot
