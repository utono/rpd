# RPD macOS Port Design

**Date**: 2026-03-04
**Status**: Approved
**Purpose**: Create `~/utono/rpd-macos` repository that replicates the RPD keyboard setup from Arch Linux on macOS.

## Repository Structure

```
~/utono/rpd-macos/
  CLAUDE.md
  README.md
  install.sh
  keylayout/
    RealProgDvorak.keylayout
  karabiner/
    karabiner.json
    assets/
      complex_modifications/
        rpd-homerow-mods.json
```

## Component 1: Custom Keyboard Layout

**File**: `keylayout/RealProgDvorak.keylayout`
**Installed to**: `~/Library/Keyboard Layouts/`
**Format**: macOS `.keylayout` XML

Full parity with the XKB layout (`xkb/usr/share/X11/xkb/symbols/real_prog_dvorak`):

- Number row unshifted: `$+[{(&=)}]*!|#`
- Number row shifted: `~1234567890%``
- Dvorak letter positions: `;,.pyfgcrl` / `aoeuidhtns-` / `'qjkxbmwvz`
- Special: `/?` on `[` position, `@^` on `]` position, `\#` on `\` position
- Dead keys preserved: grave, tilde, circumflex, cedilla, caron, abovedot, acute, diaeresis, ogonek, doubleacute

Uses macOS keycodes (different numbering from Linux scancodes). Hand-crafted XML with comments mapping each keycode to physical key position.

## Component 2: Karabiner-Elements Config

**Files**: `karabiner/karabiner.json` + `karabiner/assets/complex_modifications/rpd-homerow-mods.json`
**Installed to**: `~/.config/karabiner/`
**Prereq**: Karabiner-Elements (`brew install --cask karabiner-elements`)

All rules use physical keycodes (QWERTY key_code values) so they work regardless of active keyboard layout.

### Home row mods (tap = character, hold = modifier)

Left hand (QWERTY physical positions):
- `a` → tap: passthrough, hold: left_shift (100ms tap, 200ms hold)
- `s` → tap: passthrough, hold: left_control (100ms tap, 200ms hold)
- `d` → tap: passthrough, hold: left_option (100ms tap, 200ms hold)
- `f` → tap: passthrough, hold: left_command (100ms tap, 150ms hold)

Right hand:
- `j` → tap: passthrough, hold: left_command (100ms tap, 150ms hold)
- `k` → tap: passthrough, hold: left_option (100ms tap, 200ms hold)
- `l` → tap: passthrough, hold: left_control (100ms tap, 200ms hold)
- `;` → tap: passthrough, hold: left_shift (100ms tap, 200ms hold)

### Other overloads

- Capslock: tap = escape, hold = left_command
- Space: hold = left_command (100ms tap, 200ms hold)
- Backslash: hold = left_command (100ms tap, 200ms hold)

### Plain mode toggle

- Fn + Escape: toggles all home row mods on/off
- Implemented via Karabiner variable (`rpd_plain_mode`) that conditionally disables rules
- When plain mode is active, capslock overload is preserved (matches Linux behavior)

### Modifier mapping (Linux → macOS)

| Linux (keyd) | macOS (Karabiner) |
|---|---|
| shift | shift |
| control | control |
| alt | option |
| meta | command |

## Component 3: Install Script

**File**: `install.sh`
**No sudo required** — all files go to user-space directories.

Steps:
1. Check if Karabiner-Elements is installed; if not, prompt to install via Homebrew
2. Copy `RealProgDvorak.keylayout` to `~/Library/Keyboard Layouts/`
3. Backup existing Karabiner config if present
4. Copy Karabiner JSON to `~/.config/karabiner/`
5. Print post-install instructions:
   - Log out and back in (macOS requires this to detect new layouts)
   - System Settings > Keyboard > Input Sources > Add "Real Programmers Dvorak"
   - Grant Karabiner-Elements accessibility permissions if prompted

## Key Differences from Linux Version

- No KBD keymap (macOS has no TTY console equivalent)
- No vconsole.conf
- No systemctl/service management (Karabiner runs as a user app)
- No sudo required for installation
- Insert key replaced by Fn+Escape for plain mode toggle
- Meta maps to Command (not Super/Win key)

## Implementation Notes

- macOS keycodes reference: Apple Technical Note TN2450
- Karabiner key_code values match Apple's virtual keycode numbering
- The `.keylayout` XML must include a proper DTD reference and keyboard ID
- Karabiner `to_if_alone` and `to_if_held_down` implement the dual-role behavior
- Karabiner timing parameters: `basic.to_if_alone_timeout_milliseconds` and `basic.to_if_held_down_threshold_milliseconds`
