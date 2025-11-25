#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────
# 1️⃣ Helpers – keep the same colour‑coded log functions
# ────────────────────────────────────────────────────────
run_as_root() { sudo -E "$@"; }
info()        { printf '\e[32m[INFO]\e[0m %s\n' "$*"; }
warn()        { printf '\e[33m[WARN]\e[0m %s\n' "$*"; }
error()       { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2; }

# ────────────────────────────────────────────────────────
# 2️⃣ Idempotency helper
# ────────────────────────────────────────────────────────
needs_update() {
    local flag_file="$1"
    [[ ! -f "$flag_file" ]] && return 0 || return 1
}

# ────────────────────────────────────────────────────────
# 3️⃣ Timezone – only set if not already America/New_York
# ────────────────────────────────────────────────────────
TARGET_TZ="/usr/share/zoneinfo/America/New_York"
LOCALTIME="/etc/localtime"
if [[ "$(readlink -f "$LOCALTIME")" != "$TARGET_TZ" ]]; then
    info "Setting timezone to America/New_York …"
    run_as_root ln -fs "$TARGET_TZ" "$LOCALTIME"
    run_as_root dpkg-reconfigure -f noninteractive tzdata
else
    info "Timezone already set to America/New_York – skipping."
fi

# ────────────────────────────────────────────────────────
# 4️⃣ Ensure deb-get is installed
# ────────────────────────────────────────────────────────
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

# ────────────────────────────────────────────────────────
# 5️⃣ Dotfiles – install for the regular user
# ────────────────────────────────────────────────────────
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_FLAG="$DOTFILES_DIR/.installed"
info "Installing dotfiles for regular user…"
if [[ -d "$DOTFILES_DIR" ]]; then
    info "dotfiles directory already exists – pulling latest changes."
    git -C "$DOTFILES_DIR" pull --rebase
else
    git clone https://github.com/flipsidecreations/dotfiles.git "$DOTFILES_DIR"
fi
if needs_update "$DOTFILES_FLAG"; then
    (cd "$DOTFILES_DIR" && ./install.sh)
    touch "$DOTFILES_FLAG"
    run_as_root chsh -s /bin/zsh
else
    info "Dotfiles already installed – skipping install.sh."
fi

# ────────────────────────────────────────────────────────
# 6️⃣ Dotfiles – install for root (using the same logic)
# ────────────────────────────────────────────────────────
ROOT_DOTFILES_DIR="/root/dotfiles"
ROOT_DOTFILES_FLAG="/root/.dotfiles_installed"

info "Installing dotfiles for root…"
if [[ -d "$ROOT_DOTFILES_DIR" ]]; then
    if [[ -d "$ROOT_DOTFILES_DIR/.git" ]]; then
        info "dotfiles directory already exists – pulling latest changes."
        run_as_root git -C "$ROOT_DOTFILES_DIR" pull --rebase
    else
        warn "Existing directory is not a git repo; moving it to ${ROOT_DOTFILES_DIR}.bak"
        run_as_root mv "$ROOT_DOTFILES_DIR" "${ROOT_DOTFILES_DIR}.bak"
        run_as_root git clone https://github.com/flipsidecreations/dotfiles.git "$ROOT_DOTFILES_DIR"
    fi
else
    info "Cloning root dotfiles repository."
    run_as_root git clone https://github.com/flipsidecreations/dotfiles.git "$ROOT_DOTFILES_DIR"
fi
if [[ ! -f "$ROOT_DOTFILES_FLAG" ]]; then
    (cd "$ROOT_DOTFILES_DIR" && sudo ./install.sh)
    run_as_root touch "$ROOT_DOTFILES_FLAG"
    run_as_root chsh -s /bin/zsh
else
    info "Root dotfiles already installed – skipping install.sh."
fi

# ────────────────────────────────────────────────────────
# 7️⃣ System pre‑upgrade (optional but handy)
# ────────────────────────────────────────────────────────
info "Running a quick apt‑upgrade before topgrade."
run_as_root apt-get update
run_as_root apt-get upgrade -y

# ────────────────────────────────────────────────────────
# 8️⃣ System upgrade – Topgrade (idempotent)
# ────────────────────────────────────────────────────────
needs_topgrade_update() {
    local current_version top_version
    current_version="$(topgrade --version | awk '{print $2}')"
    top_version="$(deb-get get topgrade | awk 'NR==1{print $2}')"
    [[ "$current_version" != "$top_version" ]]
}
if needs_topgrade_update; then
    info "Updating topgrade to the newest deb-get‑supplied version …"
    deb-get upgrade topgrade
else
    info "Topgrade already up‑to‑date."
fi

info "Running topgrade …"
# Run as the user; Topgrade will auto‑install missing packages
topgrade

# ────────────────────────────────────────────────────────
# 9️⃣ xen‑guest‑utilities – install / upgrade (root)
# ────────────────────────────────────────────────────────
if ! dpkg -l | grep -q '^ii\s\+xen-guest-utils'; then
    info "Installing xen‑guest‑utilities …"
    run_as_root deb-get install xen-guest-utils
else
    info "xen-guest‑utilities already present – skipping."
fi

# ────────────────────────────────────────────────────────
# 10️⃣ Ask the user if they want to reboot
# ────────────────────────────────────────────────────────
read -r -p "All done! Do you want to reboot now? (y/N) " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    run_as_root reboot
else
    info "You can reboot later whenever you’re ready."
fi
