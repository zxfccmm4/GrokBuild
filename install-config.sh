#!/usr/bin/env bash
# install-config.sh — 交互式将 GrokBuild 配置安装到 ~/.grok/config.toml
# base_url 与 api_key 必须由用户自定义；预览时自动隐去。

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

info()  { printf '%s\n' "${CYAN}ℹ${RESET}  $*"; }
ok()    { printf '%s\n' "${GREEN}✓${RESET}  $*"; }
warn()  { printf '%s\n' "${YELLOW}!${RESET}  $*"; }
err()   { printf '%s\n' "${RED}✗${RESET}  $*" >&2; }
ask()   { printf '%s' "${BOLD}?${RESET}  $*"; }

# ---------- 路径 ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="${SCRIPT_DIR}/config.toml"
TARGET_DIR="${HOME}/.grok"
TARGET_CONFIG="${TARGET_DIR}/config.toml"

# 预览时需隐去的键（含 base_url / api_key 等）
REDACT_KEYS_RE='^(api[_-]?key|base[_-]?url|secret|token|password|passwd|authorization|auth[_-]?token|access[_-]?key)$'

# ---------- 工具函数 ----------
redact_config() {
  # 将敏感/自定义键的值替换为 ***REDACTED***
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

confirm() {
  local prompt="${1:-继续?}"
  local reply
  ask "${prompt} ${DIM}[y/N]${RESET} "
  read -r reply || true
  case "${reply:-}" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

read_line() {
  # 普通输入（可回显）
  local prompt="$1"
  local value=""
  ask "${prompt}"
  read -r value || true
  # 去掉首尾空白
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

read_secret() {
  # 敏感输入（尽量不回显）
  local prompt="$1"
  local value=""
  ask "${prompt}"
  if [[ -t 0 ]]; then
    # shellcheck disable=SC2162
    read -r -s value || true
    printf '\n'
  else
    read -r value || true
  fi
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
  # $1=提示 $2=模式: plain|secret
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

validate_base_url() {
  local url="$1"
  # 简单校验：http(s):// 开头
  if [[ "$url" =~ ^https?://[^[:space:]]+$ ]]; then
    return 0
  fi
  return 1
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
  # 转义写入 TOML 双引号字符串时的 \ 与 "
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

write_config() {
  # 将源配置写入目标，强制替换 base_url 与 api_key
  local src="$1"
  local dest="$2"
  local new_url="$3"
  local new_key="$4"

  local esc_url esc_key
  esc_url="$(escape_toml_string "$new_url")"
  esc_key="$(escape_toml_string "$new_key")"

  awk -v new_url="$esc_url" -v new_key="$esc_key" '
    BEGIN { IGNORECASE = 1 }
    {
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
  ' "$src" > "$dest"
}

# ---------- 主流程 ----------
main() {
  printf '\n'
  printf '%s\n' "${BOLD}Grok Build 配置安装向导${RESET}"
  printf '%s\n' "${DIM}将模板配置安装到 ~/.grok/config.toml${RESET}"
  printf '%s\n' "${DIM}base_url 与 api_key 必须由你自定义填写${RESET}"
  printf '\n'

  # 1. 检查源文件
  if [[ ! -f "$SOURCE_CONFIG" ]]; then
    err "找不到源配置: ${SOURCE_CONFIG}"
    err "请把本脚本与 config.toml 放在同一目录后重试。"
    exit 1
  fi
  ok "模板配置: ${DIM}${SOURCE_CONFIG}${RESET}"

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

  # 3. 展示脱敏预览（base_url / api_key 均隐去）
  printf '\n'
  info "模板预览（base_url / api_key 等已隐去，安装时需你填写）:"
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

  # 5. 强制自定义 base_url
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

  # 6. 强制自定义 api_key
  info "请填写你的 API Key（输入时不回显）"
  local custom_key=""
  custom_key="$(require_nonempty "api_key: " secret)"
  ok "api_key（脱敏）: ${DIM}$(mask_secret "$custom_key")${RESET}"
  printf '\n'

  # 可选：再确认一次 api_key
  if confirm "是否再次输入 api_key 以核对?"; then
    local custom_key2
    custom_key2="$(require_nonempty "再次输入 api_key: " secret)"
    if [[ "$custom_key" != "$custom_key2" ]]; then
      err "两次输入的 api_key 不一致，已取消。"
      exit 1
    fi
    ok "两次输入一致。"
    printf '\n'
  fi

  # 7. 最终确认
  info "即将写入:"
  printf '  模板:   %s\n' "${DIM}${SOURCE_CONFIG}${RESET}"
  printf '  目标:   %s\n' "${DIM}${TARGET_CONFIG}${RESET}"
  printf '  base_url: %s\n' "${DIM}${custom_url}${RESET}"
  printf '  api_key:  %s\n' "${DIM}$(mask_secret "$custom_key")${RESET}"
  printf '\n'

  if ! confirm "确认安装并覆盖目标配置?"; then
    warn "已取消，未做任何修改。"
    exit 0
  fi

  # 8. 备份 + 写入
  printf '\n'
  backup_if_exists "$TARGET_CONFIG"

  local tmp
  tmp="$(mktemp "${TARGET_DIR}/.config.toml.XXXXXX")"
  chmod 600 "$tmp" 2>/dev/null || true

  write_config "$SOURCE_CONFIG" "$tmp" "$custom_url" "$custom_key"
  mv -f "$tmp" "$TARGET_CONFIG"
  chmod 600 "$TARGET_CONFIG" 2>/dev/null || true

  ok "配置已安装 → ${BOLD}${TARGET_CONFIG}${RESET}"

  # 9. 安装后脱敏展示
  printf '\n'
  info "安装后内容预览（敏感字段已隐去）:"
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  redact_config "$TARGET_CONFIG" | sed 's/^/  /'
  printf '%s\n' "${DIM}────────────────────────────────────────${RESET}"
  printf '\n'
  ok "完成。可运行 grok 验证配置是否生效。"
  printf '\n'
}

main "$@"
