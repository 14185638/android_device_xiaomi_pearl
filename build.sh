#!/bin/bash
# =============================================================================
# LineageOS Build Script for pearl device (MTK 6895)
# Usage:
#   ./build.sh            - 自动模式，顺序编译 VANILLA + GAPPS 两个版本
#   ./build.sh auto       - 同 ./build.sh
#   ./build.sh manual     - 生成可执行的命令脚本
# =============================================================================

set -eo pipefail

# --- 配置区 -----------------------------------------------------------
export USE_CCACHE=1
export CCACHE_DIR=
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_MAXSIZE=80G

LINEAGE_VER="22.2"
BUILD_DATE=$(date +%Y%m%d)
KEY_DIR=".android-certs"
MY_TMP=""
PAYLOAD_DUMPPER="payload-dummper/payload-dumper-go"
OUTPUT_BASE="Android-ROMs"
RAW_TARGET_ZIP="out/dist/lineage_pearl-target_files-admin.zip"

GAPPS_OTA_NAME="GAPPS-lineage-${LINEAGE_VER}-${BUILD_DATE}-UNOFFICIAL-pearl"
VANILLA_OTA_NAME="VANILLA-lineage-${LINEAGE_VER}-${BUILD_DATE}-UNOFFICIAL-pearl"

GAPPS_OUTPUT_DIR="${OUTPUT_BASE}/${GAPPS_OTA_NAME}"
VANILLA_OUTPUT_DIR="${OUTPUT_BASE}/${VANILLA_OTA_NAME}"

# --- 参数解析 ---------------------------------------------------------
MODE="${1:-auto}"
if [ "$MODE" != "auto" ] && [ "$MODE" != "manual" ]; then
    echo "Usage: $0 [auto|manual]"
    exit 1
fi

# --- 辅助函数 ---------------------------------------------------------
green()  { echo -e "\033[1;32m$*\033[0m"; }
cyan()   { echo -e "\033[1;36m$*\033[0m"; }
yellow() { echo -e "\033[1;33m$*\033[0m"; }
red()    { echo -e "\033[1;31m$*\033[0m"; }

header() {
    echo -e "\n\033[1;33m================================================================\033[0m"
    echo -e "\033[1;33m  $*\033[0m"
    echo -e "\033[1;33m================================================================\033[0m"
}

