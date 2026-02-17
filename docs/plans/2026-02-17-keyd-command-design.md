# Design: `/rpd keyd` Command

**Date:** 2026-02-17

## Purpose

A Claude Code slash command to report and modify keyd lettermod timeout values in `etc/keyd/default.conf`.

## Routing

| Input | Action |
|---|---|
| `/rpd keyd` (no args) | Show usage with available subcommands |
| `/rpd keyd report` | Display table of all lettermod bindings with key, modifier, tap timeout, hold timeout |
| `/rpd keyd set <key> <tap> <hold>` | Edit timeout values for a key, then run `sudo keyd reload` |

## Report Output

Parses all `lettermod()` calls from `etc/keyd/default.conf` and displays:

```
Key  Modifier  Tap(ms)  Hold(ms)
---  --------  -------  --------
\    meta      100      200
a    shift     100      200
s    control   100      200
d    alt       100      200
f    meta      100      150
j    meta      100      150
k    alt       100      200
l    control   100      200
;    shift     100      200
spc  meta      100      200
```

## Set Workflow

1. Read `etc/keyd/default.conf`
2. Find the lettermod line for the specified key
3. Replace the two timeout values
4. Write the file
5. Run `sudo keyd reload`
6. Confirm the change by showing the updated line

## Usage Output (no args)

```
/rpd keyd report               - show lettermod timeout values
/rpd keyd set <key> <tap> <hold> - change timeout for a key
```

## File

`~/utono/rpd/.claude/commands/rpd/keyd.md`
