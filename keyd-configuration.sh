#!/usr/bin/env bash
# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system. It automates the following tasks:
#
# 1. Ensures the script is run with root privileges and required tools are installed.
# 2. Configures the keyd service:
#    - Installs keyd if missing.
#    - Links the keyd configuration file from the specified directory.
#    - Enables the keyd systemd service.
# 3. Synchronizes Xorg configuration files to /etc/X11/xorg.conf.d/.
# 4. Installs a custom XKB keyboard layout:
#    - Copies the layout file to the appropriate directory.
#    - Updates the evdev.xml file to register the new layout.
#    - Sets the custom layout as the default in /etc/environment.
# 5. Synchronizes a custom KBD keyboard layout to /usr/share/kbd/keymaps/.
# 6. Synchronizes the vconsole.conf file:
#    - Copies the configuration file from the source directory to /etc/vconsole.conf.
# 7. Logs rsync operations for all file synchronization steps and reports any failures.
#
# Usage:
#   ./script_name.sh <utono_directory_path>
#
# Arguments:
#   <utono_directory_path> - Path to the directory containing configuration files
#                            (e.g., keyd, Xorg, XKB, and KBD layouts).
#
# Requirements:
#   - Must be run as root.
#   - Requires the 'rsync' and 'keyd' utilities to be installed.
#   - Assumes a specific directory structure within the provided path.
#
# Notes:
#   - Backup operations are performed for evdev.xml and environment files before changes.
#   - The script attempts to recover from errors by logging failed operations.

set -uo pipefail

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Ensure required commands are available
if ! command -v rsync &> /dev/null; then
    echo "Required command (rsync) is missing. Install it and re-run the script."
    exit 1
fi

# Arrays to track failed commands and rsync operations
FAILED_COMMANDS=()
RSYNC_LOG=()

# Function to log rsync operations
log_rsync() {
    local src="$1"
    local dest="$2"
    RSYNC_LOG+=("Synced: $src -> $dest")
}

# Function to log rsync failures
log_rsync_failure() {
    local src="$1"
    local dest="$2"
    RSYNC_LOG+=("FAILED: $src -> $dest")
}

# Function to sync Xorg configuration
sync_xorg_conf() {
    local utono_path="$1"

    if [ ! -d /etc/X11/xorg.conf.d ]; then
        echo "The directory /etc/X11/xorg.conf.d does not exist. Please install xorg-xserver so that all necessary directories are created."
        FAILED_COMMANDS+=("check /etc/X11/xorg.conf.d existence")
        return
    fi

    if [ -d "${utono_path}/rpd/xorg.conf.d/etc/X11/xorg.conf.d" ]; then
        rsync -av --chown=root:root "${utono_path}/rpd/xorg.conf.d/etc/X11/xorg.conf.d/" /etc/X11/xorg.conf.d/
        if [ $? -eq 0 ]; then
            log_rsync "${utono_path}/rpd/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
        else
            log_rsync_failure "${utono_path}/rpd/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
            FAILED_COMMANDS+=("rsync Xorg configuration")
        fi
    else
        echo "[SKIPPED] Xorg configuration source directory does not exist."
    fi
}

# Function to sync custom XKB keyboard layout
sync_xkb_layout() {
    local utono_path="$1"

    if [ -f "${utono_path}/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" ]; then
        rsync -av --chown=root:root "${utono_path}/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" /usr/share/X11/xkb/symbols/
        if [ $? -eq 0 ]; then
            log_rsync "${utono_path}/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
        else
            log_rsync_failure "${utono_path}/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
            FAILED_COMMANDS+=("rsync real_prog_dvorak")
        fi
    else
        echo "[SKIPPED] real_prog_dvorak source file does not exist."
    fi
}

# Function to add custom layout to evdev.xml
add_custom_layout_to_evdev() {
    local layout_name="real_prog_dvorak"
    local short_desc="RPD"
    local desc="Real Programmer's Dvorak"
    local evdev_path="/usr/share/X11/xkb/rules/evdev.xml"
    local env_file="/etc/environment"

    if [ -f "$evdev_path" ]; then
        cp "$evdev_path" "${evdev_path}.bak" || FAILED_COMMANDS+=("backup evdev.xml")
    fi

    if ! grep -q "<name>${layout_name}</name>" "$evdev_path"; then
        echo "Adding custom layout '${layout_name}' to ${evdev_path}..."
        sed -i "/<layoutList>/a \        <layout>\
            <configItem>\
                <name>${layout_name}</name>\
                <shortDescription>${short_desc}</shortDescription>\
                <description>${desc}</description>\
                <languageList>\
                    <iso639Id>eng</iso639Id>\
                </languageList>\
            </configItem>\
        </layout>" "$evdev_path"
        if [ $? -ne 0 ]; then
            FAILED_COMMANDS+=("add_custom_layout_to_evdev")
        fi
    else
        echo "Custom layout '${layout_name}' is already present in ${evdev_path}."
    fi

    if [ -f "$env_file" ]; then
        cp "$env_file" "${env_file}.bak" || FAILED_COMMANDS+=("backup environment file")
    fi

    if ! grep -q "XKB_DEFAULT_LAYOUT=${layout_name}" "$env_file"; then
        echo "Adding 'XKB_DEFAULT_LAYOUT=${layout_name}' to ${env_file}..."
        echo "XKB_DEFAULT_LAYOUT=${layout_name}" >> "$env_file"
        if [ $? -ne 0 ]; then
            FAILED_COMMANDS+=("add_XKB_DEFAULT_LAYOUT_to_environment")
        fi
    else
        echo "'XKB_DEFAULT_LAYOUT=${layout_name}' is already present in ${env_file}."
    fi
}