# ==========================================================================
# 手动模式: 打印编译命令到终端
# ==========================================================================
if [ "$MODE" = "manual" ]; then
    yellow "================================================================================"
    yellow " 手动模式 — 已解析参数的编译命令 (可直接逐条复制执行)"
    yellow " 配置摘要: CCACHE=${CCACHE_DIR}  KEY=${KEY_DIR}  TMP=${MY_TMP}"
    yellow "================================================================================"
    echo ""

    cyan "# === 环境设置 ==="
    echo "export USE_CCACHE=1"
    echo "export CCACHE_DIR=${CCACHE_DIR}"
    echo "export CCACHE_EXEC=${CCACHE_EXEC}"
    echo "export CCACHE_MAXSIZE=${CCACHE_MAXSIZE}"
    echo "mkdir -p ${MY_TMP}"
    echo "export TMPDIR=${MY_TMP}"
    echo "mkdir -p ${OUTPUT_BASE}"
    echo "source build/envsetup.sh"
    echo ""

    cyan "# ========== 编译 VANILLA (无GMS) =========="
    echo "export WITH_GMS=false"
    echo "lunch lineage_pearl-bp1a-user"
    echo "mka target-files-package dist WITH_GMS=false"
    echo "sign_target_files_apks -v -d ${KEY_DIR}/ ${RAW_TARGET_ZIP} signed-target-files-VANILLA.zip"
    echo "ota_from_target_files -v -k ${KEY_DIR}/releasekey signed-target-files-VANILLA.zip ${VANILLA_OTA_NAME}.zip"
    echo "mkdir -p ${VANILLA_OUTPUT_DIR}"
    echo "cp ${VANILLA_OTA_NAME}.zip ${VANILLA_OUTPUT_DIR}/"
    echo "mkdir -p ${MY_TMP}payload-extract-VANILLA"
    echo "${PAYLOAD_DUMPPER} -o ${MY_TMP}payload-extract-VANILLA -p boot,vendor_boot ${VANILLA_OTA_NAME}.zip"
    echo "cp ${MY_TMP}payload-extract-VANILLA/boot.img ${VANILLA_OUTPUT_DIR}/boot.img"
    echo "cp ${MY_TMP}payload-extract-VANILLA/vendor_boot.img ${VANILLA_OUTPUT_DIR}/vendor_boot.img"
    echo "rm -rf ${MY_TMP}payload-extract-VANILLA"
    echo "cd ${VANILLA_OUTPUT_DIR} && sha256sum ${VANILLA_OTA_NAME}.zip boot.img vendor_boot.img > SHA256.txt && cd - > /dev/null"
    echo "rm -f signed-target-files-VANILLA.zip"
    echo "rm -f ${VANILLA_OTA_NAME}.zip"
    echo "mka installclean"
    echo ""

    cyan "# ========== 编译 GAPPS (带GMS) =========="
    echo "export WITH_GMS=true"
    echo "lunch lineage_pearl-bp1a-user"
    echo "mka target-files-package dist WITH_GMS=true"
    echo "sign_target_files_apks -v -d ${KEY_DIR}/ ${RAW_TARGET_ZIP} signed-target-files-GAPPS.zip"
    echo "ota_from_target_files -v -k ${KEY_DIR}/releasekey signed-target-files-GAPPS.zip ${GAPPS_OTA_NAME}.zip"
    echo "mkdir -p ${GAPPS_OUTPUT_DIR}"
    echo "cp ${GAPPS_OTA_NAME}.zip ${GAPPS_OUTPUT_DIR}/"
    echo "mkdir -p ${MY_TMP}payload-extract-GAPPS"
    echo "${PAYLOAD_DUMPPER} -o ${MY_TMP}payload-extract-GAPPS -p boot,vendor_boot ${GAPPS_OTA_NAME}.zip"
    echo "cp ${MY_TMP}payload-extract-GAPPS/boot.img ${GAPPS_OUTPUT_DIR}/boot.img"
    echo "cp ${MY_TMP}payload-extract-GAPPS/vendor_boot.img ${GAPPS_OUTPUT_DIR}/vendor_boot.img"
    echo "rm -rf ${MY_TMP}payload-extract-GAPPS"
    echo "cd ${GAPPS_OUTPUT_DIR} && sha256sum ${GAPPS_OTA_NAME}.zip boot.img vendor_boot.img > SHA256.txt && cd - > /dev/null"
    echo "rm -f signed-target-files-GAPPS.zip"
    echo "rm -f ${GAPPS_OTA_NAME}.zip"
    echo ""

    yellow "================================================================================"
    yellow " 产物目录: ${VANILLA_OUTPUT_DIR}/"
    yellow " 产物目录: ${GAPPS_OUTPUT_DIR}/"
    yellow "================================================================================"
    exit 0
fi

# ==========================================================================
# 自动模式: 从此以下只在 auto 模式运行
# ==========================================================================
set -e

# 依赖检查
if [ ! -f "$PAYLOAD_DUMPPER" ]; then
    red "[!] 找不到 payload-dumper-go: ${PAYLOAD_DUMPPER}"
    exit 1
fi
if [ ! -d "$KEY_DIR" ]; then
    red "[!] 找不到密钥目录: ${KEY_DIR}"
    exit 1
fi

# 环境初始化
mkdir -p "$MY_TMP"
mkdir -p "$OUTPUT_BASE"
export TMPDIR="$MY_TMP"

