#!/usr/bin/env bash

# Usage: ./keyd-configuration.sh <path>
# 
# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system. The user must provide a single argument 
# that resolves to an absolute path ending with 'utono/rpd'.
# 
# The script performs the following steps:
# 1. Validates that required dependencies (rsync, pacman, localectl, systemctl) are installed.
# 2. Verifies that the provided path is valid and exists.
# 3. Synchronizes custom keyboard layouts for KBD and XKB.
# 4. Updates vconsole.conf with the specified configuration.
# 5. Configures and enables the Keyd service.
# 
# Logs are stored in the file 'keyd-configuration.log' in the current directory.

set -uo pipefail

# Initialize logging
LOGFILE="$(pwd)/keyd-configuration.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Starting script at $(date)"

# Validate required dependencies
validate_dependencies() {
    local required_tools=("rsync" "pacman" "localectl" "systemctl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Required tool '$tool' is missing. Install it and re-run the script."
            exit 1
        fi
    done
}

# Validate the input path
validate_path() {
    local path="$1"
    local expanded_path

    # Resolve the absolute path
    expanded_path=$(realpath "$path") || {
        echo "Failed to resolve path: $path"
        exit 1
    }

    if [[ ! "$expanded_path" =~ .*/utono/rpd$ ]]; then
        echo "Invalid path. The argument must expand to a path ending with */utono/rpd."
        exit 1
    fi

    if [ ! -d "$expanded_path" ]; then
        echo "The directory does not exist: $expanded_path"
        exit 1
    fi

    echo "Path validation successful: $expanded_path"
    echo "$expanded_path"
}

# Backup a file with a timestamp and unique identifier
backup_file() {
    local src="$1"
    local dest="${1}.bak.$(date +%Y%m%d%H%M%S)_$$"
    if cp "$src" "$dest"; then
        echo "Backup created: $src -> $dest" >> "$LOGFILE"
    else
        echo "Failed to back up $src" >> "$LOGFILE"
    fi
}

# Log messages with a consistent format
log_message() {
    local level="$1"
    local message="$2"
    echo "[$level] $message" | tee -a "$LOGFILE"
}

# Sync custom KBD keyboard layout
sync_kbd_keymap() {
    local path="$1"
    local src="${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz"
    local dest="/usr/share/kbd/keymaps/i386/dvorak/"

    echo "Debug: Checking source file for KBD layout: $src"
    ls -l "$src" || echo "Debug: Unable to list file details for $src"

    if [ -f "$src" ]; then
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz"
    local dest="/usr/share/kbd/keymaps/i386/dvorak/"

    if [ -f "$src" ]; then
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
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
        backup_file "$dest"
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Sync custom XKB keyboard layout
sync_xkb_layout() {
    local path="$1"
    local src="${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak"
    local dest="/usr/share/X11/xkb/symbols/"

    mkdir -p "$dest"
    echo "Debug: Checking source file for XKB layout: $src"
    ls -l "$src" || echo "Debug: Unable to list file details for $src"

    if [ -f "$src" ]; then
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak"
    local dest="/usr/share/X11/xkb/symbols/"

    mkdir -p "$dest"
    if [ -f "$src" ]; then
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Configure Keyd service
configure_keyd_service() {
    local path="$1"

    if ! command -v keyd &> /dev/null; then
        for i in {1..5}; do
            pacman -Sy --noconfirm keyd && break || sleep 5
        done
    fi

    mkdir -p /etc/keyd
    chmod 755 /etc/keyd

    local src="${path}/etc/keyd/default.conf"
    local dest="/etc/keyd/default.conf"

    if [ -f "$src" ]; then
        ln -sf "$src" "$dest" && log_message "INFO" "Linked $src -> $dest" || log_message "ERROR" "Failed to link $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi

    if ! systemctl is-enabled keyd &> /dev/null; then
        systemctl enable keyd && log_message "INFO" "Keyd service enabled" || log_message "ERROR" "Failed to enable Keyd service."
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

    validate_dependencies

    local rpd_path
    rpd_path=$(validate_path "$1")

    sync_kbd_keymap "$rpd_path"
    sync_vconsole_conf "$rpd_path"
    sync_xkb_layout "$rpd_path"
    configure_keyd_service "$rpd_path"

    report_summary
}

main "$@"
