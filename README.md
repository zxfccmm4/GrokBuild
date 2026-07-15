# GrokBuild

Grok Build 的本地配置模板与交互式安装工具。

安装官方 [Grok CLI](https://x.ai) 后，可用本仓库中的 `config.toml` 作为自定义模型模板，通过 `install-config.sh` 安全地写入 `~/.grok/config.toml`。安装时可自定义 **模型别名**（`[models].default` / `[model.名称]`）、**`base_url`** 与 **`api_key`**；后两者不会从模板原样复制，必须由你填写。

---

## 目录结构

```text
GrokBuild/
├── README.md            # 本说明
├── bootstrap.sh         # 一键：装 CLI + 下载脚本 + 跑配置向导
├── config.toml          # 配置模板（含默认模型 / UI / 隐私相关选项）
└── install-config.sh    # 交互式配置安装脚本
```

| 文件 | 说明 |
|------|------|
| `bootstrap.sh` | 一条命令完成：安装 Grok Build、下载本仓库文件、运行配置向导。 |
| `config.toml` | 写入 `~/.grok/config.toml` 的模板。预览与文档中敏感字段已隐去。 |
| `install-config.sh` | 交互安装：脱敏预览 → 填写模型别名 / `base_url` / `api_key` → 备份旧配置 → 写入目标。 |

---

## 前置条件

- macOS / Linux，bash 可用
- 网络可访问 [x.ai](https://x.ai) 与 GitHub
- 本机可创建目录 `~/.grok`

---

## 一键安装（推荐）

在终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

这条命令会依次：

1. **安装 Grok Build CLI**（若本机已有 `grok` 则跳过）
2. **下载**本仓库的 `config.toml` 与 `install-config.sh`（默认到临时目录，结束后清理）
3. **运行交互配置向导**，写入 `~/.grok/config.toml`

向导中按提示填写：

1. **模型别名**（回车保留默认 `Steve`）
2. **base_url**（须以 `http://` 或 `https://` 开头）
3. **api_key**（输入时可见，便于核对；可选二次输入确认）
4. 确认安装（已有配置会先备份为 `~/.grok/config.toml.bak.<时间戳>`）

可选环境变量：

| 变量 | 含义 |
|------|------|
| `SKIP_GROK_CLI=1` | 跳过 CLI 安装，只下载并跑配置 |
| `SKIP_CONFIG=1` | 只装 CLI，不跑配置向导 |
| `GROKBUILD_WORKDIR=/path` | 把脚本下载到指定目录（不自动删除） |

示例：

```bash
# 已装好 grok，只配置
SKIP_GROK_CLI=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash

# 只装 CLI
SKIP_CONFIG=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

装完后：

```bash
# 若当前 shell 找不到 grok
export PATH="$HOME/.grok/bin:$PATH"

grok --version
grok
```

---

## 分步安装（可选）

若不想用一键脚本，可按下面分步操作。

### 1. 安装 Grok Build（Grok CLI）

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok --version
```

如需指定版本：

```bash
curl -fsSL https://x.ai/cli/install.sh | bash -s 0.1.42
```

升级：

```bash
grok update
```

### 2. 下载本仓库脚本与配置模板

**方式 A：Git 克隆**

```bash
git clone https://github.com/zxfccmm4/GrokBuild.git
cd GrokBuild
```

**方式 B：仅下载安装所需文件（无需 Git）**

```bash
mkdir -p GrokBuild && cd GrokBuild
curl -fsSL -o config.toml \
  https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/config.toml
curl -fsSL -o install-config.sh \
  https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/install-config.sh
chmod +x install-config.sh
```

**方式 C：下载 ZIP 并解压**

```bash
curl -fsSL -o GrokBuild.zip \
  https://github.com/zxfccmm4/GrokBuild/archive/refs/heads/main.zip
unzip GrokBuild.zip
cd GrokBuild-main
```

### 3. 运行交互式配置安装

```bash
./install-config.sh
```

### 4. 验证并启动

```bash
cat ~/.grok/config.toml   # 勿把真实 key 发到公开场合
grok
```

---

## 使用说明

### 安装脚本做了什么

| 步骤 | 行为 |
|------|------|
| 检查模板 | 要求脚本同目录下存在 `config.toml` |
| 检查目录 | 若无 `~/.grok` 可询问后创建 |
| 脱敏预览 | 将 `api_key`、`base_url` 等敏感字段显示为 `***REDACTED***` |
| 模型别名 | 可自定义 `default` 与对应的 `[model.名称]`（回车保留模板名，如 `Steve`） |
| 强制自定义 | **必须**交互填写 `base_url` 与 `api_key`，不沿用模板里的值 |
| 备份 | 覆盖前备份已有 `config.toml` |
| 写入 | 用模板其余字段 + 你的别名 / `base_url` / `api_key` 生成目标文件，权限尽量设为 `600` |

### 手动安装（不推荐）

若不想用脚本，可自行复制后编辑：

```bash
mkdir -p ~/.grok
cp config.toml ~/.grok/config.toml
# 按需修改：default / [model.名称]、base_url、api_key
$EDITOR ~/.grok/config.toml
chmod 600 ~/.grok/config.toml
```

### 恢复备份

```bash
ls ~/.grok/config.toml.bak.*
cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml
```

### 安全建议

- **不要**把填好真实 `api_key` 的配置提交到 Git 或发到聊天、截图里
- 模板中的示例值仅作结构参考；安装脚本会强制你重新填写
- 建议将 `~/.grok/config.toml` 权限保持为仅本人可读（`600`）
- 分享本仓库时，确认 `config.toml` 内没有可用的真实密钥

---

## `config.toml` 介绍

Grok 从用户目录读取配置：

```text
~/.grok/config.toml
```

本仓库的 `config.toml` 是一份**开箱可用的自定义模型模板**：默认模型别名、关闭遥测、限制代码库上传、以及偏宽松的权限模式等。安装时可改模型别名，并保证 `base_url` / `api_key` 正确，即可用自定义兼容接口调用模型。

### 脱敏后的结构示例

以下为结构说明用示例（**不是**你机器上的真实值）：

```toml
[cli]
installer = "internal"

[models]
default = "Steve"             # 可自定义；与下方 [model.名称] 一致
default_reasoning_effort = "high"

[model.Steve]                 # 段名 = 上面的 default，可一并改名
model = "grok-4.5"
base_url = "***REDACTED***"   # 安装时由你填写
name = "grok-4.5"
api_key = "***REDACTED***"    # 安装时由你填写
context_window = 500000
supports_reasoning_effort = true
reasoning_efforts = [
    "low",
    "medium",
    "high",
]

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

### 分段说明

#### `[cli]`

| 键 | 示例 | 说明 |
|----|------|------|
| `installer` | `"internal"` | 安装器 / 发行渠道相关标识，一般保持模板值即可。 |

#### `[models]`

| 键 | 示例 | 说明 |
|----|------|------|
| `default` | `"Steve"` | 默认使用的**模型配置名**（本地别名），必须与下方某个 `[model.名称]` 段名一致。**可自定义**，安装脚本会询问；回车则保留模板值。 |
| `default_reasoning_effort` | `"high"` | 默认推理强度。常见取值：`low` / `medium` / `high`。 |

`default` 只是本地昵称，**不是**上游 API 的模型 ID。例如可以写成：

```toml
[models]
default = "MyProxy"

[model.MyProxy]
# ...
```

安装脚本会同步改写 `default = "..."` 与 `[model.名称]`，避免两者不一致。

#### `[model.名称]`（自定义模型）

段名（如模板中的 `Steve`）是本地别名，须与 `[models].default` 相同。安装时可改成 `MyProxy`、`work-grok` 等。

| 键 | 是否必填自定义 | 说明 |
|----|----------------|------|
| `model` | 否 | 上游实际模型 ID，如 `grok-4.5`。需与你的 API 服务支持的名称一致。 |
| `base_url` | **是** | OpenAI 兼容 API 的根地址，例如 `https://api.example.com/v1`。**安装脚本强制填写。** |
| `name` | 否 | 展示名称，可与 `model` 相同。 |
| `api_key` | **是** | 访问该 `base_url` 的密钥。**安装脚本强制填写，切勿泄露。** |
| `context_window` | 否 | 上下文窗口 token 上限（模板为 `500000`）。按服务商能力调整。 |
| `supports_reasoning_effort` | 否 | 是否支持推理强度参数。 |
| `reasoning_efforts` | 否 | 可选的推理强度列表，供 UI / 命令选择。 |

**模型别名命名建议：** 字母开头，后接字母 / 数字 / `_` / `-`（如 `Steve`、`MyProxy`、`work_grok`）。

**`base_url` 填写注意：**

- 使用 `http://` 或 `https://`
- 通常包含版本路径（如 `/v1`），以你的网关文档为准
- 不要带多余空格或未转义的引号

**`api_key` 填写注意：**

- 使用服务商发给你的完整密钥
- 不要把密钥写进 README、Issue、截图或公开仓库

#### `[features]`

| 键 | 模板值 | 说明 |
|----|--------|------|
| `telemetry` | `false` | 关闭产品遥测。 |
| `feedback` | `false` | 关闭反馈相关能力（按 Grok 版本行为可能略有差异）。 |

#### `[telemetry]`

| 键 | 模板值 | 说明 |
|----|--------|------|
| `trace_upload` | `false` | 不上传 trace。 |
| `mixpanel_enabled` | `false` | 关闭 Mixpanel 类分析。 |

模板默认偏隐私：尽量减少数据外传。

#### `[harness]`

| 键 | 模板值 | 说明 |
|----|--------|------|
| `disable_codebase_upload` | `true` | 禁止将代码库上传到远端分析类通道（提高本地代码隐私）。 |

#### `[ui]`

| 键 | 模板值 | 说明 |
|----|--------|------|
| `max_thoughts_width` | `120` | 思考 / 推理区域最大显示宽度。 |
| `fork_secondary_model` | `"grok-build"` | 分叉会话等场景使用的次要模型标识。 |
| `yolo` | `false` | 是否启用极度宽松的自动执行风格（名称依版本而定）。`false` 更稳妥。 |
| `compact_mode` | `false` | 紧凑 UI 模式。 |
| `permission_mode` | `"always-approve"` | 工具调用权限策略。模板为始终批准，减少交互打断；若更在意安全，可改为更严格的模式（以当前 Grok 文档支持的取值为准）。 |

> **注意：** `permission_mode = "always-approve"` 会减少确认步骤，代理执行命令/改文件时更「大胆」。在不信任当前工作区或共享机器上，请改为更保守的策略。

---

## 常见自定义

### 只改接口地址和密钥

运行 `./install-config.sh` 重新安装，或直接编辑：

```bash
$EDITOR ~/.grok/config.toml
```

修改对应 `[model.你的别名]` 中的：

```toml
base_url = "https://你的网关/v1"
api_key = "你的密钥"
```

### 换默认模型别名（`default` / `[model.名称]`）

安装脚本会一步改好；若手动修改，**两处必须一致**：

```toml
[models]
default = "MyProxy"          # 本地别名，可任意合法标识符

[model.MyProxy]              # 段名必须与 default 相同
model = "grok-4.5"           # 上游真实模型 ID
base_url = "https://你的网关/v1"
name = "grok-4.5"
api_key = "你的密钥"
context_window = 500000
supports_reasoning_effort = true
reasoning_efforts = ["low", "medium", "high"]
```

| 字段 | 含义 | 示例 |
|------|------|------|
| `default` / `[model.XXX]` | 本地配置名，仅 Grok 用来选配置 | `Steve`、`MyProxy` |
| `model` | 发给 API 的真实模型 ID | `grok-4.5` |

### 降低默认推理强度（更省、更快）

```toml
[models]
default_reasoning_effort = "medium"  # 或 "low"
```

### 更谨慎的权限

将 `[ui].permission_mode` 从 `"always-approve"` 改为你当前 Grok 版本支持的更严格选项（详见本机 `~/.grok/docs` 或官方文档中的 Configuration / Permissions 章节）。

---

## 故障排查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| 脚本提示找不到 `config.toml` | 未在含模板的目录运行 | `cd` 到 `GrokBuild` 再执行 `./install-config.sh` |
| 模型别名反复报格式无效 | 旧版脚本把提示符混入了输入值 | 更新到最新 `install-config.sh` 后重跑；合法示例：`Steve`、`MyProxy`、`work-grok`（也可直接回车用默认） |
| `base_url` 反复报格式无效 | 缺少协议或含空格 | 使用 `https://host/v1` 形式 |
| Grok 无法连上模型 | 地址错误、密钥错误、网关不可达 | 检查 `base_url` / `api_key`、网络与服务商控制台 |
| 安装后行为与预期不符 | 读到了旧配置或备份未生效 | 确认编辑的是 `~/.grok/config.toml`，必要时重启 `grok` |
| 想撤销本次安装 | 需要恢复备份 | `cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml` |

更多 Grok 本身的能力（TUI、Skills、MCP、Headless 等）见安装后的：

```text
~/.grok/README.md
~/.grok/docs/user-guide/
```

---

## 许可证与免责

- 本目录提供的是**配置模板与安装辅助脚本**，不包含 Grok CLI 本体。
- `api_key`、网关地址由使用者自行申请与保管；因密钥泄露或错误配置导致的损失由使用者自行承担。
- 模板中的默认隐私与权限选项可按个人与企业合规要求再调整。
