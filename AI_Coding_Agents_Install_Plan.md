# Ubuntu Server 26.04：AI Coding / Agent 工具安装可行方案

> 目标：在 Ubuntu Server 26.04 + Xfce + x86_64 + AVX2 环境中，受控安装以下工具，并把 `/usr/local/bin` 作为统一入口目录。优先使用**官方 GitHub Release 预编译二进制**；不使用第三方 Web/桌面发行版；不使用 npm 全局安装；不执行项目官方 `install.sh`。
>
> 本文是“安装蓝图”，后续按阶段、按工具逐个执行。每安装一个工具，都先验证，再进入下一个。

## 1. 已知服务器条件

| 项目 | 当前值 | 对安装的影响 |
|---|---|---|
| OS | Ubuntu Server 26.04 | 目标平台 |
| Kernel | `7.0.0-31-generic` x86_64 | 与 Linux x86_64 Release 对应 |
| CPU 指令集 | AVX2 | OpenCode x64 不需要退回 baseline；Pi 官方 x64 二进制也可按现代 CPU 路线处理 |
| Node.js | `24.21.0`，通过 fnm | 保留；禁止安装过程覆盖 fnm Node |
| Python | `3.13` | Hermes / Python 系工具可复用 |
| uv | 已安装 | Hermes / Python 隔离环境优先使用 |
| Desktop | Xfce | 官方 AppImage / Desktop 版若需要 GUI，可作为可选组件；不采用第三方桌面封装 |

检查命令：

```bash
uname -a
grep -m1 -o 'avx2' /proc/cpuinfo
node --version
python3 --version
uv --version
fnm current
```

---

## 2. 纳入范围

### 原有 8 个项目

1. OmniRoute — `diegosouzapw/OmniRoute`
2. Pi — `earendil-works/pi`
3. DeepSeek Harness — `deepseek-ai/deepseek-harness`
4. Hermes Agent — `NousResearch/hermes-agent`
5. OpenClaw — `openclaw/openclaw`
6. OpenCode — `anomalyco/opencode`
7. RTK — `rtk-ai/rtk`
8. CodeGraph — `colbymchenry/codegraph`

### 追加

9. Codex — `openai/codex`

官方仓库：

- https://github.com/diegosouzapw/OmniRoute
- https://github.com/earendil-works/pi
- https://github.com/deepseek-ai/deepseek-harness
- https://github.com/NousResearch/hermes-agent
- https://github.com/openclaw/openclaw
- https://github.com/anomalyco/opencode
- https://github.com/rtk-ai/rtk
- https://github.com/colbymchenry/codegraph
- https://github.com/openai/codex

---

## 3. 核心原则

### 3.1 `/usr/local/bin` 只放入口

不要把整个应用目录塞进 `/usr/local/bin`。统一采用：

```text
/opt/<app>/
  versions/<version>/
  current -> versions/<version>

/usr/local/bin/<app> -> /opt/<app>/current/<binary>
```

如果应用不是单一 ELF，而是 AppImage / Node / Python 应用，则 `/usr/local/bin/<app>` 使用 wrapper，真正的程序仍留在 `/opt/<app>/current/`。

### 3.2 不共享运行时目录

以下项目之间**不要共享 `node_modules`、Python venv、Bun runtime、应用私有依赖**：

- Pi
- OpenCode
- OpenClaw
- OmniRoute
- DeepSeek Harness
- Hermes Agent

Node 24.21.0 可以作为宿主 Node，但如果官方 Release 已经自带运行时，则优先使用官方自带运行时。

### 3.3 不执行官方 install.sh

本方案明确排除：

```bash
curl ... | sh
curl ... | bash
```

包括 RTK、Hermes、OpenCode 等项目提供的便捷安装脚本。我们只下载并验证 Release，或者手工构建隔离环境。

### 3.4 不使用第三方 Web / Desktop 打包

允许：项目作者自己的官方 GitHub Release 中提供的 AppImage / deb / desktop bundle。

不采用：第三方重新打包的 Web UI、Desktop App、Docker 镜像、portable wrapper 等作为首选安装来源。

