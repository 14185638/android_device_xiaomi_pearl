#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
ifeq ($(WITH_GMS),true)
    # 请务必检查你的 vendor/ 下是否存在这个目录，MindTheGapps 常见的入口如下：
    $(call inherit-product, vendor/gapps/arm64/arm64-vendor.mk)
endif
# Inherit from pearl device
$(call inherit-product, device/xiaomi/pearl/device.mk)

PRODUCT_DEVICE := pearl
PRODUCT_NAME := lineage_pearl
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 23054RA19C
PRODUCT_MANUFACTURER := Xiaomi

PRODUCT_SYSTEM_NAME := pearl
PRODUCT_SYSTEM_DEVICE := pearl
PRODUCT_CHARACTERISTICS := nosdcard

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# ROM Flags
WITH_GMS := false

# Enable DM file pre-opting to reduce first boot time
# Note that this may significantly increase your compilation time!
PRODUCT_DEX_PREOPT_GENERATE_DM_FILES := true

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint="Xiaomi/pearl/pearl:15/AP3A.240905.015.A2/OS2.0.207.0.VLHCNXM:user/release-keys"

# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop
BUILD_FINGERPRINT := Xiaomi/pearl/pearl:15/AP3A.240905.015.A2/OS2.0.207.0.VLHCNXM:user/release-keys

