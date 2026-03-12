# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RPD (Real Programmers Dvorak) is a keyboard configuration repository for Arch Linux. It provides a custom Dvorak layout optimized for programming, deployed across multiple input layers: TTY console (KBD), X11/Wayland (XKB), and a key remapping daemon (kanata).

## Architecture

The system operates in layers that work together:

- **XKB layout** (`xkb/.../real_prog_dvorak`) defines the base Dvorak symbol mapping — number row has programming symbols (`$+[{(&=)}]*!|#`), letters follow Dvorak positioning
- **KBD keymap** (`kbd/.../real_prog_dvorak.map.gz`) provides the same layout for TTY/virtual consoles
- **Kanata config** (`etc/kanata/kanata.kbd`) adds modifier behavior on top of the layout — home row mods via `tap-hold-release`, capslock overload, plain mode toggle
- **vconsole.conf** (`etc/vconsole.conf`) tells systemd to use the RPD keymap at boot

### Kanata Layer Design

The kanata config (`etc/kanata/kanata.kbd`) has two layers:

- **default**: Home row keys double as modifiers when held using `tap-hold-release` (a=shift, s=control, d=alt, f=meta on left; j=meta, k=alt, l=control, ;=shift on right). Capslock = tap for esc, hold for meta. Space = hold for meta. Backslash = hold for meta. Insert toggles plain mode.
- **plain**: Disables all home row mods, restoring normal typing. Capslock overload is preserved.

Timing is controlled via `defvar`: `tap-time` (200ms), `hold-time` (200ms), and `index-hold-time` (150ms for f/j). The `tap-hold-release` algorithm only triggers a modifier when another key is pressed *and released* while holding, preventing accidental activation during fast typing.

Device targeting uses explicit paths in `defcfg` via `linux-dev`.

## Deployment

The single setup script handles everything:

```bash
./kanata-configuration.sh ~/utono/rpd
```

This requires sudo and performs: KBD keymap copy, vconsole.conf update, XKB layout copy, keyd sunset (stop/disable if running), kanata symlink creation (`/etc/kanata/kanata.kbd` → source), kanata service install/enable/start.

After running, `sudo mkinitcpio -P` is recommended for early-boot keymap availability (LUKS).

### Manual kanata operations

```bash
# Restart after editing kanata.kbd
sudo systemctl restart kanata

# Check kanata is running
sudo systemctl status kanata

# Validate config syntax
kanata --check -c etc/kanata/kanata.kbd
```

## Key File Map

| Source in repo | Deployed to | Method |
|---|---|---|
| `etc/kanata/kanata.kbd` | `/etc/kanata/kanata.kbd` | symlink |
| `etc/kanata/kanata.service` | `/etc/systemd/system/kanata.service` | copy |
| `kbd/.../real_prog_dvorak.map.gz` | `/usr/share/kbd/keymaps/i386/dvorak/` | rsync copy |
| `xkb/.../real_prog_dvorak` | `/usr/share/X11/xkb/symbols/` | rsync copy |
| `etc/vconsole.conf` | `/etc/vconsole.conf` | overwrite via tee |
| `xorg.conf.d/.../00-keyboard.conf` | `/etc/X11/xorg.conf.d/` | manual copy (X11 only) |

## dwl Integration

The XKB layout works with dwl once copied to `/usr/share/X11/xkb/symbols/`. No modifications to evdev.xml or base.lst are needed. dwl uses XKB directly via libxkbcommon, so the layout is available once deployed.

## XKB Layout Details

The RPD layout (`xkb/.../real_prog_dvorak`) differs from standard Dvorak primarily in the number row — unshifted keys produce programming symbols (`$+[{(&=)}]*!|#`), shifted keys produce digits. Additional differences from standard Dvorak:

- `@` and `^` on `AD12` (where `=+` is on QWERTY)
- `\` and `#` on `BKSL`
- `/` and `?` on `AD11` (where `[{` is on QWERTY)

## macOS Counterpart

The macOS version lives at `~/utono/rpd-macos` and uses a `.keylayout` file for the layout and Kanata (with Karabiner's virtual HID driver) for home row mods. Hammerspoon keybindings also live there.

## Slash Commands

- `/rpd:kanata report` — display tap-hold timeout values from `etc/kanata/kanata.kbd`
- `/rpd:kanata set <var> <value>` — change a timeout variable, then restart kanata
