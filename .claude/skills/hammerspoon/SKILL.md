---
name: hammerspoon
description: Use when listing, searching, changing, adding, or deleting Hammerspoon keybindings, or when needing RPD keycode reference for Hammerspoon
argument-hint: list | search <query> | change <binding> | add <description> | delete <binding>
---

# Hammerspoon Keybindings

Manage Hammerspoon keybindings for Real Programmers Dvorak layout.

**Config source:** `~/utono/rpd/hammerspoon/.hammerspoon/`
**Docs:** `~/utono/rpd/docs/hammerspoon-keybindings.md`
**Live config:** `~/.hammerspoon/` (copy or symlink from source)

## Arguments: $ARGUMENTS

## Routing

Parse `$ARGUMENTS` and route:

- **No arguments (empty):** Show usage:
  ```
  Usage:
    /hammerspoon list              - show all current bindings
    /hammerspoon search <query>    - find a binding by description
    /hammerspoon change <binding>  - modify an existing binding
    /hammerspoon add <description> - add a new binding
    /hammerspoon delete <binding>  - remove a binding
  ```

- **`list`:**
  1. Read all `.lua` files in `~/utono/rpd/hammerspoon/.hammerspoon/`
  2. Parse every `hs.hotkey.bind(...)` call — extract modifiers, keycode, and action (from comment or function body)
  3. Display a markdown table:

     | Shortcut | Keycode | Modifiers | Action | File |
     |----------|---------|-----------|--------|------|

  4. Show usage hint: `Use /hammerspoon search <query> to find a specific binding`

- **`search <query>`:**
  1. Read all `.lua` files in `~/utono/rpd/hammerspoon/.hammerspoon/`
  2. Parse all `hs.hotkey.bind(...)` calls
  3. Match `<query>` against: action descriptions (from comments), modifier names, keycode numbers, RPD key names, file names
  4. Display matching bindings in the same table format as `list`
  5. If no matches: "No bindings found matching '<query>'"

- **`change <description>`:**
  1. Parse `<description>` to identify which binding to change and what to change (key, modifiers, or action)
  2. Read the relevant `.lua` file
  3. Show the current binding and proposed change, ask for confirmation
  4. Edit the `.lua` file in `~/utono/rpd/hammerspoon/.hammerspoon/`
  5. Update `~/utono/rpd/docs/hammerspoon-keybindings.md`
  6. Remind user: "Copy updated files to `~/.hammerspoon/` or reload Hammerspoon to apply"

- **`add <description>`:**
  1. Parse `<description>` to determine: what the binding should do, suggested key/modifiers
  2. Identify the appropriate `.lua` file (or suggest creating a new module)
  3. Look up the keycode using the RPD Keycode Reference below
  4. Show the proposed binding code, ask for confirmation
  5. Edit the `.lua` file — use keycode (never character string)
  6. If new module: add `require("module-name")` to `init.lua`
  7. Update `~/utono/rpd/docs/hammerspoon-keybindings.md`
  8. Remind user: "Copy updated files to `~/.hammerspoon/` or reload Hammerspoon to apply"

- **`delete <binding>`:**
  1. Parse `<binding>` to identify which binding to remove
  2. Read the relevant `.lua` file, show the binding, ask for confirmation
  3. Remove the `hs.hotkey.bind(...)` call and related code
  4. If the file is now empty (no bindings left): remove the file and its `require()` from `init.lua`
  5. Update `~/utono/rpd/docs/hammerspoon-keybindings.md`
  6. Remind user: "Copy updated files to `~/.hammerspoon/` or reload Hammerspoon to apply"

- **Anything else:** Show "Unknown subcommand" and print the usage block above.

## The Keycode Rule

Always bind by **Apple virtual keycode** (physical key position), never by character string. Character-based bindings silently bind to the wrong key on RPD.

```lua
-- CORRECT: keycode-based (layout-independent)
hs.hotkey.bind({"cmd"}, 24, function()
    -- keycode 24 = QWERTY "=" position = RPD "|"
end)

-- WRONG: character-based (breaks on RPD)
hs.hotkey.bind({"cmd", "shift"}, "\\", function() end)
```

## RPD Keycode Reference

Keycodes are physical QWERTY positions. RPD Base is the unmodified output.

### Number Row

| QWERTY | Code | RPD Base | RPD Shift |
|--------|------|----------|-----------|
| \`     | 50   | $        | ~         |
| 1      | 18   | +        | 1         |
| 2      | 19   | [        | 2         |
| 3      | 20   | {        | 3         |
| 4      | 21   | (        | 4         |
| 5      | 23   | &        | 5         |
| 6      | 22   | =        | 6         |
| 7      | 26   | )        | 7         |
| 8      | 28   | }        | 8         |
| 9      | 25   | ]        | 9         |
| 0      | 29   | *        | 0         |
| -      | 27   | !        | %         |
| =      | 24   | \|       | \`        |

### Letter Rows

| QWERTY | Code | RPD Base | QWERTY | Code | RPD Base |
|--------|------|----------|--------|------|----------|
| Q      | 12   | ;        | A      | 0    | a        |
| W      | 13   | ,        | S      | 1    | o        |
| E      | 14   | .        | D      | 2    | e        |
| R      | 15   | p        | F      | 3    | u        |
| T      | 17   | y        | G      | 5    | i        |
| Y      | 16   | f        | H      | 4    | d        |
| U      | 32   | g        | J      | 38   | h        |
| I      | 34   | c        | K      | 40   | t        |
| O      | 31   | r        | L      | 37   | n        |
| P      | 35   | l        | ;      | 41   | s        |
| [      | 33   | /        | '      | 39   | -        |
| ]      | 30   | @        |        |      |          |
| \      | 42   | \        |        |      |          |

| QWERTY | Code | RPD Base |
|--------|------|----------|
| Z      | 6    | '        |
| X      | 7    | q        |
| C      | 8    | j        |
| V      | 9    | k        |
| B      | 11   | x        |
| N      | 45   | b        |
| M      | 46   | m        |
| ,      | 43   | w        |
| .      | 47   | v        |
| /      | 44   | z        |

### Special Keys

| Key     | Code |
|---------|------|
| Space   | 49   |
| Return  | 36   |
| Tab     | 48   |
| Delete  | 117  |
| Escape  | 53   |

## Anti-patterns

- **Character strings in hs.hotkey.bind** — `"\\"`, `"|"`, `"="` all resolve by QWERTY position, not RPD
- **hs.eventtap for hotkeys** — unreliable with Kanata home row mods; use `hs.hotkey.bind` with keycode
- **Adding shift for RPD symbols** — RPD puts symbols on base layer (e.g., `|` is unshifted on keycode 24), so `{"cmd"}` not `{"cmd", "shift"}`

## Discovering Unknown Keycodes

If you need a keycode not in the table, use the Hammerspoon console:

```lua
tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    hs.alert.show("key: " .. (e:getCharacters() or "nil") .. " code: " .. e:getKeyCode())
    return false
end):start()
-- Press the key, note the code, then run: tap:stop()
```
