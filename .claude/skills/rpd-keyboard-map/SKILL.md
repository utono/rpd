---
name: rpd-keyboard-map
description: Use when generating a visual keyboard map for a project's keybindings on the Real Programmers Dvorak layout. Accepts a project path argument like ~/utono/lit, ~/utono/nvim-code, ~/.config/mpv, or ~/utono/linux-lit.
argument-hint: <project-path>
---

# RPD Keyboard Map

Generate a standalone HTML file showing a visual Real Programmers Dvorak keyboard with a project's keybindings overlaid. Output is a self-contained HTML file with inline SVG-style rendering using CSS, opened in the browser.

## Process

1. **Read the argument** — the project path (e.g., `~/utono/lit`)
2. **Discover keybinds** — search the project for keybind definitions:
   - Lua: `vim.keymap.set` calls, keymap tables
   - Rust: `match key_name` arms, keymap modules
   - mpv: `input.conf`
   - Other: search for "keybind", "keymap", "shortcut", "hotkey"
3. **Classify each keybind** into the RPD layout position using the layout reference below
4. **Generate HTML** — write a self-contained HTML file to `/tmp/rpd-keyboard-<project-name>.html`
5. **Open in browser** — `xdg-open /tmp/rpd-keyboard-<project-name>.html`

## RPD Layout Reference

The layout is defined in `~/utono/rpd/xkb/usr/share/X11/xkb/symbols/real_prog_dvorak`.

### Physical Key Positions (unshifted / shifted)

**Number row:** `$ ~` `+ 1` `[ 2` `{ 3` `( 4` `& 5` `= 6` `) 7` `} 8` `] 9` `* 0` `! %` `| backtick` then Backspace

**Upper row:** Tab then `; :` `, <` `. >` `p P` `y Y` `f F` `g G` `c C` `r R` `l L` `/ ?` `@ ^` `\ #`

**Home row:** Esc (Caps Lock position) then `a A` `o O` `e E` `u U` `i I` `d D` `h H` `t T` `n N` `s S` `- _`

**Bottom row:** `' "` `q Q` `j J` `k K` `x X` `b B` `m M` `w W` `v V` `z Z`

**Caps Lock = Escape** (RPD remaps Caps Lock to Escape via xkb).

### Row Stagger

- Number row: no offset
- Upper row: Tab key (wider) then alpha keys
- Home row: Esc/Caps key (wider than Tab) then alpha keys
- Bottom row: shifted right so `'` starts slightly past `a` above
- Special row: multi-key sequences (gg, G, leader combos)
- Arrow keys: inverted-T cluster, far right

## HTML Template Structure

Generate a single self-contained HTML file. Each key is a `<div>` with absolute positioning inside a keyboard container. Use this CSS pattern for keys:

```html
<div class="key [bound|bound-shift|bound-both|unbound]" style="left:Xpx; top:Ypx; width:Wpx; height:Hpx;">
  <span class="char">a</span>
  <span class="shifted">A</span>
  <span class="action">action text</span>
  <span class="shift-action">Shift action</span>
  <div class="tooltip">C-a -> select all</div>
</div>
```

### Key Dimensions (px)

- Regular key: 68w x 66h, gap: 4
- Tab: 102w
- Esc/Caps: 120w
- Backspace: 94w
- Arrow keys: 54w x 50h
- Corner radius: 5

### Color Scheme (dark background)

- **Keyboard background:** `rgba(26, 26, 26, 0.95)`, padding 20px, border-radius 10px
- **Bound (bare key):** bg `#1a3a2a`, border `#3a6a4a`, char color `#88ff88`
- **Bound (shift only):** bg `#1a2a3a`, border `#3a4a6a`, char color `#88aaff`
- **Both / modifier:** bg `#1a3a2a`, border `#3a6a4a`, char color `#88ff88`
- **Unbound:** bg `#2a2a2a`, border `#444`, char color `#555`, opacity 0.5
- **Action text:** `#66cc66`, font-size 12px
- **Shift action text:** `#6688cc`, font-size 11px
- **Shifted char:** `#666` (dim) or `#6688cc` (active if shift binding exists)
- **Tooltip:** bg `#222`, border `#555`, Ctrl text `#88aaff`, Alt text `#cc88ff`

### Keybind Classification

For each discovered keybind, determine:

- **key**: which physical RPD key (match against the layout above)
- **modifier**: none, Shift, Ctrl, Alt, Ctrl+Alt
- **action**: short description of what it does

Then assign to the key's fields:
- No modifier -> `action` (inline, green text)
- Shift -> `shift_action` (inline, blue text)
- Ctrl/Alt/Ctrl+Alt -> tooltip only (shown on hover)

### Legend

Below the keyboard, show color swatches with labels:
- Green swatch + "bare key"
- Blue swatch + "shift only"
- Green/blue swatch + "both / modifier"
- Gray swatch + "unbound"
- Purple dot + "Alt+"

Include: "Hover keys to see Ctrl+/Alt+ combos"

### Tooltip Behavior

Use CSS `:hover` to show/hide tooltip divs positioned above the key. Ctrl+ combos in blue (`#88aaff`), Alt+ in purple (`#cc88ff`).

## Keybind Format Examples

### Neovim (Lua)
```lua
vim.keymap.set('n', '<leader>ff', telescope.find_files, { desc = 'Find files' })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
```
Map: mode `n` = normal. `<leader>` = special row. `gd` = sequence in special row.

### Rust (linux-lit keymap.rs)
```rust
"period" => { set_chapter(&mut state) }
"bracketleft" => { jump_to_prev_chapter(&mut state); true }
```
Map: GTK key names to RPD characters.

### mpv (input.conf)
```
a cycle pause
o seek -3.5
Ctrl+UP add volume 2
```
Map: key names directly to RPD layout.