header "初始化构建环境"
cyan "source build/envsetup.sh"
source build/envsetup.sh

cyan "lunch lineage_pearl-bp1a-user"
lunch lineage_pearl-bp1a-user

# ====================== VANILLA 编译 ======================
build_variant() {
    local with_gms="$1"
    local ota_name="$2"
    local output_dir="$3"
    local label

    if [ "$with_gms" = "true" ]; then
        label="GAPPS (带GMS)"
    else
        label="VANILLA (无GMS)"
    fi

    header "编译 ${label}"

    cyan "export WITH_GMS=${with_gms}"
    export WITH_GMS="${with_gms}"

    cyan "lunch lineage_pearl-bp1a-user"
    lunch lineage_pearl-bp1a-user

    cyan "mka target-files-package dist WITH_GMS=${with_gms}"
    mka target-files-package dist "WITH_GMS=${with_gms}"

    cyan "签名 target-files"
    sign_target_files_apks -v -d "$KEY_DIR/" "$RAW_TARGET_ZIP" "signed-target-files-${label}.zip"

    cyan "生成 OTA 包: ${ota_name}.zip"
    ota_from_target_files -v -k "$KEY_DIR/releasekey" "signed-target-files-${label}.zip" "${ota_name}.zip"

    if [ ! -f "${ota_name}.zip" ]; then
        red "[!] OTA 包生成失败: ${ota_name}.zip"
        exit 1
    fi

    cyan "创建输出目录: ${output_dir}"
    mkdir -p "$output_dir"

    cyan "拷贝 OTA 包"
    cp "${ota_name}.zip" "${output_dir}/"

    cyan "提取 boot.img 和 vendor_boot.img"
    local extract_dir="${MY_TMP}/payload-extract-${label}"
    mkdir -p "$extract_dir"
    "$PAYLOAD_DUMPPER" -o "$extract_dir" -p boot,vendor_boot "${ota_name}.zip"
    cp "${extract_dir}/boot.img" "${output_dir}/boot.img"
    cp "${extract_dir}/vendor_boot.img" "${output_dir}/vendor_boot.img"
    rm -rf "$extract_dir"

    cyan "生成 SHA256 校验文件"
    (
        cd "$output_dir"
        sha256sum "${ota_name}.zip" boot.img vendor_boot.img > SHA256.txt
    )
    green "${label} SHA256:"
    cat "${output_dir}/SHA256.txt"

    cyan "清理中间文件"
    rm -f "signed-target-files-${label}.zip"
    rm -f "${ota_name}.zip"

    green "${label} 编译完成！产物: ${output_dir}/"
}

# 1. 编译 VANILLA
build_variant "false" "$VANILLA_OTA_NAME" "$VANILLA_OUTPUT_DIR"

# 中间清理
header "清理构建缓存 (installclean)"
mka installclean

# 2. 编译 GAPPS
build_variant "true" "$GAPPS_OTA_NAME" "$GAPPS_OUTPUT_DIR"

# ====================== 完成 ======================
header "全部编译完成！"

echo ""
green "VANILLA (无GMS):"
ls -lh "$(pwd)/${VANILLA_OUTPUT_DIR}/" 2>/dev/null || true
echo ""
green "GAPPS (带GMS):"
ls -lh "$(pwd)/${GAPPS_OUTPUT_DIR}/" 2>/dev/null || true
echo ""
yellow "产物结构:"
echo "  ${GAPPS_OUTPUT_DIR}/"
echo "    ├── ${GAPPS_OTA_NAME}.zip"
echo "    ├── boot.img"
echo "    ├── vendor_boot.img"
echo "    └── SHA256.txt"
echo "  ${VANILLA_OUTPUT_DIR}/"
echo "    ├── ${VANILLA_OTA_NAME}.zip"
echo "    ├── boot.img"
echo "    ├── vendor_boot.img"
echo "    └── SHA256.txt"
