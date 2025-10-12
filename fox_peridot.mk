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

# screen settings
# e.g. if the aspect ratio is 19:9 then use 19*120 (=2280)
OF_SCREEN_H := 2400
#OF_STATUS_H := 100
#OF_HIDE_NOTCH := 1
OF_CLOCK_POS := 1
OF_STATUS_INDENT_LEFT := 56
OF_STATUS_INDENT_RIGHT := 48
OF_ALLOW_DISABLE_NAVBAR := 0
OF_USE_GREEN_LED := 0

# other stuff
OF_QUICK_BACKUP_LIST := /boot;/data;
OF_ENABLE_LPTOOLS := 1
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_DYNAMIC_FULL_SIZE := 9122611200

# number of list options before scrollbar creation
OF_OPTIONS_LIST_NUM := 6

# A/B with recovery partition
OF_AB_DEVICE_WITH_RECOVERY_PARTITION := 1

# ----- data format stuff -----
# ensure that /sdcard is bind-unmounted before f2fs data repair or format
OF_UNBIND_SDCARD_F2FS := 1

# automatically wipe /metadata after data format
OF_WIPE_METADATA_AFTER_DATAFORMAT := 1

# avoid MTP issues after data format
OF_BIND_MOUNT_SDCARD_ON_FORMAT := 1

# don't spam the console with loop errors
OF_LOOP_DEVICE_ERRORS_TO_LOG := 1

# lz4 compression
OF_USE_LZ4_COMPRESSION := 1 

# build all the partition tools
OF_ENABLE_ALL_PARTITION_TOOLS := 1

ifeq ($(FIXED_DECRYPT),false)
	# Set to 1 to skip the FBE decryption routines (prevents hanging at the Fox logo or Redmi/Mi logo)
	OF_SKIP_FBE_DECRYPTION := 1
endif

# Set this to 1 to replace the "Swipe up" lockscreen screen with a button
OF_USE_LOCKSCREEN_BUTTON := 1

# Called just before formatting /data; only useful for devices/ROMs that have dynamic partitions
OF_USE_DMCTL := 1

# Use this to change the default time zone
OF_DEFAULT_TIMEZONE := GMT0;BST,M3.5.0,M10.5.0

# Set this to 1 to avoid the new 'NO KERNEL CONFIG' error, when using a prebuilt kernel
OF_FORCE_PREBUILT_KERNEL := 1
