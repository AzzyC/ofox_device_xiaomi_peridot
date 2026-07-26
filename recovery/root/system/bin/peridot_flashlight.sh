#!/system/bin/sh

DIR="/tmp/flashlight"
STATE_FILE="$DIR/brightness"
MAX_FILE="$DIR/max_brightness"

SWITCH="/sys/class/leds/led:switch_2/brightness"
TORCH_0="/sys/class/leds/led:torch_0/brightness"
TORCH_1="/sys/class/leds/led:torch_1/brightness"

LAST=""

rm -rf "$DIR"
mkdir -p "$DIR"

echo 1 > "$MAX_FILE"
echo 0 > "$STATE_FILE"

chmod 666 "$MAX_FILE" "$STATE_FILE"

echo 0 > "$SWITCH"
echo 0 > "$TORCH_0"
echo 0 > "$TORCH_1"

while true; do
    STATE=""
    IFS= read -r STATE < "$STATE_FILE"

    case "$STATE" in
        1|[1-9]*)
            if [ "$LAST" != "1" ]; then
                echo 40 > "$TORCH_0"
                echo 40 > "$TORCH_1"
                echo 1 > "$SWITCH"
                LAST="1"
            fi
            ;;
        *)
            if [ "$LAST" != "0" ]; then
                echo 0 > "$SWITCH"
                echo 0 > "$TORCH_0"
                echo 0 > "$TORCH_1"
                LAST="0"
            fi
            ;;
    esac

    sleep 0.1
done
