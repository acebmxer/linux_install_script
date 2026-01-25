#!/usr/bin/env bash
#-------------------------------------------------------------
#   Helper Fucntions
#-------------------------------------------------------------
run_as_root() { sudo -E bash -c "$*"; }
run_as_user() { local user="${SUDO_USER:-${USER}}"; sudo -u "$user" -H bash -c "$*"; }
info()  { printf '\e[32m[INFO]\e[0m %s\n' "$*" | tee -a "$log_file"; }
warn()  { printf '\e[33m[WARN]\e[0m %s\n' "$*" | tee -a "$log_file"; }
error() { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2 | tee -a "$log_file"; }

# ───────────────────────────────────────────────────────
# Install prereq for timezone change and basic tools.
run_as_root apt-get update
run_as_root apt-get install -y --no-install-recommends jq tzdata git curl wget python3 python3-venv
# ───────────────────────────────────────────────────────
# 3️⃣ Timezone  - change the timezone
# ───────────────────────────────────────────────────────
LOCALTIME="/etc/localtime"
current_tz="unknown"
if [[ -e "$LOCALTIME" ]]; then
    current_tz=$(readlink -f "$LOCALTIME" | sed 's@^/usr/share/zoneinfo/@@' || true)
fi
# Non-interactive helper: set NONINTERACTIVE=1 or pass -y/--yes to skip prompts
NONINTERACTIVE=${NONINTERACTIVE:-0}
while [[ ${1:-} ]]; do
    case "$1" in
        -y|--yes) NONINTERACTIVE=1; shift ;;
        *) break ;;
    esac
done
if [[ -n "$current_tz" ]]; then
    if [[ "$NONINTERACTIVE" -eq 1 ]]; then
        info "Current timezone: $current_tz (non-interactive mode: skipping change)"
    else
        read -r -p "Your current timezone is $current_tz. Do you want to change it? (y/n): " choice
        case "$choice" in
            [yY])
                new_tz=""
                # Show available timezones
                if command -v timedatectl >/dev/null 2>&1; then
                    echo "Available timezones (sample):"
                    timedatectl list-timezones | head -n 40
                else
                    if python3 -c 'import zoneinfo' >/dev/null 2>&1; then
                        python3 - <<'PY'
import zoneinfo, json
print('\n'.join(sorted(zoneinfo.available_timezones())))
PY
                    else
                        warn "Cannot list timezones (no timedatectl and python3 zoneinfo)."
                    fi
                fi

                # Keep asking until valid timezone is entered or user cancels
                while [[ -z "$new_tz" ]]; do
                    read -r -p "Enter the timezone you want to set (e.g., America/Los_Angeles): " new_tz
                    if [[ -z "$new_tz" ]]; then
                        info "No timezone entered. Skipping timezone change."
                        break
                    fi

                    # Validate timezone exists
                    if command -v timedatectl >/dev/null 2>&1; then
                        if ! timedatectl list-timezones | grep -qxF "$new_tz"; then
                            error "Timezone '$new_tz' not found in timedatectl list. Please try again."
                            new_tz=""
                            continue
                        fi
                    else
                        if [[ ! -f "/usr/share/zoneinfo/$new_tz" ]]; then
                            error "Timezone '/usr/share/zoneinfo/$new_tz' does not exist. Please try again."
                            new_tz=""
                            continue
                        fi
                    fi
                done

                if [[ -n "$new_tz" ]]; then
                    # Change timezone
                    if command -v timedatectl >/dev/null 2>&1; then
                        if run_as_root timedatectl set-timezone "$new_tz"; then
                            info "Timezone set to $new_tz via timedatectl"
                        else
                            error "Failed to set timezone $new_tz via timedatectl"
                            exit 1
                        fi
                    else
                        if run_as_root ln -sf "/usr/share/zoneinfo/$new_tz" "$LOCALTIME"; then
                            info "Timezone set to $new_tz"
                        else
                            error "Failed to set /etc/localtime to $new_tz"
                            exit 1
                        fi
                    fi
                fi
                ;;
            [nN])
                info "Timezone change skipped."
                ;;
            *)
                error "Invalid choice. Please answer 'y' or 'n'."
                exit 1
                ;;
        esac
    fi
fi
# Rest of the script remains the same...