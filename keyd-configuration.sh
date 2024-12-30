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

# Validate and set `mainMod`
mainMod="${mainMod:-mod4}" # Default to `mod4` if not set

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

# Function definitions for all steps (same as provided)

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
    echo -e "\nbind = $mainMod SHIFT, Tab, Switch xkb layout, exec, hyprctl switchxkblayout all next\n"
}

main
