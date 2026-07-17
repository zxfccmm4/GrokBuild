# GrokBuild

<p align="center">
  <strong>Grok Build 本地配置模板 · 一键安装 · 交互向导</strong>
</p>

<p align="center">
  为 <a href="https://x.ai">Grok CLI</a> 准备自定义模型（OpenAI 兼容接口）：<br/>
  安装 CLI → 下载模板 → 填写别名 / <code>base_url</code> / <code>api_key</code> → 写入 <code>~/.grok/config.toml</code>
</p>

<p align="center">
  <a href="#一键安装"><img src="https://img.shields.io/badge/install-one%20command-0ea5e9?style=flat-square" alt="one command" /></a>
  <a href="https://github.com/zxfccmm4/GrokBuild"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-111827?style=flat-square" alt="platform" /></a>
  <a href="#安全建议"><img src="https://img.shields.io/badge/api__key-you%20fill%20in-f59e0b?style=flat-square" alt="api key" /></a>
</p>

---

## 目录

- [一键安装](#一键安装)
- [安装后验证](#安装后验证)
- [项目结构](#项目结构)
- [分步安装](#分步安装)
- [安装脚本做了什么](#安装脚本做了什么)
- [配置说明](#配置说明)
- [常见自定义](#常见自定义)
- [故障排查](#故障排查)
- [安全建议](#安全建议)
- [许可证与免责](#许可证与免责)

---

## 一键安装

> **推荐**：一条命令完成 CLI 安装 + 配置向导。

```bash
curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

| 步骤 | 行为 |
|:----:|------|
| **1** | 安装 Grok Build CLI（已有 `grok` 则跳过） |
| **2** | 下载 `config.toml` 与 `install-config.sh`（默认临时目录，结束后清理） |
| **3** | 交互写入 `~/.grok/config.toml` |

向导会依次询问：

| # | 项 | 说明 |
|:-:|----|------|
| 1 | **模型别名** | 本地配置名；回车保留默认 `Steve` |
| 2 | **base_url** | 须以 `http://` 或 `https://` 开头 |
| 3 | **api_key** | 输入时可见，便于核对；可选二次确认 |
| 4 | **Search Tool** | 可选；开启后启用原生 `web_search` / `x_search`（见下文） |
| 5 | **确认** | 已有配置会先备份为 `config.toml.bak.<时间戳>` |

### 可选环境变量

| 变量 | 作用 |
|------|------|
| `SKIP_GROK_CLI=1` | 跳过 CLI，只下载并跑配置 |
| `SKIP_CONFIG=1` | 只装 CLI，不跑配置向导 |
| `GROKBUILD_WORKDIR=/path` | 把脚本下载到指定目录（不自动删除） |

```bash
# 已装好 grok，只配置
SKIP_GROK_CLI=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash

# 只装 CLI
SKIP_CONFIG=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

### 前置条件

- macOS / Linux，`bash` + `curl`
- 可访问 [x.ai](https://x.ai) 与 GitHub
- 可创建 `~/.grok`

---

## 安装后验证

```bash
# 若当前 shell 找不到 grok
export PATH="$HOME/.grok/bin:$PATH"

grok --version
grok
```

> 查看配置时请勿把真实 `api_key` 发到公开场合：`cat ~/.grok/config.toml`

---

## 项目结构

```text
GrokBuild/
├── README.md            # 本说明
├── bootstrap.sh         # 一键：装 CLI + 下载 + 配置向导
├── config.toml          # 配置模板（隐私 / UI / 模型段）
└── install-config.sh    # 交互写入 ~/.grok/config.toml
```

| 文件 | 职责 |
|------|------|
| [`bootstrap.sh`](./bootstrap.sh) | 一条命令串联安装与配置 |
| [`config.toml`](./config.toml) | 写入目标的模板（敏感字段安装时由你填写） |
| [`install-config.sh`](./install-config.sh) | 脱敏预览 → 别名 / URL / Key → 备份 → 写入 |

---

## 分步安装

不想用一键脚本时，可按下列步骤操作。

<details>
<summary><strong>1. 安装 Grok Build CLI</strong></summary>

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok --version
```

指定版本 / 升级：

```bash
curl -fsSL https://x.ai/cli/install.sh | bash -s 0.1.42
grok update
```

</details>

<details>
<summary><strong>2. 获取本仓库文件</strong></summary>

**A. Git 克隆**

```bash
git clone https://github.com/zxfccmm4/GrokBuild.git
cd GrokBuild
```

**B. 只下两个文件（无需 Git）**

```bash
mkdir -p GrokBuild && cd GrokBuild
curl -fsSL -o config.toml \
  https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/config.toml
curl -fsSL -o install-config.sh \
  https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/install-config.sh
chmod +x install-config.sh
```

**C. ZIP**

```bash
curl -fsSL -o GrokBuild.zip \
  https://github.com/zxfccmm4/GrokBuild/archive/refs/heads/main.zip
unzip GrokBuild.zip && cd GrokBuild-main
```

</details>

<details>
<summary><strong>3. 运行配置向导</strong></summary>

```bash
./install-config.sh
```

</details>

<details>
<summary><strong>4. 手动安装（不推荐）</strong></summary>

```bash
mkdir -p ~/.grok
cp config.toml ~/.grok/config.toml
# 修改 default / [model.名称]、base_url、api_key
$EDITOR ~/.grok/config.toml
chmod 600 ~/.grok/config.toml
```

</details>

<details>
<summary><strong>5. 恢复备份</strong></summary>

```bash
ls ~/.grok/config.toml.bak.*
cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml
```

</details>

---

## 安装脚本做了什么

| 步骤 | 行为 |
|------|------|
| 检查模板 | 同目录需有 `config.toml` |
| 检查目录 | 无 `~/.grok` 时可询问创建 |
| 脱敏预览 | `api_key`、`base_url` 等显示为 `***REDACTED***` |
| 模型别名 | 自定义 `default` 与 `[model.名称]`（回车保留模板名） |
| 强制自定义 | **必须**填写 `base_url` 与 `api_key` |
| Search Tool | **可选**；开启则写入 `web_search` + Responses 后端搜索字段 |
| 备份 | 覆盖前备份已有配置 |
| 写入 | 模板 + 你的自定义项；权限尽量 `600` |

---

## 配置说明

Grok 读取：

```text
~/.grok/config.toml
```

本仓库模板默认：自定义模型别名、关闭遥测、限制代码库上传、偏宽松权限。装好后只要 `base_url` / `api_key` 正确，即可走兼容接口。

### 结构示例（脱敏）

```toml
[cli]
installer = "internal"

[models]
default = "Steve"             # 本地别名，与下方 [model.名称] 一致
default_reasoning_effort = "high"
# web_search = "Steve"        # 开启 Search Tool 时由向导写入

[model.Steve]
model = "grok-4.5"            # 上游真实模型 ID
base_url = "***REDACTED***"   # 安装时填写
name = "grok-4.5"
api_key = "***REDACTED***"    # 安装时填写
context_window = 500000
supports_reasoning_effort = true
reasoning_efforts = ["low", "medium", "high"]
# api_backend = "responses"           # 开启 Search Tool 时写入
# supports_backend_search = true      # 开启 Search Tool 时写入

[features]
telemetry = false
feedback = false

[telemetry]
trace_upload = false
mixpanel_enabled = false

[harness]
disable_codebase_upload = true

[ui]
max_thoughts_width = 120
fork_secondary_model = "grok-build"
yolo = false
compact_mode = false
permission_mode = "always-approve"
```

### 字段速查

#### `[models]`

| 键 | 示例 | 说明 |
|----|------|------|
| `default` | `"Steve"` | **本地配置名**，须与某个 `[model.名称]` 一致；安装时可改 |
| `default_reasoning_effort` | `"high"` | `low` / `medium` / `high` |
| `web_search` | `"Steve"` | **可选**；Build 内置 `web_search` 工具使用的模型别名（与 `default` 同名即可） |

`default` 是本地昵称，**不是** API 的模型 ID。

```toml
[models]
default = "MyProxy"

[model.MyProxy]
# ...
```

安装脚本会同步改写两处，避免不一致。

#### `[model.名称]`

| 键 | 必填自定义 | 说明 |
|----|:----------:|------|
| `model` | 否 | 上游模型 ID，如 `grok-4.5` |
| `base_url` | **是** | OpenAI 兼容根地址，如 `https://api.example.com/v1` |
| `name` | 否 | 展示名 |
| `api_key` | **是** | 访问密钥，切勿泄露 |
| `context_window` | 否 | 上下文上限（模板 `500000`） |
| `supports_reasoning_effort` | 否 | 是否支持推理强度 |
| `reasoning_efforts` | 否 | 可选强度列表 |
| `api_backend` | 否 | Search Tool 开启时为 `"responses"`（`/v1/responses`） |
| `supports_backend_search` | 否 | Search Tool 开启时为 `true`，允许服务端 `web_search` / `x_search` |

**别名规则：** 字母开头，后接字母 / 数字 / `_` / `-`  
例：`Steve` · `MyProxy` · `work-grok`

**base_url：** `http(s)://` · 通常含 `/v1` · 无空格  
**api_key：** 完整密钥 · 勿写进 README / Issue / 截图

#### 其他段（模板默认）

| 段 | 要点 |
|----|------|
| `[cli]` | `installer = "internal"`，一般保持 |
| `[features]` / `[telemetry]` | 默认关闭遥测与 trace 上传 |
| `[harness]` | `disable_codebase_upload = true`，减少代码外传 |
| `[ui]` | 宽度、次要模型、`permission_mode` 等 |

| `[ui]` 键 | 模板值 | 说明 |
|-----------|--------|------|
| `max_thoughts_width` | `120` | 思考区最大宽度 |
| `fork_secondary_model` | `"grok-build"` | 分叉等场景次要模型 |
| `yolo` | `false` | 极度宽松自动执行（更稳妥为关） |
| `compact_mode` | `false` | 紧凑 UI |
| `permission_mode` | `"always-approve"` | 工具调用少打断；共享机器请改严 |

> **注意：** `always-approve` 会让代理改文件 / 跑命令更「大胆」。不信任工作区时请改用更保守策略（见本机 `~/.grok/docs`）。

---

## 常见自定义

### 只改地址和密钥

```bash
./install-config.sh
# 或
$EDITOR ~/.grok/config.toml
```

```toml
base_url = "https://你的网关/v1"
api_key = "你的密钥"
```

### 换默认模型别名

两处必须一致：

```toml
[models]
default = "MyProxy"

[model.MyProxy]
model = "grok-4.5"           # 发给 API 的真实 ID
base_url = "https://你的网关/v1"
name = "grok-4.5"
api_key = "你的密钥"
context_window = 500000
supports_reasoning_effort = true
reasoning_efforts = ["low", "medium", "high"]
```

| 字段 | 含义 | 示例 |
|------|------|------|
| `default` / `[model.XXX]` | 本地配置名 | `Steve`、`MyProxy` |
| `model` | API 模型 ID | `grok-4.5` |

### 更省、更快的推理

```toml
[models]
default_reasoning_effort = "medium"  # 或 "low"
```

### 开启 Search Tool（web_search / x_search）

安装向导会询问 **「是否开启 Search Tool?」**。选 **y** 时写入：

```toml
[models]
default = "Steve"
web_search = "Steve"              # Build 的 web_search 工具指向本模型

[model.Steve]
# ...
api_backend = "responses"         # 走 /v1/responses
supports_backend_search = true    # 允许服务端原生搜索
```

| 场景 | 建议 |
|------|------|
| 网关已支持原生 `web_search` / `x_search`（如 grok2api Build 渠道） | 向导里选 **开启** |
| 普通 OpenAI 兼容转发、不支持 Responses 搜索 | 选 **关闭**（默认） |

**手动开关**（已装好后）：

```toml
# 开启：取消注释 / 补上这三行（别名与 default 一致）
[models]
web_search = "Steve"

[model.Steve]
api_backend = "responses"
supports_backend_search = true

# 关闭：删除或注释掉上述三行
```

改完后 **重启 grok** 或 **新开 session**。在对话里可直接说：

```text
请 web_search：最新 xAI 公开新闻，并给来源
用 x_search 查最近关于 Grok 的讨论
```

> **说明：** `x_search` 无独立客户端工具，依赖服务端原生工具注入；需网关与 `supports_backend_search` 均支持。

### 更谨慎的权限

将 `[ui].permission_mode` 改为当前 Grok 版本支持的更严格选项（见 `~/.grok/docs` 或官方 Configuration / Permissions）。

---

## 故障排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| 找不到 `config.toml` | 未在含模板的目录运行 | `cd` 到仓库根再执行 `./install-config.sh` |
| 模型别名一直格式无效 | 旧版脚本把提示混入输入 | 用最新 `install-config.sh`；合法例：`Steve`、`MyProxy`、`work-grok`，或回车用默认 |
| `base_url` 格式无效 | 缺协议或含空格 | 使用 `https://host/v1` |
| 连不上模型 | 地址 / 密钥 / 网络 | 查 `base_url`、`api_key`、服务商控制台 |
| 开启 Search 后报错 / 无搜索 | 网关不支持 Responses 或原生搜索 | 关掉 Search Tool，或换支持 `web_search` 的网关；确认 `api_backend` / `supports_backend_search` |
| 对话里不联网 | 旧 session / 未开 Search | 新开 session；检查 `web_search` 与 `supports_backend_search` |
| 行为与预期不符 | 读了旧配置 | 确认 `~/.grok/config.toml`，必要时重启 `grok` |
| 想撤销安装 | — | `cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml` |

Grok 本体能力（TUI、Skills、MCP、Headless 等）：

```text
~/.grok/README.md
~/.grok/docs/user-guide/
```

---

## 安全建议

- **不要**把含真实 `api_key` 的配置提交到 Git，或发到聊天 / 截图
- 模板里的示例值仅作结构参考；安装脚本会强制你重新填写
- 保持 `~/.grok/config.toml` 权限为 `600`（仅本人可读）
- 分享仓库前确认 `config.toml` 内没有可用密钥

---

## 许可证与免责

- 本仓库提供 **配置模板与安装辅助脚本**，不包含 Grok CLI 本体
- `api_key`、网关地址由使用者自行申请与保管；密钥泄露或错误配置导致的损失自行承担
- 隐私与权限默认值可按个人 / 企业合规要求再调整

---

<p align="center">
  <sub>
    <a href="https://github.com/zxfccmm4/GrokBuild">GitHub</a>
    ·
    <a href="https://x.ai">x.ai</a>
    ·
    一键安装见文档顶部
  </sub>
</p>
