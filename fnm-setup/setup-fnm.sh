#!/usr/bin/env bash
# =============================================================
# setup-fnm.sh — Ubuntu 系统级 fnm 一键部署脚本
#
# 适用: Ubuntu 20.04+ / Debian 11+ (x86_64 / aarch64)，root 执行
# 用法:
#   sudo ./setup-fnm.sh              # 安装 Node 22 并设为默认
#   sudo ./setup-fnm.sh 22 20 18     # 安装多个版本，第一个为默认
#   sudo FNM_NODE_DIST_MIRROR=https://nodejs.org/dist ./setup-fnm.sh 20
#
# 特性: 幂等(可重复执行)、静态变量去重写入、自动依赖检查
# =============================================================
set -euo pipefail

# ---------- 可配置项(可用环境变量覆盖) ----------
FNM_DIR="${FNM_DIR:-/opt/fnm}"
FNM_NODE_DIST_MIRROR="${FNM_NODE_DIST_MIRROR:-https://npmmirror.com/mirrors/node}"
FNM_BIN_DIR="/usr/local/bin"
PROFILE_D_FILE="/etc/profile.d/fnm.sh"
ENV_FILE="/etc/environment"

# 位置参数 = 要安装的 Node 主版本，第一个设为 default
if [ $# -gt 0 ]; then NODE_VERSIONS=("$@"); else NODE_VERSIONS=("22"); fi

log() { printf '\033[1;32m[fnm-setup]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[fnm-setup][错误]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- 0. 前置检查 ----------
[ "$(id -u)" -eq 0 ] || die "请以 root 运行: sudo $0"

case "$(uname -m)" in
  x86_64)  FNM_ARCH=x64   ;;
  aarch64) FNM_ARCH=arm64 ;;
  *) die "不支持的架构: $(uname -m)" ;;
esac

MISSING=()
for cmd in curl unzip; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  log "安装缺失依赖: ${MISSING[*]}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq "${MISSING[@]}"
fi

# ---------- 1. 安装 fnm 二进制 ----------
if command -v fnm >/dev/null 2>&1; then
  log "fnm 已存在，跳过安装 ($(fnm --version))"
else
  log "安装 fnm 到 $FNM_BIN_DIR ..."
  curl -fsSL https://fnm.vercel.app/install \
    | bash -s -- --install-dir "$FNM_BIN_DIR" --skip-shell
fi
command -v fnm >/dev/null 2>&1 || die "fnm 安装失败"

# ---------- 2. 建立共享版本库并安装 Node ----------
log "共享版本库: $FNM_DIR"
mkdir -p "$FNM_DIR"

for v in "${NODE_VERSIONS[@]}"; do
  log "安装 Node $v (镜像: $FNM_NODE_DIST_MIRROR) ..."
  env FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
      fnm install "$v"
done

# 设置默认版本(优先直接解析，失败则从 fnm list 提取确切版本号)
set_default() {
  local v="$1" exact
  if env FNM_DIR="$FNM_DIR" fnm default "$v" 2>/dev/null; then return 0; fi
  exact="$(env FNM_DIR="$FNM_DIR" fnm list \
           | grep -oE "v${v}\.[0-9]+\.[0-9]+" | head -n1 | tr -d 'v')"
  [ -n "$exact" ] || die "无法为版本 $v 建立 default 别名"
  env FNM_DIR="$FNM_DIR" fnm default "$exact"
}
log "设置默认版本: ${NODE_VERSIONS[0]}"
set_default "${NODE_VERSIONS[0]}"

# ---------- 3. 生成 /etc/profile.d/fnm.sh (登录 Shell 初始化) ----------
log "写入 $PROFILE_D_FILE"
cat > "$PROFILE_D_FILE" <<'EOF'
# /etc/profile.d/fnm.sh — 登录 Shell 的 fnm 初始化(系统级，由 setup-fnm.sh 生成)
if command -v fnm >/dev/null 2>&1 && [ -z "${FNM_MULTISHELL_PATH:-}" ]; then
    if [ -n "${ZSH_VERSION:-}" ]; then
        eval "$(fnm env --use-on-cd --shell zsh)"
    else
        eval "$(fnm env --use-on-cd --shell bash)"
    fi
fi
EOF
chmod 644 "$PROFILE_D_FILE"

# ---------- 4. 写入 /etc/environment (静态变量，幂等去重) ----------
set_env_var() {
  local key="$1" val="$2"
  if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=\"${val}\"|" "$ENV_FILE"
  else
    printf '%s="%s"\n' "$key" "$val" >> "$ENV_FILE"
  fi
}
log "更新 $ENV_FILE"
set_env_var FNM_DIR "$FNM_DIR"
set_env_var FNM_NODE_DIST_MIRROR "$FNM_NODE_DIST_MIRROR"

# ---------- 5. 系统级软链(供 systemd / cron 使用) ----------
log "创建系统级软链 -> $FNM_DIR/aliases/default/bin"
for bin in node npm npx corepack; do
  src="$FNM_DIR/aliases/default/bin/$bin"
  [ -e "$src" ] && ln -sfn "$src" "$FNM_BIN_DIR/$bin"
done

# ---------- 6. 验证 ----------
log "==== 部署验证 ===="
echo "fnm 版本 : $(fnm --version)"
echo "已装版本 :"
env FNM_DIR="$FNM_DIR" fnm list
echo "node 软链: $FNM_BIN_DIR/node -> $(readlink "$FNM_BIN_DIR/node")"
echo "裸环境测试(模拟 systemd/cron 的纯净环境):"
env -i "$FNM_BIN_DIR/node" -v && echo "  [OK] 系统级 node 可用"

cat <<TIP

==== 部署完成 ====
重新登录(或执行 source /etc/profile)后生效。

  SSH 登录用户 : fnm list / fnm use 20 / 进入含 .nvmrc 的目录自动切换
  系统服务     : 直接使用 /usr/local/bin/node (即 default 版本)

TIP
