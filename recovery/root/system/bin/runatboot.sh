#!/system/bin/sh

DEBUG=0
[ "$DEBUG" = "1" ] && set -o xtrace;

LOGMSG() {
	echo "I:$@" >> /tmp/recovery.log
}

reset_touch() {
	if [ -d /sys/devices/platform/goodix_ts.0 ]; then
		LOGMSG "Resetting Goodix touchscreen post screen blank..."
		echo 1 > /sys/devices/platform/goodix_ts.0/irq_info
		echo 1 > /sys/devices/platform/goodix_ts.0/reset
	else
		LOGMSG "Goodix touchscreen sysfs not present; skipping reset..."
	fi
}

purge_logs() {
	LOGMSG "Purging recovery-generated logs older than 10 days..."

	FOX_LOG_DIR="/persist/Fox/logs"

	if [ -d "$FOX_LOG_DIR" ]; then
		find "$FOX_LOG_DIR" -maxdepth 1 -type f -mtime +10 -print -delete
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
