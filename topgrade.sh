# ────────────────────────────────────────────────────────
# 8️⃣ System upgrade – Topgrade (idempotent)
# ────────────────────────────────────────────────────────
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
# ────────────────────────────────────────────────────────
