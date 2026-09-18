# fnm-system-setup

Ubuntu Server 系统级 [fnm](https://github.com/Schniz/fnm)（Fast Node Manager）部署方案。
一条脚本完成：**所有 SSH 登录用户（root/普通用户）获得完整的多版本切换能力，
systemd 服务与 cron 任务获得稳定可用的 node 路径**。

## 设计：双通道

| 场景 | 通道 | 效果 |
|---|---|---|
| root / user SSH 登录 | `/etc/environment` + `/etc/profile.d/fnm.sh` | 完整功能：`fnm use` 会话级切换、进入含 `.nvmrc`/`.node-version` 的目录自动切换 |
| systemd 服务 / cron | `/opt/fnm/aliases/default` + `/usr/local/bin` 软链 | 稳定路径，永远使用 default 版本，不依赖任何登录环境 |

```
SSH 登录 ──→ /etc/profile.d/fnm.sh → fnm env → ~/.local/state/fnm_multishells/（会话级，每用户独立）
│
/opt/fnm ←── 共享版本库 ←── root 统一 install/default ──┘
│
└── aliases/default/bin/node ←── /usr/local/bin/node ←── systemd / cron（系统级）
```

## 快速开始

```bash
git clone <本仓库> && cd fnm-system-setup
chmod +x setup-fnm.sh uninstall-fnm.sh

# 默认：安装 Node 22，使用 npmmirror 镜像
sudo ./setup-fnm.sh

# 或安装多个版本（第一个为系统默认）
sudo ./setup-fnm.sh 22 20 18
```


执行完成后**重新登录**即可。

## 可配置项（环境变量覆盖）

| 变量 | 默认值 | 说明 |
|---|---|---|
| `FNM_DIR` | `/opt/fnm` | 共享版本库位置 |
| `FNM_NODE_DIST_MIRROR` | `https://npmmirror.com/mirrors/node` | Node 下载镜像（海外可设 `https://nodejs.org/dist`） |
| 位置参数 | `22` | 要安装的 Node 主版本列表，第一个设为 default |

示例：

```bash
sudo FNM_DIR=/data/fnm FNM_NODE_DIST_MIRROR=https://nodejs.org/dist ./setup-fnm.sh 20
```


## 部署产物清单

| 文件/目录 | 作用 |
|---|---|
| `/usr/local/bin/fnm` | fnm 二进制（全局可用） |
| `/opt/fnm/node-versions/` | 所有已安装的 Node 版本（共享，root 管理） |
| `/opt/fnm/aliases/default` | default 别名软链，切换默认版本时自动更新 |
| `/etc/profile.d/fnm.sh` | 登录 Shell 执行 `fnm env`（含 `--use-on-cd` 自动切换） |
| `/etc/environment` | 追加 `FNM_DIR`、`FNM_NODE_DIST_MIRROR` 静态变量（幂等去重） |
| `/usr/local/bin/node` 等 | 指向 default 版本的系统级软链，供 systemd/cron 使用 |

## 权限模型

| 操作 | root | 普通用户 |
|---|---|---|
| `fnm install / uninstall / default / alias` | ✅ | ❌（版本管理权集中在 root） |
| `fnm use / current / list / exec` | ✅ | ✅（仅写自己家目录的 multishell 链接） |
| `npm install -g` | ✅ | ❌ |
| 运行 node / npm | ✅ | ✅ |

如需放权给开发组：`sudo chown -R root:devs /opt/fnm && sudo chmod -R g+w /opt/fnm`

## 接入系统服务

### systemd

```ini
[Service]
# 方式 A：绝对路径（推荐，明确无歧义）
ExecStart=/opt/fnm/aliases/default/bin/node /opt/app/server.js

# 方式 B：依赖系统 PATH（/usr/local/bin 在 systemd 默认 PATH 中）
# ExecStart=node /opt/app/server.js
```

### cron（默认 PATH 极窄，需显式声明）

```bash
# /etc/cron.d/node-jobs
PATH=/usr/local/bin:/usr/bin:/bin
0 3 * * * root node /opt/scripts/backup.js >> /var/log/backup.log 2>&1
```

### 全局工具（pm2 等）

```bash
sudo env FNM_DIR=/opt/fnm /opt/fnm/aliases/default/bin/npm install -g pm2
sudo ln -sfn /opt/fnm/aliases/default/bin/pm2 /usr/local/bin/pm2
```

## 验证

```bash
# 场景1：SSH 登录（root 和普通 user 各验证一次）
which node # ~/.local/state/fnm_multishells/…/bin/node（会话级）
fnm current
cd /path/to/project && node -v # 目录含 .nvmrc 时自动切换

# 场景2：系统自动执行（纯净环境）
sudo systemd-run --pipe node -v
env -i /usr/local/bin/node -v
```


## 故障排查

| 现象 | 原因与解决 |
|---|---|
| `fnm use` 报错找不到环境变量 | `fnm env` 未被 eval：确认 `/etc/profile.d/fnm.sh` 存在，重新登录或 `source /etc/profile` |
| 自动切换不生效 | 目录缺少 `.nvmrc` / `.node-version`；monorepo 场景在 profile 脚本的 `fnm env` 后追加 `--version-file-strategy=recursive` |
| 下载缓慢/失败 | 检查镜像：`curl -I $FNM_NODE_DIST_MIRROR`；或换官方源重装 |
| `which node` 命中错误路径 | 机器上残留 nvm 的 PATH 注入，确保 multishell 路径优先级高于它 |
| `sudo node -v` 版本与当前会话不符 | 正常现象：sudo 走 `secure_path` 命中系统 default；需保持会话版本用 `sudo env PATH="$PATH" node ...` |

## zsh 用户（可选）

zsh 不读 `/etc/profile`。Ubuntu 的 `/etc/zsh/zprofile` 加入：

```
zsh
if [ -d /etc/profile.d ]; then
for i in /etc/profile.d/*.sh; do [ -r “i" ] && . "i”; done
unset i
fi
```


## 升级 default 版本的影响

`sudo env FNM_DIR=/opt/fnm fnm default 20` 后：
- `/usr/local/bin/node` 软链自动跟随，**无需重新 ln**；
- 已运行的 systemd 服务**不会热切换**，需 `systemctl restart` 后生效；
- 生产环境如需锁死版本，可将软链直接指向具体版本目录：
  `sudo ln -sfn /opt/fnm/node-versions/v22.11.0/installation/bin/node /usr/local/bin/node`

## 卸载

```bash
sudo ./uninstall-fnm.sh
```