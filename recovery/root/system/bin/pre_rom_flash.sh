#!/system/bin/sh

SCRIPT_NAME="$(basename "$0")"

LOGMSG() {
    echo "I:$@" >> /tmp/recovery.log
}

LOGMSG "---$SCRIPT_NAME start---"

LOGMSG "Resetting SPL date to prevent anti-rollback protection..."
resetprop ro.build.version.security_patch 2023-12-31

# LOGMSG "Formatting /metadata..."
# make_f2fs /dev/block/bootdevice/by-name/metadata

LOGMSG "Detecting active boot slot..."
slot="$(getprop ro.boot.slot_suffix)"
if [ -z "$slot" ]; then
    LOGMSG "Unable to detect active boot slot; skipping recovery backup..."
else
    LOGMSG "Active boot slot: $slot"

    LOGMSG "Backing up OrangeFox recovery before ROM overwrites..."
    if [ -e /dev/block/bootdevice/by-name/recovery${slot} ]; then
        if dd if="/dev/block/bootdevice/by-name/recovery${slot}" of="/tmp/fox_backup.img" bs=1M; then
            sync
            LOGMSG "Backup of OrangeFox recovery was successful"
        else
            LOGMSG "Failed to backup OrangeFox recovery..."
        fi
    else
        LOGMSG "Recovery partition not found; skipping backup..."
    fi
fi

LOGMSG "---$SCRIPT_NAME end---"
