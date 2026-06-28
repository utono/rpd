# Troubleshooting — rpd

> Common issues and proven solutions. Add symptoms, root causes, and fixes as
> they are discovered.

## Keyboard reverts to QWERTY after a system upgrade

**Symptom:** After a `paru -Syu` / `pacman -Syu` that touches systemd, the TTY
(and/or X11) reverts to a QWERTY `us` layout. Home row mods (kanata) still work.

**Root cause:** A systemd upgrade runs `systemd-localed`, which rewrites the
system-owned keyboard *selection* files back to the `us` default:

- `/etc/vconsole.conf` → `KEYMAP=us` (and adds `XKBLAYOUT=us`)
- `/etc/X11/xorg.conf.d/00-keyboard.conf` → `XkbLayout "us"`

Both carry the `# Written by systemd-localed(8)` banner. The deployed layout
*files* are untouched — only the selection reverts:

- XKB symbols `/usr/share/X11/xkb/symbols/real_prog_dvorak` — survives
- KBD keymap `/usr/share/kbd/keymaps/i386/dvorak/real_prog_dvorak.map.gz` — survives
- kanata service + `/etc/kanata/kanata.kbd` symlink — survives (home row mods unaffected)

**Diagnosis:** `localectl status` shows `VC Keymap: us` and/or `X11 Layout: us`.

**Fix (console / TTY — the part that matters):**

```bash
sudo tee /etc/vconsole.conf > /dev/null <<'EOF'
# Written by systemd-localed(8) or systemd-firstboot(1), read by systemd-localed
# and systemd-vconsole-setup(8). Use localectl(1) to update this file.
KEYMAP=real_prog_dvorak
EOF
sudo loadkeys real_prog_dvorak   # applies to the live TTY immediately
```

**X11 layer — usually NOT needed:** dwl (Wayland compositor) sets
`real_prog_dvorak` itself via libxkbcommon and does not read
`00-keyboard.conf`, so a `localectl` `X11 Layout: us` is cosmetic. Only fix it
if running a literal Xorg session:

```bash
sudo localectl set-x11-keymap real_prog_dvorak
```

**Notes:**
- `kanata-configuration.sh` restores `vconsole.conf` KEYMAP but has NO X11/XKB
  selection step, so re-running the full script is overkill for this — the
  `vconsole.conf` + `loadkeys` block above is the minimal fix.
- Optional for early-boot/LUKS keymap availability: `sudo mkinitcpio -P`.
