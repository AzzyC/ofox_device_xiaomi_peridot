#!/sbin/sh

LOGMSG() {
    echo "I:$@" >> /tmp/recovery.log;
}

FILE_PATH="/FFiles/wipe_no_storage.zip"

LOGMSG "$(basename "$0") start"

[ -f "$FILE_PATH" ] && /system/bin/fox install "$FILE_PATH" && LOGMSG "${FILE_PATH##*/} flashed successfully"

LOGMSG "$(basename "$0") end"

exit 0
