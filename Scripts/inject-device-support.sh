#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026
# Inject device support for jdcloud_re-ss-01 from ImmortalWrt

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Injecting jdcloud_re-ss-01 device support${NC}"
echo -e "${GREEN}=============================================${NC}"

OPENWRT_DIR="$PWD"
IMMORTALWRT_URL="https://github.com/immortalwrt/immortalwrt.git"
IMMORTALWRT_BRANCH="master"
TEMP_DIR="/tmp/immortalwrt-device-inject"

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

echo -e "${YELLOW}[1/5] Clone ImmortalWrt source (target/linux/qualcommax)...${NC}"

cd "$TEMP_DIR"
git clone -b "$IMMORTALWRT_BRANCH" "$IMMORTALWRT_URL" --single-branch --depth 1 immortalwrt-temp

cd immortalwrt-temp
git sparse-checkout set target/linux/qualcommax 2>/dev/null || true
git checkout 2>/dev/null || true

echo -e "${YELLOW}[2/5] Copy qualcommax/ipq60xx device support files...${NC}"

TARGET_DIR="$OPENWRT_DIR/target/linux/qualcommax"
mkdir -p "$TARGET_DIR"

if [ -d "target/linux/qualcommax/ipq60xx" ]; then
    mkdir -p "$TARGET_DIR/ipq60xx"
    cp -rf target/linux/qualcommax/ipq60xx/* "$TARGET_DIR/ipq60xx/" 2>/dev/null || \
    cp -rf target/linux/qualcommax/ipq60xx "$TARGET_DIR/"
    echo -e "${GREEN}  Copied target/linux/qualcommax/ipq60xx${NC}"
fi

if [ -d "target/linux/qualcommax/dts" ]; then
    mkdir -p "$TARGET_DIR/dts"
    cp -rf target/linux/qualcommax/dts/* "$TARGET_DIR/dts/" 2>/dev/null || \
    cp -rf target/linux/qualcommax/dts "$TARGET_DIR/"
    echo -e "${GREEN}  Copied target/linux/qualcommax/dts${NC}"
fi

if [ -d "target/linux/qualcommax/image" ]; then
    mkdir -p "$TARGET_DIR/image"
    cp -rf target/linux/qualcommax/image/* "$TARGET_DIR/image/" 2>/dev/null || \
    cp -rf target/linux/qualcommax/image "$TARGET_DIR/"
    echo -e "${GREEN}  Copied target/linux/qualcommax/image${NC}"
fi

echo -e "${YELLOW}[3/5] Copy wifi board files for jdcloud...${NC}"

WIFI_BOARD_DIR="$OPENWRT_DIR/package/firmware/ipq-wifi"
mkdir -p "$WIFI_BOARD_DIR"
for board_file in "$TEMP_DIR/immortalwrt-temp/package/firmware/ipq-wifi/board-"*jdcloud*; do
    if [ -f "$board_file" ]; then
        cp -f "$board_file" "$WIFI_BOARD_DIR/"
        echo -e "${GREEN}  Copied wifi board: $(basename $board_file)${NC}"
    fi
done

echo -e "${YELLOW}[4/5] Check and fix device configuration...${NC}"

if [ -f "$TARGET_DIR/image/ipq60xx.mk" ]; then
    if grep -q "jdcloud_re-ss-01" "$TARGET_DIR/image/ipq60xx.mk"; then
        echo -e "${GREEN}  jdcloud_re-ss-01 device definition exists${NC}"
    else
        echo -e "${RED}  jdcloud_re-ss-01 device definition not found, adding...${NC}"

        cat >> "$TARGET_DIR/image/ipq60xx.mk" << 'EOF'

define Device/jdcloud_re-ss-01
	$(call Device/FitImage)
	DEVICE_VENDOR := JDCloud
	DEVICE_MODEL := RE-SS-01
	SOC := ipq6000
	BLOCKSIZE := 64k
	KERNEL_SIZE := 6144k
	DEVICE_DTS_CONFIG := config@cp03-c2
	DEVICE_PACKAGES := ipq-wifi-jdcloud_re-ss-01
endef
TARGET_DEVICES += jdcloud_re-ss-01
EOF
        echo -e "${GREEN}  Added jdcloud_re-ss-01 device definition${NC}"
    fi
else
    echo -e "${RED}  ipq60xx.mk not found${NC}"
fi

if [ ! -f "$TARGET_DIR/ipq60xx/target.mk" ]; then
    mkdir -p "$TARGET_DIR/ipq60xx"
    cat > "$TARGET_DIR/ipq60xx/target.mk" << 'EOF'
SUBTARGET:=ipq60xx
BOARDNAME:=Qualcomm Atheros IPQ60xx
DEFAULT_PACKAGES += ath11k-firmware-ipq6018
define Target/Description
	Build firmware images for Qualcomm Atheros IPQ60xx based boards.
endef
EOF
    echo -e "${GREEN}  Created ipq60xx/target.mk${NC}"
fi

if [ ! -f "$TARGET_DIR/ipq60xx/config-default" ]; then
    mkdir -p "$TARGET_DIR/ipq60xx"
    cat > "$TARGET_DIR/ipq60xx/config-default" << 'EOF'
CONFIG_IPQ_CMN_PLL=y
CONFIG_IPQ_GCC_6018=y
CONFIG_MTD_SPLIT_FIT_FW=y
CONFIG_PINCTRL_IPQ6018=y
CONFIG_PWM=y
CONFIG_PWM_IPQ=y
CONFIG_QCOM_APM=y
# CONFIG_QCOM_CLK_SMD_RPM is not set
# CONFIG_QCOM_RPMPD is not set
CONFIG_QCOM_SMD_RPM=y
CONFIG_REGULATOR_CPR3=y
# CONFIG_REGULATOR_CPR3_NPU is not set
CONFIG_REGULATOR_CPR4_APSS=y
CONFIG_REGULATOR_QCOM_SMD_RPM=y
EOF
    echo -e "${GREEN}  Created ipq60xx/config-default${NC}"
fi

echo -e "${YELLOW}[5/5] Check qualcommax/Makefile...${NC}"

if [ -f "$TARGET_DIR/Makefile" ]; then
    if grep -q "ipq60xx" "$TARGET_DIR/Makefile"; then
        echo -e "${GREEN}  qualcommax/Makefile contains ipq60xx subtarget${NC}"
    else
        echo -e "${YELLOW}  qualcommax/Makefile does not contain ipq60xx${NC}"
    fi
else
    echo -e "${RED}  qualcommax/Makefile not found${NC}"
fi

cd "$OPENWRT_DIR"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  jdcloud_re-ss-01 device support injected!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "You can now compile with these configurations:"
echo "  CONFIG_TARGET_qualcommax=y"
echo "  CONFIG_TARGET_qualcommax_ipq60xx=y"
echo "  CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-ss-01=y"
echo ""
