#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

#set -o xtrace
FDEVICE="peridot"

fox_get_target_device() {
	local script_path="${BASH_SOURCE[0]}"
	if echo "$script_path" | grep -q "$FDEVICE"; then
		FOX_BUILD_DEVICE="$FDEVICE"
	elif echo "$0" | grep -q "$FDEVICE"; then
		FOX_BUILD_DEVICE="$FDEVICE"
	fi
}

if [ -z "$FOX_BUILD_DEVICE" ]; then
	fox_get_target_device
fi

if [ "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
	echo "Detected build device: $FOX_BUILD_DEVICE"

# Review build flags with below links:
# https://gitlab.com/OrangeFox/vendor/recovery/-/raw/fox_12.1/orangefox_build_vars.txt
# https://gitlab.com/OrangeFox/bootable/Recovery/-/raw/fox_12.1/orangefox.mk
	export FOX_VIRTUAL_AB_DEVICE=1
	export FOX_VANILLA_BUILD=1
	export FOX_RECOVERY_SYSTEM_PARTITION="/dev/block/mapper/system"
	export FOX_RECOVERY_VENDOR_PARTITION="/dev/block/mapper/vendor"
	export FOX_USE_BASH_SHELL=1
	export FOX_USE_NANO_EDITOR=1
	export FOX_DELETE_AROMAFM=1
	export FOX_REMOVE_AAPT=1
	export FOX_DELETE_MAGISK_ADDON=1
else
	echo "I: vendorsetup.sh skipped; device mismatch or environment issue."
fi
