# Ubuntu Server 26.04：官方 install.sh 拆分审计与手工安装 Runbook

> 目的：对于没有官方 Linux 预编译 binary、但官方安装文档提供 `install.sh` 的项目，**下载官方脚本但绝不执行它**；从脚本中提取官方来源、依赖和安装顺序，改造成可审计、可回滚的绝对路径安装。

## 0. 总规则

### [DO NOT RUN]

禁止直接执行：

```bash
curl ... | bash
curl ... | sh
bash install.sh
sh install.sh
```

也不要把官方脚本简单改几个路径后直接运行。

### [RUN]

允许：

```bash
curl -fL '<官方脚本固定 URL>' -o /tmp/<app>-install.sh
```

然后只阅读、审计、提取命令。

### [VERIFY]

每个 install.sh 项目必须先确认：

1. 官方仓库。
2. 官方脚本路径。
3. 审计 commit/tag。
4. 脚本下载 URL。
5. 脚本实际下载的二进制、源码、包管理器和依赖来源。
6. 是否会修改现有 Node/Python/uv。
7. 是否会修改 shell profile、PATH、systemd、cron、Desktop、browser 等。

### [PAUSE]

以下情况必须停止，不继续执行：

- 官方脚本内容与登记的 commit 不一致。
- 下载 URL 从 GitHub 官方来源变成未知第三方来源。
- 需要覆盖现有 fnm Node 24.21.0。
- 需要改变系统 Python。
- 需要执行远程二级 installer。
- 需要写入 systemd / gateway / bot / webhook。
- 需要 API Key、OAuth、账号登录。
- 需要对外监听端口但端口用途尚未确认。
- 发现官方安装逻辑依赖当前资料无法安全还原。

---

# 1. 统一安装目录

```text
/opt/<app>/
├── versions/
│   ├── <version-1>/
│   └── <version-2>/
└── current -> versions/<version>

/usr/local/bin/<app>  # wrapper 或 symlink
```

应用私有数据按应用实际需要放：

```text
/etc/<app>/
/var/lib/<app>/
```

不要把应用运行文件散落到 `/usr/local/bin`。

不要共享：

```text
node_modules
Python venv
Bun runtime
native addons
应用私有 Node prefix
```

---

# 2. Hermes Agent

官方安装器目前仍是 Hermes Linux 的主要安装入口；官方文档明确把 Linux x86_64/aarch64 列为 `install.sh` 支持路线。官方 README/quickstart 也仍提供 `install.sh` 安装方式。citeturn0search11turn0search5turn0search4

本次审计固定：

```text
Repository: NousResearch/hermes-agent
Script: scripts/install.sh
Audit commit: 228022ef5b209cb0a3d739394edddf887e1db0f6
```

官方脚本当前约 3913 行 / 168 KB，不能靠肉眼只看头部判断行为。citeturn0search0

## 2.1 [RUN] 下载官方脚本

```bash
mkdir -p ~/install-audit/hermes-agent

curl -fL \
  'https://raw.githubusercontent.com/NousResearch/hermes-agent/228022ef5b209cb0a3d739394edddf887e1db0f6/scripts/install.sh' \
  -o ~/install-audit/hermes-agent/install.sh
```

## 2.2 [VERIFY] 检查来源

```bash
head -n 20 ~/install-audit/hermes-agent/install.sh
wc -l ~/install-audit/hermes-agent/install.sh
sha256sum ~/install-audit/hermes-agent/install.sh
```

**注意：** SHA-256 是本地下载文件的记录值；真正的来源锚点是上面的 Git commit。

## 2.3 [DO NOT RUN] 官方 installer

```bash
# 禁止：
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 禁止：
bash ~/install-audit/hermes-agent/install.sh
```

## 2.4 已确认的官方安装逻辑

从官方脚本已经确认：

- 支持 `--dir` 指定代码安装目录。
- 支持 `--hermes-home` 指定数据目录。
- Python 要求为 `>=3.11,<3.14`。
- 官方脚本会管理自己的 uv。
- root/Linux 新安装采用 FHS 风格代码路径 `/usr/local/lib/hermes-agent`，命令路径 `/usr/local/bin/hermes`，数据继续位于 `$HERMES_HOME`。
- 脚本会检测/处理 Git、C++ 编译器、Node、browser、computer-use 等依赖。
- 脚本包含 setup、gateway、desktop 等阶段。fileciteturn26file0L1-L20 fileciteturn26file0L300-L380 fileciteturn26file0L520-L620 fileciteturn26file0L760-L900

### 本机环境的处理原则

本机已经有：

```text
Python 3.13
uv
Node.js 24.21.0 (fnm)
```

因此不能照搬官方 installer 的“环境接管”行为。

### [PAUSE] Python

先验证：

```bash
python3 --version
python3 -c 'import sys; print(sys.version_info[:3])'
uv --version
```

预期 Python 3.13 在 Hermes 的 `>=3.11,<3.14` 范围内。

**如果不是 3.13 或 uv 状态异常，停止并讨论。**

