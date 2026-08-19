#!/usr/bin/env bash
# install-config.sh — 交互式将 GrokBuild 配置安装到 ~/.grok/config.toml
# 可自定义：模型别名、base_url、api_key、是否开启 Search Tool（web_search / x_search）
# 可选：安装 grok-search skill（search / fetch / map）
# 预览时隐去敏感字段。
#
# 可选环境变量：
#   SKIP_GROK_SEARCH=1          跳过 grok-search skill 安装步骤
#   GROK_SEARCH_REPO            git 仓库 URL（默认 Autsunset/grok-search）
#   GROK_SEARCH_DIR             skill 安装目录（默认 ~/.grok/skills/grok-search）

set -euo pipefail

# ---------- 颜色与样式 ----------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  CYAN=$'\033[36m'
  RESET=$'\033[0m'
else
  BOLD= DIM= RED= GREEN= YELLOW= CYAN= RESET=
fi

# 交互提示一律走 stderr，避免被 $(...) 捕获污染返回值
info()  { printf '%s\n' "${CYAN}ℹ${RESET}  $*" >&2; }
ok()    { printf '%s\n' "${GREEN}✓${RESET}  $*" >&2; }
warn()  { printf '%s\n' "${YELLOW}!${RESET}  $*" >&2; }
err()   { printf '%s\n' "${RED}✗${RESET}  $*" >&2; }
ask()   { printf '%s' "${BOLD}?${RESET}  $*" >&2; }

# ---------- 路径 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="${SCRIPT_DIR}/config.toml"
TARGET_DIR="${HOME}/.grok"
TARGET_CONFIG="${TARGET_DIR}/config.toml"

# grok-search skill
SKIP_GROK_SEARCH="${SKIP_GROK_SEARCH:-0}"
GROK_SEARCH_REPO="${GROK_SEARCH_REPO:-https://github.com/Autsunset/grok-search.git}"
GROK_SEARCH_DIR="${GROK_SEARCH_DIR:-${HOME}/.grok/skills/grok-search}"
GROK_SEARCH_CONFIG_DIR="${HOME}/.config/grok-search"
GROK_SEARCH_CONFIG="${GROK_SEARCH_CONFIG_DIR}/config.json"
GROK_SEARCH_MIN_NODE_MAJOR=18
GROK_SEARCH_MIN_NODE_MINOR=17

# 预览时需隐去的键
REDACT_KEYS_RE='^(api[_-]?key|base[_-]?url|secret|token|password|passwd|authorization|auth[_-]?token|access[_-]?key)$'

# ---------- 工具函数 ----------
redact_config() {
  awk -v re="$REDACT_KEYS_RE" '
    BEGIN { IGNORECASE = 1 }
    {
      line = $0
      if (match(line, /^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*/)) {
        key = substr(line, RSTART, RLENGTH)
        gsub(/^[[:space:]]+|[[:space:]]*=[[:space:]]*$/, "", key)
        if (key ~ re) {
          indent = line
          sub(/[^[:space:]].*$/, "", indent)
          printf "%s%s = \"***REDACTED***\"\n", indent, key
          next
        }
      }
      print line
    }
  ' "$1"
}

# curl | bash 时 stdin 是脚本管道，交互输入改从终端读
read_from_tty() {
  # usage: read_from_tty [-s] varname
  local secret=0
  if [[ "${1:-}" == "-s" ]]; then
    secret=1
    shift
  fi
  local __var="$1"
  local __val=""
  if [[ -r /dev/tty ]]; then
    if [[ "$secret" -eq 1 ]]; then
      # shellcheck disable=SC2162
      read -r -s __val < /dev/tty || true
      printf '\n' >&2
    else
      read -r __val < /dev/tty || true
    fi
  else
    if [[ "$secret" -eq 1 ]]; then
      # shellcheck disable=SC2162
      read -r -s __val || true
      printf '\n' >&2
    else
      read -r __val || true
    fi
  fi
  printf -v "$__var" '%s' "$__val"
}