### 3.5 先装程序，再做集成

RTK hook、CodeGraph integration、MCP、Agent 间调用、systemd、Web 反向代理等都放到后面。避免某个工具在尚未安装其它工具时写入配置，导致反复修改。

---

## 4. 当前 Release / 安装形态判断

> 版本是 2026-09-17 时检查到的参考值；正式执行时先重新打开对应官方 Release，确认版本、资产名和 SHA-256，再下载。

| 顺序 | 工具 | 参考 Release | Linux x86_64 官方形态 | 本方案 |
|---:|---|---|---|---|
| 1 | RTK | 以 GitHub Release 最新稳定版为准 | `rtk-x86_64-unknown-linux-musl.tar.gz` | **直接预编译二进制** |
| 2 | CodeGraph | 以 GitHub Release 最新稳定版为准 | `codegraph-linux-x64.tar.gz` | **直接预编译 bundle** |
| 3 | Pi | v0.85.1（参考） | `pi-linux-x64.tar.gz` | **直接官方预编译二进制** |
| 4 | OpenCode | v1.18.30（参考） | `opencode-linux-x64.tar.gz` | **直接官方预编译二进制** |
| 5 | Codex | v0.154.0 稳定版（另有 0.155.x alpha） | `codex-x86_64-unknown-linux-musl.tar.gz` | **直接官方预编译二进制** |
| 6 | OpenClaw | 2026.9.4（参考） | 官方 `amd64.AppImage` / `.deb` | **优先官方 AppImage；CLI/daemon 另行验证** |
| 7 | OmniRoute | v3.8.50（参考） | 官方 `amd64.AppImage` / `.deb` | **优先官方 AppImage；服务器 CLI 模式另行验证** |
| 8 | DeepSeek Harness | v0.1.6-alpha.1（预发布，参考） | Release 仍在快速演进 | **先确认官方 Linux Release asset，再安装** |
| 9 | Hermes Agent | v0.21.3（参考） | 当前官方 Release 主要通过 installer / managed deployment | **不假定有 standalone binary；用 uv 隔离的手工安装方案** |

### 特别说明

- RTK 官方文档明确提供 Linux x86_64 musl 预编译包。
- OpenCode 官方发布脚本明确生成 `opencode-linux-x64.tar.gz`；其安装逻辑还会根据 AVX2 和 musl/glibc 判断目标。当前机器有 AVX2。
- Pi 官方 Release 有 `pi-linux-x64.tar.gz`；历史问题表明该 standalone x64 binary 对老 CPU 指令集有要求，本机 AVX2 已满足现代 CPU 路线。
- Codex 官方 README 明确提供 Linux x86_64 / arm64 musl 二进制 archive；本机 x86_64 直接使用 x86_64 musl 版本。
- OpenClaw 官方 Release 当前提供 amd64 AppImage 和 deb；这里不使用第三方打包。
- OmniRoute 官方 Release 当前提供 amd64 AppImage 和 deb，但其桌面/Node/native-module 形态与 RTK/CodeGraph 这类单一 CLI binary 不同，因此单独隔离。
- DeepSeek Harness 当前还是 alpha 线路，不能提前假定每个 Release 都有稳定的 Linux 单文件 CLI；安装时必须以官方 Release asset 为准。
- Hermes Agent 当前 Release 页面仍把 fresh install 指向官方 installer；由于本方案禁止执行 `install.sh`，Hermes 单独处理，不把“有源码”误称为“有官方 standalone binary”。

---

## 5. 推荐总安装顺序

```text
阶段 0  基础检查 / 目录 / 依赖
        ↓
阶段 1  RTK
        ↓
阶段 2  CodeGraph
        ↓
阶段 3  Pi
        ↓
阶段 4  OpenCode
        ↓
阶段 5  Codex
        ↓
阶段 6  OpenClaw
        ↓
阶段 7  OmniRoute
        ↓
阶段 8  DeepSeek Harness
        ↓
阶段 9  Hermes Agent
        ↓
阶段 10 全部二进制 / 运行时 / 端口 / 权限验证
        ↓
阶段 11 RTK 集成
        ↓
阶段 12 CodeGraph 集成
        ↓
阶段 13 systemd / Web / GUI（按需）
```

