#!/usr/bin/env bash
# 卸载 fnm 系统级部署(与 setup-fnm.sh 的产物一一对应)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "请以 root 运行: sudo $0"; exit 1; }

FNM_DIR="${FNM_DIR:-/opt/fnm}"
FNM_BIN_DIR="/usr/local/bin"

echo "==> 删除系统软链与 fnm 二进制"
rm -f "$FNM_BIN_DIR/fnm" "$FNM_BIN_DIR/node" "$FNM_BIN_DIR/npm" \
      "$FNM_BIN_DIR/npx" "$FNM_BIN_DIR/corepack"

echo "==> 删除共享版本库 $FNM_DIR"
rm -rf "$FNM_DIR"

echo "==> 删除 /etc/profile.d/fnm.sh"
rm -f /etc/profile.d/fnm.sh

echo "==> 清理 /etc/environment 中的 FNM_ 变量"
sed -i -E '/^FNM_[A-Z_]+=/d' /etc/environment

echo "==> 卸载完成。"
echo "    (可选) 各用户家目录缓存 ~/.local/state/fnm_multishells 可自行删除"
echo "    已登录的会话需重新登录后环境变量才会彻底消失"
