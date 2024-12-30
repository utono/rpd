#!/usr/bin/env bash

# This script sets up and synchronizes keyboard layouts, configuration files, 
# and services for an Arch Linux system.

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

    if [ -f "$src" ]; then
        rsync -a --chown=root:root "$src" "$dest" && log_message "INFO" "Synced $src -> $dest" || log_message "ERROR" "Failed to sync $src -> $dest"
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

# Add custom layout to evdev.xml
add_custom_layout_to_evdev() {
    local layout_name="real_prog_dvorak"
    local short_desc="RPD"
    local desc="Real Programmer's Dvorak"
    local evdev_path="/usr/share/X11/xkb/rules/evdev.xml"

    if [ -f "$evdev_path" ]; then
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
            log_message "INFO" "Added $layout_name to $evdev_path"
        else
            log_message "SKIPPED" "$layout_name already exists in $evdev_path."
        fi
    else
        log_message "ERROR" "$evdev_path does not exist."
    fi
}

# Update /usr/share/X11/xkb/rules/base.lst
update_base_lst() {
    local layout_name="real_prog_dvorak"
    local base_lst_path="/usr/share/X11/xkb/rules/base.lst"

    if [ -f "$base_lst_path" ]; then
        backup_file "$base_lst_path"
        if ! grep -q "$layout_name" "$base_lst_path"; then
            sed -i "/! layout/a \  $layout_name\t\tReal Programmer's Dvorak" "$base_lst_path" && log_message "INFO" "Added $layout_name to $base_lst_path" || log_message "ERROR" "Failed to add $layout_name to $base_lst_path."
        else
            log_message "SKIPPED" "$layout_name already exists in $base_lst_path."
        fi
    else
        log_message "ERROR" "$base_lst_path does not exist."
    fi
}

# Add custom layout to base.xml
add_custom_layout_to_base_xml() {
    local layout_name="real_prog_dvorak"
    local short_desc="RPD"
    local desc="Real Programmer's Dvorak"
    local base_xml_path="/usr/share/X11/xkb/rules/base.xml"

    if [ -f "$base_xml_path" ]; then
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
            log_message "INFO" "Added $layout_name to $base_xml_path"
        else
            log_message "SKIPPED" "$layout_name already exists in $base_xml_path."
        fi
    else
        log_message "ERROR" "$base_xml_path does not exist."
    fi
}

# Configure Wayland keyboard layout using localectl
configure_wayland_keyboard() {
    local layout="real_prog_dvorak"
    local variant=""
    local model="pc105"

    if command -v localectl &> /dev/null; then
        if localectl set-keymap --no-convert "$layout" "$model" "$variant"; then
            log_message "INFO" "Wayland keyboard layout configured: layout=$layout, model=$model, variant=$variant"
        else
            log_message "ERROR" "Failed to configure Wayland keyboard layout."
        fi
    else
        log_message "ERROR" "localectl is not installed."
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

    local rpd_path="$1"
    validate_path "$rpd_path"

    sync_kbd_keymap "$rpd_path"
    sync_vconsole_conf "$rpd_path"
    sync_xkb_layout "$rpd_path"
    # add_custom_layout_to_evdev
    # update_base_lst
    # add_custom_layout_to_base_xml
    # configure_wayland_keyboard
    configure_keyd_service "$rpd_path"

    report_summary
}

main "$@"

# # Sync Xorg configuration
# sync_xorg_conf() {
#     local path="$1"
#
#     if [ ! -d /etc/X11/xorg.conf.d ]; then
#         echo "The directory /etc/X11/xorg.conf.d does not exist. Please install xorg-xserver."
#         return
#     fi
#
#     if [ -d "${path}/xorg.conf.d/etc/X11/xorg.conf.d" ]; then
#         rsync -a --chown=root:root "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" /etc/X11/xorg.conf.d/ || log_rsync_failure "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
#         log_rsync "${path}/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
#     else
#         echo "[SKIPPED] Xorg configuration source directory does not exist."
#     fi
# }

