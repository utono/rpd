# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RPD (Real Programmers Dvorak) is a keyboard configuration repository for Arch Linux. It provides a custom Dvorak layout optimized for programming, deployed across multiple input layers: TTY console (KBD), X11/Wayland (XKB), and a key remapping daemon (keyd).

## Architecture

The system operates in layers that work together:

- **XKB layout** (`xkb/.../real_prog_dvorak`) defines the base Dvorak symbol mapping — number row has programming symbols (`$+[{(&=)}]*!|#`), letters follow Dvorak positioning
- **KBD keymap** (`kbd/.../real_prog_dvorak.map.gz`) provides the same layout for TTY/virtual consoles
- **Keyd config** (`etc/keyd/default.conf`) adds modifier behavior on top of the layout — home row mods, capslock overload, plain mode toggle
- **vconsole.conf** (`etc/vconsole.conf`) tells systemd to use the RPD keymap at boot

### Keyd Layer Design

The keyd config (`etc/keyd/default.conf`) has two layers:

- **main**: Home row keys double as modifiers when held (a=shift, s=control, d=alt, f=meta on left; j=meta, k=alt, l=control, ;=shift on right). Capslock = tap for esc, hold for meta. Space = hold for meta. Insert toggles plain mode.
- **plain**: Disables all home row mods, restoring normal typing. Capslock overload is preserved.

The `lettermod(modifier, key, 100, 200)` parameters are tap/hold timing thresholds in milliseconds.

## Deployment

The single setup script handles everything:

```bash
./keyd-configuration.sh ~/utono/rpd
```

This requires sudo and performs: KBD keymap copy, vconsole.conf update, XKB layout copy, keyd symlink creation (`/etc/keyd/default.conf` → source), keyd service enable/start. Optionally applies Hyprland config interactively.

After running, `sudo mkinitcpio -P` is recommended for early-boot keymap availability (LUKS).

### Manual keyd operations

```bash
# Reload after editing default.conf
sudo keyd reload

# Check keyd is running
sudo systemctl status keyd

# Monitor key events for debugging
sudo keyd monitor
```

## Key File Map

| Source in repo | Deployed to | Method |
|---|---|---|
| `etc/keyd/default.conf` | `/etc/keyd/default.conf` | symlink |
| `kbd/.../real_prog_dvorak.map.gz` | `/usr/share/kbd/keymaps/i386/dvorak/` | rsync copy |
| `xkb/.../real_prog_dvorak` | `/usr/share/X11/xkb/symbols/` | rsync copy |
| `etc/vconsole.conf` | `/etc/vconsole.conf` | overwrite via tee |
| `xorg.conf.d/.../00-keyboard.conf` | `/etc/X11/xorg.conf.d/` | manual copy (X11 only) |

## Hyprland Integration

The XKB layout works with Hyprland once copied to `/usr/share/X11/xkb/symbols/`. No modifications to evdev.xml or base.lst are needed. Configuration goes in Hyprland's input section:

```
input {
    kb_layout = us,real_prog_dvorak
    kb_options = grp:alt_shift_toggle
}
```

Toggle layouts with: `hyprctl switchxkblayout all next`
