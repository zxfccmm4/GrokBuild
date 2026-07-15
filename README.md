# GrokBuild

Grok Build 的本地配置模板与交互式安装工具。

安装官方 [Grok CLI](https://x.ai) 后，可用本仓库中的 `config.toml` 作为自定义模型模板，通过 `install-config.sh` 安全地写入 `~/.grok/config.toml`。**`base_url` 与 `api_key` 不会从模板原样复制**，必须在安装时由你本人填写。

---

## 目录结构

```text
GrokBuild/
├── README.md            # 本说明
├── config.toml          # 配置模板（含默认模型 / UI / 隐私相关选项）
└── install-config.sh    # 交互式安装脚本
```

| 文件 | 说明 |
|------|------|
| `config.toml` | 写入 `~/.grok/config.toml` 的模板。预览与文档中敏感字段已隐去。 |
| `install-config.sh` | 交互安装：脱敏预览 → 填写 `base_url` / `api_key` → 备份旧配置 → 写入目标。 |

---

## 前置条件

1. 已安装 Grok CLI（Grok Build）
2. 本机存在或可创建目录 `~/.grok`
3. macOS / Linux，bash 可用

安装 Grok CLI（若尚未安装）：

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok --version
```

---

## 快速开始

```bash
cd /path/to/GrokBuild

# 赋予执行权限（首次）
chmod +x install-config.sh

# 交互式安装配置
./install-config.sh
```

按提示完成：

1. 查看**脱敏后的**模板预览（`base_url`、`api_key` 显示为 `***REDACTED***`）
2. 输入你的 **base_url**（须以 `http://` 或 `https://` 开头）
3. 输入你的 **api_key**（输入时不回显，可选二次核对）
4. 确认后安装；若已有 `~/.grok/config.toml`，会先备份为  
   `~/.grok/config.toml.bak.<时间戳>`

验证：

```bash
# 查看已安装配置（请自行注意不要把真实 key 贴到公开场合）
cat ~/.grok/config.toml

# 启动 Grok
grok
```

---

## 使用说明

### 安装脚本做了什么

| 步骤 | 行为 |
|------|------|
| 检查模板 | 要求脚本同目录下存在 `config.toml` |
| 检查目录 | 若无 `~/.grok` 可询问后创建 |
| 脱敏预览 | 将 `api_key`、`base_url` 等敏感/自定义字段显示为 `***REDACTED***` |
| 强制自定义 | **必须**交互填写 `base_url` 与 `api_key`，不沿用模板里的值 |
| 备份 | 覆盖前备份已有 `config.toml` |
| 写入 | 用模板其余字段 + 你的 `base_url` / `api_key` 生成目标文件，权限尽量设为 `600` |

### 手动安装（不推荐）

若不想用脚本，可自行复制后编辑：

```bash
mkdir -p ~/.grok
cp config.toml ~/.grok/config.toml
# 务必修改 base_url 与 api_key
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

本仓库的 `config.toml` 是一份**开箱可用的自定义模型模板**：默认模型别名、关闭遥测、限制代码库上传、以及偏宽松的权限模式等。安装后你只需保证 `base_url` / `api_key` 正确，即可用自定义兼容接口调用模型。

### 脱敏后的结构示例

以下为结构说明用示例（**不是**你机器上的真实值）：

```toml
[cli]
installer = "internal"

[models]
default = "Steve"
default_reasoning_effort = "high"

[model.Steve]
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
| `default` | `"Steve"` | 默认使用的**模型配置名**，对应下方 `[model.Steve]` 段。 |
| `default_reasoning_effort` | `"high"` | 默认推理强度。常见取值：`low` / `medium` / `high`。 |

修改默认模型时：既可改 `default` 指向另一个 `[model.XXX]`，也可继续用 `Steve` 只改该段内字段。

#### `[model.Steve]`（自定义模型）

段名 `Steve` 是本地别名，可按需改成其他名字（同时更新 `[models].default`）。

| 键 | 是否必填自定义 | 说明 |
|----|----------------|------|
| `model` | 否 | 上游实际模型 ID，如 `grok-4.5`。需与你的 API 服务支持的名称一致。 |
| `base_url` | **是** | OpenAI 兼容 API 的根地址，例如 `https://api.example.com/v1`。**安装脚本强制填写。** |
| `name` | 否 | 展示名称，可与 `model` 相同。 |
| `api_key` | **是** | 访问该 `base_url` 的密钥。**安装脚本强制填写，切勿泄露。** |
| `context_window` | 否 | 上下文窗口 token 上限（模板为 `500000`）。按服务商能力调整。 |
| `supports_reasoning_effort` | 否 | 是否支持推理强度参数。 |
| `reasoning_efforts` | 否 | 可选的推理强度列表，供 UI / 命令选择。 |

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

修改 `[model.Steve]` 中的：

```toml
base_url = "https://你的网关/v1"
api_key = "你的密钥"
```

### 换默认模型名

```toml
[models]
default = "MyProxy"

[model.MyProxy]
model = "grok-4.5"
base_url = "https://你的网关/v1"
name = "grok-4.5"
api_key = "你的密钥"
context_window = 500000
supports_reasoning_effort = true
reasoning_efforts = ["low", "medium", "high"]
```

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
