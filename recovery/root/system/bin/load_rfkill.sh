#!/system/bin/sh
# Ensure RFKill is available before WLAN OR audio modules

SCRIPT_NAME="$(basename "$0")"
LOGMSG() {
    echo "I:$@" >> /tmp/recovery.log
}

finish() {
    LOGMSG "---$SCRIPT_NAME end---"
    exit "$1"
}

fail() {
    LOGMSG "ERROR: $*"
    finish 1
}

rfkill_loaded() {
    grep -q '^rfkill ' /proc/modules || [ -d /sys/module/rfkill ]
}

LOGMSG "---$SCRIPT_NAME start---"

if rfkill_loaded; then
    LOGMSG "RFKill already available"
    finish 0
fi

SLOT="$(getprop ro.boot.slot_suffix)"
case "$SLOT" in
    _a|_b) ;;
    *) fail "Invalid active slot: $SLOT" ;;
esac

# Use existing /system_dlkm, otherwise mount via recovery's mechanism, otherwise our own mount
ROOT=/system_dlkm
if ! grep -q " $ROOT " /proc/mounts; then
    mount "$ROOT"
    if grep -q " $ROOT " /proc/mounts; then
        LOGMSG "Mounted $ROOT through recovery"
    else
        LOGMSG "Recovery mount of /system_dlkm unavailable; trying active-slot fallback"
        ROOT=/mnt/fox-rfkill-system_dlkm
        if ! grep -q " $ROOT " /proc/mounts; then
            PART="/dev/block/mapper/system_dlkm$SLOT"
            [ -b "$PART" ] || fail "Missing partition: $PART"
            mkdir -p "$ROOT" || fail "Could not create $ROOT"
            mount -t erofs -o ro "$PART" "$ROOT" || \
                mount -t ext4 -o ro "$PART" "$ROOT" || \
                fail "Could not mount $PART"
            LOGMSG "Mounted $PART read-only at $ROOT"
        fi
    fi
fi

for MODULE in \
    "$ROOT/flatten/lib/modules/rfkill.ko" \
    "$ROOT/lib/modules/rfkill.ko" \
    "$ROOT"/lib/modules/*/kernel/net/rfkill/rfkill.ko; do
    [ -f "$MODULE" ] || continue

    if rfkill_loaded; then
        LOGMSG "RFKill was loaded by another service"
        finish 0
    fi

    insmod "$MODULE"
    rfkill_loaded || fail "Unable to load RFKill from $MODULE"
    LOGMSG "Loaded RFKill from $MODULE"
    finish 0
done

fail "rfkill.ko not found in $ROOT"
