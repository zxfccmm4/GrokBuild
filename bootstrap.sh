#!/usr/bin/env bash
# bootstrap.sh — 一键：安装 Grok Build → 下载本仓库配置脚本 → 交互写入 ~/.grok/config.toml
#
# 用法（推荐）：
#   curl -fsSL https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main/bootstrap.sh | bash
#
# 可选环境变量：
#   GROKBUILD_REPO_RAW  raw 根地址（默认 GitHub main）
#   GROKBUILD_WORKDIR   下载脚本的工作目录（默认临时目录，结束后清理）
#   SKIP_GROK_CLI=1     跳过 Grok CLI 安装（已装好时）
#   SKIP_CONFIG=1       只装 CLI，不跑配置向导

set -euo pipefail

REPO_RAW="${GROKBUILD_REPO_RAW:-https://raw.githubusercontent.com/zxfccmm4/GrokBuild/main}"
GROK_CLI_INSTALL_URL="${GROK_CLI_INSTALL_URL:-https://x.ai/cli/install.sh}"
SKIP_GROK_CLI="${SKIP_GROK_CLI:-0}"
SKIP_CONFIG="${SKIP_CONFIG:-0}"

# ---------- 颜色 ----------
if [[ -t 1 ]] || [[ -t 2 ]]; then
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

info()  { printf '%s\n' "${CYAN}ℹ${RESET}  $*" >&2; }
ok()    { printf '%s\n' "${GREEN}✓${RESET}  $*" >&2; }
warn()  { printf '%s\n' "${YELLOW}!${RESET}  $*" >&2; }
err()   { printf '%s\n' "${RED}✗${RESET}  $*" >&2; }

die() {
  err "$*"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "需要命令: $1"
}

# curl | bash 时 stdin 是管道，确认从终端读
confirm() {
  local prompt="${1:-继续?}"
  local reply=""
  printf '%s' "${BOLD}?${RESET}  ${prompt} ${DIM}[y/N]${RESET} " >&2
  if [[ -r /dev/tty ]]; then
    read -r reply < /dev/tty || true
  else
    read -r reply || true
  fi
  case "${reply:-}" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_path() {
  # 官方安装器默认装到 ~/.grok/bin
  local grok_bin="${HOME}/.grok/bin"
  if [[ -d "$grok_bin" ]]; then
    case ":${PATH}:" in
      *":${grok_bin}:"*) ;;
      *) export PATH="${grok_bin}:${PATH}" ;;
    esac
  fi
}

install_grok_cli() {
  if [[ "$SKIP_GROK_CLI" == "1" ]]; then
    info "已设置 SKIP_GROK_CLI=1，跳过 Grok CLI 安装。"
    return 0
  fi

  ensure_path
  if command -v grok >/dev/null 2>&1; then
    ok "已检测到 Grok CLI: ${DIM}$(command -v grok)${RESET}"
    if grok --version >/dev/null 2>&1; then
      info "版本: ${DIM}$(grok --version 2>/dev/null | head -n1)${RESET}"
    fi
    return 0
  fi

  info "未检测到 grok，开始安装 Grok Build（官方安装器）…"
  need_cmd curl
  # 官方脚本同样需要交互/终端时尽量从 /dev/tty；此处按官方推荐管道安装
  curl -fsSL "$GROK_CLI_INSTALL_URL" | bash

  ensure_path
  if ! command -v grok >/dev/null 2>&1; then
    warn "安装完成但当前 shell 仍找不到 grok。"
    warn "请确认 PATH 包含: ${HOME}/.grok/bin"
    warn "可执行:  export PATH=\"\${HOME}/.grok/bin:\$PATH\""
    if [[ -x "${HOME}/.grok/bin/grok" ]]; then
      export PATH="${HOME}/.grok/bin:${PATH}"
      ok "已在本会话加入 PATH。"
    else
      die "未找到 ${HOME}/.grok/bin/grok，请手动检查官方安装输出。"
    fi
  fi
  ok "Grok CLI 可用: ${DIM}$(command -v grok)${RESET}"
}

# 下载到 WORKDIR；由 main 负责创建目录与 EXIT 清理（避免 $(fn) 子 shell 提前删目录）
download_assets() {
  need_cmd curl
  local workdir="${1:?workdir required}"

  info "下载配置模板与安装脚本 → ${DIM}${workdir}${RESET}"
  curl -fsSL -o "${workdir}/config.toml" \
    "${REPO_RAW}/config.toml"
  curl -fsSL -o "${workdir}/install-config.sh" \
    "${REPO_RAW}/install-config.sh"
  chmod +x "${workdir}/install-config.sh"

  if [[ ! -s "${workdir}/config.toml" ]]; then
    die "下载的 config.toml 为空，请检查网络或 REPO 地址。"
  fi
  if ! head -n1 "${workdir}/install-config.sh" | grep -q bash; then
    die "install-config.sh 看起来不是 shell 脚本，下载可能失败。"
  fi
  ok "资源已就绪。"
}

run_config_wizard() {
  if [[ "$SKIP_CONFIG" == "1" ]]; then
    info "已设置 SKIP_CONFIG=1，跳过配置向导。"
    return 0
  fi

  local workdir="$1"
  info "启动交互式配置安装…"
  printf '\n' >&2
  # 交互从 /dev/tty 读（install-config.sh 已处理 curl|bash 场景）
  bash "${workdir}/install-config.sh"
}

main() {
  printf '\n' >&2
  printf '%s\n' "${BOLD}GrokBuild 一键安装${RESET}" >&2
  printf '%s\n' "${DIM}1) 安装 Grok Build CLI  2) 下载配置脚本  3) 交互写入 ~/.grok/config.toml${RESET}" >&2
  printf '\n' >&2

  need_cmd curl
  need_cmd bash

  install_grok_cli
  printf '\n' >&2

  local workdir cleanup=0
  if [[ -n "${GROKBUILD_WORKDIR:-}" ]]; then
    workdir="$GROKBUILD_WORKDIR"
    mkdir -p "$workdir"
  else
    workdir="$(mktemp -d "${TMPDIR:-/tmp}/grokbuild.XXXXXX")"
    cleanup=1
    # shellcheck disable=SC2064
    trap 'rm -rf "'"$workdir"'"' EXIT
  fi

  download_assets "$workdir"
  printf '\n' >&2

  run_config_wizard "$workdir"

  if [[ "$cleanup" -eq 1 ]]; then
    rm -rf "$workdir"
    trap - EXIT
  fi

  printf '\n' >&2
  ok "全部完成。"
  info "新开终端后若找不到 grok，请把下面加入 shell 配置："
  printf '  %s\n' "${DIM}export PATH=\"\$HOME/.grok/bin:\$PATH\"${RESET}" >&2
  info "启动: ${BOLD}grok${RESET}"
  printf '\n' >&2
}

main "$@"
