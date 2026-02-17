# Keyd Settings

Manage lettermod timeout values in `etc/keyd/default.conf`.

## Arguments: $ARGUMENTS

## Routing

Parse `$ARGUMENTS` and route:

- **No arguments (empty):** Show usage:
  ```
  Usage:
    /rpd keyd report                 - show lettermod timeout values
    /rpd keyd set <key> <tap> <hold> - change timeout for a key

  Keys: \ a s d f j k l ; space
  ```

- **`report`:** Read `etc/keyd/default.conf` from the repo root (`~/utono/rpd/etc/keyd/default.conf`). Parse every `lettermod(modifier, key, tap, hold)` line. Display a markdown table:

  | Key | Modifier | Tap (ms) | Hold (ms) |
  |-----|----------|----------|-----------|

  Use `spc` as the display name for the `space` key and `\` for `backslash`.

- **`set <key> <tap> <hold>`:**
  1. Read `~/utono/rpd/etc/keyd/default.conf`
  2. Find the lettermod line matching `<key>` (accept `\` or `backslash` for backslash, `space` or `spc` for space)
  3. Replace the tap and hold timeout values in that line's `lettermod()` call
  4. Write the updated file
  5. Run `sudo keyd reload`
  6. Show the updated line to confirm the change

- **Anything else:** Show "Unknown subcommand" and print the usage block above.
