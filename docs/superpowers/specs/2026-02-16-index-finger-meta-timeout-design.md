# Reduce Index Finger Meta Hold Timeout

**Date:** 2026-02-16
**Status:** Approved

## Problem

The 200ms hold timeout on `f` and `j` (index finger meta keys) makes meta activate too slowly when intentionally held.

## Change

Reduce hold timeout from 200ms to 150ms on both index finger meta keys in `etc/keyd/default.conf`. Tap timeout (100ms) unchanged.

**Before:**
```
f = lettermod(meta, f, 100, 200)
j = lettermod(meta, j, 100, 200)
```

**After:**
```
f = lettermod(meta, f, 100, 150)
j = lettermod(meta, j, 100, 150)
```

All other home row mods remain at 100/200.

## Verification

Run `sudo keyd reload` after editing to apply live.
