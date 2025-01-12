#!/usr/bin/env bash

# Usage: run as user for setting Hyprland
# Usage: ./keyd-configuration.sh <path>
# 
# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system. The user must provide a single argument 
# that resolves to an absolute path ending with 'utono/rpd'.
# 
# The script performs the following steps:
# 1. Verifies that the provided path is valid and exists.
# 2. Synchronizes custom keyboard layouts for KBD and XKB.
# 3. Updates vconsole.conf with the specified configuration.
# 4. Configures and enables the Keyd service.
# 5. Optionally executes Hyprland keyboard configuration commands after syncing XKB layout.
# 
# Logs are stored in a writable directory, either in the current directory or in $HOME.

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
    local src="${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/rpd.map.gz"
    local dest="/usr/share/kbd/keymaps/i386/dvorak/"

    if [ -f "$src" ]; then
        sudo mkdir -p "$dest"
        sudo rsync -a --chown=root:root "$src" "$dest"
        log_message "INFO" "Synced $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Sync vconsole.conf
sync_vconsole_conf() {
    local path="$1"
    local src="${path}/etc/vconsole.conf"
    local dest="/etc/vconsole.conf"

    if [ -f "$src" ]; then
        sudo rm -f "$dest"
        log_message "INFO" "Removed existing $dest"
        sudo cp "$src" "$dest"
        log_message "INFO" "Copied $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Sync custom XKB keyboard layout
sync_xkb_layout() {
    local path="$1"
    local src="${path}/xkb/usr/share/X11/xkb/symbols/rpd"
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
        hyprctl keyword input:kb_layout rpd && \
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
    sync_vconsole_conf "$rpd_path"
    sync_xkb_layout "$rpd_path"
    configure_keyd_service "$rpd_path"

    report_summary
}

main "$@"
