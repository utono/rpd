---
name: kanata
description: Use when reporting, modifying kanata tap-hold timeout values, or debugging home row mod misfires, wrong modifier triggers, or unexpected output during fast typing
argument-hint: report | set <var|key> <value>
---

# Kanata Settings

Manage tap-hold timeout variables in `etc/kanata/kanata.kbd`.

## Arguments: $ARGUMENTS

## Routing

Parse `$ARGUMENTS` and route:

- **No arguments (empty):** Show usage:
  ```
  Usage:
    /kanata report            - show tap-hold timeout values
    /kanata set <var> <value>  - change a timeout variable
    /kanata set <key> <value>  - change a key's hold time

  Variables: tap-time, hold-time, index-hold-time
  Keys: a s d f j k l ;

  Example:
    /kanata set hold-time 250
    /kanata set j 450
  ```

- **`report`:** Read `etc/kanata/kanata.kbd` from the repo root (`~/utono/rpd/etc/kanata/kanata.kbd`). Parse the `(defvar ...)` block. Display a markdown table:

  | Variable | Value (ms) |
  |----------|------------|

  Then show each alias with its tap-hold-release parameters.

  After the table, show usage:
  ```
  Usage:
    /kanata set <var> <value>  - change a timeout variable
    /kanata set <key> <value>  - change a key's hold time

  Variables: tap-time, hold-time, index-hold-time
  Keys: a s d f j k l ;

  Example:
    /kanata set hold-time 250
    /kanata set j 450
  ```

- **`set <var> <value>`** (where `<var>` is one of `tap-time`, `hold-time`, `index-hold-time`):
  1. Read `~/utono/rpd/etc/kanata/kanata.kbd`
  2. Find the variable in the `(defvar ...)` block matching `<var>`
  3. Replace the value
  4. Write the updated file
  5. Run `sudo systemctl restart kanata`
  6. Show the updated defvar block to confirm the change

- **`set <key> <value>`** (where `<key>` is a home row mod key: `a`, `s`, `d`, `f`, `j`, `k`, `l`, `;`):
  1. Read `~/utono/rpd/etc/kanata/kanata.kbd`
  2. Find the alias line in the `(defalias ...)` block for `<key>`, e.g.
     `j (tap-hold-release $tap-time 500 j rmet)`
  3. Replace the **hold-time** parameter (the second numeric argument — literal value or `$var`) with `<value>`. Do NOT touch `$tap-time` (the first argument).
  4. Write the updated file
  5. Run `sudo systemctl restart kanata`
  6. Show the updated alias line to confirm the change

- **Anything else:** Show "Unknown subcommand" and print the usage block above.

## Debugging Misfires

When a key misfires or triggers a modifier unexpectedly during fast typing:

1. **Identify the physical key.** RPD uses Dvorak — the reported letter is NOT the physical key name in kanata:

   | Dvorak letter | Physical key (QWERTY) | Kanata alias |
   |---|---|---|
   | a | a | `@a` (lsft) |
   | o | s | `@s` (lctl) |
   | e | d | `@d` (lalt) |
   | u | f | `@f` (lmet) |
   | h | j | `@j` (rmet) |
   | t | k | `@k` (ralt) |
   | n | l | `@l` (rctl) |
   | s | ; | `@;` (rsft) |

2. **Read `etc/kanata/kanata.kbd`** and find the alias for that physical key.

3. **Check timing.** The alias uses `tap-hold-release $tap-time $hold-time` (or `$index-hold-time` for f/j). Lower hold times trigger mods more easily during fast typing.

4. **Choose a fix** (simplest first):
   - **Increase hold time** — raise `index-hold-time` or `hold-time` in `defvar`. Start by matching the general `hold-time` value, then go higher (220, 250) if needed.
   - **Switch algorithm** — change `tap-hold-release` to `tap-hold-press` for that key. Less responsive for intentional mod use but eliminates misfires from adjacent key rolls.
   - **Restrict trigger keys** — use `tap-hold-release-keys` with an explicit key list so only specific keys activate the hold, excluding neighbors that cause rolls.

5. **Apply and test.** Edit the config, then:
   ```bash
   sudo systemctl restart kanata
   ```

### Common Mistakes

- Assuming the reported letter matches the physical key name (Dvorak vs QWERTY)
- Adjusting `hold-time` when the key uses `index-hold-time` (f and j use the separate index variable)
- Adding the misfiring key to `defsrc` when it's not there — the problem is usually the *neighboring* home row mod key, not the misfiring key itself
