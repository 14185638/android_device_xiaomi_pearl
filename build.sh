#!/bin/bash
export USE_CCACHE=1
export CCACHE_DIR=/run/media/admin/a5395aff-301c-46e3-b383-f32a6b9bbde7/CCACHE/
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_MAXSIZE=80G
# --- 配置区 ---
# 直接写死路径，确保万无一失
RAW_TARGET_ZIP="out/dist/lineage_pearl-target_files-admin.zip"
KEY_DIR=".android-certs"
MY_TMP="/run/media/admin/a5395aff-301c-46e3-b383-f32a6b9bbde7/tmp/"

# 提取版本号
LINEAGE_VER="22.2"
BUILD_DATE=$(date +%Y%m%d)
FINAL_OTA_NAME="lineage-${LINEAGE_VER}-${BUILD_DATE}-UNOFFICIAL-pearl.zip"
# --------------

# 设置环境变量
export TMPDIR="$MY_TMP"
mkdir -p "$TMPDIR"

function wait_5s() {
    echo -e "\n\033[1;33m>>> 准备执行: $1\033[0m"
    echo -e "\033[0;36m[等待5秒...] 按任意键跳过，或 Ctrl+C 退出\033[0m"
    read -t 5 -n 1
    echo "开始执行..."
}

function check_status() {
    if [ $? -ne 0 ]; then
        echo -e "\n\033[1;31m[!] 上一步命令执行出错！\033[0m"
        echo -e "\033[1;32m是否强制继续下一步？(y/n)\033[0m"
        read -n 1 user_choice
        echo ""
        if [[ "$user_choice" != "y" ]]; then
            echo "脚本已终止。"
            exit 1
        fi
    fi
}

# --- 步骤 0: 初始化环境 ---
wait_5s "source build/envsetup.sh && lunch lineage_pearl-bp1a-user"
source build/envsetup.sh
check_status
lunch lineage_pearl-bp1a-user
check_status

# --- 步骤 1: 编译 Target Files ---
wait_5s "mka target-files-package"
mka target-files-package dist
check_status

# --- 步骤 2: 执行正式签名 ---
wait_5s "签名 APK 并重写 build.prop (源文件: $RAW_TARGET_ZIP)"
# 显式指定从根目录开始的路径
sign_target_files_apks \
    -v \
    -d "$KEY_DIR/" \
    "$RAW_TARGET_ZIP" \
    signed-target-files.zip
check_status

# --- 步骤 3: 生成 OTA 包 ---
wait_5s "生成最终发布包: $FINAL_OTA_NAME"
ota_from_target_files \
    -v \
    -k "$KEY_DIR/releasekey" \
    signed-target-files.zip \
    "$FINAL_OTA_NAME"
check_status

echo -e "\n\033[1;32m--------------------------------------------------\033[0m"
echo -e "编译与签名流程全部完成！"
echo -e "最终产物: \033[1;34m$(pwd)/$FINAL_OTA_NAME\033[0m"
echo -e "\033[1;32m--------------------------------------------------\033[0m"