这样排序的主要原因不是“程序之间有硬依赖”，而是为了把风险拆开：

1. 先安装真正独立的二进制。
2. 再安装带自己 runtime / bundle 的 Agent。
3. 最后处理 Node/Python/native dependency 较复杂的应用。
4. 所有 Agent 都安装完成后，再做跨工具集成。

---

# 6. 阶段 0：创建统一目录

建议：

```bash
sudo mkdir -p /opt/{rtk,codegraph,pi,opencode,codex,openclaw,omniroute,deepseek-harness,hermes-agent}/versions
sudo mkdir -p /usr/local/bin
sudo mkdir -p /etc/{rtk,codegraph,pi,opencode,codex,openclaw,omniroute,deepseek-harness,hermes-agent}
```

对于确实需要持久化服务数据的工具，再创建：

```bash
sudo mkdir -p /var/lib/{openclaw,omniroute,deepseek-harness,hermes-agent}
```

不要一开始就给所有目录 `chmod 777`。

---

# 7. 每个 Release 的统一安装模板

以单文件 binary 为例：

```bash
APP=example
VER=1.2.3
ARCHIVE=/tmp/${APP}-${VER}.tar.gz

sudo mkdir -p /opt/${APP}/versions/${VER}
sudo tar -xzf "${ARCHIVE}" -C /opt/${APP}/versions/${VER}

sudo ln -sfn /opt/${APP}/versions/${VER} /opt/${APP}/current
```

然后根据 archive 实际目录结构创建入口：

```bash
sudo ln -sfn /opt/${APP}/current/<binary> /usr/local/bin/${APP}
```

验证：

```bash
type -a ${APP}
readlink -f "$(command -v ${APP})"
${APP} --version
```

升级时只替换：

```text
/opt/<app>/current
```

不直接覆盖旧版本；这样可以快速回滚。

---

# 8. 阶段 1：RTK

官方预编译 Linux x86_64：

```text
rtk-x86_64-unknown-linux-musl.tar.gz
```

官方安装文档：

https://github.com/rtk-ai/rtk/blob/develop/docs/guide/getting-started/installation.md

操作原则：

1. 从官方 GitHub Release 下载。
2. `sha256sum` 验证 Release asset digest。
3. 解压到 `/opt/rtk/versions/<version>/`。
4. `/usr/local/bin/rtk` 指向真实 binary。
5. **暂时不要执行 `rtk init --global`。**

验证：

```bash
rtk --version
rtk gain
```

RTK 的 hook 集成放到最后。

---

# 9. 阶段 2：CodeGraph

官方 Release 有 Linux x64 self-contained bundle，包含自己的运行环境，不需要先把 Node/npm 作为它的安装方式。

参考资产：

```text
codegraph-linux-x64.tar.gz
```

安装到：

```text
/opt/codegraph/versions/<version>/
/opt/codegraph/current -> versions/<version>
/usr/local/bin/codegraph
```

先只验证：

```bash
codegraph --version
```

**不要立即执行：**

```bash
codegraph install --yes
```

原因：CodeGraph 可以把 integration 写入 Claude、Cursor、Codex、OpenCode、Hermes 等 Agent；应该等这些 Agent 全部安装并确定最终配置后再做。

---

# 10. 阶段 3：Pi

官方 Release 提供：

```text
pi-linux-x64.tar.gz
```

安装原则：

```text
/opt/pi/versions/<version>/
/opt/pi/current
/usr/local/bin/pi
```

不执行：

```bash
npm install -g ...
```

也不要让 Pi 的 project-local extensions 与系统级其它 Agent 共享目录。

验证：

```bash
pi --version
pi --help
```

如果后面使用 Pi extension，仍按 Pi 自己的项目目录隔离。

---

# 11. 阶段 4：OpenCode

官方 Release 生成 Linux x64：

```text
opencode-linux-x64.tar.gz
```

官方发布脚本明确使用该资产；安装器会检测 AVX2，并在不支持时切换 baseline。当前服务器已有 AVX2，因此正常 x64 路线即可。

