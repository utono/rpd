# Kanata Help

## Home Row Mods — How Timing Affects Behavior

Home row keys double as modifiers using `tap-hold-release`. Three variables control timing:

### tap-time

The maximum time (ms) a key can be held before it becomes eligible for the hold action. If you press and release a key within tap-time and no other key was pressed during that window, it always registers as a tap. Lower values make taps snappier but require faster typing to avoid accidental holds.

### hold-time

The window (ms) in which another key must be **pressed and released** while the home row key is held down for the modifier to activate. With `tap-hold-release`, simply holding past hold-time does nothing — a second key must complete a full press-release cycle within that window.

- **Higher hold-time** (e.g. 300-350ms) — more forgiving during fast typing; reduces accidental modifier triggers from key rolls. Intentional modifier use feels slightly slower.
- **Lower hold-time** (e.g. 150-200ms) — modifiers activate faster for shortcuts, but fast typing rolls can accidentally trigger modifiers.

### index-hold-time

A separate hold-time applied only to the index finger keys (`f` and `j`). Typically set lower than hold-time because index fingers are used more deliberately for shortcuts and are less prone to accidental rolls with non-adjacent keys.

### Algorithm: tap-hold-release

The `tap-hold-release` algorithm requires another key to be **pressed and released** while the home row key is held. This is stricter than `tap-hold-press` (which triggers on press alone) and prevents most misfires from adjacent key rolls during fast typing.

### Tuning Tips

- If a home row key fires as a modifier during normal typing, **increase** its hold-time
- If intentional modifier combos feel sluggish, **decrease** hold-time
- Individual keys can use hardcoded values instead of the shared variable for per-key tuning
- The `f` and `j` keys use `$index-hold-time` — adjust that variable separately

---

## Features to Explore

### Mouse Emulation

Control the mouse cursor from the keyboard via a dedicated layer.

#### Getting Started

Add a mouse layer activated by holding a key (e.g., right alt):

```lisp
(defalias
  mse (layer-toggle mouse)
)

(deflayer mouse
  _    _    _    _    _    _    _    _    _    _    _    _
  ;; hjkl for cursor movement
  ;; u/i for scroll
  ;; space/enter for clicks
)
```

Kanata mouse actions:

- `(movemouse-left N T)` — move cursor left N pixels every T milliseconds
- `(movemouse-right N T)`, `(movemouse-up N T)`, `(movemouse-down N T)`
- `(movemouse-accel-left N T A MAX)` — accelerated movement (starts at N, accelerates by A every T ms, caps at MAX)
- `mlft` / `mrgt` / `mmid` — left, right, middle click
- `(mwheel-up N T)` / `(mwheel-down N T)` — scroll wheel

#### Example Mouse Layer

```lisp
(defvar
  msp 1       ;; mouse speed (pixels)
  msi 20      ;; mouse interval (ms)
  macc 1      ;; mouse acceleration
  mmax 5      ;; max mouse speed
)

(defalias
  mlt (movemouse-accel-left $msp $msi $macc $mmax)
  mdn (movemouse-accel-down $msp $msi $macc $mmax)
  mup (movemouse-accel-up $msp $msi $macc $mmax)
  mrt (movemouse-accel-right $msp $msi $macc $mmax)
  msu (mwheel-up 3 50)
  msd (mwheel-down 3 50)
)

(deflayer mouse
  _    _    _    _    _    _    _    _    _    _    _    _
  ;;   a    s    d    f    ...  j     k     l     ;
  _    _    _    _    _    @mlt @mdn  @mup  @mrt  _
  ;;                       hjkl = arrow-style cursor movement
  ;;   space = left click, enter = right click
)
```

Tune `$msp`, `$msi`, `$macc`, and `$mmax` to get the right cursor feel.

### Tap-Dance

Multi-tap keys — different actions based on how many times you tap.

```lisp
(defalias
  ;; tap once = ;  tap twice = :  tap three times = ::
  td; (tap-dance 200 (; S-; (macro S-; S-;)))
)
```

The number (200) is the timeout between taps in milliseconds.

Use cases:
- `;` / `:` on a single key
- `'` / `"` on a single key
- Quick access to rarely-used symbols

### Combos

Press two keys simultaneously to produce a different output.

```lisp
(defcfg
  combo-timeout 50
)

;; Press j+k simultaneously = Enter
(defcombo jk-enter (j k))

(deflayer default
  ;; ... include combo reference
)
```

Use cases:
- `j+k` = Enter (no reaching)
- `d+f` = Tab
- `s+d` = Escape (alternative to capslock)

### One-Shot Modifiers

Tap a modifier key, and it applies to only the next keypress. No holding required.

```lisp
(defalias
  os-sft (one-shot 2000 lsft)   ;; tap for shift, applies to next key
  os-ctl (one-shot 2000 lctl)   ;; timeout = 2000ms before it cancels
)
```

Useful for reducing finger strain — instead of holding shift+key, tap shift then tap key.

### Per-Application Layers

Kanata itself doesn't detect the active application, but you can use external tools to switch layers:

- Use `kanata-tcp` or signals to switch layers from a script
- Combine with `hyprctl` or `wlr-foreign-toplevel` to detect the focused window
- Script sends a layer-switch command to kanata when the focused app changes

This is advanced and requires external scripting beyond kanata's config.

### Resources

- Kanata docs: https://github.com/jtroo/kanata/blob/main/docs/config.adoc
- Sample configs: https://github.com/jtroo/kanata/tree/main/cfg_samples
- Home row mod advanced example: https://github.com/jtroo/kanata/blob/main/cfg_samples/home-row-mod-advanced.kbd