# Function to sync custom KBD keyboard layout
sync_kbd_keymap() {
    local utono_path="$1"

    if [ -f "${utono_path}/rpd/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" ]; then
        rsync -av --chown=root:root "${utono_path}/rpd/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" /usr/share/kbd/keymaps/i386/dvorak/
        if [ $? -eq 0 ]; then
            log_rsync "${utono_path}/rpd/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
        else
            log_rsync_failure "${utono_path}/rpd/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
            FAILED_COMMANDS+=("rsync real_prog_dvorak.map.gz")
        fi
    else
        echo "[SKIPPED] real_prog_dvorak.map.gz source file does not exist."
    fi
}

# Function to sync vconsole.conf
sync_vconsole_conf() {
    local utono_path="$1"

    if [ -f "${utono_path}/rpd/etc/vconsole.conf" ]; then
        rsync -av --chown=root:root "${utono_path}/rpd/etc/vconsole.conf" /etc/vconsole.conf
        if [ $? -eq 0 ]; then
            log_rsync "${utono_path}/rpd/etc/vconsole.conf" "/etc/vconsole.conf"
        else
            log_rsync_failure "${utono_path}/rpd/etc/vconsole.conf" "/etc/vconsole.conf"
            FAILED_COMMANDS+=("rsync vconsole.conf")
        fi
    else
        echo "[SKIPPED] vconsole.conf source file does not exist."
    fi
}

# Function to configure keyd service
configure_keyd_service() {
    local utono_path="$1"

    # Check if keyd is installed, install it if missing
    if ! command -v keyd &> /dev/null; then
        echo "Keyd is not installed. Installing..."
        local installed=0
        for i in {1..5}; do
            echo "Attempt $i to install keyd..."
            if pacman -Sy --noconfirm keyd; then
                installed=1
                break
            else
                sleep 5
            fi
        done
        if [[ $installed -ne 1 ]]; then
            FAILED_COMMANDS+=("install keyd")
        fi
    fi

    # Create /etc/keyd directory if it does not exist
    mkdir -p /etc/keyd || FAILED_COMMANDS+=("mkdir /etc/keyd")
    chmod 755 /etc/keyd

    # Create symbolic link for keyd configuration file
    if [[ -f "${utono_path}/rpd/etc/keyd/default.conf" ]]; then
        ln -sf "${utono_path}/rpd/etc/keyd/default.conf" /etc/keyd/default.conf
        if [ $? -eq 0 ]; then
            log_rsync "Symlink created for ${utono_path}/rpd/etc/keyd/default.conf" "/etc/keyd/"
        else
            FAILED_COMMANDS+=("symlink keyd config")
        fi
    else
        echo "Keyd configuration file not found: ${utono_path}/rpd/etc/keyd/default.conf"
        FAILED_COMMANDS+=("missing keyd config")
    fi

    # Enable keyd service
    systemctl enable keyd
    if [ $? -ne 0 ]; then
        FAILED_COMMANDS+=("enable keyd")
    fi
}

# Report rsync operations
report_rsync_operations() {
    if [ ${#RSYNC_LOG[@]} -eq 0 ]; then
        echo "No rsync operations were performed."
    else
        echo "Rsync operations performed:"
        for operation in "${RSYNC_LOG[@]}"; do
            echo "- $operation"
        done
    fi
}

# Report any failures
report_failures() {
    if [ ${#FAILED_COMMANDS[@]} -ne 0 ]; then
        echo "The following commands failed:"
        for cmd in "${FAILED_COMMANDS[@]}"; do
            echo "- $cmd"
        done
        exit 1
    else
        echo "All commands completed successfully."
    fi
}

# Main script logic
main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <utono_directory_path>"
        exit 1
    fi

    local utono_path="$1"

    sync_xorg_conf "$utono_path"
    sync_xkb_layout "$utono_path"
    add_custom_layout_to_evdev
    sync_kbd_keymap "$utono_path"
    sync_vconsole_conf "$utono_path"
    configure_keyd_service "$utono_path"
    report_rsync_operations
    report_failures
}

main "$@"