安装到：

```text
/opt/opencode/versions/<version>/
/opt/opencode/current
/usr/local/bin/opencode
```

验证：

```bash
opencode --version
opencode --help
```

OpenCode 本身支持 `opencode web`，如果以后需要 Web UI，应优先使用其官方 binary 自带能力，而不是额外安装第三方 Web UI。

---

# 12. 阶段 5：Codex

追加的 Codex 使用 OpenAI 官方仓库：

https://github.com/openai/codex

官方 README 明确提供 Linux x86_64：

```text
codex-x86_64-unknown-linux-musl.tar.gz
```

当前 stable 参考为 `0.154.0`；2026-09-17 同期还有 `0.155.x-alpha`，本方案默认**不追 alpha**，除非后续明确需要。

安装：

```text
/opt/codex/versions/<version>/
/opt/codex/current
/usr/local/bin/codex
```

验证：

```bash
codex --version
codex --help
```

认证、ChatGPT 登录、API key 等放到安装完成后的独立步骤，不写进系统级 `/etc` 明文。

---

# 13. 阶段 6：OpenClaw

官方 Release 当前提供：

```text
OpenClaw-<version>-amd64.AppImage
OpenClaw-<version>-amd64.deb
```

本方案优先考虑官方 AppImage，原因是：

- 不污染 apt 包数据库。
- 不需要第三方重新打包。
- 可以放进 `/opt/openclaw/versions/<version>/`。
- Xfce 已经存在，因此如果官方 Desktop 能运行，可以直接验证。

但必须区分：**Desktop AppImage ≠ 一定等于服务器 CLI/Gateway 安装方式**。

所以 OpenClaw 阶段拆成：

### 13.1 官方 GUI/AppImage 验证

```text
/opt/openclaw/versions/<version>/OpenClaw-<version>-amd64.AppImage
```

### 13.2 CLI/Gateway

再根据同一官方 Release / 官方源码的实际启动入口确认，不直接把 Electron Desktop binary 当作 daemon。

重点检查：

```bash
openclaw --version
openclaw doctor
```

如果 CLI 不是 Release standalone binary，则进入“受控 Node 应用”方案，而不是偷偷使用 npm 全局安装。

---

# 14. 阶段 7：OmniRoute

官方 Release 当前提供：

```text
OmniRoute-<version>.AppImage
omniroute-desktop_<version>_amd64.deb
```

优先：

```text
/opt/omniroute/versions/<version>/OmniRoute-<version>.AppImage
```

OmniRoute 与 RTK/CodeGraph 的主要区别：它涉及 Node/native dependency（包括 `better-sqlite3`）以及 Desktop/CLI/host-integrated 等不同运行方式，因此**不能把它当成一个普通单文件 CLI 与其它 Node 应用共享依赖**。

如果后续采用 CLI/host-integrated 模式，则单独建立自己的 Node dependency tree，不使用其它 Agent 的 `node_modules`。

---

# 15. 阶段 8：DeepSeek Harness

当前官方 Release 参考：

```text
v0.1.6-alpha.1
```

这是预发布版本，因此这一项与前面几个项目不同：

1. 先查看官方 Release assets。
2. 只使用官方 Linux x64 asset（如果该版本提供）。
3. 不使用第三方 portable binary。
4. 不因为仓库存在 Python/Node 代码就直接 `pip install` / `npm install`。
5. 如果当前 Release 没有适合本机的官方 executable，则暂停该阶段，改为确认官方下一版 Release，而不是擅自源码构建。

目标目录：

```text
/opt/deepseek-harness/versions/<version>/
/opt/deepseek-harness/current
/usr/local/bin/dsh
```

如果官方 binary 自带 Web sidebar / terminal / browser capability，允许使用；仍然只采用官方发行物。

---

# 16. 阶段 9：Hermes Agent

当前官方稳定 Release 参考：

```text
v0.21.3
```

官方 Release 页面当前 fresh install 仍指向 installer，而不是一个明确的 Linux standalone CLI binary。因此本方案**不伪造“官方 binary 安装”**。

处理方式：

