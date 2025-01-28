#!/usr/bin/env bash

# Usage: run as user for setting Hyprland
# Usage: ./keyd-configuration.sh <path>
# 
# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system. The user must provide a single argument 
# that resolves to an absolute path ending with 'utono/rpd'.

set -uo pipefail
set -e

# Initialize logging
if [ ! -w "$(pwd)" ]; then
    LOGFILE="$HOME/keyd-configuration.log"
    echo "Using $LOGFILE for logging due to insufficient permissions in $(pwd)."
else
    LOGFILE="$(pwd)/keyd-configuration.log"
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

# Validate the input path
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

# Sync custom KBD keyboard layout
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

# Configure vconsole keymap
configure_vconsole_keymap() {
    local vconsole_conf="/etc/vconsole.conf"
    local backup_dir="$HOME/backups/etc"
    
    sudo mkdir -p "$backup_dir"

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

# Sync custom XKB keyboard layout
sync_xkb_layout() {
    local path="$1"
    local src="${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak"
    local dest="/usr/share/X11/xkb/symbols/"

    if [ -f "$src" ]; then
        sudo mkdir -p "$dest"
        sudo rsync -a --chown=root:root "$src" "$dest"
        log_message "INFO" "Synced $src -> $dest"
        post_sync_xkb_layout
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Execute Hyprland keyboard configuration commands
post_sync_xkb_layout() {
    if [ "$EUID" -eq 0 ]; then
        log_message "INFO" "Hyprland configuration must be run as the user, not root. Skipping."
        return
    fi

    echo "Do you want to apply Hyprland keyboard configuration? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        hyprctl keyword input:kb_variant "" && \
        hyprctl keyword input:kb_layout real_prog_dvorak && \
        log_message "INFO" "Hyprland keyboard configuration applied." || \
        log_message "ERROR" "Failed to apply Hyprland keyboard configuration."
    else
        log_message "INFO" "Hyprland keyboard configuration skipped by user."
    fi
}

# Configure Keyd service
configure_keyd_service() {
    local path="$1"

    if ! command -v keyd &> /dev/null; then
        for i in {1..5}; do
            sudo pacman -Sy --noconfirm keyd && break || sleep 5
        done
    fi

    sudo mkdir -p /etc/keyd
    sudo chmod 755 /etc/keyd

    local src="${path}/etc/keyd/default.conf"
    local dest="/etc/keyd/default.conf"

    if [ -f "$src" ]; then
        sudo ln -sf "$src" "$dest"
        log_message "INFO" "Linked $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi

    if ! systemctl is-enabled keyd &> /dev/null; then
        sudo systemctl enable keyd
        log_message "INFO" "Keyd service enabled"
    fi

    if ! systemctl is-active keyd &> /dev/null; then
        sudo systemctl start keyd
        log_message "INFO" "Keyd service started"
    fi
}

# Report summary
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

# Main logic
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
    configure_keyd_service "$rpd_path"

    report_summary
}

main "$@"
