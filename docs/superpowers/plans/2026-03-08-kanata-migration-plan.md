# Kanata Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace keyd with kanata as the keyboard remapping daemon for better home row mod behavior using `tap-hold-release`.

**Architecture:** Kanata config at `etc/kanata/kanata.kbd` with custom systemd service. Deployment script `kanata-configuration.sh` handles install, keyd sunset, symlink, and service management. Slash command `/rpd:kanata` replaces `/rpd:keyd`.

**Tech Stack:** Kanata (Rust), systemd, bash, S-expression config format

---

### Task 1: Create kanata.kbd config

**Files:**
- Create: `etc/kanata/kanata.kbd`

**Step 1: Create the kanata config file**

```lisp
(defcfg
  linux-dev /dev/input/by-path/platform-i8042-serio-0-event-kbd
  process-unmapped-keys yes
)

(defsrc
  caps a s d f j k l ; spc bksl ins
)

(defvar
  tap-time 200
  hold-time 200
  index-hold-time 150
)

(defalias
  ;; Capslock: tap=esc, hold=meta
  cec (tap-hold $tap-time $hold-time esc lmet)

  ;; Left home row mods
  a (tap-hold-release $tap-time $hold-time a lsft)
  s (tap-hold-release $tap-time $hold-time s lctl)
  d (tap-hold-release $tap-time $hold-time d lalt)
  f (tap-hold-release $tap-time $index-hold-time f lmet)

  ;; Right home row mods
  j (tap-hold-release $tap-time $index-hold-time j rmet)
  k (tap-hold-release $tap-time $hold-time k ralt)
  l (tap-hold-release $tap-time $hold-time l rctl)
  ; (tap-hold-release $tap-time $hold-time ; rsft)

  ;; Thumb/other
  spc (tap-hold-release $tap-time $hold-time spc lmet)
  bksl (tap-hold-release $tap-time $hold-time bksl lmet)
)

(deflayer default
  @cec @a @s @d @f @j @k @l @; @spc @bksl (layer-switch plain)
)

(deflayer plain
  @cec a s d f j k l ; spc bksl (layer-switch default)
)
```

**Step 2: Validate config syntax**

Run: `kanata --check -c etc/kanata/kanata.kbd` (if kanata is installed)
Expected: No errors. If kanata isn't installed yet, defer validation to Task 4.

**Step 3: Commit**

```bash
git add etc/kanata/kanata.kbd
git commit -m "feat: add kanata config with tap-hold-release home row mods"
```

---

### Task 2: Create systemd service file

**Files:**
- Create: `etc/kanata/kanata.service`

**Step 1: Create the service file**

```ini
[Unit]
Description=Kanata keyboard remapper
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/kanata -c /etc/kanata/kanata.kbd
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

**Step 2: Commit**

```bash
git add etc/kanata/kanata.service
git commit -m "feat: add custom kanata systemd service file"
```

---

### Task 3: Create kanata-configuration.sh

**Files:**
- Create: `kanata-configuration.sh`
- Reference: `keyd-configuration.sh` (for structure, do not modify)

**Step 1: Write the deployment script**

The script follows the same structure as `keyd-configuration.sh` but replaces keyd functions with kanata equivalents:

- `validate_path()` — same, validates `*/utono/rpd` path
- `sync_kbd_keymap()` — same, copies KBD keymap
- `configure_vconsole_keymap()` — same, updates vconsole.conf
- `sync_xkb_layout()` — same, copies XKB layout + optional Hyprland config
- `sunset_keyd()` — NEW: stops and disables keyd if running
- `configure_kanata_service()` — NEW: replaces `configure_keyd_service()`
  1. Install kanata via `paru -S --noconfirm kanata` if not present
  2. Create `/etc/kanata/` directory
  3. Symlink `/etc/kanata/kanata.kbd` → repo file
  4. Copy `etc/kanata/kanata.service` to `/etc/systemd/system/kanata.service`
  5. `systemctl daemon-reload`
  6. Enable and start kanata service

```bash
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
        post_sync_xkb_layout
    else
        log_message "SKIPPED" "$src does not exist."
    fi
}

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
```

**Step 2: Make executable**

Run: `chmod +x kanata-configuration.sh`

**Step 3: Commit**

```bash
git add kanata-configuration.sh
git commit -m "feat: add kanata deployment script replacing keyd-configuration.sh"
```

---

### Task 4: Create /rpd:kanata slash command

**Files:**
- Create: `.claude/commands/rpd/kanata.md`
- Reference: `.claude/commands/rpd/keyd.md` (keep for now)

**Step 1: Write the slash command**

```markdown
---
name: kanata
description: Report and modify kanata tap-hold timeout values
argument-hint: report | set <var> <value>
---

