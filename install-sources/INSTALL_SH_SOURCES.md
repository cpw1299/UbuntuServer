# 官方 install.sh 来源登记

> 本目录只登记“官方 install.sh 的固定来源、审计状态和获取方法”。
>
> **原则：官方 install.sh 永不直接执行。**
>
> 对于没有官方 Linux 预编译 binary、但官方文档依赖 install.sh 的项目：先下载脚本到本地，固定到已审计的 commit，阅读并拆分为“下载 / 安装 / 配置 / 服务”步骤；实际执行时使用绝对路径和本方案的 `/opt/<app>/...` 布局。

## 1. Hermes Agent

- 官方仓库：`NousResearch/hermes-agent`
- 官方脚本路径：`scripts/install.sh`
- 本次审计 commit：`228022ef5b209cb0a3d739394edddf887e1db0f6`
- 官方脚本 URL：
  `https://raw.githubusercontent.com/NousResearch/hermes-agent/228022ef5b209cb0a3d739394edddf887e1db0f6/scripts/install.sh`
- 官方仓库路径：
  `https://github.com/NousResearch/hermes-agent/blob/228022ef5b209cb0a3d739394edddf887e1db0f6/scripts/install.sh`

本次读取确认：

- 脚本约 3913 行 / 168 KB（当前 main 页面信息）。
- 官方 installer 默认使用 `uv` 管理 Python，并建立 Hermes 自己的运行环境。
- 官方 Linux root 新安装路径已经采用 FHS 风格：代码 `/usr/local/lib/hermes-agent`，命令 `/usr/local/bin/hermes`，数据仍放在 `$HERMES_HOME`。
- 官方脚本会自动处理 Python、uv、Git、C++ 编译器、Node 以及浏览器/计算机使用相关依赖。
- 官方脚本还包含交互式 setup、gateway、desktop 等阶段。

### 本项目的处理方式

**不执行官方脚本。**

实际安装时拆为：

1. [RUN] 下载并保存官方 `install.sh` 到本机审计目录。
2. [VERIFY] `sha256sum` / Git commit 与本登记一致。
3. [PAUSE] 检查服务器现有 Python 3.13、uv、Node 24.21.0、Git、编译工具，不让 installer 接管已有 fnm Node。
4. [RUN] 按官方脚本的 repository 阶段取得 Hermes 源码。
5. [RUN] 建立独立 Python venv。
6. [RUN] 按官方 `pyproject.toml` / installer 使用 `uv pip` 安装 Hermes 依赖。
7. [RUN] 按官方脚本要求安装 Hermes 私有 Node/browser/tool 依赖，但安装位置必须限定在 Hermes 自己的目录。
8. [RUN] 自己创建 `/usr/local/bin/hermes` wrapper。
9. [PAUSE] API Key / OAuth / gateway / desktop 等交互配置，必须等基础 CLI 验证成功后再继续。
10. [VERIFY] `hermes --version`、`hermes doctor`、最小模型调用成功后，才进入 gateway/systemd。

## 2. OpenClaw

- 官方仓库：`openclaw/openclaw`
- 官方脚本路径：`scripts/install.sh`
- 本次审计参考 commit：`aac3b2773c7f80bede88e8ce67417ed72a3eb33d`
- 官方脚本 URL：
  `https://raw.githubusercontent.com/openclaw/openclaw/aac3b2773c7f80bede88e8ce67417ed72a3eb33d/scripts/install.sh`
- 官方仓库路径：
  `https://github.com/openclaw/openclaw/blob/aac3b2773c7f80bede88e8ce67417ed72a3eb33d/scripts/install.sh`

本次读取确认：

- 官方 `scripts/install.sh` 是 macOS/Linux 安装器，约 4224 行 / 147 KB。
- 脚本包含 downloader、HTTPS/TLS 下载、checksum 校验、Node 版本判断、npm/prefix 管理以及 OpenClaw CLI 安装逻辑。
- 脚本不是单纯的“下载一个二进制”：它会处理 Node、npm 包、路径、升级和交互配置。
- 因此不能简单把脚本中的 `/usr/local` 替换掉后直接运行。

### 本项目的处理方式

1. [RUN] 下载固定 commit 的官方 `scripts/install.sh`。
2. [VERIFY] 校验来源 commit。
3. [PAUSE] 确认当前 Node 24.21.0 是否满足该版本 OpenClaw 的 engine 要求；不得覆盖 fnm。
4. [RUN] 单独建立 `/opt/openclaw/versions/<version>/`。
5. [RUN] 在 OpenClaw 自己的目录内建立依赖树，不与 Pi/OpenCode/OmniRoute/DeepSeek 共用 `node_modules`。
6. [RUN] 手工执行官方脚本中真正需要的下载/解包/依赖安装步骤。
7. [RUN] 自己创建 `/usr/local/bin/openclaw` wrapper。
8. [PAUSE] 首次 onboarding、provider/channel credentials、gateway、systemd/Web UI 必须在基础 CLI 验证后单独处理。

## 3. 不属于本规则的项目

如果项目已经提供可靠的官方 Linux x86_64 Release binary：

- RTK
- CodeGraph
- Pi
- OpenCode
- Codex

直接使用官方 Release asset，不再研究 install.sh。

如果某项目没有可靠的官方 binary，也没有官方 install.sh 提供可复现的安装路径：

- 不猜 asset 名称。
- 不使用第三方构建。
- 不自行执行未知安装脚本。
- 标记 `[PAUSE / NEED DISCUSSION]`，等待确认。

---

## 标记规范

后续所有执行步骤统一使用：

- `[RUN]`：可以直接执行。
- `[VERIFY]`：必须执行并把输出与预期核对。
- `[PAUSE]`：执行到这里必须停下来；如果结果异常、版本不匹配、下载源变化、需要输入密钥/账号/权限，先找我讨论。
- `[DO NOT RUN]`：仅供阅读/对照，禁止执行。
- `[OPTIONAL]`：非核心功能，需要时再执行。
- `[ROLLBACK]`：出现问题时使用。
- `[NEED DISCUSSION]`：当前资料不足以安全给出下一步命令。
