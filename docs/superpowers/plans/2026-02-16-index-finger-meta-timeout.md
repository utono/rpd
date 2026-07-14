# Index Finger Meta Hold Timeout Reduction — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce meta hold timeout from 200ms to 150ms on both index finger keys (f, j) so meta activates faster when held.

**Architecture:** Single config file edit — two lines in `etc/keyd/default.conf`, then reload keyd daemon.

**Tech Stack:** keyd key remapping daemon, lettermod function

---

### Task 1: Edit index finger meta timeouts

**Files:**
- Modify: `etc/keyd/default.conf:19` — f key lettermod
- Modify: `etc/keyd/default.conf:21` — j key lettermod

**Step 1: Change f hold timeout**

Line 19, change:
```
f = lettermod(meta, f, 100, 200)
```
To:
```
f = lettermod(meta, f, 100, 150)
```

**Step 2: Change j hold timeout**

Line 21, change:
```
j = lettermod(meta, j, 100, 200)
```
To:
```
j = lettermod(meta, j, 100, 150)
```

**Step 3: Verify no other lines changed**

Run: `rg "lettermod" etc/keyd/default.conf`

Expected output — only f and j show 150, all others remain 200:
```
backslash = lettermod(meta, backslash, 100, 200)
a = lettermod(shift, a, 100, 200)
s = lettermod(control, s, 100, 200)
d = lettermod(alt, d, 100, 200)
f = lettermod(meta, f, 100, 150)
j = lettermod(meta, j, 100, 150)
k = lettermod(alt, k, 100, 200)
l = lettermod(control, l, 100, 200)
; = lettermod(shift, ;, 100, 200)
space = lettermod(meta, space, 100, 200)
```

**Step 4: Reload keyd**

Run: `sudo keyd reload`

Expected: keyd picks up new config. Meta on f/j should activate noticeably faster when held.

**Step 5: Commit**

```bash
git add etc/keyd/default.conf
git commit -m "feat(keyd): reduce index finger meta hold timeout to 150ms"
```
