---
name: kanata
description: Report and modify kanata tap-hold timeout values
argument-hint: report | set <var> <value>
---

# Kanata Settings

Manage tap-hold timeout variables in `etc/kanata/kanata.kbd`.

## Arguments: $ARGUMENTS

## Routing

Parse `$ARGUMENTS` and route:

- **No arguments (empty):** Show usage:
  ```
  Usage:
    /rpd:kanata report           - show tap-hold timeout values
    /rpd:kanata set <var> <value> - change a timeout variable

  Variables: tap-time, hold-time, index-hold-time
  ```

- **`report`:** Read `etc/kanata/kanata.kbd` from the repo root (`~/utono/rpd/etc/kanata/kanata.kbd`). Parse the `(defvar ...)` block. Display a markdown table:

  | Variable | Value (ms) |
  |----------|------------|

  Then show each alias with its tap-hold-release parameters.

  After the table, show usage:
  ```
  Usage:
    /rpd:kanata set <var> <value> - change a timeout variable

  Variables: tap-time, hold-time, index-hold-time
  ```

- **`set <var> <value>`:**
  1. Read `~/utono/rpd/etc/kanata/kanata.kbd`
  2. Find the variable in the `(defvar ...)` block matching `<var>` (one of: `tap-time`, `hold-time`, `index-hold-time`)
  3. Replace the value
  4. Write the updated file
  5. Run `sudo systemctl restart kanata`
  6. Show the updated defvar block to confirm the change

- **Anything else:** Show "Unknown subcommand" and print the usage block above.
