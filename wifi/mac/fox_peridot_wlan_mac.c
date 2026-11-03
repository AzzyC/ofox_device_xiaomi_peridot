/*
 * Copyright (C) 2026
 * SPDX-License-Identifier: Apache-2.0
 *
 * WLAN MAC provisioning and writes the existing wlan_mac.bin format
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/system_properties.h>
#include <unistd.h>

#define MAC_PATH "/vendor/firmware/wlan/qca_cld/qca6750/wlan_mac.bin"
#define MAC_DIR  "/vendor/firmware/wlan/qca_cld/qca6750"

static uint64_t fnv1a64(const char *serial) {
    uint64_t hash = UINT64_C(1469598103934665603);
    const char *sections[] = { "AERA-WLAN-v1:", serial };
    for (size_t part = 0; part < 2; ++part) {
        const unsigned char *p = (const unsigned char *) sections[part];
        while (*p) {
            hash ^= *p++;
            hash *= UINT64_C(1099511628211);
        }
    }
    return hash;
}

int main(void) {
    char serial[PROP_VALUE_MAX] = {0};
    if (__system_property_get("ro.serialno", serial) <= 0 || !serial[0]) {
        memset(serial, 0, sizeof(serial));
        __system_property_get("ro.boot.serialno", serial);
    }
    if (!serial[0]) {
        fputs("early MAC: no serial property; refusing shared fallback MAC\n", stderr);
        return 1;
    }

    /* /vendor must be the recovery ramdisk, not a mounted live-ROM partition. */
    FILE *mounts = fopen("/proc/mounts", "r");
    if (!mounts) {
        perror("early MAC: open /proc/mounts");
        return 1;
    }
    char line[1024];
    while (fgets(line, sizeof(line), mounts)) {
        char device[256], mountpoint[256];
        if (sscanf(line, "%255s %255s", device, mountpoint) == 2 &&
            strcmp(mountpoint, "/vendor") == 0) {
            fclose(mounts);
            fputs("early MAC: /vendor is mounted; refusing to write to ROM\n", stderr);
            return 1;
        }
    }
    fclose(mounts);

    struct stat st;
    if (stat(MAC_DIR, &st) != 0 || !S_ISDIR(st.st_mode)) {
        fputs("early MAC: recovery firmware directory missing\n", stderr);
        return 1;
    }

    const uint64_t hash = fnv1a64(serial);
    const unsigned char mac[6] = {
        0x02,
        (unsigned char)(hash),
        (unsigned char)(hash >> 8),
        (unsigned char)(hash >> 16),
        (unsigned char)(hash >> 24),
        (unsigned char)(hash >> 32),
    };
    char contents[64];
    const int length = snprintf(contents, sizeof(contents),
        "Intf0MacAddress=%02X%02X%02X%02X%02X%02X\n",
        mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    if (length <= 0 || (size_t)length >= sizeof(contents)) return 1;

    const int fd = open(MAC_PATH, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW, 0644);
    if (fd < 0) {
        perror("early MAC: create wlan_mac.bin");
        return 1;
    }
    ssize_t written = 0;
    while (written < length) {
        const ssize_t count = write(fd, contents + written, (size_t)(length - written));
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) {
            perror("early MAC: write wlan_mac.bin");
            close(fd);
            return 1;
        }
        written += count;
    }
    if (fchmod(fd, 0644) != 0) {
        perror("early MAC: chmod wlan_mac.bin");
        close(fd);
        return 1;
    }
    if (close(fd) != 0) {
        perror("early MAC: close wlan_mac.bin");
        return 1;
    }
    puts("early MAC: generated FOX-compatible per-device wlan_mac.bin");
    return 0;
}
