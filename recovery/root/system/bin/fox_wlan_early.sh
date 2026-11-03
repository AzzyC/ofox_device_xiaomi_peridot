#!/system/bin/sh
# Start WPSS after pd-mapper exposes firmware
PATH=/system/bin:/sbin:/vendor/bin
export PATH
LOG=/tmp/fox_wlan_early.log

log() {
    echo "[fox-wlan-early] uptime=$(cut -d ' ' -f 1 /proc/uptime) $*" >> "$LOG"
    echo "[fox-wlan-early] $*" > /dev/kmsg 2>/dev/null || true
}
fail() { log "STOP: $*"; exit 1; }
prop() { getprop "$1" 2>/dev/null; }
loaded() {
    if [ "$1" = qca_cld3_qca6750 ]; then
        grep -Eq '^(qca_cld3_qca6750|wlan) ' /proc/modules 2>/dev/null
    else
        grep -q "^$1 " /proc/modules 2>/dev/null
    fi
}

# Both the early trigger and the post-decrypt fallback call this helper
if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 already present; no WPSS re-boot"
    [ "$(prop wifi.driver.ready)" = true ] || setprop wifi.driver.ready true
    exit 0
fi
if [ "$(prop ro.twrp.fastbootd)" = 1 ] || [ "$(prop ro.twrp.fastbootd)" = true ]; then
    log "fastbootd: skipping WLAN"
    exit 0
fi
[ "$(prop twrp.modules.loaded)" = true ] || fail "Initial modules not ready"

log "Early WLAN requested; post.decrypt.modules=$(prop post.decrypt.modules)"

# rfkill may not be loaded, e.g. on HyperOS, even after the initial module pass
/system/bin/load_rfkill.sh || fail "RFKill prerequisite unavailable"

# The initial module pass may have failed before rfkill exists
# Now rfkill is present, retry the modules that depend on it in correct, dependency order
for mod in cfg80211 qca_cld3_qca6750; do
    loaded "$mod" && continue
    candidate=""
    for path in \
        "/lib/modules/$mod.ko" \
        "/tmp/vendor/lib/modules/$mod.ko" \
        "/tmp/vendor_dlkm/lib/modules/$mod.ko" \
        "/vendor/lib/modules/$mod.ko" \
        "/vendor_dlkm/lib/modules/$mod.ko"; do
        if [ -f "$path" ]; then
            candidate="$path"
            break
        fi
    done
    if [ -z "$candidate" ]; then
        log "WLAN module missing on disk: $mod"
        continue
    fi
    if insmod "$candidate" 2>> "$LOG"; then
        log "Loaded missing WLAN module: $mod"
    else
        log "Could not load WLAN module $mod from $candidate"
    fi
done

count=0
while [ "$count" -lt 120 ]; do
    modules_ok=1
    for mod in cfg80211 gsim rmnet_mem ipam qca_cld3_qca6750; do
        loaded "$mod" || modules_ok=0
    done
    if [ "$modules_ok" = 1 ] && \
       [ "$(prop init.svc.vendor.gatekeeper_default)" = running ] && \
       [ -r /vendor/firmware_mnt/image/qca6750/wpss.mdt ] && \
       [ -r /vendor/firmware_mnt/image/qca6750/bdwlan.bin ]; then
        break
    fi
    sleep 0.1
    count=$((count+1))
done
if [ "$count" -ge 120 ]; then
    for mod in cfg80211 gsim rmnet_mem ipam qca_cld3_qca6750; do
        loaded "$mod" || log "MISSING_EARLY_MODULE: $mod"
    done
    fail "WLAN driver/crypto/mapper/firmware prerequisites not ready after 12s"
fi
log "WLAN modules and firmware ready, Gatekeeper running"

[ -w /sys/kernel/icnss/wlan_en_delay ] || fail "Missing WLAN delay node"
[ -w /sys/kernel/icnss/wpss_boot ] || fail "Missing WPSS boot node"

# The driver requests wlan_mac.bin about 7s after this worker starts.
# Provide recovery a per-device identity before requesting WPSS, instead of
# relying on recovery's later Wi-Fi setup to generate the file.
# This modifies only the recovery ramdisk
if [ ! -e /tmp/fox_wlan_wpss_requested ]; then
    [ -x /system/bin/fox-peridot-wlan-mac ] || fail "Missing recovery MAC helper"
    /system/bin/fox-peridot-wlan-mac >> "$LOG" 2>&1 || \
        fail "Failed to generate the deterministic MAC before WPSS"
    log "Prepared per-device WLAN MAC file before WPSS boot"
fi

# This marker survives the post-decrypt fallback but not a recovery reboot
# Avoid retriggering a remote processor that is already booting or running
if [ ! -e /tmp/fox_wlan_wpss_requested ]; then
    : > /tmp/fox_wlan_wpss_requested || fail "Cannot save WPSS boot marker"
    log "Requesting WPSS boot"
    printf '1000\n' > /sys/kernel/icnss/wlan_en_delay || fail "Cannot set WLAN delay"
    printf '1\n' > /sys/kernel/icnss/wpss_boot || fail "Cannot start WPSS"
else
    log "WPSS was already requested; waiting without repeating boot"
fi

count=0
while [ "$count" -lt 45 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done
[ -e /sys/class/net/wlan0 ] || fail "wlan0 absent after 45s"
log "wlan0 available after ${count}s; publishing wifi.driver.ready"
[ "$(prop wifi.driver.ready)" = true ] || setprop wifi.driver.ready true || fail "Cannot publish wifi.driver.ready"
