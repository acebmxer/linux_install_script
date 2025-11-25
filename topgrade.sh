#!/bin/bash

# ────────────────────────────────────────────────────────
# 8️⃣ System upgrade – Topgrade (idempotent)
# ────────────────────────────────────────────────────────

# Ensure dependencies are installed
run_as_root apt install -y curl lsb-release wget
run_as_root curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get

info() {
  echo "INFO: $1"
}

error() {
  echo "ERROR: $1"
  exit 1
}

info "Installing topgrade"
deb-get install topgrade
if error; then
  info "Updating topgrade to the newest deb-get‑supplied version …"
  deb-get upgrade topgrade
else
  info "Topgrade has been installed or has been updated."
fi

info "Running topgrade …"
# Run as the user; Topgrade will auto‑install missing packages
topgrade -y

exit 0