### [PAUSE] Node

先验证：

```bash
node --version
fnm current
npm --version
```

不要让 Hermes installer 自动安装/替换 Node。

Hermes 的 Node 依赖必须放在 Hermes 自己的路径中；不能让它污染 fnm 的全局 Node 环境。

---

## 2.5 [RUN] 建立 Hermes 目录

建议：

```bash
sudo mkdir -p /opt/hermes-agent/versions
sudo mkdir -p /etc/hermes-agent
sudo mkdir -p /var/lib/hermes-agent
```

首次版本确定后：

```bash
sudo mkdir -p /opt/hermes-agent/versions/<VERSION>
```

**不要现在自行填版本号。** 先以执行当天官方 release/tag/commit 为准。

---

## 2.6 [RUN] 取得 Hermes 源码

原则上使用固定 commit，而不是 `main` 漂移：

```bash
sudo git clone \
  https://github.com/NousResearch/hermes-agent.git \
  /opt/hermes-agent/versions/<VERSION>

cd /opt/hermes-agent/versions/<VERSION>
sudo git checkout <OFFICIAL_COMMIT>
```

然后：

```bash
git rev-parse HEAD
git status --short
```

### [VERIFY]

`git rev-parse HEAD` 必须与安装计划中的固定 commit 一致。

---

## 2.7 [RUN] Python 隔离环境

不要把 venv 放进用户的公共 Python 目录，也不要与其它 Agent 共用。

推荐：

```bash
sudo mkdir -p /opt/hermes-agent/venv
sudo uv venv /opt/hermes-agent/venv --python /usr/bin/python3
```

如果 `uv` 不接受 `/usr/bin/python3` 的当前路径或权限模型出现异常：

### [PAUSE]

把完整错误输出发来，不要自行切换到 `sudo uv python install`。

激活/验证：

```bash
source /opt/hermes-agent/venv/bin/activate
python --version
which python
```

---

## 2.8 [RUN] 安装 Hermes Python 依赖

这一步必须根据安装时实际固定的 Hermes commit 的 `pyproject.toml` 来执行，不提前写死可能已经变化的 extra 名称。

先：

```bash
cd /opt/hermes-agent/versions/<VERSION>
grep -nE '^\[project\]|requires-python|^dependencies|^\[project.optional-dependencies\]' pyproject.toml
```

### [PAUSE]

把上述输出发给我，我确认当前 commit 应该安装哪个 extra，再执行 `uv pip install`。

**这一条是故意设置的人工检查点。**

---

## 2.9 Node / browser / computer-use 依赖

官方脚本明确包含 browser-tool、Node 依赖、native Node module 编译等逻辑。脚本会检查 C++ 编译器，并可能安装 build-essential；还会维护自己的 Node/npm prefix。fileciteturn26file0L760-L900

### [PAUSE]

不要根据经验直接执行：

```bash
npm install -g ...
```

也不要直接运行官方 `install.sh`。

下一步需要根据固定 commit 的 `package.json`、相关 scripts 和 installer 的具体调用链，整理出 Hermes 私有 Node prefix 的绝对路径命令。

---

## 2.10 `/usr/local/bin/hermes`

基础 CLI 安装完成后，使用 wrapper，而不是把 Hermes 私有文件直接散到 PATH：

```bash
sudo tee /usr/local/bin/hermes >/dev/null <<'EOF'
#!/bin/sh
exec /opt/hermes-agent/venv/bin/python /opt/hermes-agent/current/hermes_cli/main.py "$@"
EOF

sudo chmod 0755 /usr/local/bin/hermes
```

### [PAUSE]

**上面只是 wrapper 模板，不要盲目执行。**

必须先确认当前 Hermes commit 的实际 entrypoint，再生成最终 wrapper。

---

## 2.11 [VERIFY] 基础验证

只做基础 CLI：

```bash
hermes --version
hermes --help
```

如果提供 doctor：

```bash
hermes doctor
```

### [PAUSE]

在基础 CLI 正常之前，禁止：

- API/OAuth 配置
- gateway
- Telegram/Discord/Slack 等 channel
- systemd
- Web dashboard
- desktop
- browser/computer-use 扩展

官方文档本身也建议先让普通 chat 工作，再叠加 gateway、cron、skills、voice、routing 等功能。citeturn0search4

---

# 3. OpenClaw

官方仓库存在 `scripts/install.sh`，官方文档也以它作为 Linux/macOS/WSL 安装入口。citeturn0search2

本次审计固定：

```text
Repository: openclaw/openclaw
Script: scripts/install.sh
Audit commit: aac3b2773c7f80bede88e8ce67417ed72a3eb33d
```

## 3.1 [RUN] 下载

```bash
mkdir -p ~/install-audit/openclaw

curl -fL \
  'https://raw.githubusercontent.com/openclaw/openclaw/aac3b2773c7f80bede88e8ce67417ed72a3eb33d/scripts/install.sh' \
  -o ~/install-audit/openclaw/install.sh
```

