#!/usr/bin/env bash

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

# Ensure a full path to the rpd directory is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <rpd_directory_path>"
    exit 1
fi

rpd_path="$1"

# Validate the provided rpd directory path
if [ ! -d "$rpd_path" ]; then
    echo "The provided path does not exist or is not a directory: $rpd_path"
    exit 1
fi

# Validate required subdirectories in the rpd directory
required_subdirs=("xorg.conf.d" "xkb" "kbd" "etc")
for subdir in "${required_subdirs[@]}"; do
    if [ ! -d "$rpd_path/$subdir" ]; then
        echo "Missing required subdirectory: $subdir in $rpd_path"
        exit 1
    fi
done

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
    if [ -d "$rpd_path/xorg.conf.d/etc/X11/xorg.conf.d" ]; then
        rsync -av --chown=root:root "$rpd_path/xorg.conf.d/etc/X11/xorg.conf.d/" /etc/X11/xorg.conf.d/
        if [ $? -eq 0 ]; then
            log_rsync "$rpd_path/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
        else
            log_rsync_failure "$rpd_path/xorg.conf.d/etc/X11/xorg.conf.d/" "/etc/X11/xorg.conf.d/"
            FAILED_COMMANDS+=("rsync Xorg configuration")
        fi
    else
        echo "[SKIPPED] Xorg configuration source directory does not exist."
    fi
}

# Function to sync custom XKB keyboard layout
sync_xkb_layout() {
    if [ -f "$rpd_path/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" ]; then
        rsync -av --chown=root:root "$rpd_path/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" /usr/share/X11/xkb/symbols/
        if [ $? -eq 0 ]; then
            log_rsync "$rpd_path/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
        else
            log_rsync_failure "$rpd_path/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak" "/usr/share/X11/xkb/symbols/"
            FAILED_COMMANDS+=("rsync real_prog_dvorak")
        fi
    else
        echo "[SKIPPED] real_prog_dvorak source file does not exist."
    fi
}

# Function to sync custom KBD keyboard layout
sync_kbd_keymap() {
    if [ -f "$rpd_path/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" ]; then
        rsync -av --chown=root:root "$rpd_path/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" /usr/share/kbd/keymaps/i386/dvorak/
        if [ $? -eq 0 ]; then
            log_rsync "$rpd_path/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
        else
            log_rsync_failure "$rpd_path/kbd/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz" "/usr/share/kbd/keymaps/i386/dvorak/"
            FAILED_COMMANDS+=("rsync real_prog_dvorak.map.gz")
        fi
    else
        echo "[SKIPPED] real_prog_dvorak.map.gz source file does not exist."
    fi
}

# Function to sync vconsole.conf
sync_vconsole_conf() {
    if [ -f "$rpd_path/etc/vconsole.conf" ]; then
        rsync -av --chown=root:root "$rpd_path/etc/vconsole.conf" /etc/vconsole.conf
        if [ $? -eq 0 ]; then
            log_rsync "$rpd_path/etc/vconsole.conf" "/etc/vconsole.conf"
        else
            log_rsync_failure "$rpd_path/etc/vconsole.conf" "/etc/vconsole.conf"
            FAILED_COMMANDS+=("rsync vconsole.conf")
        fi
    else
        echo "[SKIPPED] vconsole.conf source file does not exist."
    fi
}

# Function to configure keyd service
configure_keyd_service() {
    if ! command -v keyd &> /dev/null; then
        echo "Keyd is not installed. Installing..."
        pacman -Sy --noconfirm keyd || FAILED_COMMANDS+=("install keyd")
    fi

    mkdir -p /etc/keyd || FAILED_COMMANDS+=("mkdir /etc/keyd")
    chmod 755 /etc/keyd

    if [[ -f "$rpd_path/etc/keyd/default.conf" ]]; then
        ln -sf "$rpd_path/etc/keyd/default.conf" /etc/keyd/default.conf || FAILED_COMMANDS+=("symlink keyd config")
    else
        echo "Keyd configuration file not found: $rpd_path/etc/keyd/default.conf"
        FAILED_COMMANDS+=("missing keyd config")
    fi

    systemctl enable keyd || FAILED_COMMANDS+=("enable keyd")
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
    sync_xorg_conf "$rpd_path"
    sync_xkb_layout "$rpd_path"
    add_custom_layout_to_evdev
    update_base_lst
    add_custom_layout_to_base_xml
    sync_kbd_keymap "$rpd_path"
    sync_vconsole_conf "$rpd_path"
    configure_keyd_service "$rpd_path"
    report_rsync_operations
    report_failures

    # Instruction for Hyprland configuration
    echo -e "\n[INFO] To activate the custom layout in Hyprland, create the file ~/.config/hypr/config/user-config.conf with the following content:"
    echo -e "\ninput {"
    echo -e "    kb_layout = us,real_prog_dvorak"
    echo -e "    kb_options = grp:alt_shift_toggle"
    echo -e "}\n"
    echo -e "Set 'kb_layout = us,real_prog_dvorak' if you want Hyprland to use the 'us' layout for binds."
    echo -e "Even when 'real_prog_dvorak' is the active layout, the binds will function as if the active layout is 'us'."
    echo -e "\nOnce configured, you can use the following command to switch between 'us' and 'real_prog_dvorak' layouts:"
    echo -e "\nhyprctl switchxblayout all next\n"
    echo -e "Additionally, it is recommended to add the following keybind to your keybinds.conf to make layout switching easier:"
    echo -e "\nbind = mainMod SHIFT, Tab, Switch xkb layout, exec, hyprctl switchxkblayout all next\n"
}

main

main