confirm() {
  local prompt="${1:-继续?}"
  local reply
  ask "${prompt} ${DIM}[y/N]${RESET} "
  read_from_tty reply
  case "${reply:-}" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# 默认 yes 的确认（用于推荐开启的选项）
confirm_default_yes() {
  local prompt="${1:-继续?}"
  local reply
  ask "${prompt} ${DIM}[Y/n]${RESET} "
  read_from_tty reply
  case "${reply:-}" in
    ""|[yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

read_line() {
  local prompt="$1"
  local value=""
  ask "${prompt}"
  read_from_tty value
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

read_secret() {
  local prompt="$1"
  local value=""
  ask "${prompt}"
  read_from_tty -s value
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

mask_secret() {
  local s="$1"
  if [[ -z "$s" ]]; then
    printf '%s' "(空)"
  elif [[ ${#s} -le 4 ]]; then
    printf '%s' "****"
  else
    printf '%s****%s' "${s:0:2}" "${s: -2}"
  fi
}

require_nonempty() {
  local prompt="$1"
  local mode="${2:-plain}"
  local value=""
  while true; do
    if [[ "$mode" == "secret" ]]; then
      value="$(read_secret "$prompt")"
    else
      value="$(read_line "$prompt")"
    fi
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
    warn "不能为空，请重新输入。"
  done
}

# 读取带默认值的输入：回车则用 default
read_with_default() {
  local prompt="$1"
  local default="$2"
  local value
  value="$(read_line "${prompt}${DIM}[默认: ${default}]${RESET} ")"
  if [[ -z "$value" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

validate_base_url() {
  local url="$1"
  if [[ "$url" =~ ^https?://[^[:space:]]+$ ]]; then
    return 0
  fi
  return 1
}

# 模型别名：用作 [model.Name] 与 default = "Name"
# 允许字母开头，后接字母/数字/_/-
validate_model_alias() {
  local name="$1"
  if [[ "$name" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
    return 0
  fi
  return 1
}

# 从模板解析当前 [model.XXX] 段名（取第一个）
detect_template_model_alias() {
  local src="$1"
  local name
  name="$(awk '
    match($0, /^\[model\.([A-Za-z0-9_-]+)\]/, a) { print a[1]; exit }
    # 兼容无第三参数的 awk：用 sub
  ' "$src" 2>/dev/null || true)"
  if [[ -z "${name:-}" ]]; then
    name="$(sed -n 's/^\[model\.\([A-Za-z0-9_-]*\)\]/\1/p' "$src" | head -n1)"
  fi
  if [[ -z "${name:-}" ]]; then
    name="Steve"
  fi
  printf '%s' "$name"
}

backup_if_exists() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local ts
    ts="$(date +%Y%m%d-%H%M%S)"
    local backup="${target}.bak.${ts}"
    cp -p "$target" "$backup"
    ok "已备份现有配置 → ${DIM}${backup}${RESET}"
  fi
}

escape_toml_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# 写入配置：别名 / base_url / api_key / 可选 Search Tool
# enable_search: "1" 开启，"0" 关闭
write_config() {
  local src="$1"
  local dest="$2"
  local old_alias="$3"
  local new_alias="$4"
  local new_url="$5"
  local new_key="$6"
  local enable_search="${7:-0}"

  local esc_url esc_key esc_alias
  esc_url="$(escape_toml_string "$new_url")"
  esc_key="$(escape_toml_string "$new_key")"
  esc_alias="$(escape_toml_string "$new_alias")"

  # BSD awk 兼容：避免函数内多行布尔表达式
  awk -v old_alias="$old_alias" \
      -v new_alias="$esc_alias" \
      -v new_url="$esc_url" \
      -v new_key="$esc_key" \
      -v enable_search="$enable_search" '
    BEGIN {
      IGNORECASE = 0
      in_models = 0
      in_model = 0
      wrote_web_search = 0
      wrote_backend = 0
    }

    function flush_web_search() {
      if (enable_search == "1" && in_models && !wrote_web_search) {
        printf "web_search = \"%s\"\n", new_alias
        print ""
        wrote_web_search = 1
      }
    }

    function flush_backend() {
      if (enable_search == "1" && in_model && !wrote_backend) {
        print "api_backend = \"responses\""
        print "supports_backend_search = true"
        print ""
        wrote_backend = 1
      }
    }

    function is_search_comment(line,   t) {
      if (line !~ /^[[:space:]]*#/) return 0
      t = line
      if (t ~ /web_search/) return 1
      if (t ~ /api_backend/) return 1
      if (t ~ /supports_backend_search/) return 1
      if (t ~ /Optional: point Build/) return 1
      if (t ~ /Optional: native web_search/) return 1
      if (t ~ /Enable via install-config/) return 1
      return 0
    }

    {
      # 进入新 section 前，冲刷未写完的字段
      if ($0 ~ /^\[/) {
        flush_web_search()
        flush_backend()
        in_models = 0
        in_model = 0
      }

      # [model.OldAlias] -> [model.NewAlias]
      if ($0 ~ ("^\\[model\\." old_alias "\\][[:space:]]*$")) {
        printf "[model.%s]\n", new_alias
        in_model = 1
        in_models = 0
        wrote_backend = 0
        next
      }

      if ($0 ~ /^\[models\][[:space:]]*$/) {
        in_models = 1
        in_model = 0
        print
        next
      }

      if ($0 ~ /^\[model\./) {
        in_model = 1
        in_models = 0
        wrote_backend = 0
        print
        next
      }

      # 开启 Search 时：跳过模板相关注释；段末空白留给 flush_web_search 统一排版
      if (enable_search == "1" && is_search_comment($0)) {
        next
      }
      # 段内空白在 flush_* 时统一补，避免注释删掉后叠空行
      if (enable_search == "1" && (in_models || in_model) && $0 ~ /^[[:space:]]*$/) {
        next
      }

      # 关闭 Search 时：去掉可能已存在的生效项（从旧配置当模板时）
      if (enable_search != "1") {
        if (match($0, /^[[:space:]]*web_search[[:space:]]*=/)) next
        if (match($0, /^[[:space:]]*api_backend[[:space:]]*=/)) next
        if (match($0, /^[[:space:]]*supports_backend_search[[:space:]]*=/)) next
      }

      # default = "OldAlias"
      if (match($0, /^[[:space:]]*default[[:space:]]*=[[:space:]]*/)) {
        rest = substr($0, RSTART + RLENGTH)
        val = rest
        gsub(/^["'\'']|["'\''][[:space:]]*$/, "", val)
        if (val == old_alias) {
          indent = $0
          sub(/[^[:space:]].*$/, "", indent)
          printf "%sdefault = \"%s\"\n", indent, new_alias
          next
        }
      }

      # 已有 web_search 行：开启时改写为新别名
      if (match($0, /^[[:space:]]*web_search[[:space:]]*=/)) {
        if (enable_search == "1") {
          indent = $0
          sub(/[^[:space:]].*$/, "", indent)
          printf "%sweb_search = \"%s\"\n", indent, new_alias
          wrote_web_search = 1
          next
        }
      }

      # 已有 api_backend / supports_backend_search：开启时规范化
      if (match($0, /^[[:space:]]*api_backend[[:space:]]*=/)) {
        if (enable_search == "1") {
          print "api_backend = \"responses\""
          wrote_backend = 1
          next
        }
      }
      if (match($0, /^[[:space:]]*supports_backend_search[[:space:]]*=/)) {
        if (enable_search == "1") {
          print "supports_backend_search = true"
          wrote_backend = 1
          next
        }
      }

      if (match($0, /^[[:space:]]*base[_-]?url[[:space:]]*=[[:space:]]*/)) {
        indent = $0
        sub(/[^[:space:]].*$/, "", indent)
        printf "%sbase_url = \"%s\"\n", indent, new_url
        next
      }
      if (match($0, /^[[:space:]]*api[_-]?key[[:space:]]*=[[:space:]]*/)) {
        indent = $0
        sub(/[^[:space:]].*$/, "", indent)
        printf "%sapi_key = \"%s\"\n", indent, new_key
        next
      }
      print
    }

    END {
      flush_web_search()
      flush_backend()
    }
  ' "$src" > "$dest"
}

# ---------- grok-search skill ----------
# 解析 node 主.次版本；失败返回非 0
node_version_ok() {
  command -v node >/dev/null 2>&1 || return 1
  local ver major minor
  ver="$(node -v 2>/dev/null | sed 's/^v//')"
  major="${ver%%.*}"
  minor="${ver#*.}"
  minor="${minor%%.*}"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
  if (( major > GROK_SEARCH_MIN_NODE_MAJOR )); then
    return 0
  fi
  if (( major == GROK_SEARCH_MIN_NODE_MAJOR && minor >= GROK_SEARCH_MIN_NODE_MINOR )); then
    return 0
  fi
  return 1
}

# 粗略推断 apiProvider：openrouter / xai / openai-compatible
infer_api_provider() {
  local url
  url="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  if [[ "$url" == *openrouter* ]]; then
    printf '%s' "openrouter"
  elif [[ "$url" == *api.x.ai* ]]; then
    printf '%s' "xai"
  else
    printf '%s' "openai-compatible"
  fi
}

# JSON 字符串转义
escape_json_string() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

mask_key_short() {
  local s="$1"
  if [[ -z "$s" ]]; then
    printf '%s' "(空)"
  elif [[ ${#s} -le 8 ]]; then
    printf '%s' "****"
  else
    printf '%s****%s' "${s:0:4}" "${s: -4}"
  fi
}

# 写入 ~/.config/grok-search/config.json
write_grok_search_config() {
  local api_url="$1"
  local api_key="$2"
  local search_endpoint="$3"
  local model="$4"
  local api_provider
  api_provider="$(infer_api_provider "$api_url")"

  local esc_url esc_key esc_model esc_provider esc_endpoint
  esc_url="$(escape_json_string "$api_url")"
  esc_key="$(escape_json_string "$api_key")"
  esc_model="$(escape_json_string "$model")"
  esc_provider="$(escape_json_string "$api_provider")"
  esc_endpoint="$(escape_json_string "$search_endpoint")"

  mkdir -p "$GROK_SEARCH_CONFIG_DIR"
  chmod 700 "$GROK_SEARCH_CONFIG_DIR" 2>/dev/null || true

  local tmp
  tmp="$(mktemp "${GROK_SEARCH_CONFIG_DIR}/.config.json.XXXXXX")"
  chmod 600 "$tmp" 2>/dev/null || true

  if [[ "$search_endpoint" == "chat" ]]; then
    cat > "$tmp" <<EOF
{
  "apiUrl": "${esc_url}",
  "apiKey": "${esc_key}",
  "apiProvider": "${esc_provider}",
  "searchEndpoint": "chat",
  "model": "${esc_model}",
  "defaultExtra": 6,
  "sourceChars": 400
}
EOF
  else
    cat > "$tmp" <<EOF
{
  "apiUrl": "${esc_url}",
  "apiKey": "${esc_key}",
  "apiProvider": "${esc_provider}",
  "searchEndpoint": "responses",
  "model": "${esc_model}",
  "responsesMaxTurns": 3,
  "responsesReasoningEffort": "low",
  "defaultExtra": 6,
  "sourceChars": 400
}
EOF
  fi

  mv -f "$tmp" "$GROK_SEARCH_CONFIG"
  chmod 600 "$GROK_SEARCH_CONFIG" 2>/dev/null || true
}

# clone 或更新 skill 仓库，并 npm install
install_grok_search_repo() {
  local dest="$GROK_SEARCH_DIR"
  local parent
  parent="$(dirname "$dest")"
  mkdir -p "$parent"

  if [[ -d "${dest}/.git" ]]; then
    info "已存在 skill 仓库，尝试 git pull …"
    if git -C "$dest" pull --ff-only 2>/dev/null; then
      ok "已更新: ${DIM}${dest}${RESET}"
    else
      warn "git pull 失败，继续使用现有目录: ${DIM}${dest}${RESET}"
    fi
  elif [[ -d "$dest" ]]; then
    if [[ -f "${dest}/SKILL.md" && -f "${dest}/scripts/search.js" ]]; then
      ok "已存在 skill 目录（非 git）: ${DIM}${dest}${RESET}"
    else
      err "目录已存在但不是有效的 grok-search: ${dest}"
      return 1
    fi
  else
    info "克隆 grok-search → ${DIM}${dest}${RESET}"
    if ! git clone --depth 1 "$GROK_SEARCH_REPO" "$dest"; then
      err "git clone 失败: ${GROK_SEARCH_REPO}"
      return 1
    fi
    ok "已克隆 skill"
  fi

  if [[ ! -f "${dest}/SKILL.md" ]]; then
    err "缺少 SKILL.md: ${dest}"
    return 1
  fi
  if [[ ! -f "${dest}/scripts/search.js" ]]; then
    err "缺少 scripts/search.js: ${dest}"
    return 1
  fi

  if [[ ! -d "${dest}/node_modules/undici" ]]; then
    info "安装 npm 依赖（undici）…"
    if ! (cd "$dest" && npm install --no-fund --no-audit); then
      err "npm install 失败。请检查 Node/npm 网络后手动执行:"
      err "  cd ${dest} && npm install"
      return 1
    fi
    ok "npm 依赖已安装"
  else
    ok "npm 依赖已存在，跳过 install"
  fi
  return 0
}

# 连通性测试（可选）；不因失败中止整个向导
test_grok_search() {
  local dest="$GROK_SEARCH_DIR"
  info "连通性测试: node scripts/search.js --no-extra …"
  local out ec=0
  set +e
  out="$(cd "$dest" && node scripts/search.js --no-extra "latest tech news" 2>/dev/null)"
  ec=$?
  set -e

  if [[ "$ec" -ne 0 ]]; then
    warn "搜索测试退出码 ${ec}（配置仍已写入，可稍后排查）"
    if [[ -n "$out" ]]; then
      printf '%s\n' "${DIM}$(printf '%s' "$out" | head -c 400)${RESET}" >&2
    fi
    return 1
  fi
  if printf '%s' "$out" | grep -q '"error"'; then
    warn "搜索返回 error 字段，请检查协议 / 模型 / 密钥"
    printf '%s\n' "${DIM}$(printf '%s' "$out" | head -c 400)${RESET}" >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -q '"text"'; then
    warn "未看到 answer.text，结果可能异常"
    return 1
  fi
  ok "连通性测试通过"
  return 0
}

# 可选：安装并配置 grok-search skill
# 参数: base_url api_key enable_native_search(0|1)
maybe_install_grok_search() {
  local base_url="$1"
  local api_key="$2"
  local enable_native_search="${3:-0}"

  if [[ "$SKIP_GROK_SEARCH" == "1" ]]; then
    info "已设置 SKIP_GROK_SEARCH=1，跳过 grok-search skill。"
    return 0
  fi

  printf '\n'
  info "grok-search skill（可选）"
  printf '  %s\n' "${DIM}独立脚本：search / fetch / map（Node.js）${RESET}"
  printf '  %s\n' "${DIM}安装到: ${GROK_SEARCH_DIR}${RESET}"
  printf '  %s\n' "${DIM}配置到: ${GROK_SEARCH_CONFIG}${RESET}"
  printf '  %s\n' "${DIM}上游: https://github.com/Autsunset/grok-search${RESET}"
  if [[ "$enable_native_search" -eq 1 ]]; then
    printf '  %s\n' "${YELLOW}!${RESET}  ${DIM}已开启原生 Search Tool；skill 仍可用于 fetch/map 与多源搜索${RESET}"
    printf '  %s\n' "${DIM}避免同一问题既 web_search 又跑 search.js（重复联网）${RESET}"
  else
    printf '  %s\n' "${DIM}未开原生 Search 时，推荐安装 skill 作为联网通道${RESET}"
  fi
  printf '\n'

  local want=0
  if [[ "$enable_native_search" -eq 1 ]]; then
    if confirm "是否安装 grok-search skill?"; then
      want=1
    fi
  else
    if confirm_default_yes "是否安装 grok-search skill?（推荐）"; then
      want=1
    fi
  fi

  if [[ "$want" -ne 1 ]]; then
    ok "grok-search: ${DIM}跳过${RESET}"
    info "稍后可手动: git clone ${GROK_SEARCH_REPO} ${GROK_SEARCH_DIR}"
    return 0
  fi

  # 环境检查
  if ! command -v git >/dev/null 2>&1; then
    err "需要 git 才能克隆 skill，已跳过 grok-search。"
    return 0
  fi
  if ! command -v node >/dev/null 2>&1; then
    err "未检测到 Node.js。grok-search 需要 Node >= ${GROK_SEARCH_MIN_NODE_MAJOR}.${GROK_SEARCH_MIN_NODE_MINOR}"
    err "请安装 Node 后手动安装 skill，或重跑本向导。"
    return 0
  fi
  if ! node_version_ok; then
    err "Node 版本过低: $(node -v 2>/dev/null || echo '?')（需要 >= ${GROK_SEARCH_MIN_NODE_MAJOR}.${GROK_SEARCH_MIN_NODE_MINOR}）"
    return 0
  fi
  ok "Node: ${DIM}$(node -v)${RESET}"
  if ! command -v npm >/dev/null 2>&1; then
    err "未检测到 npm，无法安装 undici 依赖。已跳过。"
    return 0
  fi

  if ! install_grok_search_repo; then
    warn "skill 仓库安装失败，已跳过配置写入。"
    return 0
  fi

  # 协议
  printf '\n'
  info "选择搜索协议（searchEndpoint）"
  printf '  %s\n' "${DIM}1) chat      — 推荐 grok2api / NewAPI；模型如 grok-4.3-fast${RESET}"
  printf '  %s\n' "${DIM}2) responses — CPA / 官方 xAI 风格；常见 grok-4.6${RESET}"
  local endpoint_choice default_endpoint default_model
  if [[ "$enable_native_search" -eq 1 ]]; then
    default_endpoint="responses"
    default_model="grok-4.6"
  else
    default_endpoint="chat"
    default_model="grok-4.3-fast"
  fi
  endpoint_choice="$(read_with_default "协议 [chat/responses]: " "$default_endpoint")"
  endpoint_choice="$(printf '%s' "$endpoint_choice" | tr '[:upper:]' '[:lower:]')"
  case "$endpoint_choice" in
    chat|responses) ;;
    *)
      warn "无效协议，改用默认: ${default_endpoint}"
      endpoint_choice="$default_endpoint"
      ;;
  esac
  if [[ "$endpoint_choice" == "chat" ]]; then
    default_model="grok-4.3-fast"
  else
    default_model="grok-4.6"
  fi
  ok "searchEndpoint: ${BOLD}${endpoint_choice}${RESET}"

  # 模型
  local search_model
  search_model="$(read_with_default "搜索模型 ID: " "$default_model")"
  if [[ -z "$search_model" ]]; then
    search_model="$default_model"
  fi
  ok "model: ${DIM}${search_model}${RESET}"

  # 是否复用本次 base_url / api_key
  printf '\n'
  info "将写入 grok-search 配置（可复用本次 GrokBuild 的 base_url / api_key）"
  printf '  apiUrl:  %s\n' "${DIM}${base_url}${RESET}"
  printf '  apiKey:  %s\n' "${DIM}$(mask_key_short "$api_key")${RESET}"
  printf '  协议:    %s\n' "${DIM}${endpoint_choice}${RESET}"
  printf '  模型:    %s\n' "${DIM}${search_model}${RESET}"
  printf '  路径:    %s\n' "${DIM}${GROK_SEARCH_CONFIG}${RESET}"
  printf '\n'

  local use_same=1
  if ! confirm_default_yes "使用上述 base_url / api_key 写入 grok-search?"; then
    use_same=0
  fi

  local gs_url="$base_url" gs_key="$api_key"
  if [[ "$use_same" -ne 1 ]]; then
    while true; do
      gs_url="$(require_nonempty "grok-search apiUrl (base，勿带 /chat/completions): " plain)"
      if validate_base_url "$gs_url"; then
        break
      fi
      warn "格式无效，需以 http:// 或 https:// 开头。"
    done
    gs_key="$(require_nonempty "grok-search apiKey: " plain)"
  fi

  if [[ -f "$GROK_SEARCH_CONFIG" ]]; then
    warn "已有配置: ${GROK_SEARCH_CONFIG}（将被覆盖；未做自动备份）"
    if ! confirm "确认覆盖 grok-search 配置?"; then
      warn "已跳过写入 config.json；skill 代码仍保留在 ${GROK_SEARCH_DIR}"
      return 0
    fi
  fi

  write_grok_search_config "$gs_url" "$gs_key" "$endpoint_choice" "$search_model"
  ok "已写入 ${BOLD}${GROK_SEARCH_CONFIG}${RESET}"
  ok "apiProvider: ${DIM}$(infer_api_provider "$gs_url")${RESET}  key: ${DIM}$(mask_key_short "$gs_key")${RESET}"

  printf '\n'
  if confirm "是否现在测试搜索连通性?（--no-extra，需联网）"; then
    test_grok_search || true
  else
    info "跳过测试。稍后可执行:"
    printf '  %s\n' "${DIM}node \"${GROK_SEARCH_DIR}/scripts/search.js\" --no-extra \"随便搜个新闻\"${RESET}" >&2
  fi

  printf '\n'
  ok "grok-search skill 就绪。"
  info "Grok 会从 ~/.grok/skills/ 自动发现；也可 /grok-search 或让模型在需要联网时调用。"
  info "示例: node \"${GROK_SEARCH_DIR}/scripts/fetch.js\" https://example.com"
  printf '\n'
}

# ---------- 主流程 ----------
main() {
  printf '\n'
  printf '%s\n' "${BOLD}Grok Build 配置安装向导${RESET}"
  printf '%s\n' "${DIM}将模板配置安装到 ~/.grok/config.toml${RESET}"
  printf '%s\n' "${DIM}可自定义：模型别名 / base_url / api_key / Search Tool / grok-search${RESET}"
  printf '\n'

  # 1. 检查源文件
  if [[ ! -f "$SOURCE_CONFIG" ]]; then
    err "找不到源配置: ${SOURCE_CONFIG}"
    err "请把本脚本与 config.toml 放在同一目录后重试。"
    exit 1
  fi
  ok "模板配置: ${DIM}${SOURCE_CONFIG}${RESET}"

  local template_alias
  template_alias="$(detect_template_model_alias "$SOURCE_CONFIG")"
  ok "模板模型别名: ${DIM}${template_alias}${RESET}  →  [model.${template_alias}]"

  # 2. 检查目标目录
  if [[ ! -d "$TARGET_DIR" ]]; then
    warn "目录不存在: ${TARGET_DIR}"
    if confirm "是否创建 ~/.grok 目录?"; then
      mkdir -p "$TARGET_DIR"
      ok "已创建 ${TARGET_DIR}"
    else
      err "已取消。"
      exit 1
    fi
  else
    ok "目标目录: ${DIM}${TARGET_DIR}${RESET}"
  fi

  # 3. 展示脱敏预览
  printf '\n'
  info "模板预览（敏感字段已隐去；安装时需填写自定义项）:"
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  redact_config "$SOURCE_CONFIG" | sed 's/^/  /'
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  printf '\n'

  # 4. 目标已存在时提示
  if [[ -f "$TARGET_CONFIG" ]]; then
    warn "目标已存在: ${TARGET_CONFIG}"
    info "安装前会自动备份为 config.toml.bak.<时间戳>"
  else
    info "目标尚无配置文件，将新建。"
  fi
  printf '\n'

  # 5. 自定义模型别名 default / [model.XXX]
  info "请设置本地模型配置名（对应 [models].default 与 [model.名称]）"
  printf '  %s\n' "${DIM}仅允许字母开头，后接字母/数字/_/- ；回车保留模板名${RESET}"
  printf '  %s\n' "${DIM}示例: Steve / MyProxy / work-grok${RESET}"
  local custom_alias=""
  while true; do
    custom_alias="$(read_with_default "模型别名 (default): " "$template_alias")"
    if validate_model_alias "$custom_alias"; then
      ok "default = \"${custom_alias}\"  →  [model.${custom_alias}]"
      break
    fi
    warn "格式无效。请使用如 MyModel、work_proxy、Grok-Home 这类标识符。"
  done
  printf '\n'

  # 6. 强制自定义 base_url
  info "请填写你的 API 服务地址（base_url）"
  printf '  %s\n' "${DIM}示例: https://api.example.com/v1${RESET}"
  local custom_url=""
  while true; do
    custom_url="$(require_nonempty "base_url: " plain)"
    if validate_base_url "$custom_url"; then
      ok "base_url: ${DIM}${custom_url}${RESET}"
      break
    fi
    warn "格式无效，需以 http:// 或 https:// 开头，且不能含空格。"
  done
  printf '\n'

  # 7. 强制自定义 api_key（明文输入，便于核对）
  info "请填写你的 API Key（输入时可见，请注意周围环境）"
  local custom_key=""
  custom_key="$(require_nonempty "api_key: " plain)"
  ok "api_key: ${DIM}${custom_key}${RESET}"
  printf '\n'

  if confirm "是否再次输入 api_key 以核对?"; then
    local custom_key2
    custom_key2="$(require_nonempty "再次输入 api_key: " plain)"
    if [[ "$custom_key" != "$custom_key2" ]]; then
      err "两次输入的 api_key 不一致，已取消。"
      exit 1
    fi
    ok "两次输入一致。"
    printf '\n'
  fi

  # 8. 可选：Search Tool（web_search / x_search）
  info "Search Tool（可选）"
  printf '  %s\n' "${DIM}开启后写入：${RESET}"
  printf '  %s\n' "${DIM}  [models] web_search = \"<别名>\"${RESET}"
  printf '  %s\n' "${DIM}  [model.*] api_backend = \"responses\"${RESET}"
  printf '  %s\n' "${DIM}  [model.*] supports_backend_search = true${RESET}"
  printf '  %s\n' "${DIM}适用：grok2api 等已支持原生 web_search / x_search 的网关${RESET}"
  printf '  %s\n' "${DIM}关闭则保持模板注释，不启用服务端搜索${RESET}"
  local enable_search=0
  if confirm "是否开启 Search Tool?"; then
    enable_search=1
    ok "Search Tool: ${BOLD}开启${RESET}"
  else
    enable_search=0
    ok "Search Tool: ${DIM}关闭（默认）${RESET}"
  fi
  printf '\n'

  # 9. 最终确认
  info "即将写入:"
  printf '  模板:        %s\n' "${DIM}${SOURCE_CONFIG}${RESET}"
  printf '  目标:        %s\n' "${DIM}${TARGET_CONFIG}${RESET}"
  printf '  default:     %s\n' "${DIM}\"${custom_alias}\"  ([model.${custom_alias}])${RESET}"
  printf '  base_url:    %s\n' "${DIM}${custom_url}${RESET}"
  printf '  api_key:     %s\n' "${DIM}${custom_key}${RESET}"
  if [[ "$enable_search" -eq 1 ]]; then
    printf '  search:      %s\n' "${GREEN}开启${RESET}  ${DIM}(web_search + responses backend)${RESET}"
  else
    printf '  search:      %s\n' "${DIM}关闭${RESET}"
  fi
  printf '\n'

  if ! confirm "确认安装并覆盖目标配置?"; then
    warn "已取消，未做任何修改。"
    exit 0
  fi

  # 10. 备份 + 写入
  printf '\n'
  backup_if_exists "$TARGET_CONFIG"

  local tmp
  tmp="$(mktemp "${TARGET_DIR}/.config.toml.XXXXXX")"
  chmod 600 "$tmp" 2>/dev/null || true

  write_config "$SOURCE_CONFIG" "$tmp" "$template_alias" "$custom_alias" "$custom_url" "$custom_key" "$enable_search"
  mv -f "$tmp" "$TARGET_CONFIG"
  chmod 600 "$TARGET_CONFIG" 2>/dev/null || true

  ok "配置已安装 → ${BOLD}${TARGET_CONFIG}${RESET}"

  # 11. 安装后脱敏展示
  printf '\n'
  info "安装后内容预览（敏感字段已隐去）:"
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  redact_config "$TARGET_CONFIG" | sed 's/^/  /'
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  printf '\n'
  if [[ "$enable_search" -eq 1 ]]; then
    ok "Search Tool 已开启。重启 grok 或新开 session 后生效。"
    info "试用: 请 web_search 最新 xAI 新闻并给来源"
  fi

  # 12. 可选：grok-search skill（在 config.toml 成功写入之后）
  maybe_install_grok_search "$custom_url" "$custom_key" "$enable_search"

  ok "完成。可运行 grok 验证配置是否生效。"
  printf '\n'
}

main "$@"
