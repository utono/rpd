# Kanata Migration Design

**Date:** 2026-03-08T12:16:46Z
**Status:** Approved
**Goal:** Replace keyd with kanata for better home row mod behavior

## Motivation

keyd's `lettermod()` on index finger keys (f/j) triggers accidental meta activation
during fast tapping, even at 150ms. The resolution algorithm is a black box with no
way to control *how* tap vs hold is decided — only the timeout values.

Kanata's `tap-hold-release` variant fixes this: it only resolves as a modifier when
another key is pressed *and released* while held. Quick taps won't accidentally
become modifiers.

## Scope

- Replace keyd with kanata as the remapping daemon
- Same home row mod layout, better algorithm
- Explore advanced features (tap-dance, combos, etc.) after migration stabilizes
- keyd files stay in repo for reference, no longer deployed

## Repository Structure

```
rpd/
  etc/
    keyd/default.conf              # kept for reference, not deployed
    kanata/
      kanata.kbd                   # main kanata config
      kanata.service               # custom systemd unit
  kanata-configuration.sh          # deployment script (replaces keyd-configuration.sh)
```

## Kanata Config Design

### Device Targeting

Explicit device paths via `/dev/input/by-id/` in `defcfg`:

```lisp
(defcfg
  linux-dev /dev/input/by-id/your-keyboard-id-here
  process-unmapped-keys yes
)
```

### Home Row Mods

All home row mods use `tap-hold-release` instead of keyd's `lettermod()`:

```lisp
(defvar
  tap-time 200
  hold-time 200
  index-hold-time 150
)

(defalias
  cec (tap-hold $tap-time $hold-time esc lmet)

  ;; Left hand
  a (tap-hold-release $tap-time $hold-time a lsft)
  s (tap-hold-release $tap-time $hold-time s lctl)
  d (tap-hold-release $tap-time $hold-time d lalt)
  f (tap-hold-release $tap-time $index-hold-time f lmet)

  ;; Right hand
  j (tap-hold-release $tap-time $index-hold-time j rmet)
  k (tap-hold-release $tap-time $hold-time k ralt)
  l (tap-hold-release $tap-time $hold-time l rctl)
  ; (tap-hold-release $tap-time $hold-time ; rsft)

  ;; Thumb/other
  spc (tap-hold-release $tap-time $hold-time spc lmet)
  bksl (tap-hold-release $tap-time $hold-time bksl lmet)
)
```

### Layers

Two layers matching keyd's main/plain design:

```lisp
(defsrc
  caps a s d f j k l ; spc bksl ins
)

(deflayer default
  @cec @a @s @d @f @j @k @l @; @spc @bksl (layer-switch plain)
)

(deflayer plain
  @cec a s d f j k l ; spc bksl (layer-switch default)
)
```

Insert toggles between layers via `layer-switch` (permanent, not hold-based).

## Deployment Script

`kanata-configuration.sh` replaces `keyd-configuration.sh`:

1. Install kanata if not present (`paru -S kanata`)
2. Stop and disable keyd if running
3. Create `/etc/kanata/` directory
4. Symlink `/etc/kanata/kanata.kbd` to repo file
5. Install custom systemd service file
6. Enable and start kanata service
7. Preserve existing duties: KBD keymap copy, vconsole.conf update, XKB layout copy
8. Optional Hyprland config (interactive)

## Systemd Service

Custom service file at `etc/kanata/kanata.service` (option b — full control, lives in repo):

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

## Slash Command

`/rpd:kanata` replaces `/rpd:keyd`:

- `report` — reads `$tap-time`, `$hold-time`, `$index-hold-time` from `.kbd`
- `set <var> <value>` — modifies `defvar` values, restarts kanata service

## CLAUDE.md Updates

- Architecture section: replace keyd references with kanata
- Deployment section: reference `kanata-configuration.sh`
- Manual operations: `sudo systemctl restart kanata`, `killall -SIGUSR1 kanata` for reload
- Key File Map: update `/etc/kanata/kanata.kbd` symlink entry

## Future Features

After core migration stabilizes:

- Tap-dance (multi-tap keys)
- Combos (simultaneous key chords)
- One-shot modifiers
- Mouse emulation via keyboard layer
- Per-application layers

See `docs/kanata/features.md` for details.
