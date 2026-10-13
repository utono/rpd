#!/usr/bin/env bash
# Tests for bin/kanata-launch. Prints "N failure(s)", exits with the count.
here=$(cd "$(dirname "$0")/.." && pwd)
launch="$here/bin/kanata-launch"
fail=0
t=$(mktemp -d)
trap 'command rm -rf "$t"' EXIT

ok() { echo "PASS $1"; }
bad() { echo "FAIL $1"; fail=$((fail + 1)); }

mkdir -p "$t/bp-with" "$t/bp-none"
: > "$t/bp-with/platform-i8042-serio-0-event-kbd"
: > "$t/bp-with/platform-i8042-serio-1-event-kbd"
printf '#!/bin/sh\necho "STUB $*"\n' > "$t/stub"
chmod +x "$t/stub"
cp "$here/etc/kanata/kanata.kbd" "$t/in.kbd"
printf '(defcfg\n  process-unmapped-keys yes\n)\n(defsrc a)\n' > "$t/nodev.kbd"

run() { # byPath kbd out conf -> sets $stdout, $stderr
    stdout=$(BY_PATH="$1" KANATA_KBD="$2" KANATA_OUT="$3" MACHINE_CONF="$4" \
        KANATA_BIN="$t/stub" bash "$launch" 2> "$t/err")
    stderr=$(cat "$t/err")
}

# built-in present, no record
run "$t/bp-with" "$t/in.kbd" "$t/out1.kbd" "$t/none.conf"
want="  linux-dev $t/bp-with/platform-i8042-serio-0-event-kbd"
if [ "$(sed -n 2p "$t/out1.kbd")" = "$want" ]; then ok builtin-line; else bad builtin-line; fi
if [ "$stdout" = "STUB -c $t/out1.kbd" ]; then ok builtin-exec-args; else bad builtin-exec-args; fi
if [[ "$stderr" == *"kanata-launch: device $t/bp-with/platform-i8042-serio-0-event-kbd (built-in)"* ]]; then ok builtin-log; else bad builtin-log; fi
if diff <(sed 2d "$t/in.kbd") <(sed 2d "$t/out1.kbd") > /dev/null; then ok builtin-rest-identical; else bad builtin-rest-identical; fi

# no built-in, no record
run "$t/bp-none" "$t/in.kbd" "$t/out2.kbd" "$t/none.conf"
if ! rg -q linux-dev "$t/out2.kbd"; then ok none-no-linux-dev; else bad none-no-linux-dev; fi
if [[ "$stderr" == *"kanata-launch: every keyboard"* ]]; then ok none-log; else bad none-log; fi
if diff <(sed 2d "$t/in.kbd") "$t/out2.kbd" > /dev/null; then ok none-rest-identical; else bad none-rest-identical; fi

# record wins
printf 'hostname=x\nkanata_dev=/dev/input/event8\nkanata_dev=/dev/input/event9\n' > "$t/m.conf"
run "$t/bp-with" "$t/in.kbd" "$t/out3.kbd" "$t/m.conf"
if [ "$(sed -n 2p "$t/out3.kbd")" = "  linux-dev /dev/input/event9" ]; then ok record-line; else bad record-line; fi
if [[ "$stderr" == *"kanata-launch: device /dev/input/event9 (record)"* ]]; then ok record-log; else bad record-log; fi

# input without linux-dev, device found: inserted after (defcfg
run "$t/bp-with" "$t/nodev.kbd" "$t/out4.kbd" "$t/none.conf"
if [ "$(sed -n 1p "$t/out4.kbd")" = "(defcfg" ] && [ "$(sed -n 2p "$t/out4.kbd")" = "$want" ]; then ok insert-line; else bad insert-line; fi
if diff <(sed 2d "$t/out4.kbd") "$t/nodev.kbd" > /dev/null; then ok insert-rest-identical; else bad insert-rest-identical; fi

# input without linux-dev, no device: unchanged
run "$t/bp-none" "$t/nodev.kbd" "$t/out5.kbd" "$t/none.conf"
if cmp -s "$t/nodev.kbd" "$t/out5.kbd"; then ok nodev-nodevice-unchanged; else bad nodev-nodevice-unchanged; fi

# output directory is created
run "$t/bp-with" "$t/in.kbd" "$t/sub/dir/out.kbd" "$t/none.conf"
if [ -f "$t/sub/dir/out.kbd" ]; then ok creates-out-dir; else bad creates-out-dir; fi

echo "$fail failure(s)"
exit "$fail"
