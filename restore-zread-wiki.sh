#!/usr/bin/env bash
set -euo pipefail

# ── zread wiki 备份解密恢复脚本 ──
# 密码: zread2026backup
# 用法: 将此脚本放在备份文件同目录下，直接运行即可
#       bash restore-zread-wiki.sh
#
# 支持两种来源:
#   1. 原始 .enc 文件 (zread-wiki-2026-07-02-backup.tar.gz.enc)
#   2. 分片 base64 文件 (backup_part_00.txt ~ backup_part_16.txt)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENC_FILE="$SCRIPT_DIR/zread-wiki-2026-07-02-backup.tar.gz.enc"
PART_PREFIX="$SCRIPT_DIR/backup_part_"

# 加密文件的基名，去掉 .enc 后缀就是解压后的 .tar.gz
BASENAME="zread-wiki-2026-07-02-backup.tar.gz"

# 目标目录: 从仓库根目录回到 .zread/wiki/
RESTORE_DIR="$SCRIPT_DIR/../.zread/wiki"

# ── 前置检查 ──
if ! command -v openssl &>/dev/null; then
    echo "❌ 需要openssl，请先安装"
    exit 1
fi

# ── 查找备份来源 ──
enc_available=false
parts_available=false

if [ -f "$ENC_FILE" ]; then
    enc_available=true
fi

# 检查是否存在分片文件
part_files=()
for f in "${PART_PREFIX}"*.txt; do
    if [ -f "$f" ]; then
        parts_available=true
        part_files+=("$f")
    fi
    break
done

if [ "$enc_available" = false ] && [ "$parts_available" = false ]; then
    echo "❌ 找不到备份文件"
    echo "   需要: $ENC_FILE 或 ${PART_PREFIX}*.txt"
    exit 1
fi

# ── 如果没有 .enc 文件，从分片还原 ──
if [ "$enc_available" = false ]; then
    echo "📦 从分片文件还原 .enc 文件..."
    cat "${PART_PREFIX}"*.txt | tr -d '\n\r' | base64 -d > "$ENC_FILE"
    echo "✅ 已还原: $ENC_FILE"
fi

# ── 输入密码 ──
read -rsp "请输入解密密码: " PASSWORD
echo ""
if [ -z "$PASSWORD" ]; then
    echo "❌ 密码不能为空"
    exit 1
fi

# ── 解密并解压 ──
echo "🔓 正在解密..."
mkdir -p "$RESTORE_DIR"

if echo "$PASSWORD" | openssl enc -aes-256-cbc -d -pbkdf2 -pass stdin \
    -in "$ENC_FILE" \
    | tar xzf - -C "$RESTORE_DIR" 2>/dev/null; then

    # ── 验证 ──
    if [ -f "$RESTORE_DIR/current" ]; then
        VERSION=$(cat "$RESTORE_DIR/current")
        echo "✅ 恢复成功! 版本: $VERSION"
        echo "   目标目录: $RESTORE_DIR"
    else
        echo "⚠️  解压完成但未找到 current 文件，请检查内容"
        echo "   目标目录: $RESTORE_DIR"
    fi
else
    echo "❌ 解密或解压失败，请检查密码是否正确"
    exit 1
fi