# Kanata Settings

Manage tap-hold timeout variables in `etc/kanata/kanata.kbd`.

## Arguments: $ARGUMENTS

## Routing

Parse `$ARGUMENTS` and route:

- **No arguments (empty):** Show usage:
  ```
  Usage:
    /rpd:kanata report           - show tap-hold timeout values
    /rpd:kanata set <var> <value> - change a timeout variable

  Variables: tap-time, hold-time, index-hold-time
  ```

- **`report`:** Read `etc/kanata/kanata.kbd` from the repo root (`~/utono/rpd/etc/kanata/kanata.kbd`). Parse the `(defvar ...)` block. Display a markdown table:

  | Variable | Value (ms) |
  |----------|------------|

  Then show each alias with its tap-hold-release parameters.

  After the table, show usage:
  ```
  Usage:
    /rpd:kanata set <var> <value> - change a timeout variable

  Variables: tap-time, hold-time, index-hold-time
  ```

- **`set <var> <value>`:**
  1. Read `~/utono/rpd/etc/kanata/kanata.kbd`
  2. Find the variable in the `(defvar ...)` block matching `<var>` (one of: `tap-time`, `hold-time`, `index-hold-time`)
  3. Replace the value
  4. Write the updated file
  5. Run `sudo systemctl restart kanata`
  6. Show the updated defvar block to confirm the change

- **Anything else:** Show "Unknown subcommand" and print the usage block above.
```

**Step 2: Commit**

```bash
git add .claude/commands/rpd/kanata.md
git commit -m "feat: add /rpd:kanata slash command for timeout management"
```

---

### Task 5: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update Architecture section**

Replace keyd references with kanata:
- "Keyd config" → "Kanata config" with path `etc/kanata/kanata.kbd`
- "Keyd Layer Design" → "Kanata Layer Design"
- Update descriptions to reference `tap-hold-release` instead of `lettermod()`
- Update timing description to reference `defvar` block
- Replace `[ids]` device targeting description with `linux-dev` in `defcfg`

**Step 2: Update Deployment section**

- Script name: `kanata-configuration.sh`
- Remove `keyd symlink creation` reference, replace with `kanata symlink + service install`
- Update manual operations section:

```bash
# Restart after editing kanata.kbd
sudo systemctl restart kanata

# Check kanata is running
sudo systemctl status kanata

# Live reload (send SIGUSR1)
sudo killall -SIGUSR1 kanata

# Monitor key events for debugging
sudo kanata --check -c /etc/kanata/kanata.kbd
```

**Step 3: Update Key File Map**

Replace keyd row:
- `etc/kanata/kanata.kbd` | `/etc/kanata/kanata.kbd` | symlink
- `etc/kanata/kanata.service` | `/etc/systemd/system/kanata.service` | copy

**Step 4: Update Slash Commands section**

Replace keyd entries with:
- `/rpd:kanata report` — display tap-hold timeout values from `etc/kanata/kanata.kbd`
- `/rpd:kanata set <var> <value>` — change a timeout variable, then restart kanata

**Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md for kanata migration"
```

---

### Task 6: Validate and test

**Step 1: Install kanata if not already installed**

Run: `paru -S kanata`

**Step 2: Validate kanata config syntax**

Run: `kanata --check -c etc/kanata/kanata.kbd`
Expected: No syntax errors

**Step 3: Dry-run the deployment script**

Review the script logic manually — do NOT run it yet as it will disable keyd and start kanata, which changes the active keyboard behavior.

**Step 4: Commit any fixes**

If validation revealed issues, fix and commit.

---

### Task 7: Deploy (manual, user-initiated)

**This task is performed by the user, not automated.**

**Step 1: Run the deployment script**

```bash
./kanata-configuration.sh ~/utono/rpd
```

**Step 2: Verify kanata is running**

```bash
sudo systemctl status kanata
```

**Step 3: Test keyboard behavior**

- Type normally — no accidental modifiers on f/j
- Hold f — should produce meta
- Tap capslock — should produce esc
- Hold capslock — should produce meta
- Press Insert — should toggle to plain layer
- Press Insert again — should toggle back

**Step 4: If issues, rollback**

```bash
sudo systemctl stop kanata
sudo systemctl disable kanata
sudo systemctl enable keyd
sudo systemctl start keyd
```
