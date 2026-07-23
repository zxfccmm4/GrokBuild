# GrokBuild

<p align="center">
  <strong>Grok Build 配置模板</strong><br/>
  <sub>一键安装 · 交互向导 · 可选联网</sub>
</p>

<p align="center">
  把 <a href="https://x.ai">Grok CLI</a> 接到你自己的 OpenAI 兼容网关<br/>
  装 CLI → 填 <code>base_url</code> / <code>api_key</code> → 写入 <code>~/.grok/config.toml</code>
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/install-one%20command-0ea5e9?style=flat-square" alt="install" /></a>
  &nbsp;
  <a href="https://github.com/zxfccmm4/GrokBuild"><img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-111827?style=flat-square" alt="platform" /></a>
  &nbsp;
  <a href="#search"><img src="https://img.shields.io/badge/search-native%20%2B%20skill-6366f1?style=flat-square" alt="search" /></a>
  &nbsp;
  <a href="#security"><img src="https://img.shields.io/badge/api__key-you%20fill%20in-f59e0b?style=flat-square" alt="security" /></a>
</p>

<p align="center">
  <a href="#quick-start">安装</a>
  ·
  <a href="#verify">验证</a>
  ·
  <a href="#config">配置</a>
  ·
  <a href="#search">联网</a>
  ·
  <a href="#troubleshoot">排错</a>
  ·
  <a href="#security">安全</a>
</p>

---

<a id="quick-start"></a>

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

一条命令完成：**装 CLI → 拉模板 → 交互写入配置 → 可选 skill**。