## 3.2 [VERIFY]

```bash
head -n 30 ~/install-audit/openclaw/install.sh
wc -l ~/install-audit/openclaw/install.sh
sha256sum ~/install-audit/openclaw/install.sh
```

官方脚本当前约 4224 行 / 147 KB，因此也必须按阶段拆分，而不是直接执行。citeturn0search2

## 3.3 已确认的官方逻辑

脚本包含：

- HTTPS/TLS downloader。
- checksum 校验能力。
- Node 版本判断。
- npm/prefix 管理。
- OpenClaw CLI 安装逻辑。
- 更新/升级相关处理。
- 交互式流程。

因此 OpenClaw 的安装策略是：

```text
官方脚本
   ↓
只提取下载 / 解包 / npm prefix / CLI 部署逻辑
   ↓
/opt/openclaw/versions/<VERSION>
   ↓
/opt/openclaw/current
   ↓
/usr/local/bin/openclaw
```

## 3.4 [PAUSE] Node

先验证：

```bash
node --version
npm --version
fnm current
```

**不允许 installer 修改 fnm。**

如果当前 OpenClaw commit 要求的 Node 范围与 24.21.0 不一致：

### [PAUSE / NEED DISCUSSION]

不要自动切换 Node。

---

## 3.5 [RUN] 建立目录

```bash
sudo mkdir -p /opt/openclaw/versions
sudo mkdir -p /etc/openclaw
sudo mkdir -p /var/lib/openclaw
```

---

## 3.6 Node 依赖隔离

OpenClaw 必须有自己的 Node 依赖目录/安装前缀。

禁止：

```bash
npm install -g openclaw
```

禁止：

```bash
npm install -g <openclaw-dependency>
```

除非审计后确认该命令实际上写入 `/opt/openclaw/...` 的私有 prefix。

### [PAUSE]

在执行 npm 安装命令之前，必须先确认：

```bash
npm config get prefix
npm root -g
npm bin -g
```

以及 installer 中对应的 prefix 设置。

如果输出不是 `/opt/openclaw/...`：**停止。**

---

## 3.7 [RUN] 基础 CLI 验证

完成最小安装后：

```bash
openclaw --version
openclaw --help
```

### [PAUSE]

基础 CLI 没有通过之前，不做：

- onboarding
- provider/API key
- channel/bot
- gateway
- systemd
- Web/Desktop

---

# 4. 其它项目的处理规则

如果发现某项目的官方文档出现 install.sh，但项目同时提供可靠官方 Linux x86_64 Release binary：

### [RUN]

直接使用官方 Release binary。

### [DO NOT RUN]

不要研究 install.sh，也不要执行它。

当前已确认优先走 Release binary 的项目：

- RTK
- CodeGraph
- Pi
- OpenCode
- Codex

---

# 5. 执行时的统一标记

以后每个实际安装步骤都使用以下标签：

| 标签 | 含义 | 用户动作 |
|---|---|---|
| `[RUN]` | 可以执行 | 执行并继续 |
| `[VERIFY]` | 必须核对 | 执行后把结果与预期比较 |
| `[PAUSE]` | 人工检查点 | **停下，先沟通** |
| `[DO NOT RUN]` | 仅供阅读 | 禁止执行 |
| `[OPTIONAL]` | 可选功能 | 暂不执行，除非明确需要 |
| `[ROLLBACK]` | 回滚 | 出现异常时使用 |
| `[NEED DISCUSSION]` | 资料不足/有风险 | **停下，找我讨论** |

### 最重要的一条

**任何 `[PAUSE]` / `[NEED DISCUSSION]` 都不是“建议”，而是本安装方案的硬停止点。**

执行时如果你看到：

```text
[PAUSE]
```

就先不要继续下一条命令，把：

1. 实际命令
2. 完整输出
3. `echo $?`
4. 当前目录

发给我，我们再决定下一步。

---

# 6. 当前审计结论

## Hermes

**结论：可以采用“下载官方 install.sh → 审计 → 手工拆分”的方案。**

但 Hermes installer 很复杂，不能只改 `HERMES_HOME` 或 `INSTALL_DIR` 后执行。必须把 Python、Node、browser、computer-use、setup、gateway 等阶段分别处理。

## OpenClaw

**结论：同样可以采用“下载官方 install.sh → 审计 → 手工拆分”的方案。**

OpenClaw installer 同样包含 Node/npm/prefix/升级逻辑，因此必须建立自己的 `/opt/openclaw` 私有依赖树，不能把它当成简单的 `npm install -g`。

## 安装顺序

仍然保持：

```text
RTK
 ↓
CodeGraph
 ↓
Pi
 ↓
OpenCode
 ↓
Codex
 ↓
OpenClaw
 ↓
OmniRoute
 ↓
DeepSeek Harness
 ↓
Hermes
 ↓
全部验证
 ↓
RTK / CodeGraph 集成
 ↓
systemd / Web / GUI
```

这样可以把复杂 install.sh 项目留到基础 binary 都稳定之后处理。