1. 不运行 `scripts/install.sh`。
2. 不执行 curl-pipe-bash。
3. 使用已有 Python 3.13 + uv。
4. 建立 Hermes 独立 Python environment。
5. Hermes 的 Python 依赖、CLI、browser/CUA 依赖全部留在 `/opt/hermes-agent` 的隔离环境。
6. `/usr/local/bin/hermes` 使用 wrapper，明确调用该隔离环境。

推荐结构：

```text
/opt/hermes-agent/versions/<version>/
/opt/hermes-agent/current
/opt/hermes-agent/venv/
/usr/local/bin/hermes
```

正式执行这一阶段时，要先阅读对应 tag 的官方安装脚本内容，**只把其中的安装逻辑人工转换成可审计的命令**，不直接执行脚本。

---

# 17. Node / Python / Native dependency 隔离

## Node

宿主：

```text
fnm -> Node 24.21.0
```

原则：

- 不修改 fnm 默认 Node。
- 不安装 npm global package。
- 不让一个项目的 `node_modules` 被另一个项目复用。
- 官方 standalone binary 优先于 source install。

## Python

宿主：

```text
Python 3.13 + uv
```

Hermes / Python 应用各自：

```text
/opt/<app>/venv/
```

禁止多个 Agent 共用同一个 venv。

## Native modules

特别关注：

```text
better-sqlite3
```

它意味着 ABI / Node 版本 / libc / architecture 可能成为实际运行时约束，因此 OmniRoute 必须保持自己的依赖树。

---

# 18. `/usr/local/bin` 最终目标

最终希望看到类似：

```text
/usr/local/bin/
├── rtk
├── codegraph
├── pi
├── opencode
├── codex
├── openclaw
├── omniroute
├── dsh
└── hermes
```

检查：

```bash
for x in rtk codegraph pi opencode codex openclaw omniroute dsh hermes; do
    printf '%-16s ' "$x"
    command -v "$x" || true
done
```

进一步检查实际目标：

```bash
for x in rtk codegraph pi opencode codex openclaw omniroute dsh hermes; do
    p=$(command -v "$x" 2>/dev/null || true)
    [ -n "$p" ] && printf '%-16s -> %s\n' "$x" "$(readlink -f "$p")"
done
```

---

# 19. 端口规划

安装时不要让多个 Web/Gateway Agent 随机抢默认端口。

建议先建立清单：

| 工具 | Web/API | 端口 | 状态 |
|---|---|---:|---|
| OpenCode | `opencode web` | 待确认 | 后置 |
| OpenClaw | Gateway/Web | 待确认 | 后置 |
| OmniRoute | Dashboard/API | 待确认 | 后置 |
| DeepSeek Harness | Web/terminal | 待确认 | 后置 |
| Hermes | Gateway/Desktop backend | 待确认 | 后置 |

不要在安装阶段就同时启动所有服务。

---

# 20. systemd 原则

只有确认命令行启动、配置目录、端口和数据目录都正确后，才建立 systemd。

示意：

```ini
[Service]
Type=simple
User=<dedicated-user>
Group=<dedicated-user>
WorkingDirectory=/var/lib/<app>
EnvironmentFile=/etc/<app>/env
ExecStart=/usr/local/bin/<app> ...
Restart=on-failure
RestartSec=5
```

不要以 root 长期运行 Agent。

---

# 21. RTK 与 CodeGraph 集成必须最后做

## RTK

先完成所有 Agent 安装，再按具体 Agent 的官方支持方式执行：

```bash
rtk init
```

或者需要全局配置时再评估：

```bash
rtk init --global
```

不要在第一天就全局 patch 所有 settings。

## CodeGraph

等 Pi / OpenCode / Codex / OpenClaw / Hermes 等实际可执行入口都稳定后，再执行 CodeGraph integration。

目标是一次性生成最终 integration，而不是安装一个 Agent 就改一次配置。

---

# 22. 每安装一个工具的验收模板

必须完成以下 6 项才进入下一个工具：