| 步骤 | 做什么 |
|:----:|--------|
| **1** | 安装 Grok Build CLI（已有 `grok` 则跳过） |
| **2** | 下载 `config.toml` 与向导（默认临时目录，结束后清理） |
| **3** | 交互写入 `~/.grok/config.toml` |
| **4** | 可选安装 [grok-search](https://github.com/Autsunset/grok-search) skill |

### 向导问答

| # | 项 | 说明 |
|:-:|----|------|
| 1 | 模型别名 | 本地配置名；回车保留 `Steve` |
| 2 | `base_url` | 须以 `http://` 或 `https://` 开头 |
| 3 | `api_key` | 输入可见，便于核对；可选二次确认 |
| 4 | Search Tool | 可选；原生 `web_search` / `x_search` |
| 5 | 确认写入 | 已有配置先备份为 `config.toml.bak.<时间戳>` |
| 6 | grok-search | 可选；search / fetch / map |

<details>
<summary><strong>环境变量</strong></summary>

<br/>

| 变量 | 作用 |
|------|------|
| `SKIP_GROK_CLI=1` | 跳过 CLI，只跑配置 |
| `SKIP_CONFIG=1` | 只装 CLI，不跑向导 |
| `SKIP_GROK_SEARCH=1` | 跳过 grok-search skill |
| `GROKBUILD_WORKDIR=/path` | 脚本落到指定目录（不自动删） |
| `GROK_SEARCH_REPO` | skill 的 git URL（默认 Autsunset） |
| `GROK_SEARCH_DIR` | skill 目录（默认 `~/.grok/skills/grok-search`） |

```bash
# 已装好 grok，只配置
SKIP_GROK_CLI=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash

# 只装 CLI
SKIP_CONFIG=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash

# 配置时不装 grok-search
SKIP_GROK_SEARCH=1 SKIP_GROK_CLI=1 curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
```

</details>

<details>
<summary><strong>前置条件</strong></summary>

<br/>

| 需要 | 说明 |
|------|------|
| 系统 | macOS / Linux · `bash` · `curl` |
| 网络 | 可访问 [x.ai](https://x.ai) 与 GitHub |
| 目录 | 可创建 `~/.grok` |
| skill（可选） | `git` · Node ≥ 18.17 · `npm` |

</details>

---

<a id="verify"></a>

## 安装后验证

```bash
export PATH="$HOME/.grok/bin:$PATH"   # 若当前 shell 找不到 grok

grok --version
grok
```

查看配置时 **不要** 把真实 `api_key` 发到公开场合：

```bash
cat ~/.grok/config.toml
```

---

## 项目结构

```text
GrokBuild/
├── bootstrap.sh         # 一键：装 CLI + 下载 + 配置向导
├── config.toml          # 配置模板（隐私 / UI / 模型段）
├── install-config.sh    # 交互写入 ~/.grok/config.toml（+ 可选 skill）
└── README.md
```

| 文件 | 职责 |
|------|------|
| [`bootstrap.sh`](./bootstrap.sh) | 串联 CLI 安装与配置 |
| [`config.toml`](./config.toml) | 写入目标的模板（敏感字段安装时填写） |
| [`install-config.sh`](./install-config.sh) | 别名 → URL / Key → Search → skill → 备份写入 |

<details>
<summary><strong>向导内部步骤</strong></summary>

<br/>

| 步骤 | 行为 |
|------|------|
| 检查模板 | 同目录需有 `config.toml` |
| 检查目录 | 无 `~/.grok` 时可询问创建 |
| 脱敏预览 | `api_key`、`base_url` 等显示为 `***REDACTED***` |
| 模型别名 | 同步 `default` 与 `[model.名称]` |
| 强制自定义 | **必须**填写 `base_url` 与 `api_key` |
| Search Tool | 可选；写入 `web_search` + Responses 后端字段 |
| 备份 / 写入 | 覆盖前备份；权限尽量 `600` |
| grok-search | 可选；clone skill + 写 `~/.config/grok-search/config.json` |

</details>

<details>
<summary><strong>分步安装（不用一键脚本时）</strong></summary>

<br/>

**1. 安装 Grok Build CLI**

```bash
curl -fsSL https://x.ai/cli/install.sh | bash
grok --version

# 指定版本 / 升级
curl -fsSL https://x.ai/cli/install.sh | bash -s 0.1.42
grok update
```

**2. 获取本仓库**

```bash
# A. Git
git clone https://github.com/zxfccmm4/GrokBuild.git && cd GrokBuild

# B. 只下两个文件
mkdir -p GrokBuild && cd GrokBuild
curl -fsSL -o config.toml https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/config.toml
curl -fsSL -o install-config.sh https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/install-config.sh
chmod +x install-config.sh

# C. ZIP
curl -fsSL -o GrokBuild.zip https://github.com/zxfccmm4/GrokBuild/archive/refs/heads/main.zip
unzip GrokBuild.zip && cd GrokBuild-main
```

**3. 运行向导**

```bash
./install-config.sh
```

**4. 手动安装（不推荐）**

```bash
mkdir -p ~/.grok
cp config.toml ~/.grok/config.toml
$EDITOR ~/.grok/config.toml
chmod 600 ~/.grok/config.toml
```

**5. 恢复备份**

```bash
ls ~/.grok/config.toml.bak.*
cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml
```

</details>

---

<a id="config"></a>

## 配置说明

Grok 读取：

```text
~/.grok/config.toml
```

模板默认：自定义模型别名 · 关闭遥测 · 限制代码库上传 · 偏宽松权限。  
`base_url` / `api_key` 正确即可走兼容接口。

<details open>
<summary><strong>结构示例（脱敏）</strong></summary>

<br/>

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
# api_backend = "responses"           # Search Tool 开启时写入
# supports_backend_search = true      # Search Tool 开启时写入

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

</details>

### 字段速查

**`[models]`**

| 键 | 示例 | 说明 |
|----|------|------|
| `default` | `"Steve"` | **本地配置名**，须与某个 `[model.名称]` 一致 |
| `default_reasoning_effort` | `"high"` | `low` / `medium` / `high` |
| `web_search` | `"Steve"` | 可选；Build 内置 `web_search` 用的模型别名 |

`default` 是本地昵称，**不是** API 模型 ID。安装脚本会同步改写 `default` 与 `[model.名称]`。

**`[model.名称]`**

| 键 | 必填 | 说明 |
|----|:----:|------|
| `model` | | 上游模型 ID，如 `grok-4.5` |
| `base_url` | **是** | OpenAI 兼容根地址，如 `https://api.example.com/v1` |
| `api_key` | **是** | 访问密钥，切勿泄露 |
| `name` | | 展示名 |
| `context_window` | | 上下文上限（模板 `500000`） |
| `supports_reasoning_effort` | | 是否支持推理强度 |
| `reasoning_efforts` | | 可选强度列表 |
| `api_backend` | | Search 开启时为 `"responses"` |
| `supports_backend_search` | | Search 开启时为 `true` |

| 规则 | 要求 |
|------|------|
| 别名 | 字母开头，后接字母 / 数字 / `_` / `-`（`Steve` · `MyProxy` · `work-grok`） |
| `base_url` | `http(s)://` · 通常含 `/v1` · 无空格 |
| `api_key` | 完整密钥 · 勿写进 README / Issue / 截图 |

<details>
<summary><strong>其他段（模板默认）</strong></summary>

<br/>

| 段 | 要点 |
|----|------|
| `[cli]` | `installer = "internal"`，一般保持 |
| `[features]` / `[telemetry]` | 默认关闭遥测与 trace 上传 |
| `[harness]` | `disable_codebase_upload = true` |
| `[ui]` | 宽度、次要模型、`permission_mode` 等 |

| `[ui]` 键 | 模板值 | 说明 |
|-----------|--------|------|
| `max_thoughts_width` | `120` | 思考区最大宽度 |
| `fork_secondary_model` | `"grok-build"` | 分叉等场景次要模型 |
| `yolo` | `false` | 极度宽松自动执行（更稳妥为关） |
| `compact_mode` | `false` | 紧凑 UI |
| `permission_mode` | `"always-approve"` | 工具调用少打断；共享机器请改严 |

> `always-approve` 会让代理改文件 / 跑命令更「大胆」。不信任工作区时请改用更保守策略（见 `~/.grok/docs`）。

</details>

---

## 常见自定义

<table>
<tr>
<td width="50%" valign="top">

**只改地址和密钥**

```bash
./install-config.sh
# 或
$EDITOR ~/.grok/config.toml
```

```toml
base_url = "https://你的网关/v1"
api_key = "你的密钥"
```

</td>
<td width="50%" valign="top">

**更省 / 更快的推理**

```toml
[models]
default_reasoning_effort = "medium"  # 或 "low"
```

**更谨慎的权限**

将 `[ui].permission_mode` 改为当前 Grok 版本支持的更严格选项（见 `~/.grok/docs`）。

</td>
</tr>
</table>

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

---

<a id="search"></a>

## 联网能力

两条路径，可并存，职责不同。同一问题不要既 `web_search` 又跑 `search.js`。

| | 原生 Search Tool | grok-search skill |
|--|:----------------:|:-----------------:|
| **配置** | `~/.grok/config.toml` | `~/.config/grok-search/config.json` |
| **调用** | 后端 `web_search` / `x_search` | `node scripts/*.js` |
| **依赖** | 网关支持 Responses 搜索 | Node ≥ 18.17 + `npm install` |
| **适合** | 网关已开原生联网 | 中转无原生搜索，或需要 fetch / map |
| **向导默认** | 关闭 `[y/N]` | 未开原生时推荐 `[Y/n]` |

```text
会话
 ├── 原生 Search Tool ──► 网关 Responses / web_search / x_search
 │                        └── ~/.grok/config.toml
 │
 └── grok-search skill ──► node scripts/{search,fetch,map}.js
                           └── ~/.config/grok-search/config.json
```

### 原生 Search Tool

向导问 **「是否开启 Search Tool?」**。选 **y** 时写入：

```toml
[models]
default = "Steve"
web_search = "Steve"

[model.Steve]
api_backend = "responses"
supports_backend_search = true
```

| 场景 | 建议 |
|------|------|
| 网关已支持原生搜索（如 grok2api Build 渠道） | 向导里 **开启** |
| 普通 OpenAI 兼容转发、不支持 Responses | **关闭**（默认），改用 skill |

<details>
<summary><strong>手动开关 · 试用提示</strong></summary>

<br/>

```toml
# 开启：补上这三行（别名与 default 一致）
[models]
web_search = "Steve"

[model.Steve]
api_backend = "responses"
supports_backend_search = true

# 关闭：删除或注释掉上述三行
```

改完后 **重启 grok** 或 **新开 session**。

```text
请 web_search：最新 xAI 公开新闻，并给来源
用 x_search 查最近关于 Grok 的讨论
```

> `x_search` 无独立客户端工具，依赖服务端原生注入；需网关与 `supports_backend_search` 均支持。

</details>

### grok-search skill

[Autsunset/grok-search](https://github.com/Autsunset/grok-search) — 独立 Skill + Node 脚本。

| 脚本 | 能力 |
|------|------|
| `search.js` | Chat / Responses 联网；可并行 Tavily / Firecrawl |
| `fetch.js` | 抓取 URL 可读正文 |
| `map.js` | 发现站点内候选页面 |

**向导在写入 `config.toml` 之后：**

1. 是否安装 skill（`SKIP_GROK_SEARCH=1` 可跳过）
2. 检查 `git` / Node ≥ 18.17 / `npm`
3. `git clone` 或 `git pull` → `~/.grok/skills/grok-search`
4. `npm install`（缺 `undici` 时）
5. 选协议：`chat`（中转）或 `responses`（CPA / xAI 风格）
6. 搜索模型 ID（默认 `grok-4.3-fast` 或 `grok-4.5`）
7. 复用本次 `base_url` / `api_key` 写 `config.json`
8. 可选连通性测试：`search.js --no-extra`

<details>
<summary><strong>字段对照 · 手动安装 · 试用</strong></summary>

<br/>

| GrokBuild | grok-search `config.json` |
|-----------|---------------------------|
| `base_url` | `apiUrl`（base，勿带 `/chat/completions`） |
| `api_key` | `apiKey` |
| Search Tool 开启 ≈ responses | `searchEndpoint`: `responses` |
| 常见中转快模型联网 | `searchEndpoint`: `chat` |
| `[model.*].model` | 独立字段 `model`（可与主对话不同） |

```bash
./install-config.sh                          # 含 skill 步骤
SKIP_GROK_SEARCH=1 ./install-config.sh       # 跳过 skill

# 完全手动
git clone https://github.com/Autsunset/grok-search.git ~/.grok/skills/grok-search
cd ~/.grok/skills/grok-search && npm install
mkdir -p ~/.config/grok-search
# 编辑 ~/.config/grok-search/config.json（见上游 README）
chmod 600 ~/.config/grok-search/config.json
```

```bash
node ~/.grok/skills/grok-search/scripts/search.js --no-extra "随便搜个新闻"
node ~/.grok/skills/grok-search/scripts/fetch.js https://example.com
node ~/.grok/skills/grok-search/scripts/map.js https://example.com --limit 5
```

Skill 装在 `~/.grok/skills/`，Grok 会自动发现。

</details>

---

<a id="troubleshoot"></a>

## 故障排查

| 现象 | 处理 |
|------|------|
| 找不到 `config.toml` | `cd` 到仓库根再执行 `./install-config.sh` |
| 模型别名格式无效 | 用最新向导；合法例：`Steve`、`MyProxy`、`work-grok` |
| `base_url` 无效 | 使用 `https://host/v1`，勿含空格 |
| 连不上模型 | 查 `base_url`、`api_key`、服务商控制台 |
| Search 报错 / 无搜索 | 关掉 Search Tool，换支持网关，或改用 **grok-search** |
| 对话里不联网 | 新开 session；检查 `web_search` / skill 是否装好 |
| grok-search 安装失败 | 装 Node ≥ 18.17 与 git；`cd ~/.grok/skills/grok-search && npm install` |
| `search.js` 401 / 404 / 422 | 核对 `searchEndpoint` 与 `model`（chat 用快模型，responses 常用 `grok-4.5`） |
| 行为与预期不符 | 确认 `~/.grok/config.toml`，重启 `grok` |
| 想撤销 | `cp ~/.grok/config.toml.bak.<时间戳> ~/.grok/config.toml` |

Grok 本体文档：

```text
~/.grok/README.md
~/.grok/docs/user-guide/
```

---

<a id="security"></a>

## 安全建议

| 做 | 不做 |
|:---|:-----|
| 安装时重新填写密钥 | 把含真实 `api_key` 的配置提交到 Git |
| `config.toml` 与 grok-search `config.json` 权限 `600` | 在聊天 / Issue / 截图里贴完整密钥 |
| 分享仓库前确认模板无可用密钥 | 把密钥写进 README 示例 |

---

## 许可证与免责

- 本仓库提供 **配置模板与安装辅助脚本**，不包含 Grok CLI 本体
- `api_key`、网关地址由使用者自行申请与保管；密钥泄露或错误配置导致的损失自行承担
- 隐私与权限默认值可按个人 / 企业合规要求再调整
- grok-search 为第三方 MIT 项目（[Autsunset/grok-search](https://github.com/Autsunset/grok-search)），与本仓库独立维护

---

<p align="center">
  <sub>
    <a href="https://github.com/zxfccmm4/GrokBuild">GitHub</a>
    ·
    <a href="https://x.ai">x.ai</a>
    ·
    <a href="https://github.com/Autsunset/grok-search">grok-search</a>
    ·
    <a href="#quick-start">一键安装</a>
  </sub>
</p>
