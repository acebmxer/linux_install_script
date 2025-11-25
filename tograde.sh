# -----------------------------------------------------------------
# 6️⃣  Topgrade – download & install
# -----------------------------------------------------------------
run_as_root apt install curl lsb-release wget
curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get
deb-get install topgrade 
# -----------------------------------------------------------------
# 👉  **Run Topgrade immediately after installation**
# -----------------------------------------------------------------
info "Running Topgrade to upgrade the system …"
# `--yes` (or `-y`) skips the interactive confirmation
topgrade --yes
# -----------------------------------------------------------------
# 9️⃣  Final summary
# -----------------------------------------------------------------
info "All components are now installed and, all tests passed successfully!"
#  🔄  Reboot prompt – now or later?
# -----------------------------------------------------------------
echo
info "The installation is finished. A reboot is recommended to apply all changes."
read -rp "Reboot now? (y/N) " REBOOT_CHOICE
REBOOT_CHOICE=${REBOOT_CHOICE:-N}
case "$REBOOT_CHOICE" in
  y|Y|yes|YES)
    info "Rebooting…"
    run_as_root reboot
    ;;
  n|N|no|NO)
    warn "Remember to reboot the server later to complete the setup."
    ;;
  *)
    error "Unexpected input – exiting without reboot."
    ;;
esac
# If we reach this point, the script has already rebooted (or not).
# No further action is required.
exit 0
