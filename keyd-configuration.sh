#!/usr/bin/env bash

# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system.

set -uo pipefail

# Initialize logging
LOGFILE="$(pwd)/keyd-configuration.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Starting script at $(date)"

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

# Backup a file with a timestamp
backup_file() {
    local src="$1"
    local dest="${1}.bak.$(date +%Y%m%d%H%M%S)"
    if cp "$src" "$dest"; then
        echo "Backup created: $src -> $dest" >> "$LOGFILE"
    else
        echo "Failed to back up $src" >> "$LOGFILE"
    fi
}

# Rsync operation logging
log_rsync() {
    local src="$1"
    local dest="$2"
    echo "Synced: $src -> $dest"
}

log_rsync_failure() {
    local src="$1"
    local dest="$2"
    echo "FAILED: $src -> $dest"
}

# Sync Xorg configuration
sync_xorg_conf() {
    local path="$1"

    if [ ! -d /etc/X11/xorg.conf.d ]; then
        echo "The directory /etc/X11/xorg.conf.d does not exist. Please install xorg-xserver."
        return
    fi

    if [ -d "${path}/xorg.conf.d/etc/X11/xorg.conf.d" ]; then
        rsync -av --chown=root:root "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" /etc/X11/xorg.conf.d/ || log_rsync_failure "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
        log_rsync "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
    else
        echo "[SKIPPED] Xorg configuration source directory does not exist."
    fi
}

# Sync custom XKB keyboard layout
sync_xkb_layout() {
    local path="$1"

    backup_file "/usr/share/X11/xkb/rules/evdev.xml" # Backup before making changes

    if [ -f "${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" ]; then
        rsync -av --chown=root:root "${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" /usr/share/X11/xkb/symbols/ || log_rsync_failure "${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
        log_rsync "${path}/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
    else
        echo "[SKIPPED] real_prog_dvorak source file does not exist."
    fi
}

# Add custom layout to evdev.xml
add_custom_layout_to_evdev() {
    local layout_name="real_prog_dvorak"
    local short_desc="RPD"
    local desc="Real Programmer's Dvorak"
    local evdev_path="/usr/share/X11/xkb/rules/evdev.xml"

    backup_file "$evdev_path"

    if ! grep -q "<name>${layout_name}</name>" "$evdev_path"; then
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
    fi
}

# Update /usr/share/X11/xkb/rules/base.lst
update_base_lst() {
    local layout_name="real_prog_dvorak"
    local base_lst_path="/usr/share/X11/xkb/rules/base.lst"

    backup_file "$base_lst_path"

    if ! grep -q "$layout_name" "$base_lst_path"; then
        sed -i "/! layout/a \  $layout_name\t\tReal Programmer's Dvorak" "$base_lst_path"
    fi
}

# Add custom layout to base.xml
add_custom_layout_to_base_xml() {
    local layout_name="real_prog_dvorak"
    local short_desc="RPD"
    local desc="Real Programmer's Dvorak"
    local base_xml_path="/usr/share/X11/xkb/rules/base.xml"

    backup_file "$base_xml_path"

    if ! grep -q "<name>${layout_name}</name>" "$base_xml_path"; then
        sed -i "/<layoutList>/a \        <layout>\
            <configItem>\
                <name>${layout_name}</name>\
                <shortDescription>${short_desc}</shortDescription>\
                <description>${desc}</description>\
                <languageList>\
                    <iso639Id>eng</iso639Id>\
                </languageList>\
            </configItem>\
        </layout>" "$base_xml_path"
    fi
}

# Sync custom KBD keyboard layout
sync_kbd_keymap() {
    local path="$1"

    if [ -f "${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" ]; then
        rsync -av --chown=root:root "${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" /usr/share/kbd/keymaps/i386/dvorak/ || log_rsync_failure "${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
        log_rsync "${path}/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
    else
        echo "[SKIPPED] real_prog_dvorak.map.gz source file does not exist."
    fi
}

# Sync vconsole.conf
sync_vconsole_conf() {
    local path="$1"

    if [ -f "${path}/etc/vconsole.conf" ]; then
        backup_file "/etc/vconsole.conf"
        rsync -av --chown=root:root "${path}/etc/vconsole.conf" /etc/vconsole.conf || log_rsync_failure "${path}/etc/vconsole.conf" "/etc/vconsole.conf"
        log_rsync "${path}/etc/vconsole.conf" "/etc/vconsole.conf"
    else
        echo "[SKIPPED] vconsole.conf source file does not exist."
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

    if [ -f "${path}/etc/keyd/default.conf" ]; then
        ln -sf "${path}/etc/keyd/default.conf" /etc/keyd/default.conf
    fi

    if ! systemctl is-enabled keyd &> /dev/null; then
        systemctl enable keyd
    fi
}

# Report summary
report_summary() {
    echo "Script completed at $(date)"
    echo "The script has completed. For detailed logs, refer to the file: $LOGFILE"
    echo "For Hyprland keyboard configuration, refer to the file: hyprland-keyboard-configuration.rst"
}

# Main logic
main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <rpd_path>"
        exit 1
    fi

    local rpd_path="$1"
    validate_path "$rpd_path"

    sync_xorg_conf "$rpd_path"
    sync_xkb_layout "$rpd_path"
    add_custom_layout_to_evdev
    update_base_lst
    add_custom_layout_to_base_xml
    sync_kbd_keymap "$rpd_path"
    sync_vconsole_conf "$rpd_path"
    configure_keyd_service "$rpd_path"

    report_summary
}

main "$@"
