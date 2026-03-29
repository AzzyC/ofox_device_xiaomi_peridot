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

purge_logs() {
	LOGMSG "Purging recovery-generated logs older than 14 days..."

	FOX_LOG_DIR="/persist/Fox/logs"

	if [ -d "$FOX_LOG_DIR" ]; then
		find "$FOX_LOG_DIR" -maxdepth 1 -type f -mtime +14 -print -delete
	else
		LOGMSG "$FOX_LOG_DIR not present"
	fi
}

SCRIPT_NAME="$(basename "$0")"

LOGMSG "---$SCRIPT_NAME start---"

reset_touch

purge_logs

LOGMSG "---$SCRIPT_NAME end---"
exit 0