```bash
# 1. 路径
command -v <app>
readlink -f "$(command -v <app>)"

# 2. 版本
<app> --version

# 3. help
<app> --help

# 4. 动态链接（ELF binary 时）
file "$(readlink -f "$(command -v <app>)")"
ldd "$(readlink -f "$(command -v <app>)")" 2>&1 | head -n 30

# 5. 权限
ls -l "$(readlink -f "$(command -v <app>)")"

# 6. 运行一次后检查进程 / 端口
ps aux | grep -i '[<app>]'
ss -lntup
```

AppImage / Desktop 应用不强行套 `ldd`；改为检查启动日志和进程。

---

# 23. 安装过程中绝对不要做的事情

```text
❌ npm install -g <agent>
❌ npm link
❌ curl | bash
❌ curl | sh
❌ 把多个项目的 node_modules 混在一起
❌ 把 Hermes venv 给其它 Python Agent 使用
❌ 直接把完整 app tree 放进 /usr/local/bin
❌ 用第三方 portable / repack / unofficial Web UI 替代官方 Release
❌ 在所有 Agent 安装完之前执行全局 RTK / CodeGraph integration
❌ 直接用 root 启动长期运行的 Agent gateway
❌ 一次性启动所有 Web 服务，导致端口和认证配置混乱
```

---

# 24. 最终阶段：统一检查

```bash
printf '\n=== PATH ===\n'
echo "$PATH"

printf '\n=== BINARIES ===\n'
for x in rtk codegraph pi opencode codex openclaw omniroute dsh hermes; do
    printf '\n[%s]\n' "$x"
    command -v "$x" || true
    if command -v "$x" >/dev/null 2>&1; then
        readlink -f "$(command -v "$x")" || true
        "$x" --version 2>&1 | head -n 3 || true
    fi
done

printf '\n=== NODE ===\n'
node --version
fnm current

printf '\n=== PYTHON ===\n'
python3 --version
uv --version

printf '\n=== CPU ===\n'
grep -m1 -o 'avx2' /proc/cpuinfo || true

printf '\n=== KERNEL ===\n'
uname -a
```

---

# 25. 回滚策略

每个应用版本独立：

```text
/opt/opencode/versions/1.18.29/
/opt/opencode/versions/1.18.30/
/opt/opencode/current -> versions/1.18.30
```

如果新版本异常：

```bash
sudo ln -sfn /opt/opencode/versions/1.18.29 /opt/opencode/current
```

然后重新验证：

```bash
opencode --version
```

不要删除旧版本，直到新版本运行稳定。

---

# 26. 执行节奏

后续实际操作建议严格按下面节奏：

```text
Step 0  基础环境检查
  ↓
Step 1  创建 /opt、/etc、/usr/local/bin 结构
  ↓
Step 2  RTK
  ↓
Step 3  CodeGraph
  ↓
Step 4  Pi
  ↓
Step 5  OpenCode
  ↓
Step 6  Codex
  ↓
Step 7  OpenClaw
  ↓
Step 8  OmniRoute
  ↓
Step 9  DeepSeek Harness
  ↓
Step 10 Hermes Agent
  ↓
Step 11 全部工具统一验收
  ↓
Step 12 RTK
  ↓
Step 13 CodeGraph
  ↓
Step 14 systemd / Web / GUI
```

**一次只执行一个 Step。**

每一步的实际命令都应该在执行前根据当时的官方 Release asset、SHA-256、archive 内部目录结构重新确认；尤其是 DeepSeek Harness 和 Hermes Agent，不提前假定存在未验证的 standalone binary。

---

## 官方资料入口

- RTK：https://github.com/rtk-ai/rtk/releases
- CodeGraph：https://github.com/colbymchenry/codegraph/releases
- Pi：https://github.com/earendil-works/pi/releases
- OpenCode：https://github.com/anomalyco/opencode/releases
- Codex：https://github.com/openai/codex/releases
- OpenClaw：https://github.com/openclaw/openclaw/releases
- OmniRoute：https://github.com/diegosouzapw/OmniRoute/releases
- DeepSeek Harness：https://github.com/deepseek-ai/deepseek-harness/releases
- Hermes Agent：https://github.com/NousResearch/hermes-agent/releases
