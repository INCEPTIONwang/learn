#!/usr/bin/env bash
set -euo pipefail

# ── zread wiki 备份解密恢复脚本 ──
#密码:zread2026backup
# 用法: 将此脚本放在 .enc 文件同目录下，直接运行即可
#       bash restore-zread-wiki.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENC_FILE="$SCRIPT_DIR/zread-wiki-2026-07-02-backup.tar.gz.enc"

# 加密文件的基名，去掉 .enc 后缀就是解压后的 .tar.gz
BASENAME="$(basename "$ENC_FILE" .enc)"

# 目标目录: 从 backups/ 上一级进入 .zread/wiki/
RESTORE_DIR="$SCRIPT_DIR/../.zread/wiki"

# ── 前置检查 ──
if [ ! -f "$ENC_FILE" ]; then
    echo "❌ 找不到加密文件: $ENC_FILE"
    exit 1
fi

if ! command -v openssl &>/dev/null; then
    echo "❌ 需要openssl，请先安装"
    exit 1
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

echo "$PASSWORD" | openssl enc -aes-256-cbc -d -pbkdf2 -pass stdin \
    -in "$ENC_FILE" \
    | tar xzf - -C "$RESTORE_DIR"

# ── 验证 ──
if [ -f "$RESTORE_DIR/current" ]; then
    VERSION=$(cat "$RESTORE_DIR/current")
    echo "✅ 恢复成功! 版本: $VERSION"
    echo "   目标目录: $RESTORE_DIR"
else
    echo "⚠️  解压完成但未找到 current 文件，请检查密码是否正确"
    exit 1
fi
