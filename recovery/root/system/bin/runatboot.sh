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

optimize_io_and_cpu() {
	LOGMSG "Applying I/O optimizations to block devices..."

	# Optimize all physical UFS partitions (sda, sdb, sdc, sdd, sde, sdf)
	for disk in /sys/block/sd*; do
		if [ -d "$disk/queue" ]; then
			dev=$(basename "$disk")
			# 1. Bypass scheduler overhead (direct I/O dispatch)
			if grep -q "none" "$disk/queue/scheduler" 2>/dev/null; then
				echo none > "$disk/queue/scheduler" 2>/dev/null
			fi

			# 2. Increase read-ahead buffer to 2048 KB
			echo 2048 > "$disk/queue/read_ahead_kb" 2>/dev/null

			# 3. Increase block request backlog depth
			echo 512 > "$disk/queue/nr_requests" 2>/dev/null

			# 4. Disable I/O accounting statistics to reduce CPU kernel overhead
			echo 0 > "$disk/queue/iostats" 2>/dev/null

			# 5. Disable rotational delay penalty
			echo 0 > "$disk/queue/rotational" 2>/dev/null

			# 6. Disable add_random overhead (don't contribute disk entropy)
			echo 0 > "$disk/queue/add_random" 2>/dev/null

			LOGMSG "Optimized physical device: $dev"
		fi
	done

	# Optimize dynamic partition mapper and loop devices (dm-*, loop*)
	for dev in /sys/block/dm-* /sys/block/loop*; do
		if [ -d "$dev/queue" ]; then
			echo 2048 > "$dev/queue/read_ahead_kb" 2>/dev/null
			echo 512 > "$dev/queue/nr_requests" 2>/dev/null
			echo 0 > "$dev/queue/iostats" 2>/dev/null
		fi
	done

	LOGMSG "Setting CPU scaling governors to walt..."
	echo walt > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null
	echo walt > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor 2>/dev/null
	echo walt > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor 2>/dev/null

	LOGMSG "I/O optimization complete."
}

SCRIPT_NAME="$(basename "$0")"

LOGMSG "---$SCRIPT_NAME start---"

reset_touch
optimize_io_and_cpu

/sbin/prune_historic_logs.sh 10

LOGMSG "---$SCRIPT_NAME end---"
exit 0
