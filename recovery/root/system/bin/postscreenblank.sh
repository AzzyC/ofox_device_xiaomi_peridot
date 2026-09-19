#!/system/bin/sh

SCRIPT_NAME="$(basename "$0")"

LOGMSG() {
    echo "I:$@" >> /tmp/recovery.log
}

TS="/sys/devices/platform/goodix_ts.0"
MARKER="/tmp/.ts_blank"

[ -e "$MARKER" ] && exit 0

LOGMSG "---$SCRIPT_NAME start---"

if [ -e "$TS/irq_info" ] && [ -e "$TS/reset" ]; then
    if echo 1 > "$TS/irq_info" &&
       echo 1 > "$TS/reset"; then
        touch "$MARKER"
        LOGMSG "Touchscreen reset and marker placed"
    else
        LOGMSG "Failed to reset touchscreen"
    fi
fi

LOGMSG "---$SCRIPT_NAME end---"
