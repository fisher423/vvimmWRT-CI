#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026
# OpenWrt DIY script part 1 (Before Update feeds)

echo "--- DIY Part 1: Device-specific modifications ---"
echo "WORKFLOW_NAME: $WORKFLOW_NAME"
echo "---"

if [[ "$WORKFLOW_NAME" == "jdcloud_re-ss-01" ]]; then
    echo ">>> Detected device: $WORKFLOW_NAME. Applying jdcloud_re-ss-01 specific modifications"

    echo ">>> Modifying default IP to 192.168.31.1..."
    sed -i 's/192\.168\.[0-9]*\.[0-9]*/192.168.31.1/g' package/base-files/files/bin/config_generate
    echo "IP modified to 192.168.31.1"

    echo ">>> Modifying hostname..."
    sed -i "s/hostname='.*'/hostname='jdcloud-re-ss-01'/g" package/base-files/files/bin/config_generate
    echo "Hostname modified to jdcloud-re-ss-01"

    echo ">>> Injecting jdcloud_re-ss-01 device support from ImmortalWrt..."
    if [ -f "$GITHUB_WORKSPACE/sh/inject-device-support.sh" ]; then
        chmod +x $GITHUB_WORKSPACE/sh/inject-device-support.sh
        $GITHUB_WORKSPACE/sh/inject-device-support.sh
        echo ">>> Device support injection completed"
    else
        echo ">>> Warning: inject-device-support.sh not found at $GITHUB_WORKSPACE/sh/"
    fi

else
    echo ">>> Unknown WORKFLOW_NAME ('$WORKFLOW_NAME'). Skipping device-specific modifications."
fi

echo "--- DIY Part 1 completed ---"
