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

Device targeting is in `defcfg` via `linux-dev`. The tracked line is only
default text: the unit runs `bin/kanata-launch` (linked to
`/usr/local/bin/kanata-launch`), which writes `/run/kanata/kanata.kbd` with
that line set from `kanata_dev` in `/etc/machine.conf`, else the first
`/dev/input/by-path/platform-i8042-serio-*-event-kbd`, else removed (kanata
grabs every keyboard), and execs kanata on the result. Edit
`etc/kanata/kanata.kbd`, not the `/run` copy.

## Deployment

The single setup script handles everything:

```bash
./kanata-configuration.sh ~/utono/rpd
```

This requires sudo and performs: KBD keymap copy, vconsole.conf update, XKB layout copy, keyd sunset (stop/disable if running), kanata symlink creation (`/etc/kanata/kanata.kbd` → source), kanata service install/enable/start.

After running, `sudo mkinitcpio -P` is recommended for early-boot keymap availability (LUKS).

### Recovery after a system upgrade reverts the keymap

A `paru -Syu` / `pacman -Syu` that upgrades systemd runs `systemd-localed`,
which rewrites `/etc/vconsole.conf` back to the `us` default (`KEYMAP=us`,
adding `XKBLAYOUT=us`). The TTY then reverts to QWERTY. The deployed layout
files, the XKB symbols, and the kanata service all survive — only the keymap
*selection* reverts.

To recover, re-run the setup script — its `configure_vconsole_keymap()` step
backs up the clobbered `vconsole.conf` to `~/backups/etc/` and rewrites it with
`KEYMAP=real_prog_dvorak`:

```bash
./kanata-configuration.sh ~/utono/rpd
sudo loadkeys real_prog_dvorak   # apply to the live TTY immediately
```

The script does **not** touch the X11 layer (`localectl` / `00-keyboard.conf`),
but that is fine: dwl (Wayland) sets `real_prog_dvorak` itself via libxkbcommon
and does not read `00-keyboard.conf`. Only fix the X11 side for a literal Xorg
session: `sudo localectl set-x11-keymap real_prog_dvorak`.

See `CLAUDE-troubleshooting.md` for the full diagnosis.

### Manual kanata operations

```bash
# Restart after editing kanata.kbd
sudo systemctl restart kanata

# Check kanata is running
sudo systemctl status kanata

# Run the launcher's tests
bash tests/test-kanata-launch.sh

# Validate config syntax
kanata --check -c etc/kanata/kanata.kbd
```

## Key File Map

| Source in repo | Deployed to | Method |
|---|---|---|
| `etc/kanata/kanata.kbd` | `/etc/kanata/kanata.kbd` | symlink |
| `bin/kanata-launch` | `/usr/local/bin/kanata-launch` | symlink |
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

### Consequences for keybinding advice

Every consumer config binds by the **character RPD produces**, not the QWERTY
position. Never assume a US QWERTY position when reasoning about a binding:

- **Digits need Shift.** A binding on "1" is physically `Shift+1`; the
  unshifted key there is `+`.
- **`-` and `_` moved to the QWERTY apostrophe key**; the QWERTY `-` key is
  now `!`/`%`.
- **`/` and `?` are on the QWERTY `[` key.** Relevant to any `?`-for-help
  binding — e.g. herdr's `prefix+?` is `ctrl+b` then `Shift+[` (physical).
- **Vim `hjkl` is scattered**: `h`=QWERTY `J`, `j`=QWERTY `C`, `k`=QWERTY `V`,
  `l`=QWERTY `P`. Not adjacent, so "hjkl is ergonomic" does not hold here.
  Conversely `htns` (QWERTY `jkl;`) IS the right home row run.
- **`ctrl+a` is not a home-row-pinky reach.** `a` stays on the QWERTY `A` key,
  but the usual QWERTY ergonomic argument for `ctrl+a` prefixes doesn't transfer.
- Ergonomic claims from upstream docs assume QWERTY — re-derive before
  repeating them.

**Kanata's `defsrc` is the exception**: it names **physical QWERTY positions**,
so the aliases written `a s d f j k l ;` sit on the keys RPD types as `a o e u`
and `h t n s`. Mixing this up with the XKB side is the classic error.

Confirmed consumers, all outside this repo — verified 2026-08-06:

- `~/utono/mangowm-mlj/.config/mango/cfg/keybinds.conf` — RPD keysym names
  (`plus`, `bracketleft`, `braceleft` … for tags 1-3). Must use `binds=`, not
  `bind=`; see that repo's `docs/troubleshooting/keysym-verification.md`.
- `~/utono/linux-lit/src/input/keymap.rs` — GTK `keyval.name()` /
  `keyval.to_unicode()`, layout-aware; the hardware keycode is discarded.
- `~/.config/mpv/input.conf` — RPD characters, organized in
  unshifted/shifted pairs per physical key (`$`/`~`, `+`/`1`, `(`/`4` …).

## macOS Counterpart

The macOS version lives at `~/utono/rpd-macos` and uses a `.keylayout` file for the layout and Kanata (with Karabiner's virtual HID driver) for home row mods. Hammerspoon keybindings also live there.

## Slash Commands

- `/rpd:kanata report` — display tap-hold timeout values from `etc/kanata/kanata.kbd`
- `/rpd:kanata set <var> <value>` — change a timeout variable, then restart kanata

## Memory Bank System

This project uses a structured memory bank system. Always check these context
files before starting work, and keep them updated as the project evolves:

- **CLAUDE-activeContext.md** — current session state, goals, and progress
- **CLAUDE-patterns.md** — established code patterns and conventions
- **CLAUDE-decisions.md** — architecture decisions and rationale
- **CLAUDE-troubleshooting.md** — common issues and proven solutions
- **CLAUDE-config-variables.md** — configuration variables reference

Always read **CLAUDE-activeContext.md** first to maintain session continuity.
When you change core context, update the relevant memory bank file.

## `CLAUDE-activeContext.md` (`ac`) — do NOT auto-update after each commit

Do **NOT** update this project's `ac` (`CLAUDE-activeContext.md`) after each
`git commit`. `ac` is a **scoped session-continuity file, not a changelog** — a
per-commit summary is recoverable from `git log`, so do not accumulate one in
`ac`. Update `ac` only when the user asks ("update ac" / "uac") or before a
likely context break (reboot, compaction, end of a work block). When refreshing
it, **replace** stale state rather than prepending a new block on top of the old
ones; keep it short (current state + uncommitted work + next actions +
genuinely non-recoverable decisions/gotchas). This overrides the older
"After a Commit" rule.
