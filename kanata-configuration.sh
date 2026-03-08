#!/usr/bin/env bash

# Usage: ./kanata-configuration.sh <path>
#
# Sets up keyboard layouts and kanata remapping daemon for Arch Linux.
# The user must provide a single argument resolving to an absolute path
# ending with 'utono/rpd'.
#
# Operations:
# - rsync KBD keymap to /usr/share/kbd/keymaps/i386/dvorak/
# - Update /etc/vconsole.conf with KEYMAP=real_prog_dvorak
# - rsync XKB layout to /usr/share/X11/xkb/symbols/
# - Stop and disable keyd if running (sunset)
# - Symlink /etc/kanata/kanata.kbd → repo file
# - Install kanata.service to /etc/systemd/system/
# - Enable and start kanata service

set -uo pipefail
set -e

# Initialize logging
if [ ! -w "$(pwd)" ]; then
    LOGFILE="$HOME/kanata-configuration.log"
    echo "Using $LOGFILE for logging due to insufficient permissions in $(pwd)."
else
    LOGFILE="$(pwd)/kanata-configuration.log"
fi
exec > >(tee -a "$LOGFILE") 2>&1

log_message() {
    local level="$1"
    local message="$2"
    echo "[$level] $message" | tee -a "$LOGFILE"
}

echo "Starting script at $(date)"

# Prompt for sudo password upfront
if [ "$EUID" -ne 0 ]; then
    sudo -v || { echo "sudo privileges are required."; exit 1; }
fi

validate_path() {
    local path="$1"
    if [[ ! "$path" =~ .*/utono/rpd$ ]]; then
        echo "Invalid path. The argument must match the pattern */utono/rpd."
        exit 1
    fi
    if [ ! -d "$path" ]; then
        echo "The directory does not exist: $path"
        exit 1
    fi
    echo "Path validation successful: $path"
}

sync_kbd_keymap() {
    local path="$1"
    local src="${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz"
    local dest="/usr/share/kbd/keymaps/i386/dvorak/"
    if [ -f "$src" ]; then
        sudo mkdir -p "$dest"
        sudo rsync -a --chown=root:root "$src" "$dest"
        log_message "INFO" "Synced $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

configure_vconsole_keymap() {
    local vconsole_conf="/etc/vconsole.conf"
    local backup_dir="$HOME/backups/etc"
    mkdir -p "$backup_dir"
    if [ -f "$vconsole_conf" ]; then
        sudo cp "$vconsole_conf" "$backup_dir/vconsole.conf"
        log_message "INFO" "Backed up existing vconsole.conf to $backup_dir/vconsole.conf"
    else
        log_message "INFO" "No existing vconsole.conf found to back up."
    fi
    sudo tee "$vconsole_conf" > /dev/null <<EOF
# Written by systemd-localed(8) or systemd-firstboot(1), read by systemd-localed
# and systemd-vconsole-setup(8). Use localectl(1) to update this file.
KEYMAP=real_prog_dvorak
EOF
    log_message "INFO" "Updated vconsole.conf with KEYMAP=real_prog_dvorak"
}

sync_xkb_layout() {
    local path="$1"
    local src="${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak"
    local dest="/usr/share/X11/xkb/symbols/"
    if [ -f "$src" ]; then
        sudo mkdir -p "$dest"
        sudo rsync -a --chown=root:root "$src" "$dest"
        log_message "INFO" "Synced $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}


sunset_keyd() {
    if systemctl is-active keyd &> /dev/null; then
        sudo systemctl stop keyd
        log_message "INFO" "Stopped keyd service"
    fi
    if systemctl is-enabled keyd &> /dev/null; then
        sudo systemctl disable keyd
        log_message "INFO" "Disabled keyd service"
    fi
}

configure_kanata_service() {
    local path="$1"

    if ! command -v kanata &> /dev/null; then
        log_message "INFO" "Installing kanata..."
        paru -S --noconfirm kanata || { log_message "ERROR" "Failed to install kanata"; exit 1; }
    fi

    sudo mkdir -p /etc/kanata
    sudo chmod 755 /etc/kanata

    local src="${path}/etc/kanata/kanata.kbd"
    local dest="/etc/kanata/kanata.kbd"
    if [ -f "$src" ]; then
        sudo ln -sf "$src" "$dest"
        log_message "INFO" "Linked $src -> $dest"
    else
        log_message "ERROR" "$src does not exist."
        exit 1
    fi

    local service_src="${path}/etc/kanata/kanata.service"
    local service_dest="/etc/systemd/system/kanata.service"
    if [ -f "$service_src" ]; then
        sudo cp "$service_src" "$service_dest"
        sudo systemctl daemon-reload
        log_message "INFO" "Installed kanata.service to $service_dest"
    else
        log_message "ERROR" "$service_src does not exist."
        exit 1
    fi

    if ! systemctl is-enabled kanata &> /dev/null; then
        sudo systemctl enable kanata
        log_message "INFO" "Kanata service enabled"
    fi

    if ! systemctl is-active kanata &> /dev/null; then
        sudo systemctl start kanata
        log_message "INFO" "Kanata service started"
    fi
}

report_summary() {
    echo "Script completed at $(date)"
    echo "The script has completed. For detailed logs, refer to the file: $LOGFILE"
    echo
    echo "IMPORTANT: You may need to regenerate your initramfs for the new vconsole settings to take effect during early boot."
    echo "Run the following command as root:"
    echo "  sudo mkinitcpio -P"
    echo
    echo "This ensures that the updated keyboard layout is available during the initramfs stage, especially if your system prompts for a password during boot (e.g., for LUKS encryption)."
}

main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <rpd_path>"
        exit 1
    fi

    local rpd_path="$1"
    validate_path "$rpd_path"

    sync_kbd_keymap "$rpd_path"
    configure_vconsole_keymap
    sync_xkb_layout "$rpd_path"
    sunset_keyd
    configure_kanata_service "$rpd_path"

    report_summary
}

main "$@"
