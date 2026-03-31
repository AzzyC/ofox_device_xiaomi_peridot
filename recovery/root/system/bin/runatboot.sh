#!/system/bin/sh

DEBUG=0
[ "$DEBUG" = "1" ] && set -o xtrace;

LOGMSG() {
	echo "I:$@" >> /tmp/recovery.log
}

reset_touch() {
	LOGMSG "Resetting touchscreen post screen blank..."
	echo 1 > /sys/devices/platform/goodix_ts.0/irq_info
	echo 1 > /sys/devices/platform/goodix_ts.0/reset
}

SCRIPT_NAME="$(basename "$0")"

LOGMSG "---$SCRIPT_NAME start---"

reset_touch

/sbin/prune_historic_logs.sh 10

LOGMSG "---$SCRIPT_NAME end---"
exit 0
