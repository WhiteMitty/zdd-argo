#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

SCRIPT_VERSION="0.1.0"
BUILD_ID="SINGBOX-WARP-DOH-MENU-STRATEGY-AUDIT-20260710"
DEFAULT_NODE_NAME="zdd-argo"
DEFAULT_LOCAL_PORT="10000"
DEFAULT_XRAY_NODE_NAME="$DEFAULT_NODE_NAME"
DEFAULT_XRAY_LOCAL_PORT="10001"
DEFAULT_PREFERRED_ENDPOINT="saas.sin.fan"
DEFAULT_XRAY_PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
DEFAULT_DOH_ENABLED="0"
DEFAULT_WARP_ENABLED="0"
DEFAULT_OUTBOUND_IP_MODE="prefer_ipv4"
NODE_NAME="$DEFAULT_NODE_NAME"
LOCAL_PORT="$DEFAULT_LOCAL_PORT"
XRAY_NODE_NAME="$DEFAULT_XRAY_NODE_NAME"
XRAY_LOCAL_PORT="$DEFAULT_XRAY_LOCAL_PORT"
PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
DOH_ENABLED="$DEFAULT_DOH_ENABLED"
WARP_ENABLED="$DEFAULT_WARP_ENABLED"
OUTBOUND_IP_MODE="$DEFAULT_OUTBOUND_IP_MODE"
ECH_CONFIG="cloudflare-ech.com+https://doh.pub/dns-query"
SETTINGS_CONFIGURED=0
TMUX_SESSION="zdd-argo-singbox"
LEGACY_TMUX_SESSION="zdd-argo"
XRAY_TMUX_SESSION="zdd-argo-xr"
SERVICE_NAME="zdd-argo-singbox"
XRAY_SERVICE_NAME="zdd-argo-xray"
SERVICE_USER="zdd-argo-svc"
SERVICE_GROUP="zdd-argo-svc"
SERVICE_HOME="/var/lib/zdd-argo"
SERVICE_MARKER="${SERVICE_HOME}/.managed-by-zdd-argo"
SERVICE_MARKER_CONTENT="zdd-argo-service-account-v0.1.0"
SERVICE_SHELL="/usr/sbin/nologin"
OS_ID=""
INIT_SYSTEM=""

DATA_DIR="/etc/zdd-argo"
STATE_JSON="${DATA_DIR}/state.json"
LEGACY_STATE_FILE="${DATA_DIR}/state.env"
SINGBOX_CONFIG="${DATA_DIR}/sing-box.json"
XRAY_CONFIG="${DATA_DIR}/xray-vlessenc-ws.json"
XRAY_STATE_JSON="${DATA_DIR}/xray-state.json"
SINGBOX_SYSTEMD_UNIT="/etc/systemd/system/${SERVICE_NAME}.service"
SINGBOX_OPENRC_SERVICE="/etc/init.d/${SERVICE_NAME}"
XRAY_SYSTEMD_UNIT="/etc/systemd/system/${XRAY_SERVICE_NAME}.service"
XRAY_OPENRC_SERVICE="/etc/init.d/${XRAY_SERVICE_NAME}"
SINGBOX_UNIT="$SINGBOX_SYSTEMD_UNIT"
XRAY_UNIT="$XRAY_SYSTEMD_UNIT"
CLOUDFLARED_RUNNER="${DATA_DIR}/run-cloudflared.sh"
XRAY_CLOUDFLARED_RUNNER="${DATA_DIR}/run-cloudflared-xray.sh"
CLOUDFLARED_HOME="${SERVICE_HOME}/cloudflared-home"
XRAY_CLOUDFLARED_HOME="${SERVICE_HOME}/cloudflared-home-xray"
CLOUDFLARED_PID_FILE="${DATA_DIR}/cloudflared.pid"
XRAY_CLOUDFLARED_PID_FILE="${DATA_DIR}/cloudflared-xray.pid"
LOG_FILE="/var/log/zdd-argo-cloudflared.log"
XRAY_LOG_FILE="/var/log/zdd-argo-xray-cloudflared.log"
SINGBOX_LOG_FILE="/var/log/zdd-argo-singbox.log"
XRAY_CORE_LOG_FILE="/var/log/zdd-argo-xray.log"
LOGROTATE_CONFIG="/etc/logrotate.d/zdd-argo-cloudflared"
VMESS_JSON_FILE="${DATA_DIR}/vmess.json"
VMESS_LINK_FILE="${DATA_DIR}/vmess.txt"
XRAY_VLESS_JSON_FILE="${DATA_DIR}/vless-ws.json"
XRAY_VLESS_LINK_FILE="${DATA_DIR}/vless-ws.txt"
ECH_NOTE_FILE="${DATA_DIR}/ech.txt"
SETTINGS_JSON="${DATA_DIR}/settings.json"
WARP_DIR="${DATA_DIR}/warp"
WARP_ACCOUNT_FILE="${WARP_DIR}/wgcf-account.toml"
WARP_PROFILE_FILE="${WARP_DIR}/wgcf-profile.conf"
WARP_CHECK_FILE="${WARP_DIR}/warp-check.json"
LOCK_DIR="/run/lock/zdd-argo.lock.d"
LOCK_OWNER_FILE="${LOCK_DIR}/owner"
SHORTCUT_PATH="/usr/local/bin/zargo"
SHORTCUT_COMPAT_PATH="/usr/local/sbin/zargo"
SHORTCUT_FALLBACK_PATH="/usr/bin/zargo"
LEGACY_ZDD_PATHS=("/usr/bin/zdd" "/usr/local/sbin/zdd" "/usr/local/bin/zdd")
LEGACY_SHORTCUT_PATH="/usr/local/sbin/zdd-argo"
LEGACY_SHORTCUT_BIN="/usr/local/bin/zdd-argo"

BIN_DIR="/usr/local/lib/zdd-argo"
SOURCE_RECORD_FILE="${BIN_DIR}/source-record"
MANAGED_SCRIPT_PATH="${BIN_DIR}/zdd-argo.sh"
MANAGED_SINGBOX_BIN="${BIN_DIR}/sing-box"
MANAGED_XRAY_BIN="${BIN_DIR}/xray"
MANAGED_CLOUDFLARED_BIN="${BIN_DIR}/cloudflared"
MANAGED_WGCF_BIN="${BIN_DIR}/wgcf"
SINGBOX_RELEASE_META="${BIN_DIR}/sing-box.release.json"
XRAY_RELEASE_META="${BIN_DIR}/xray.release.json"
CLOUDFLARED_RELEASE_META="${BIN_DIR}/cloudflared.release.json"
WGCF_RELEASE_META="${BIN_DIR}/wgcf.release.json"
GITHUB_API_BASE="https://api.github.com"

SCRIPT_PATH=""
UUID=""
WSPATH=""
ARGO_HOST=""
XRAY_UUID=""
XRAY_WS_PATH=""
XRAY_ARGO_HOST=""
XRAY_CREATED_AT=""
XRAY_VLESS_ENCRYPTION=""
XRAY_VLESS_DECRYPTION=""
XRAY_KEY_PRIVATE=""
XRAY_KEY_PUBLIC=""
CREATED_AT=""
SINGBOX_BIN=""
XRAY_BIN=""
CLOUDFLARED_BIN=""
WGCF_BIN=""
WARP_PRIVATE_KEY=""
WARP_IPV4=""
WARP_IPV6=""
WARP_PEER_PUBLIC_KEY=""
WARP_ENDPOINT_ADDRESS=""
WARP_ENDPOINT_PORT=""
WARP_PROFILE_ENDPOINT_PORT=""
WARP_MTU="1280"
MENU_MODE=0
LOCK_HELD=0
LOCK_OWNER_PID=""
LOCK_OWNER_START=""
LOCK_DIR_INODE=""
TRANSACTION_ACTIVE=0
TRANSACTION_SCOPE="all"
TRANSACTION_DIR=""
TRANSACTION_OLD_SERVICE_ACTIVE=0
TRANSACTION_OLD_TUNNEL_RUNNING=0
TRANSACTION_OLD_XRAY_SERVICE_ACTIVE=0
TRANSACTION_OLD_XRAY_TUNNEL_RUNNING=0
TRANSACTION_OLD_SERVICE_ACCOUNT=0
TRANSACTION_OLD_SERVICE_GROUP=0
TRANSACTION_OLD_SERVICE_HOME=0

if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[1;93m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
  C_BOLD=$'\033[1m'
  C_RESET=$'\033[0m'
else
  C_GREEN=""
  C_YELLOW=""
  C_RED=""
  C_CYAN=""
  C_BOLD=""
  C_RESET=""
fi

read_interactive() {
  local variable_name="$1"
  local prompt="${2:-}"
  local default_value="${3:-}"
  local value=""
  local input_fd=0

  if [[ -t 0 ]]; then
    input_fd=0
  elif [[ -r /dev/tty ]]; then
    exec {input_fd}</dev/tty 2>/dev/null || {
      printf -v "$variable_name" '%s' "$default_value"
      return 1
    }
  else
    printf -v "$variable_name" '%s' "$default_value"
    return 1
  fi

  if ! IFS= read -r -u "$input_fd" -p "$prompt" value; then
    value="$default_value"
  fi

  if [[ $input_fd -ne 0 ]]; then
    exec {input_fd}<&-
  fi

  printf -v "$variable_name" '%s' "$value"
}

info() {
  printf '%s[%s]%s %s\n' \
    "$C_CYAN" \
    "$(printf '%s' "信息")" \
    "$C_RESET" \
    "$*"
}

ok() {
  printf '%s[%s]%s %s\n' \
    "$C_GREEN" \
    "$(printf '%s' "完成")" \
    "$C_RESET" \
    "$*"
}

warn() {
  printf '%s[%s] %s%s\n' \
    "$C_YELLOW" \
    "$(printf '%s' "注意")" \
    "$*" \
    "$C_RESET"
}

error() {
  printf '%s[%s]%s %s\n' \
    "$C_RED" \
    "$(printf '%s' "错误")" \
    "$C_RESET" \
    "$*" \
    >&2
}

die() {
  error "$*"
  exit 1
}

clear_screen() {
  if [[ -t 1 ]]; then
    printf '\033[2J\033[H'
  fi
}

ensure_utf8_locale() {
  local current=""
  local candidate=""

  if command -v locale >/dev/null 2>&1; then
    current="$(locale charmap 2>/dev/null || true)"
    if [[ "${current^^}" == "UTF-8" || "${current^^}" == "UTF8" ]]; then
      return 0
    fi

    for candidate in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
      current="$(LC_ALL="$candidate" locale charmap 2>/dev/null || true)"
      if [[ "${current^^}" == "UTF-8" || "${current^^}" == "UTF8" ]]; then
        export LANG="$candidate"
        export LC_ALL="$candidate"
        return 0
      fi
    done
  fi

  export LANG=C.UTF-8
  export LC_ALL=C.UTF-8
}

text_is_valid_utf8() {
  local value="$1"

  if command -v iconv >/dev/null 2>&1; then
    printf '%s' "$value" \
      | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1
    return
  fi

  return 0
}

text_display_width() {
  local value="$1"
  local width=""

  if command -v wc >/dev/null 2>&1; then
    width="$(printf '%s' "$value" | wc -L 2>/dev/null | tr -d '[:space:]' || true)"
  fi

  if [[ "$width" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$width"
  else
    printf '%s\n' "${#value}"
  fi
}

print_aligned_label() {
  local label="$1"
  local target_width="${2:-20}"
  local actual_width=""
  local padding=1

  actual_width="$(text_display_width "$label")"
  [[ "$actual_width" =~ ^[0-9]+$ ]] || actual_width="${#label}"

  padding=$((target_width - actual_width))
  ((padding >= 1)) || padding=1

  printf '%s' "$label"
  printf '%*s' "$padding" ''
}

print_kv() {
  local label="$1"
  local value="$2"
  local target_width="${3:-20}"

  print_aligned_label "$label" "$target_width"
  printf '%s\n' "$value"
}

print_section_header() {
  local title="$1"
  local color="${2:-}"
  local total_width="${3:-78}"
  local title_width=""
  local left=0
  local right=0

  title_width="$(text_display_width "$title")"
  [[ "$title_width" =~ ^[0-9]+$ ]] || title_width="${#title}"

  if ((title_width + 2 >= total_width)); then
    printf '\n%s%s%s\n' "$color" "$title" "$C_RESET"
    return 0
  fi

  left=$(((total_width - title_width - 2) / 2))
  right=$((total_width - title_width - 2 - left))

  printf '\n%s' "$C_CYAN"
  printf '%*s' "$left" '' | tr ' ' '='
  printf ' %s%s%s ' "$color" "$title" "$C_CYAN"
  printf '%*s' "$right" '' | tr ' ' '='
  printf '%s\n' "$C_RESET"
}

print_section_footer() {
  local color="${1:-}"
  local total_width="${2:-78}"

  printf '%s' "$C_CYAN"
  printf '%*s' "$total_width" '' | tr ' ' '='
  printf '%s\n' "$C_RESET"
}

wait_for_zero() {
  local prompt="$1"
  local choice=""

  if [[ ! -t 0 && ! -r /dev/tty ]]; then
    return 0
  fi

  while true; do
    if ! read_interactive choice "$prompt" ""; then
      return 0
    fi

    if [[ "$choice" == "0" ]]; then
      return 0
    fi

    warn "$(printf '%s' "请输入 0。")"
  done
}

pause_screen() {
  printf '\n'

  wait_for_zero "$(printf '%s' "输入 0 返回菜单：")"
}

resolve_script_path() {
  local candidate="${BASH_SOURCE[0]:-}"
  local dir=""
  local base=""

  if [[ -z "$candidate" ]]; then
    SCRIPT_PATH=""
    return 0
  fi

  if [[ "$candidate" != /* ]]; then
    candidate="$(pwd)/$candidate"
  fi

  dir="$(dirname -- "$candidate")"
  base="$(basename -- "$candidate")"

  dir="$(
    cd -- "$dir" 2>/dev/null \
      && pwd -P \
      || printf '%s' "$dir"
  )"

  SCRIPT_PATH="${dir}/${base}"
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] \
    || die "$(printf '%s' "请使用 root 运行此脚本。")"
}

check_os() {
  [[ -r /etc/os-release ]] \
    || die "$(printf '%s' "无法识别操作系统，仅支持 Debian / Ubuntu / Alpine。")"

  source /etc/os-release
  OS_ID="${ID:-}"

  case "${ID:-}" in
    debian|ubuntu)
      INIT_SYSTEM="systemd"
      SINGBOX_UNIT="$SINGBOX_SYSTEMD_UNIT"
      XRAY_UNIT="$XRAY_SYSTEMD_UNIT"
      SERVICE_SHELL="/usr/sbin/nologin"
      ;;

    alpine)
      INIT_SYSTEM="openrc"
      SINGBOX_UNIT="$SINGBOX_OPENRC_SERVICE"
      XRAY_UNIT="$XRAY_OPENRC_SERVICE"
      if [[ -x /sbin/nologin ]]; then
        SERVICE_SHELL="/sbin/nologin"
      else
        SERVICE_SHELL="/bin/false"
      fi
      ;;

    *)
      case " ${ID_LIKE:-} " in
        *" debian "*)
          INIT_SYSTEM="systemd"
          SINGBOX_UNIT="$SINGBOX_SYSTEMD_UNIT"
          XRAY_UNIT="$XRAY_SYSTEMD_UNIT"
          SERVICE_SHELL="/usr/sbin/nologin"
          ;;

        *)
          die "$(printf '%s' "当前系统为 ${PRETTY_NAME:-未知}，本脚本仅支持 Debian / Ubuntu / Alpine。")"
          ;;
      esac
      ;;
  esac
}

service_is_active() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null
      ;;
    openrc)
      rc-service "$SERVICE_NAME" status >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

service_enable() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl enable "$SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-update add "$SERVICE_NAME" default >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

service_restart() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl restart "$SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$SERVICE_NAME" restart \
        || rc-service "$SERVICE_NAME" start
      ;;
    *)
      return 1
      ;;
  esac
}

service_stop() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl stop "$SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$SERVICE_NAME" stop >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

service_disable_now() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl disable --now "$SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$SERVICE_NAME" stop >/dev/null 2>&1 || true
      rc-update del "$SERVICE_NAME" default >/dev/null 2>&1 || true
      ;;
    *)
      return 1
      ;;
  esac
}

service_enable_now() {
  service_enable || return 1
  case "$INIT_SYSTEM" in
    systemd)
      systemctl start "$SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$SERVICE_NAME" start >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

service_daemon_reload() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl daemon-reload >/dev/null 2>&1 || true
      ;;
    openrc)
      :
      ;;
  esac
}

service_reset_failed() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl reset-failed "$SERVICE_NAME" >/dev/null 2>&1 || true
      ;;
    openrc)
      :
      ;;
  esac
}

service_print_logs() {
  local lines="${1:-80}"

  case "$INIT_SYSTEM" in
    systemd)
      journalctl \
        -u "$SERVICE_NAME" \
        -n "$lines" \
        --no-pager \
        >&2 \
        || true
      ;;
    openrc)
      rc-service "$SERVICE_NAME" status >&2 || true
      ss -ltnp 2>/dev/null | grep -E "(^|:)${LOCAL_PORT}[[:space:]]" >&2 || true

      if [[ -f "$SINGBOX_LOG_FILE" ]]; then
        tail -n "$lines" "$SINGBOX_LOG_FILE" >&2 || true
      else
        warn "OpenRC 模式未找到 sing-box 日志文件：${SINGBOX_LOG_FILE}"
      fi
      ;;
  esac
}

runtime_label() {
  case "$INIT_SYSTEM" in
    systemd)
      printf '%s' "Debian/Ubuntu + systemd"
      ;;
    openrc)
      printf '%s' "Alpine + OpenRC"
      ;;
    *)
      printf '%s' "未知"
      ;;
  esac
}

download_tool_available() {
  command -v curl >/dev/null 2>&1 \
    || wget_is_usable
}

wget_is_usable() {
  command -v wget >/dev/null 2>&1 || return 1
  wget --version >/dev/null 2>&1
}

ensure_download_tool() {
  [[ -n "$INIT_SYSTEM" ]] || check_os

  if download_tool_available; then
    return 0
  fi

  info "未检测到 curl 或 wget，正在安装下载工具……"

  case "$INIT_SYSTEM" in
    systemd)
      command -v apt-get >/dev/null 2>&1 \
        || die "未找到 curl/wget，且当前系统无法使用 apt-get 自动安装。"

      export DEBIAN_FRONTEND=noninteractive
      export NEEDRESTART_MODE=a
      export APT_LISTCHANGES_FRONTEND=none

      apt-get update \
        || die "apt-get update 失败，无法安装 curl/wget。"
      apt-get install -y curl wget ca-certificates \
        || die "curl/wget 安装失败。"
      ;;
    openrc)
      command -v apk >/dev/null 2>&1 \
        || die "未找到 curl/wget，且当前系统无法使用 apk 自动安装。"

      apk add --no-cache curl wget ca-certificates \
        || die "Alpine curl/wget 安装失败。"
      ;;
    *)
      die "未检测到 curl/wget，且无法识别系统包管理器。"
      ;;
  esac

  download_tool_available \
    || die "已尝试安装 curl/wget，但仍未检测到可用下载工具。"
}

ensure_alpine_binary_compat() {
  [[ "$INIT_SYSTEM" == "openrc" ]] || return 0
  command -v apk >/dev/null 2>&1 \
    || return 1

  if apk info -e gcompat >/dev/null 2>&1; then
    apk info -e libstdc++ >/dev/null 2>&1 \
      || apk add --no-cache libstdc++ >/dev/null 2>&1 \
      || true
    return 0
  fi

  if apk info -e libc6-compat >/dev/null 2>&1; then
    apk info -e libstdc++ >/dev/null 2>&1 \
      || apk add --no-cache libstdc++ >/dev/null 2>&1 \
      || true
    return 0
  fi

  info "Alpine 正在安装二进制兼容库（gcompat/libstdc++）……"
  if apk add --no-cache gcompat libstdc++ >/dev/null 2>&1; then
    return 0
  fi

  ensure_alpine_community_repo || true
  if apk add --no-cache gcompat libstdc++ >/dev/null 2>&1; then
    return 0
  fi

  warn "gcompat 安装失败，尝试 libc6-compat/libstdc++ 兼容层。"
  if apk add --no-cache libc6-compat libstdc++ >/dev/null 2>&1; then
    return 0
  fi

  warn "无法自动安装 Alpine 二进制兼容库；如仍自检失败，请手动启用 community 仓库后安装 gcompat。"
  return 1
}

ensure_alpine_community_repo() {
  local repo_file="/etc/apk/repositories"
  local release_line=""
  local branch=""
  local community_line=""

  [[ "$INIT_SYSTEM" == "openrc" ]] || return 0
  [[ -f "$repo_file" ]] || return 1

  if grep -Eq '^[[:space:]]*https?://.*/community([[:space:]]|$)' "$repo_file"; then
    return 0
  fi

  release_line="$(cat /etc/alpine-release 2>/dev/null || true)"
  if [[ "$release_line" =~ ^([0-9]+)\.([0-9]+) ]]; then
    branch="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  else
    branch="edge"
  fi

  community_line="https://dl-cdn.alpinelinux.org/alpine/${branch}/community"
  warn "未检测到 Alpine community 仓库，正在追加：${community_line}"
  printf '%s\n' "$community_line" >> "$repo_file" \
    || return 1
  apk update >/dev/null 2>&1 || true
}

print_binary_run_error() {
  local binary="$1"
  local err_file=""

  shift
  err_file="$(mktemp)"
  "$binary" "$@" >/dev/null 2>"$err_file" || true

  if [[ -s "$err_file" ]]; then
    warn "二进制运行错误：$(head -n 1 "$err_file")"
  fi

  rm -f "$err_file"
}

singbox_version_ok() {
  local binary="$1"
  local first_line=""

  first_line="$("$binary" version 2>/dev/null | head -n 1 || true)"
  [[ "$first_line" == sing-box\ version\ * ]]
}

cloudflared_version_ok() {
  local binary="$1"
  local first_line=""

  first_line="$("$binary" --version 2>/dev/null | head -n 1 || true)"
  [[ "${first_line,,}" == cloudflared\ version\ * ]]
}

wgcf_version_ok() {
  local binary="$1"
  local help_text=""

  help_text="$("$binary" --help 2>&1 || true)"
  [[ "$help_text" == *"WireGuard Cloudflare Warp utility"* \
    || "$help_text" == *"wgcf is a utility for Cloudflare Warp"* ]]
}

xray_version_ok() {
  local binary="$1"
  local first_line=""

  first_line="$("$binary" version 2>/dev/null | head -n 1 || true)"
  [[ "$first_line" == Xray\ * || "$first_line" == *"Xray"* ]]
}

install_dependencies() {
  local missing=0
  local cmd=""

  [[ -n "$INIT_SYSTEM" ]] || check_os

  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    [[ -d /run/systemd/system ]] \
      || die "当前系统不是由 systemd 管理，无法创建后台服务。"

    command -v systemctl >/dev/null 2>&1 \
      || die "未找到 systemctl。"

    command -v journalctl >/dev/null 2>&1 \
      || die "未找到 journalctl。"

    ensure_download_tool

    for cmd in \
      curl jq openssl tmux ss base64 awk sed grep tar unzip sha256sum find \
      install mktemp readlink stat getent useradd groupadd userdel groupdel \
      setpriv logrotate wc iconv locale
    do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        missing=1
        break
      fi
    done

    if [[ $missing -eq 1 ]]; then
      info "安装 Debian / Ubuntu 基础依赖……"

      export DEBIAN_FRONTEND=noninteractive
      export NEEDRESTART_MODE=a
      export APT_LISTCHANGES_FRONTEND=none

      apt-get update \
        || die "apt-get update 失败。"

      apt-get install -y \
        curl wget jq openssl ca-certificates tmux iproute2 coreutils tar unzip \
        findutils grep sed gawk passwd util-linux logrotate libc-bin \
        || die "基础依赖安装失败。"
    fi
  elif [[ "$INIT_SYSTEM" == "openrc" ]]; then
    command -v apk >/dev/null 2>&1 \
      || die "Alpine 模式未找到 apk。"

    if ! command -v rc-service >/dev/null 2>&1 \
        || ! command -v rc-update >/dev/null 2>&1; then
      info "未检测到完整 OpenRC 工具，正在安装 openrc……"
      apk add --no-cache openrc \
        || die "Alpine openrc 安装失败。"
    fi

    command -v rc-service >/dev/null 2>&1 \
      || die "Alpine 模式未找到 rc-service；请确认当前系统使用 OpenRC。"
    command -v rc-update >/dev/null 2>&1 \
      || die "Alpine 模式未找到 rc-update；请确认当前系统使用 OpenRC。"

    ensure_download_tool

    for cmd in \
      curl jq openssl tmux ss base64 awk sed grep tar unzip sha256sum find \
      install mktemp readlink stat getent useradd groupadd userdel groupdel \
      su-exec logrotate wc
    do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        missing=1
        break
      fi
    done

    if [[ $missing -eq 1 ]]; then
      info "安装 Alpine / OpenRC 基础依赖……"

      apk add --no-cache \
        bash curl wget jq openssl ca-certificates tmux iproute2 coreutils tar unzip \
        findutils grep sed gawk shadow su-exec logrotate musl-utils \
        || die "Alpine 基础依赖安装失败。"
    fi

    ensure_alpine_binary_compat || true
  else
    die "无法识别服务管理器，当前 INIT_SYSTEM=${INIT_SYSTEM:-unknown}。"
  fi
}

process_start_time() {
  local pid="$1"
  local stat_line=""
  local remainder=""
  local start_time=""
  local -a fields=()

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "/proc/${pid}/stat" ]] || return 1

  IFS= read -r stat_line < "/proc/${pid}/stat" \
    || return 1

  [[ "$stat_line" == *") "* ]] || return 1
  remainder="${stat_line##*) }"

  IFS=' ' read -r -a fields <<< "$remainder"
  [[ ${#fields[@]} -ge 20 ]] || return 1

  start_time="${fields[19]}"
  [[ "$start_time" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$start_time"
}

process_state() {
  local pid="$1"

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "/proc/${pid}/status" ]] || return 1

  awk '
    $1 == "State:" {
      print substr($2, 1, 1)
      exit
    }
  ' "/proc/${pid}/status" 2>/dev/null
}

process_command_line() {
  local pid="$1"

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "/proc/${pid}/cmdline" ]] || return 1

  tr '\0' ' ' \
    < "/proc/${pid}/cmdline" \
    2>/dev/null
}

process_effective_uid() {
  local pid="$1"

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "/proc/${pid}/status" ]] || return 1

  awk '
    $1 == "Uid:" {
      print $3
      exit
    }
  ' "/proc/${pid}/status" 2>/dev/null
}

process_is_zdd_operation() {
  local pid="$1"
  local uid=""
  local cmdline=""

  uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
  [[ "$uid" == "0" ]] || return 1

  cmdline="$(process_command_line "$pid" 2>/dev/null || true)"
  [[ -n "$cmdline" ]] || return 1

  [[ ( -n "$SCRIPT_PATH" && "$cmdline" == *"${SCRIPT_PATH}"* ) \
    || "$cmdline" == *"${MANAGED_SCRIPT_PATH}"* \
    || "$cmdline" == *"${SHORTCUT_PATH}"* \
    || "$cmdline" == *"${SHORTCUT_COMPAT_PATH}"* \
    || "$cmdline" == *"${SHORTCUT_FALLBACK_PATH}"* ]]
}

secure_root_directory() {
  local path="$1"
  local uid=""
  local mode=""

  [[ -d "$path" && ! -L "$path" ]] || return 1
  uid="$(stat -Lc '%u' "$path" 2>/dev/null || true)"
  mode="$(stat -Lc '%a' "$path" 2>/dev/null || true)"

  [[ "$uid" == "0" && "$mode" == "700" ]]
}

secure_root_file() {
  local path="$1"
  local uid=""
  local mode=""

  [[ -f "$path" && ! -L "$path" ]] || return 1
  uid="$(stat -Lc '%u' "$path" 2>/dev/null || true)"
  mode="$(stat -Lc '%a' "$path" 2>/dev/null || true)"

  [[ "$uid" == "0" && "$mode" == "600" ]]
}

read_lock_owner() {
  local lock_path="${1:-$LOCK_DIR}"
  local owner_file="${lock_path}/owner"
  local pid=""
  local start=""
  local operation=""
  local extra=""

  secure_root_directory "$lock_path" || return 1
  secure_root_file "$owner_file" || return 1

  IFS=' ' read -r pid start operation extra < "$owner_file" \
    || return 1

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ "$start" =~ ^[0-9]+$ ]] || return 1
  [[ "$operation" =~ ^[A-Za-z0-9_.:-]+$ ]] || operation="unknown"
  [[ -z "$extra" ]] || return 1

  printf '%s %s %s\n' "$pid" "$start" "$operation"
}

lock_owner_is_alive() {
  local pid="$1"
  local recorded_start="$2"
  local actual_start=""
  local state=""

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  state="$(process_state "$pid" 2>/dev/null || true)"

  [[ -n "$actual_start" \
    && "$actual_start" == "$recorded_start" \
    && "$state" != "Z" \
    && "$state" != "X" ]] \
    || return 1

  process_is_zdd_operation "$pid"
}

write_lock_owner() {
  local operation="${1:-unknown}"
  local owner_pid="$BASHPID"
  local start=""
  local tmp=""

  [[ "$operation" =~ ^[A-Za-z0-9_.:-]+$ ]] || operation="unknown"

  start="$(process_start_time "$owner_pid")" \
    || {
      rm -rf -- "$LOCK_DIR"
      die "无法记录当前 zdd-argo 操作。"
    }

  tmp="${LOCK_DIR}/.owner.${owner_pid}"

  if ! printf '%s %s %s\n' "$owner_pid" "$start" "$operation" > "$tmp"; then
    rm -f "$tmp"
    rm -rf -- "$LOCK_DIR"
    die "无法写入 zdd-argo 操作锁信息。"
  fi

  if ! chmod 600 "$tmp" || ! mv -f "$tmp" "$LOCK_OWNER_FILE"; then
    rm -f "$tmp"
    rm -rf -- "$LOCK_DIR"
    die "无法保存 zdd-argo 操作锁信息。"
  fi

  LOCK_OWNER_PID="$owner_pid"
  LOCK_OWNER_START="$start"
  LOCK_HELD=1
  trap 'deployment_transaction_exit_handler $?' EXIT
}

release_lock() {
  local pid=""
  local start=""
  local operation=""
  local current_inode=""

  [[ $LOCK_HELD -eq 1 ]] || return 0
  [[ "$BASHPID" == "$LOCK_OWNER_PID" ]] || return 0

  current_inode="$(
    stat -Lc '%i' "$LOCK_DIR" 2>/dev/null \
      || true
  )"

  if [[ -n "$LOCK_DIR_INODE" \
      && "$current_inode" == "$LOCK_DIR_INODE" ]]; then

    if IFS=' ' read -r \
        pid \
        start \
        operation \
        < <(read_lock_owner 2>/dev/null); then

      if [[ "$pid" == "$LOCK_OWNER_PID" \
          && "$start" == "$LOCK_OWNER_START" ]]; then
        rm -f "$LOCK_OWNER_FILE"
        rmdir "$LOCK_DIR" 2>/dev/null || true
      fi
    elif [[ ! -e "$LOCK_OWNER_FILE" ]]; then
      rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
  fi

  LOCK_HELD=0
  LOCK_OWNER_PID=""
  LOCK_OWNER_START=""
  LOCK_DIR_INODE=""
}

collect_descendants() {
  local parent="$1"
  local status=""
  local child=""
  local ppid=""

  for status in /proc/[0-9]*/status; do
    [[ -r "$status" ]] || continue

    child="${status#/proc/}"
    child="${child%/status}"

    [[ "$child" =~ ^[0-9]+$ ]] || continue

    ppid="$(
      awk '
        $1 == "PPid:" {
          print $2
          exit
        }
      ' "$status" 2>/dev/null \
        || true
    )"

    [[ "$ppid" == "$parent" ]] || continue

    collect_descendants "$child"
    printf '%s\n' "$child"
  done
}

snapshot_process_tree() {
  local owner_pid="$1"
  local pid=""
  local start=""

  while IFS= read -r pid; do
    start="$(
      process_start_time "$pid" \
        2>/dev/null \
        || true
    )"

    if [[ "$start" =~ ^[0-9]+$ ]]; then
      printf '%s %s\n' \
        "$pid" \
        "$start"
    fi
  done < <(
    collect_descendants "$owner_pid"
  )

  start="$(
    process_start_time "$owner_pid" \
      2>/dev/null \
      || true
  )"

  if [[ "$start" =~ ^[0-9]+$ ]]; then
    printf '%s %s\n' \
      "$owner_pid" \
      "$start"
  fi
}

signal_process_tree() {
  local signal_name="$1"
  local snapshot_file="$2"
  local pid=""
  local recorded_start=""
  local actual_start=""

  while IFS=' ' read -r \
      pid \
      recorded_start
  do
    [[ "$pid" =~ ^[0-9]+$ ]] || continue

    [[ "$pid" != "$BASHPID" \
      && "$pid" != "$$" ]] \
      || continue

    actual_start="$(
      process_start_time "$pid" \
        2>/dev/null \
        || true
    )"

    [[ "$actual_start" == "$recorded_start" ]] \
      || continue

    kill "-${signal_name}" "$pid" \
      2>/dev/null \
      || true
  done < "$snapshot_file"
}

wait_for_process_exit() {
  local pid="$1"
  local recorded_start="$2"
  local seconds="$3"
  local i=0

  for ((i = 0; i < seconds; i++)); do
    if ! lock_owner_is_alive \
        "$pid" \
        "$recorded_start"; then
      return 0
    fi

    sleep 1
  done

  return 1
}

lock_operation_label() {
  case "${1:-unknown}" in
    command_generate_noninteractive)
      printf '%s' "新建 sing-box VMess/WS（直出）"
      ;;
    command_generate_noninteractive_doh_warp)
      printf '%s' "新建 sing-box VMess/WS（DoH + WARP）"
      ;;
    command_generate_custom)
      printf '%s' "新建 sing-box VMess/WS（自定义）"
      ;;
    command_generate_xray_vlessenc_ws)
      printf '%s' "新建 Xray VLESS-ENC/WS（直出）"
      ;;
    show_subscription|show_all_subscriptions|show_xray_subscription)
      printf '%s' "查看当前订阅"
      ;;
    command_update_components)
      printf '%s' "更新全部组件"
      ;;
    command_stop_clear_cache)
      printf '%s' "停止全部隧道并清理缓存"
      ;;
    command_uninstall_all)
      printf '%s' "完整卸载 zdd-argo（含 Xray）"
      ;;
    *)
      printf '%s' "未知操作"
      ;;
  esac
}

confirm_force() {
  local prompt="$1"
  local answer=""

  read_interactive answer "$prompt" "" \
    || die "$(printf '%s' "此操作必须在交互式终端中执行。")"

  answer="${answer#"${answer%%[![:space:]]*}"}"
  answer="${answer%"${answer##*[![:space:]]}"}"

  [[ "$answer" == "FORCE" ]]
}

quarantine_lock_dir() {
  local expected_inode="$1"
  local expected_pid="${2:-}"
  local expected_start="${3:-}"
  local quarantine=""
  local moved_inode=""
  local pid=""
  local start=""
  local operation=""

  [[ "$expected_inode" =~ ^[0-9]+$ ]] || return 1

  quarantine="${LOCK_DIR}.stale.${BASHPID}.${RANDOM}"
  while [[ -e "$quarantine" || -L "$quarantine" ]]; do
    quarantine="${LOCK_DIR}.stale.${BASHPID}.${RANDOM}"
  done

  mv -- "$LOCK_DIR" "$quarantine" 2>/dev/null || return 1

  moved_inode="$(stat -Lc '%i' "$quarantine" 2>/dev/null || true)"
  if [[ "$moved_inode" != "$expected_inode" ]]; then
    if [[ ! -e "$LOCK_DIR" && ! -L "$LOCK_DIR" ]]; then
      mv -- "$quarantine" "$LOCK_DIR" 2>/dev/null || true
    fi
    return 1
  fi

  if [[ -n "$expected_pid" || -n "$expected_start" ]]; then
    if ! IFS=' ' read -r pid start operation \
        < <(read_lock_owner "$quarantine" 2>/dev/null); then
      if [[ ! -e "$LOCK_DIR" && ! -L "$LOCK_DIR" ]]; then
        mv -- "$quarantine" "$LOCK_DIR" 2>/dev/null || true
      fi
      return 1
    fi

    if [[ "$pid" != "$expected_pid" || "$start" != "$expected_start" ]]; then
      if [[ ! -e "$LOCK_DIR" && ! -L "$LOCK_DIR" ]]; then
        mv -- "$quarantine" "$LOCK_DIR" 2>/dev/null || true
      fi
      return 1
    fi
  fi

  rm -rf -- "$quarantine"
}

remove_lock_dir_if_owner_matches() {
  local expected_pid="$1"
  local expected_start="$2"
  local inode=""
  local pid=""
  local start=""
  local operation=""

  [[ -d "$LOCK_DIR" && ! -L "$LOCK_DIR" ]] || return 0

  inode="$(stat -Lc '%i' "$LOCK_DIR" 2>/dev/null || true)"
  [[ "$inode" =~ ^[0-9]+$ ]] || return 1

  if ! IFS=' ' read -r pid start operation \
      < <(read_lock_owner 2>/dev/null); then
    return 1
  fi

  [[ "$pid" == "$expected_pid" \
    && "$start" == "$expected_start" ]] \
    || return 1

  quarantine_lock_dir "$inode" "$expected_pid" "$expected_start"
}

clear_unverifiable_lock() {
  local inode_before=""
  local pid=""
  local start=""
  local operation=""

  inode_before="$(
    stat -Lc '%i' "$LOCK_DIR" 2>/dev/null \
      || true
  )"

  [[ "$inode_before" =~ ^[0-9]+$ ]] \
    || die "$(printf '%s' "zdd-argo 操作锁状态异常，无法安全处理。")"

  warn "$(printf '%s' "检测到无法验证所有者的 zdd-argo 操作锁。")"
  warn "$(printf '%s' "这通常表示上一次操作在创建锁后被强制中断；清理该锁不会终止任何已确认的进程。")"

  if ! confirm_force "$(printf '%s' "输入大写 FORCE 清理异常锁并继续，输入其他内容取消：")"; then
    die "$(printf '%s' "已取消清理异常操作锁。")"
  fi

  if IFS=' ' read -r pid start operation \
      < <(read_lock_owner 2>/dev/null); then
    return 0
  fi

  if quarantine_lock_dir "$inode_before"; then
    ok "$(printf '%s' "异常的 zdd-argo 操作锁已清理。")"
  fi
}

force_take_over_lock() {
  local owner_pid=""
  local owner_start=""
  local owner_operation=""
  local owner_command=""
  local snapshot_file=""

  for _ in 1 2 3 4 5; do
    if IFS=' ' read -r \
        owner_pid \
        owner_start \
        owner_operation \
        < <(read_lock_owner 2>/dev/null); then
      break
    fi

    sleep 0.2
  done

  if [[ ! "$owner_pid" =~ ^[0-9]+$ \
      || ! "$owner_start" =~ ^[0-9]+$ ]]; then
    clear_unverifiable_lock
    return 0
  fi

  if ! lock_owner_is_alive \
      "$owner_pid" \
      "$owner_start"; then

    if remove_lock_dir_if_owner_matches \
        "$owner_pid" \
        "$owner_start"; then
      ok "$(printf '%s' "检测到上一次操作留下的陈旧锁，已自动清理。")"
    fi

    return 0
  fi

  owner_command="$(
    process_command_line "$owner_pid" \
      2>/dev/null \
      || true
  )"

  warn "$(printf '%s' "另一个 zdd-argo 操作正在运行。")"

  printf '%s %s\n' \
    "$(printf '%s' "占用进程：")" \
    "$owner_pid"

  printf '%s %s\n' \
    "$(printf '%s' "当前操作：")" \
    "$(lock_operation_label "$owner_operation")"

  printf '%s %s\n' \
    "$(printf '%s' "进程命令：")" \
    "${owner_command:-$(printf '%s' "无法读取")}"

  warn "$(printf '%s' "强制接管会终止该 zdd-argo 操作及其子进程；如果它正在安装或更新程序，该次操作会被中断。")"

  if ! confirm_yes "$(printf '%s' "确认强制停止并接管请输入 yes：")"; then

    die "$(printf '%s' "已取消强制接管。")"
  fi

  snapshot_file="$(mktemp)"

  snapshot_process_tree "$owner_pid" \
    > "$snapshot_file"

  signal_process_tree \
    TERM \
    "$snapshot_file"

  if ! wait_for_process_exit \
      "$owner_pid" \
      "$owner_start" \
      8; then

    signal_process_tree \
      KILL \
      "$snapshot_file"

    if ! wait_for_process_exit \
        "$owner_pid" \
        "$owner_start" \
        3; then

      rm -f "$snapshot_file"

      die "$(printf '%s' "无法停止原 zdd-argo 操作，当前操作不会继续。")"
    fi
  else
    sleep 1

    signal_process_tree \
      KILL \
      "$snapshot_file"
  fi

  rm -f "$snapshot_file"

  remove_lock_dir_if_owner_matches \
    "$owner_pid" \
    "$owner_start" \
    || true

  ok "$(printf '%s' "原 zdd-argo 操作已停止，当前操作将接管。")"
}

acquire_lock() {
  local operation="${1:-unknown}"

  if [[ $LOCK_HELD -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$LOCK_DIR")"

  while true; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      if ! chmod 700 "$LOCK_DIR"; then
        rm -rf -- "$LOCK_DIR"
        die "$(printf '%s' "无法设置 zdd-argo 操作锁目录权限。")"
      fi

      LOCK_DIR_INODE="$(
        stat -Lc '%i' "$LOCK_DIR" 2>/dev/null \
          || true
      )"

      if [[ ! "$LOCK_DIR_INODE" =~ ^[0-9]+$ ]]; then
        rm -rf -- "$LOCK_DIR"

        die "$(printf '%s' "无法确认 zdd-argo 操作锁目录。")"
      fi

      write_lock_owner "$operation"
      return 0
    fi

    if [[ ! -d "$LOCK_DIR" ]]; then
      die "无法创建 zdd-argo 操作锁目录：${LOCK_DIR}"
    fi

    if ! secure_root_directory "$LOCK_DIR"; then
      clear_unverifiable_lock
      continue
    fi

    force_take_over_lock
  done
}

run_with_lock() {
  local fn="$1"
  shift

  acquire_lock "$fn"
  install_dependencies
  "$fn" "$@"
}

path_is_zdd_launcher() {
  local path="$1"

  [[ -f "$path" ]] \
    && { \
      grep -Fqx 'ZDD_ARGO_LAUNCHER=1' "$path" 2>/dev/null \
        || grep -Fq '# zdd-argo launcher' "$path" 2>/dev/null; \
    } \
    && grep -Fq \
      "$MANAGED_SCRIPT_PATH" \
      "$path" \
      2>/dev/null
}

path_is_legacy_zdd_launcher() {
  local path="$1"

  [[ -f "$path" ]] \
    && grep -Fq \
      'zdd argo' \
      "$path" \
      2>/dev/null \
    && grep -Fq \
      'exec /usr/bin/env bash' \
      "$path" \
      2>/dev/null \
    && grep -Fq \
      'zdd-argo.sh' \
      "$path" \
      2>/dev/null
}

path_is_replaceable_zdd_launcher() {
  local path="$1"

  path_is_zdd_launcher "$path" \
    || path_is_legacy_zdd_launcher "$path"
}

resolved_zdd_is_ours() {
  local resolved="${1:-}"

  [[ -n "$resolved" ]] \
    && path_is_zdd_launcher "$resolved"
}

script_file_is_ours() {
  local path="$1"

  [[ -f "$path" && ! -L "$path" ]] \
    && grep -Eq '^SCRIPT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$' "$path" 2>/dev/null \
    && grep -Eq '^BUILD_ID="[A-Z0-9_.-]+"$' "$path" 2>/dev/null \
    && grep -Fqx 'DEFAULT_NODE_NAME="zdd-argo"' "$path" 2>/dev/null \
    && grep -Fq 'MANAGED_SCRIPT_PATH="${BIN_DIR}/zdd-argo.sh"' "$path" 2>/dev/null \
    && grep -Fq 'SERVICE_MARKER_CONTENT="zdd-argo-service-account-v0.1.0"' "$path" 2>/dev/null
}

record_source_file() {
  local source_sha=""
  local tmp=""

  [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "$MANAGED_SCRIPT_PATH" ]] || return 0
  [[ "$SCRIPT_PATH" != *$'\n'* && "$SCRIPT_PATH" != *$'\r'* ]] || return 0
  [[ -f "$SCRIPT_PATH" && ! -L "$SCRIPT_PATH" ]] || return 0
  script_file_is_ours "$SCRIPT_PATH" || return 0
  command -v sha256sum >/dev/null 2>&1 || return 0

  source_sha="$(sha256sum "$SCRIPT_PATH" | awk '{print $1}')"
  [[ "$source_sha" =~ ^[0-9a-fA-F]{64}$ ]] || return 0

  tmp="${SOURCE_RECORD_FILE}.new.$$"
  printf '%s\n%s\n' "$SCRIPT_PATH" "${source_sha,,}" > "$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$SOURCE_RECORD_FILE"
}

install_shortcut() {
  [[ -n "$SCRIPT_PATH" \
    && -f "$SCRIPT_PATH" ]] \
    || die "$(printf '%s' "无法识别当前脚本文件，不能安装快捷命令。")"

  script_file_is_ours "$SCRIPT_PATH" \
    || die "$(printf '%s' "当前文件未通过 zdd-argo 脚本标识校验。")"

  bash -n "$SCRIPT_PATH" \
    || die "$(printf '%s' "当前脚本未通过 Bash 语法检查，拒绝安装。")"

  local existing_zargo=""
  local path=""

  existing_zargo="$(
    type -P zargo \
      2>/dev/null \
      || true
  )"

  if [[ -n "$existing_zargo" ]] \
      && ! path_is_replaceable_zdd_launcher "$existing_zargo"; then
    die "$(printf '%s' "当前 PATH 中的 zargo 已被其他程序占用：${existing_zargo}；为避免覆盖，未进行安装。")"
  fi

  for path in \
    "$SHORTCUT_PATH" \
    "$SHORTCUT_COMPAT_PATH" \
    "$SHORTCUT_FALLBACK_PATH"
  do
    [[ -e "$path" || -L "$path" ]] || continue

    if [[ \
      ( "$path" == "$SHORTCUT_COMPAT_PATH" \
        || "$path" == "$SHORTCUT_FALLBACK_PATH" ) \
      && -L "$path" \
    ]] && [[ \
      "$(readlink "$path" 2>/dev/null || true)" \
        == "$SHORTCUT_PATH" \
    ]]; then
      continue
    fi

    path_is_replaceable_zdd_launcher "$path" \
      || die "$(printf '%s' "快捷命令路径已被其他程序占用：${path}")"
  done

  if [[ -e "$MANAGED_SCRIPT_PATH" ]] \
      && ! script_file_is_ours "$MANAGED_SCRIPT_PATH"; then

    die "$(printf '%s' "目标路径已存在非 zdd-argo 文件：${MANAGED_SCRIPT_PATH}")"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"
  record_source_file
  mkdir -p \
    "$(dirname -- "$SHORTCUT_PATH")" \
    "$(dirname -- "$SHORTCUT_COMPAT_PATH")" \
    "$(dirname -- "$SHORTCUT_FALLBACK_PATH")"

  if [[ "$SCRIPT_PATH" != "$MANAGED_SCRIPT_PATH" ]]; then
    local managed_tmp=""

    managed_tmp="${MANAGED_SCRIPT_PATH}.new.$$"

    install -m 0755 \
      "$SCRIPT_PATH" \
      "$managed_tmp"

    mv -f \
      "$managed_tmp" \
      "$MANAGED_SCRIPT_PATH"
  else
    chmod 0755 "$MANAGED_SCRIPT_PATH"
  fi

  local tmp=""
  local launcher_new=""
  local resolved_zargo=""

  tmp="$(mktemp)"

  printf '%s\n' '#!/usr/bin/env bash' > "$tmp"
  cat >> "$tmp" <<EOF
set -Eeuo pipefail
ZDD_ARGO_LAUNCHER=1

if [[ "\$#" -ne 0 ]]; then
  printf '%s\n' '用法：zargo' >&2
  exit 2
fi

exec /usr/bin/env bash ${MANAGED_SCRIPT_PATH@Q}
EOF

  launcher_new="${SHORTCUT_PATH}.new.$$"

  install -m 0755 \
    "$tmp" \
    "$launcher_new"

  rm -f "$tmp"

  mv -f \
    "$launcher_new" \
    "$SHORTCUT_PATH"

  rm -f "$SHORTCUT_COMPAT_PATH"

  ln -s \
    "$SHORTCUT_PATH" \
    "$SHORTCUT_COMPAT_PATH"

  hash -r

  resolved_zargo="$(
    type -P zargo \
      2>/dev/null \
      || true
  )"

  if [[ -n "$resolved_zargo" \
      && ( -e "$SHORTCUT_FALLBACK_PATH" \
        || -L "$SHORTCUT_FALLBACK_PATH" ) ]]; then

    if path_is_replaceable_zdd_launcher \
        "$SHORTCUT_FALLBACK_PATH"; then
      rm -f "$SHORTCUT_FALLBACK_PATH"

      ln -s \
        "$SHORTCUT_PATH" \
        "$SHORTCUT_FALLBACK_PATH"
    fi
  fi

  if [[ -z "$resolved_zargo" ]]; then
    if [[ -e "$SHORTCUT_FALLBACK_PATH" \
        || -L "$SHORTCUT_FALLBACK_PATH" ]]; then

      if [[ -L "$SHORTCUT_FALLBACK_PATH" ]] \
          && [[ \
            "$(readlink "$SHORTCUT_FALLBACK_PATH" 2>/dev/null || true)" \
              == "$SHORTCUT_PATH" \
          ]]; then
        :
      elif path_is_replaceable_zdd_launcher \
          "$SHORTCUT_FALLBACK_PATH"; then

        rm -f "$SHORTCUT_FALLBACK_PATH"

        ln -s \
          "$SHORTCUT_PATH" \
          "$SHORTCUT_FALLBACK_PATH"
      else
        die "$(printf '%s' "当前 PATH 无法找到 /usr/local/bin/zargo，且备用路径已被其他程序占用：${SHORTCUT_FALLBACK_PATH}")"
      fi
    else
      ln -s \
        "$SHORTCUT_PATH" \
        "$SHORTCUT_FALLBACK_PATH"
    fi

    hash -r

    resolved_zargo="$(
      type -P zargo \
        2>/dev/null \
        || true
    )"
  fi

  [[ -x "$MANAGED_SCRIPT_PATH" ]] \
    || die "$(printf '%s' "已安装脚本副本不可执行。")"

  [[ -x "$SHORTCUT_PATH" ]] \
    || die "$(printf '%s' "快捷启动器安装失败。")"

  bash -n "$SHORTCUT_PATH" \
    || die "$(printf '%s' "快捷启动器语法检查失败。")"

  resolved_zdd_is_ours "$resolved_zargo" \
    || die "$(printf '%s' "快捷命令已写入磁盘，但当前 shell 未解析到本项目的 zargo；请检查 PATH。")"

  for path in "${LEGACY_ZDD_PATHS[@]}"; do
    [[ -e "$path" || -L "$path" ]] || continue

    if path_is_replaceable_zdd_launcher "$path"; then
      rm -f "$path"
    fi
  done

  for path in \
    "$LEGACY_SHORTCUT_PATH" \
    "$LEGACY_SHORTCUT_BIN"
  do
    [[ -e "$path" || -L "$path" ]] || continue

    if path_is_replaceable_zdd_launcher "$path" \
        || grep -Fq \
          'zdd-argo' \
          "$path" \
          2>/dev/null; then
      rm -f "$path"
    else
      warn "$(printf '%s' "发现同名旧快捷路径但无法确认归属，未删除：${path}")"
    fi
  done
}

resolve_singbox_bin() {
  SINGBOX_BIN=""

  if [[ -x "$MANAGED_SINGBOX_BIN" ]]; then
    SINGBOX_BIN="$MANAGED_SINGBOX_BIN"
  elif command -v sing-box >/dev/null 2>&1; then
    SINGBOX_BIN="$(command -v sing-box)"
  elif [[ -x /usr/bin/sing-box ]]; then
    SINGBOX_BIN="/usr/bin/sing-box"
  fi
}

resolve_xray_bin() {
  XRAY_BIN=""

  if [[ -x "$MANAGED_XRAY_BIN" ]]; then
    XRAY_BIN="$MANAGED_XRAY_BIN"
  elif command -v xray >/dev/null 2>&1; then
    XRAY_BIN="$(command -v xray)"
  elif [[ -x /usr/local/bin/xray ]]; then
    XRAY_BIN="/usr/local/bin/xray"
  elif [[ -x /usr/bin/xray ]]; then
    XRAY_BIN="/usr/bin/xray"
  fi
}

resolve_cloudflared_bin() {
  CLOUDFLARED_BIN=""

  if [[ -x "$MANAGED_CLOUDFLARED_BIN" ]]; then
    CLOUDFLARED_BIN="$MANAGED_CLOUDFLARED_BIN"
  elif command -v cloudflared >/dev/null 2>&1; then
    CLOUDFLARED_BIN="$(command -v cloudflared)"
  elif [[ -x /usr/local/bin/cloudflared ]]; then
    CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
  fi
}

resolve_wgcf_bin() {
  WGCF_BIN=""

  if [[ -x "$MANAGED_WGCF_BIN" ]]; then
    WGCF_BIN="$MANAGED_WGCF_BIN"
  elif command -v wgcf >/dev/null 2>&1; then
    WGCF_BIN="$(command -v wgcf)"
  elif [[ -x /usr/local/bin/wgcf ]]; then
    WGCF_BIN="/usr/local/bin/wgcf"
  fi
}

safe_download() {
  local url="$1"
  local output="$2"

  ensure_download_tool

  if command -v curl >/dev/null 2>&1; then
    curl \
      --proto '=https' \
      --tlsv1.2 \
      --user-agent "zdd-argo/${SCRIPT_VERSION}" \
      -fL \
      --retry 4 \
      --retry-all-errors \
      --connect-timeout 15 \
      --max-time 300 \
      "$url" \
      -o "$output"
  elif wget_is_usable; then
    wget \
      --https-only \
      --secure-protocol=TLSv1_2 \
      --user-agent="zdd-argo/${SCRIPT_VERSION}" \
      --tries=5 \
      --timeout=300 \
      -O "$output" \
      "$url"
  else
    die "未检测到可用的 curl 或 GNU wget，无法下载：${url}"
  fi
}

safe_download_github_api() {
  local url="$1"
  local output="$2"

  ensure_download_tool

  if command -v curl >/dev/null 2>&1; then
    curl \
      --proto '=https' \
      --tlsv1.2 \
      --user-agent "zdd-argo/${SCRIPT_VERSION}" \
      -H 'Accept: application/vnd.github+json' \
      -H 'X-GitHub-Api-Version: 2022-11-28' \
      -fL \
      --retry 4 \
      --retry-all-errors \
      --connect-timeout 15 \
      --max-time 120 \
      "$url" \
      -o "$output"
  elif wget_is_usable; then
    wget \
      --https-only \
      --secure-protocol=TLSv1_2 \
      --user-agent="zdd-argo/${SCRIPT_VERSION}" \
      --header='Accept: application/vnd.github+json' \
      --header='X-GitHub-Api-Version: 2022-11-28' \
      --tries=5 \
      --timeout=120 \
      -O "$output" \
      "$url"
  else
    die "未检测到可用的 curl 或 GNU wget，无法读取 GitHub API：${url}"
  fi
}

github_latest_asset_info() {
  local repo="$1"
  local asset_regex="$2"
  local api_file=""
  local result=""

  api_file="$(mktemp)"

  if ! safe_download_github_api \
      "${GITHUB_API_BASE}/repos/${repo}/releases/latest" \
      "$api_file"; then
    rm -f "$api_file"

    die "$(printf '%s' "无法读取 ${repo} 的 GitHub 最新稳定版信息。")"
  fi

  if ! jq -e '
      type == "object"
      and (.tag_name | type == "string")
      and (.assets | type == "array")
    ' \
    "$api_file" \
    >/dev/null 2>&1; then

    rm -f "$api_file"

    die "$(printf '%s' "${repo} 的 GitHub Release 响应格式异常。")"
  fi

  if ! result="$(
    jq -er \
      --arg re "$asset_regex" \
      '
        [.assets[] | select(.name | test($re))] as $matches
        | if ($matches | length) == 1 then
            [
              $matches[0].name,
              $matches[0].browser_download_url,
              ($matches[0].digest // ""),
              .tag_name
            ]
            | @tsv
          else
            error("matching asset count: \($matches | length)")
          end
      ' \
      "$api_file" \
      2>/dev/null
  )"; then
    rm -f "$api_file"

    die "$(printf '%s' "${repo} 最新稳定版中未找到唯一匹配的安装文件。")"
  fi

  rm -f "$api_file"
  printf '%s\n' "$result"
}

verify_github_asset() {
  local repo="$1"
  local asset_name="$2"
  local asset_url="$3"
  local digest="$4"
  local file="$5"
  local expected=""
  local actual=""

  case "$asset_url" in
    "https://github.com/${repo}/releases/download/"*)
      ;;
    *)
      die "$(printf '%s' "GitHub 资源下载地址异常，已拒绝安装：${asset_url}")"
      ;;
  esac

  [[ "$digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]] \
    || die "$(printf '%s' "${asset_name} 没有可用的 GitHub SHA-256 摘要，已拒绝无校验安装。")"

  expected="${digest#sha256:}"
  expected="${expected,,}"

  actual="$(
    sha256sum "$file" \
      | awk '{print tolower($1)}'
  )"

  [[ "$actual" == "$expected" ]] \
    || die "$(printf '%s' "${asset_name} 的 SHA-256 校验失败，已拒绝安装。")"
}

write_release_metadata() {
  local output="$1"
  local repo="$2"
  local tag="$3"
  local asset="$4"
  local digest="$5"
  local tmp=""

  mkdir -p "$BIN_DIR" || return 1

  tmp="$(
    mktemp "${BIN_DIR}/.release.XXXXXX"
  )" || return 1

  if ! jq -n \
      --arg repo "$repo" \
      --arg tag "$tag" \
      --arg asset "$asset" \
      --arg digest "$digest" \
      --arg installed_at \
        "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      '{
        repository: $repo,
        tag: $tag,
        asset: $asset,
        digest: $digest,
        installed_at: $installed_at
      }' \
      > "$tmp"; then

    rm -f "$tmp"
    return 1
  fi

  if ! chmod 0644 "$tmp" \
      || ! mv -f "$tmp" "$output"; then

    rm -f "$tmp"
    return 1
  fi
}

install_or_update_singbox() {
  local arch=""
  local asset_regex=""
  local info_line=""
  local asset_name=""
  local asset_url=""
  local digest=""
  local release_tag=""
  local work=""
  local archive=""
  local extract_dir=""
  local list_file=""
  local candidate=""
  local new_binary=""
  local backup=""
  local before=""
  local after=""
  local meta_backup=""
  local had_managed=0
  local had_unit=0
  local was_active=0
  local config_refresh=0
  local -a sb_candidates=()

  if singbox_config_needs_refresh; then
    config_refresh=1
  fi

  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_regex='^sing-box-.*-linux-amd64\.tar\.gz$'
      ;;

    aarch64|arm64)
      asset_regex='^sing-box-.*-linux-arm64\.tar\.gz$'
      ;;

    *)
      die "$(printf '%s' "暂不支持 CPU 架构：${arch}；当前脚本支持 amd64 与 arm64。")"
      ;;
  esac

  resolve_singbox_bin

  before="$(printf '%s' "未安装")"

  if [[ -n "$SINGBOX_BIN" ]]; then
    before="$(
      "$SINGBOX_BIN" version \
        2>/dev/null \
        | head -n 1 \
        || true
    )"
  fi

  info "$(printf '%s' "查询 sing-box 官方 GitHub 最新稳定版……")"

  info_line="$(
    github_latest_asset_info \
      "SagerNet/sing-box" \
      "$asset_regex"
  )"

  IFS=$'\t' read -r \
    asset_name \
    asset_url \
    digest \
    release_tag \
    <<< "$info_line"

  [[ -n "$asset_name" \
    && -n "$asset_url" \
    && -n "$release_tag" ]] \
    || die "$(printf '%s' "sing-box Release 信息不完整。")"

  work="$(mktemp -d)"
  archive="${work}/${asset_name}"
  extract_dir="${work}/extract"

  mkdir -p "$extract_dir"

  if ! safe_download \
      "$asset_url" \
      "$archive"; then
    rm -rf "$work"

    die "$(printf '%s' "sing-box 安装包下载失败。")"
  fi

  verify_github_asset \
    "SagerNet/sing-box" \
    "$asset_name" \
    "$asset_url" \
    "$digest" \
    "$archive"

  list_file="${work}/archive.list"

  if ! tar -tzf \
      "$archive" \
      > "$list_file"; then
    rm -rf "$work"

    die "$(printf '%s' "无法读取 sing-box 压缩包目录。")"
  fi

  if grep -Eq \
      '(^/|(^|/)\.\.(/|$))' \
      "$list_file"; then
    rm -rf "$work"

    die "$(printf '%s' "sing-box 压缩包包含不安全路径，已拒绝解压。")"
  fi

  if ! tar -xzf \
      "$archive" \
      -C "$extract_dir"; then
    rm -rf "$work"

    die "$(printf '%s' "sing-box 压缩包解压失败。")"
  fi

  mapfile -t sb_candidates < <(
    find \
      "$extract_dir" \
      -type f \
      -name sing-box \
      -print
  )

  if [[ ${#sb_candidates[@]} -ne 1 ]]; then
    rm -rf "$work"

    die "$(printf '%s' "sing-box 压缩包内未找到唯一可执行文件。")"
  fi

  candidate="${sb_candidates[0]}"
  chmod 0755 "$candidate"

  if ! singbox_version_ok "$candidate"; then
    if [[ "$INIT_SYSTEM" == "openrc" ]]; then
      ensure_alpine_binary_compat || true
    fi
  fi

  if ! singbox_version_ok "$candidate"; then
    print_binary_run_error "$candidate" version
    rm -rf "$work"

    die "$(printf '%s' "sing-box 新二进制无法通过版本自检。")"
  fi

  if [[ -f "$SINGBOX_CONFIG" ]] \
      && ! "$candidate" check \
        -c "$SINGBOX_CONFIG"; then
    if [[ $config_refresh -eq 1 ]]; then
      warn "检测到旧版或不完整的 sing-box 配置；更新后将自动重建为当前类型化 DNS 与 WireGuard Endpoint 语法。"
    else
      rm -rf "$work"
      die "$(printf '%s' "新版 sing-box 无法通过现有 zdd-argo 配置校验，未执行更新。")"
    fi
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  new_binary="${MANAGED_SINGBOX_BIN}.new.$$"
  backup="${MANAGED_SINGBOX_BIN}.backup.$$"

  if [[ -x "$MANAGED_SINGBOX_BIN" ]]; then
    cp -a \
      "$MANAGED_SINGBOX_BIN" \
      "$backup"

    had_managed=1
  fi

  if [[ -f "$SINGBOX_RELEASE_META" ]]; then
    meta_backup="${SINGBOX_RELEASE_META}.backup.$$"

    cp -a \
      "$SINGBOX_RELEASE_META" \
      "$meta_backup"
  fi

  if [[ -f "$SINGBOX_UNIT" ]]; then
    had_unit=1
  fi

  if service_is_active; then
    was_active=1
  fi

  install -m 0755 \
    "$candidate" \
    "$new_binary"

  mv -f \
    "$new_binary" \
    "$MANAGED_SINGBOX_BIN"

  if ! write_release_metadata \
      "$SINGBOX_RELEASE_META" \
      "SagerNet/sing-box" \
      "$release_tag" \
      "$asset_name" \
      "$digest"; then

    warn "$(printf '%s' "sing-box 元数据写入失败，正在回滚……")"

    if [[ $had_managed -eq 1 \
        && -f "$backup" ]]; then
      mv -f \
        "$backup" \
        "$MANAGED_SINGBOX_BIN"
    else
      rm -f "$MANAGED_SINGBOX_BIN"
    fi

    if [[ -n "$meta_backup" \
        && -f "$meta_backup" ]]; then
      mv -f \
        "$meta_backup" \
        "$SINGBOX_RELEASE_META"
    else
      rm -f "$SINGBOX_RELEASE_META"
    fi

    rm -rf "$work"
    hash -r
    resolve_singbox_bin

    die "$(printf '%s' "sing-box 更新失败，已恢复更新前状态。")"
  fi

  rm -rf "$work"

  hash -r
  resolve_singbox_bin

  if [[ "$SINGBOX_BIN" != "$MANAGED_SINGBOX_BIN" ]] \
      || ! "$MANAGED_SINGBOX_BIN" version \
        >/dev/null 2>&1; then

    warn "$(printf '%s' "新版 sing-box 安装后校验失败，正在回滚……")"

    if [[ $had_managed -eq 1 \
        && -f "$backup" ]]; then
      mv -f \
        "$backup" \
        "$MANAGED_SINGBOX_BIN"
    else
      rm -f "$MANAGED_SINGBOX_BIN"
    fi

    if [[ -n "$meta_backup" \
        && -f "$meta_backup" ]]; then
      mv -f \
        "$meta_backup" \
        "$SINGBOX_RELEASE_META"
    else
      rm -f "$SINGBOX_RELEASE_META"
    fi

    hash -r
    resolve_singbox_bin

    die "$(printf '%s' "sing-box 更新失败，已恢复更新前状态。")"
  fi

  if [[ $had_unit -eq 1 \
      && -f "$SINGBOX_CONFIG" \
      && $config_refresh -eq 0 ]]; then
    write_singbox_service

    if [[ $was_active -eq 1 ]]; then
      service_restart || true
    fi

    if [[ $was_active -eq 1 ]] \
        && ! wait_for_singbox_ready; then

      warn "$(printf '%s' "新版 sing-box 启动失败，正在回滚……")"

      if [[ $had_managed -eq 1 \
          && -f "$backup" ]]; then
        mv -f \
          "$backup" \
          "$MANAGED_SINGBOX_BIN"
      else
        rm -f "$MANAGED_SINGBOX_BIN"
      fi

      if [[ -n "$meta_backup" \
          && -f "$meta_backup" ]]; then
        mv -f \
          "$meta_backup" \
          "$SINGBOX_RELEASE_META"
      else
        rm -f "$SINGBOX_RELEASE_META"
      fi

      hash -r
      resolve_singbox_bin

      if [[ -n "$SINGBOX_BIN" ]]; then
        write_singbox_service

        if [[ $was_active -eq 1 ]]; then
          service_restart || true
        fi
      fi

      if [[ $was_active -eq 1 ]] \
          && ! wait_for_singbox_ready; then
        service_print_logs 80

        die "$(printf '%s' "新版启动失败，且旧版回滚后也未恢复，请检查日志。")"
      fi

      service_print_logs 40

      die "$(printf '%s' "sing-box 更新后启动失败，已成功恢复旧版本。")"
    fi
  fi

  rm -f \
    "$backup" \
    "$meta_backup"

  after="$(
    "$SINGBOX_BIN" version \
      2>/dev/null \
      | head -n 1 \
      || true
  )"

  print_kv "更新前：" "$before" 14
  print_kv "更新后：" "${after:-未知}" 14

  ok "$(printf '%s' "sing-box 已通过 GitHub Release SHA-256 摘要校验。")"
}

install_singbox_if_needed() {
  if [[ -x "$MANAGED_SINGBOX_BIN" ]]; then
    resolve_singbox_bin
    return 0
  fi

  info "$(printf '%s' "安装脚本专用 sing-box；不会覆盖系统包管理器维护的版本。")"

  install_or_update_singbox
}

install_or_update_cloudflared() {
  local asset_regex=""
  local arch=""
  local info_line=""
  local asset_name=""
  local asset_url=""
  local digest=""
  local release_tag=""
  local tmp_file=""
  local new_binary=""
  local backup=""
  local meta_backup=""
  local before=""
  local after=""
  local had_managed=0

  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_regex='^cloudflared-linux-amd64$'
      ;;

    aarch64|arm64)
      asset_regex='^cloudflared-linux-arm64$'
      ;;

    *)
      die "$(printf '%s' "暂不支持 CPU 架构：${arch}；当前脚本支持 amd64 与 arm64。")"
      ;;
  esac

  resolve_cloudflared_bin

  before="$(printf '%s' "未安装")"

  if [[ -n "$CLOUDFLARED_BIN" ]]; then
    before="$(
      "$CLOUDFLARED_BIN" --version \
        2>/dev/null \
        | head -n 1 \
        || true
    )"
  fi

  info "$(printf '%s' "查询 cloudflared 官方 GitHub 最新稳定版……")"

  info_line="$(
    github_latest_asset_info \
      "cloudflare/cloudflared" \
      "$asset_regex"
  )"

  IFS=$'\t' read -r \
    asset_name \
    asset_url \
    digest \
    release_tag \
    <<< "$info_line"

  [[ -n "$asset_name" \
    && -n "$asset_url" \
    && -n "$release_tag" ]] \
    || die "$(printf '%s' "cloudflared Release 信息不完整。")"

  tmp_file="$(mktemp)"

  if ! safe_download \
      "$asset_url" \
      "$tmp_file"; then
    rm -f "$tmp_file"

    die "$(printf '%s' "cloudflared 下载失败。")"
  fi

  verify_github_asset \
    "cloudflare/cloudflared" \
    "$asset_name" \
    "$asset_url" \
    "$digest" \
    "$tmp_file"

  chmod 0755 "$tmp_file"

  if ! cloudflared_version_ok "$tmp_file"; then
    if [[ "$INIT_SYSTEM" == "openrc" ]]; then
      ensure_alpine_binary_compat || true
    fi
  fi

  if ! cloudflared_version_ok "$tmp_file"; then
    print_binary_run_error "$tmp_file" --version
    rm -f "$tmp_file"

    die "$(printf '%s' "cloudflared 新二进制无法通过版本自检。")"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  new_binary="${MANAGED_CLOUDFLARED_BIN}.new.$$"
  backup="${MANAGED_CLOUDFLARED_BIN}.backup.$$"
  meta_backup="${CLOUDFLARED_RELEASE_META}.backup.$$"

  if [[ -x "$MANAGED_CLOUDFLARED_BIN" ]]; then
    cp -a \
      "$MANAGED_CLOUDFLARED_BIN" \
      "$backup"

    had_managed=1
  fi

  if [[ -f "$CLOUDFLARED_RELEASE_META" ]]; then
    cp -a \
      "$CLOUDFLARED_RELEASE_META" \
      "$meta_backup"
  fi

  install -m 0755 \
    "$tmp_file" \
    "$new_binary"

  rm -f "$tmp_file"

  mv -f \
    "$new_binary" \
    "$MANAGED_CLOUDFLARED_BIN"

  if ! write_release_metadata \
      "$CLOUDFLARED_RELEASE_META" \
      "cloudflare/cloudflared" \
      "$release_tag" \
      "$asset_name" \
      "$digest"; then

    warn "$(printf '%s' "cloudflared 元数据写入失败，正在回滚……")"

    if [[ $had_managed -eq 1 \
        && -f "$backup" ]]; then
      mv -f \
        "$backup" \
        "$MANAGED_CLOUDFLARED_BIN"
    else
      rm -f "$MANAGED_CLOUDFLARED_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f \
        "$meta_backup" \
        "$CLOUDFLARED_RELEASE_META"
    else
      rm -f "$CLOUDFLARED_RELEASE_META"
    fi

    die "$(printf '%s' "cloudflared 更新失败，已恢复旧版本。")"
  fi

  hash -r
  resolve_cloudflared_bin

  if [[ "$CLOUDFLARED_BIN" != "$MANAGED_CLOUDFLARED_BIN" ]] \
      || ! "$CLOUDFLARED_BIN" --version \
        >/dev/null 2>&1; then

    warn "$(printf '%s' "新版 cloudflared 安装后校验失败，正在回滚……")"

    if [[ $had_managed -eq 1 \
        && -f "$backup" ]]; then
      mv -f \
        "$backup" \
        "$MANAGED_CLOUDFLARED_BIN"
    else
      rm -f "$MANAGED_CLOUDFLARED_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f \
        "$meta_backup" \
        "$CLOUDFLARED_RELEASE_META"
    else
      rm -f "$CLOUDFLARED_RELEASE_META"
    fi

    hash -r
    resolve_cloudflared_bin

    die "$(printf '%s' "cloudflared 更新失败，已恢复旧版本。")"
  fi

  rm -f \
    "$backup" \
    "$meta_backup"

  after="$(
    "$CLOUDFLARED_BIN" --version \
      2>/dev/null \
      | head -n 1 \
      || true
  )"

  print_kv "更新前：" "$before" 14
  print_kv "更新后：" "${after:-未知}" 14

  ok "$(printf '%s' "cloudflared 已通过 GitHub Release SHA-256 摘要校验。")"
}

install_cloudflared_if_needed() {
  if [[ -x "$MANAGED_CLOUDFLARED_BIN" ]]; then
    resolve_cloudflared_bin
    return 0
  fi

  info "$(printf '%s' "安装脚本专用 cloudflared；不会覆盖系统包管理器维护的版本。")"

  install_or_update_cloudflared
}

install_or_update_wgcf() {
  local arch=""
  local asset_regex=""
  local info_line=""
  local asset_name=""
  local asset_url=""
  local digest=""
  local release_tag=""
  local tmp_file=""
  local new_binary=""
  local backup=""
  local meta_backup=""
  local before="未安装"
  local after=""
  local had_managed=0

  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_regex='^wgcf_[0-9][0-9.]*_linux_amd64$'
      ;;

    aarch64|arm64)
      asset_regex='^wgcf_[0-9][0-9.]*_linux_arm64$'
      ;;

    *)
      die "$(printf '%s' "暂不支持 CPU 架构：${arch}；wgcf 当前仅启用 amd64 与 arm64。")"
      ;;
  esac

  resolve_wgcf_bin

  if [[ -f "$WGCF_RELEASE_META" ]]; then
    before="$(jq -r '.tag // "未知"' "$WGCF_RELEASE_META" 2>/dev/null || printf '%s' "未知")"
  elif [[ -n "$WGCF_BIN" ]]; then
    before="已安装（外部版本）"
  fi

  info "查询 wgcf GitHub 最新稳定版……"

  info_line="$(
    github_latest_asset_info \
      "ViRb3/wgcf" \
      "$asset_regex"
  )"

  IFS=$'\t' read -r \
    asset_name \
    asset_url \
    digest \
    release_tag \
    <<< "$info_line"

  [[ -n "$asset_name" \
    && -n "$asset_url" \
    && -n "$release_tag" ]] \
    || die "wgcf Release 信息不完整。"

  tmp_file="$(mktemp)"

  if ! safe_download "$asset_url" "$tmp_file"; then
    rm -f "$tmp_file"
    die "wgcf 下载失败。"
  fi

  verify_github_asset \
    "ViRb3/wgcf" \
    "$asset_name" \
    "$asset_url" \
    "$digest" \
    "$tmp_file"

  chmod 0755 "$tmp_file"

  if ! wgcf_version_ok "$tmp_file"; then
    if [[ "$INIT_SYSTEM" == "openrc" ]]; then
      ensure_alpine_binary_compat || true
    fi
  fi

  if ! wgcf_version_ok "$tmp_file"; then
    print_binary_run_error "$tmp_file" --help
    rm -f "$tmp_file"
    die "wgcf 新二进制无法通过自检。"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  new_binary="${MANAGED_WGCF_BIN}.new.$$"
  backup="${MANAGED_WGCF_BIN}.backup.$$"
  meta_backup="${WGCF_RELEASE_META}.backup.$$"

  if [[ -x "$MANAGED_WGCF_BIN" ]]; then
    cp -a "$MANAGED_WGCF_BIN" "$backup"
    had_managed=1
  fi

  if [[ -f "$WGCF_RELEASE_META" ]]; then
    cp -a "$WGCF_RELEASE_META" "$meta_backup"
  fi

  install -m 0755 "$tmp_file" "$new_binary"
  rm -f "$tmp_file"
  mv -f "$new_binary" "$MANAGED_WGCF_BIN"

  if ! write_release_metadata \
      "$WGCF_RELEASE_META" \
      "ViRb3/wgcf" \
      "$release_tag" \
      "$asset_name" \
      "$digest"; then

    warn "wgcf 元数据写入失败，正在回滚……"

    if [[ $had_managed -eq 1 && -f "$backup" ]]; then
      mv -f "$backup" "$MANAGED_WGCF_BIN"
    else
      rm -f "$MANAGED_WGCF_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f "$meta_backup" "$WGCF_RELEASE_META"
    else
      rm -f "$WGCF_RELEASE_META"
    fi

    hash -r
    resolve_wgcf_bin
    die "wgcf 更新失败，已恢复旧版本。"
  fi

  hash -r
  resolve_wgcf_bin

  if [[ "$WGCF_BIN" != "$MANAGED_WGCF_BIN" ]] \
      || ! wgcf_version_ok "$MANAGED_WGCF_BIN"; then

    warn "wgcf 安装后校验失败，正在回滚……"

    if [[ $had_managed -eq 1 && -f "$backup" ]]; then
      mv -f "$backup" "$MANAGED_WGCF_BIN"
    else
      rm -f "$MANAGED_WGCF_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f "$meta_backup" "$WGCF_RELEASE_META"
    else
      rm -f "$WGCF_RELEASE_META"
    fi

    hash -r
    resolve_wgcf_bin
    die "wgcf 更新失败，已恢复旧版本。"
  fi

  rm -f "$backup" "$meta_backup"
  after="$release_tag"

  print_kv "更新前：" "$before" 14
  print_kv "更新后：" "$after" 14
  ok "wgcf 已通过 GitHub Release SHA-256 摘要校验。"
}

install_wgcf_if_needed() {
  if [[ -x "$MANAGED_WGCF_BIN" ]]; then
    resolve_wgcf_bin
    return 0
  fi

  info "安装脚本专用 wgcf；不会覆盖系统中由其他方式安装的同名程序。"
  install_or_update_wgcf
}


install_or_update_xray() {
  local arch=""
  local asset_regex=""
  local info_line=""
  local asset_name=""
  local asset_url=""
  local digest=""
  local release_tag=""
  local work=""
  local archive=""
  local extract_dir=""
  local list_file=""
  local candidate=""
  local new_binary=""
  local backup=""
  local before=""
  local after=""
  local meta_backup=""
  local had_managed=0
  local had_unit=0
  local was_active=0
  local -a xray_candidates=()

  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_regex='^Xray-linux-64\.zip$'
      ;;
    aarch64|arm64)
      asset_regex='^Xray-linux-arm64-v8a\.zip$'
      ;;
    *)
      die "暂不支持 CPU 架构：${arch}；当前 Xray 临时 Argo 仅支持 amd64 与 arm64。"
      ;;
  esac

  resolve_xray_bin
  before="未安装"
  if [[ -n "$XRAY_BIN" ]]; then
    before="$("$XRAY_BIN" version 2>/dev/null | head -n 1 || true)"
    [[ -n "$before" ]] || before="已安装"
  fi

  info "查询 XTLS/Xray-core 官方 GitHub 最新稳定版……"
  info_line="$(github_latest_asset_info "XTLS/Xray-core" "$asset_regex")"

  IFS=$'\t' read -r asset_name asset_url digest release_tag <<< "$info_line"
  [[ -n "$asset_name" && -n "$asset_url" && -n "$release_tag" ]] \
    || die "Xray Release 信息不完整。"

  work="$(mktemp -d)"
  archive="${work}/${asset_name}"
  extract_dir="${work}/extract"
  mkdir -p "$extract_dir"

  if ! safe_download "$asset_url" "$archive"; then
    rm -rf "$work"
    die "Xray 安装包下载失败。"
  fi

  verify_github_asset "XTLS/Xray-core" "$asset_name" "$asset_url" "$digest" "$archive"

  list_file="${work}/archive.list"
  if ! unzip -Z1 "$archive" > "$list_file"; then
    rm -rf "$work"
    die "无法读取 Xray zip 目录。"
  fi

  if grep -Eq '(^/|(^|/)\.\.(/|$))' "$list_file"; then
    rm -rf "$work"
    die "Xray zip 包含不安全路径，已拒绝安装。"
  fi

  if ! unzip -q "$archive" -d "$extract_dir"; then
    rm -rf "$work"
    die "Xray 解压失败。"
  fi

  while IFS= read -r -d '' candidate; do
    [[ -f "$candidate" ]] || continue
    chmod 0755 "$candidate" || true
    if xray_version_ok "$candidate"; then
      xray_candidates+=("$candidate")
    fi
  done < <(find "$extract_dir" -type f -name xray -print0)

  if [[ ${#xray_candidates[@]} -ne 1 ]]; then
    rm -rf "$work"
    die "Xray 安装包中未找到唯一可执行核心。"
  fi

  candidate="${xray_candidates[0]}"
  new_binary="${MANAGED_XRAY_BIN}.new.$$"
  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"
  install -m 0755 "$candidate" "$new_binary"

  if ! xray_version_ok "$new_binary"; then
    rm -f "$new_binary"
    rm -rf "$work"
    die "下载后的 Xray 无法运行。"
  fi

  if [[ -f "$XRAY_CONFIG" ]]; then
    if ! "$new_binary" run -test -config "$XRAY_CONFIG"; then
      warn "现有 Xray 配置未通过新核心校验；将继续安装核心，重建时会写入新配置。"
    fi
  fi

  had_managed=0
  had_unit=0
  was_active=0
  backup="${MANAGED_XRAY_BIN}.backup.$$"
  meta_backup="${XRAY_RELEASE_META}.backup.$$"

  if [[ -x "$MANAGED_XRAY_BIN" ]]; then
    had_managed=1
    cp -a "$MANAGED_XRAY_BIN" "$backup"
  fi
  if [[ -f "$XRAY_RELEASE_META" ]]; then
    cp -a "$XRAY_RELEASE_META" "$meta_backup" || true
  fi
  if [[ -e "$XRAY_UNIT" || -L "$XRAY_UNIT" ]]; then
    had_unit=1
  fi
  if xray_service_is_active; then
    was_active=1
  fi

  mv -f "$new_binary" "$MANAGED_XRAY_BIN"
  hash -r
  resolve_xray_bin

  if [[ $had_unit -eq 1 ]]; then
    write_xray_service
  fi

  if [[ $was_active -eq 1 ]]; then
    if ! xray_service_restart || ! wait_for_xray_ready; then
      warn "Xray 更新后启动失败，正在回滚旧核心。"
      [[ $had_managed -eq 1 && -f "$backup" ]] && mv -f "$backup" "$MANAGED_XRAY_BIN"
      [[ -f "$meta_backup" ]] && mv -f "$meta_backup" "$XRAY_RELEASE_META" || rm -f "$XRAY_RELEASE_META"
      hash -r
      resolve_xray_bin
      xray_service_restart || true
      rm -rf "$work"
      die "Xray 更新失败，已恢复旧版本。"
    fi
  fi

  if ! write_release_metadata "$XRAY_RELEASE_META" "XTLS/Xray-core" "$release_tag" "$asset_name" "$digest"; then
    warn "Xray 元数据写入失败，正在回滚。"
    [[ $had_managed -eq 1 && -f "$backup" ]] && mv -f "$backup" "$MANAGED_XRAY_BIN" || rm -f "$MANAGED_XRAY_BIN"
    [[ -f "$meta_backup" ]] && mv -f "$meta_backup" "$XRAY_RELEASE_META" || rm -f "$XRAY_RELEASE_META"
    hash -r
    resolve_xray_bin
    rm -rf "$work"
    die "Xray 更新失败，已恢复旧版本。"
  fi

  if [[ "$XRAY_BIN" != "$MANAGED_XRAY_BIN" ]] || ! xray_version_ok "$MANAGED_XRAY_BIN"; then
    warn "Xray 安装后校验失败，正在回滚。"
    [[ $had_managed -eq 1 && -f "$backup" ]] && mv -f "$backup" "$MANAGED_XRAY_BIN" || rm -f "$MANAGED_XRAY_BIN"
    [[ -f "$meta_backup" ]] && mv -f "$meta_backup" "$XRAY_RELEASE_META" || rm -f "$XRAY_RELEASE_META"
    hash -r
    resolve_xray_bin
    rm -rf "$work"
    die "Xray 更新失败，已恢复旧版本。"
  fi

  rm -f "$backup" "$meta_backup"
  rm -rf "$work"
  after="$release_tag"
  print_kv "更新前：" "$before" 14
  print_kv "更新后：" "$after" 14
  ok "Xray 已通过 GitHub Release SHA-256 摘要校验。"
}

install_xray_if_needed() {
  if [[ -x "$MANAGED_XRAY_BIN" ]]; then
    resolve_xray_bin
    return 0
  fi

  info "安装脚本专用 Xray；不会覆盖系统中由其他方式安装的同名程序。"
  install_or_update_xray
}

valid_uuid() {
  [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}

valid_ws_path() {
  [[ "$1" =~ ^/[A-Za-z0-9._~-]+$ ]]
}

valid_argo_host() {
  [[ -z "$1" \
    || "$1" =~ ^[a-z0-9-]+\.trycloudflare\.com$ ]]
}

valid_ipv4() {
  local value="$1"
  local a=""
  local b=""
  local c=""
  local d=""
  local extra=""
  local part=""

  IFS='.' read -r \
    a \
    b \
    c \
    d \
    extra \
    <<< "$value"

  [[ -z "${extra:-}" \
    && -n "${a:-}" \
    && -n "${b:-}" \
    && -n "${c:-}" \
    && -n "${d:-}" ]] \
    || return 1

  for part in "$a" "$b" "$c" "$d"; do
    [[ "$part" =~ ^[0-9]{1,3}$ ]] || return 1
    ((10#$part >= 0 && 10#$part <= 255)) || return 1
  done
}

valid_ipv6() {
  local value="$1"
  local left=""
  local right=""
  local compressed=0
  local units=0
  local part=""
  local index=0
  local -a left_parts=()
  local -a right_parts=()

  [[ -n "$value" && "$value" == *:* ]] || return 1
  [[ "$value" =~ ^[0-9A-Fa-f:.]+$ ]] || return 1
  [[ "$value" != *:::* ]] || return 1

  if [[ "$value" == *::* ]]; then
    compressed=1
    left="${value%%::*}"
    right="${value#*::}"
    [[ "$right" != *::* ]] || return 1
  else
    [[ "$value" != :* && "$value" != *: ]] || return 1
    left="$value"
  fi

  if [[ -n "$left" ]]; then
    [[ "$left" != :* && "$left" != *: ]] || return 1
    IFS=':' read -r -a left_parts <<< "$left"
  fi
  if [[ -n "$right" ]]; then
    [[ "$right" != :* && "$right" != *: ]] || return 1
    IFS=':' read -r -a right_parts <<< "$right"
  fi

  for ((index = 0; index < ${#left_parts[@]}; index++)); do
    part="${left_parts[index]}"
    [[ -n "$part" ]] || return 1

    if [[ "$part" == *.* ]]; then
      [[ $compressed -eq 0 && $index -eq $((${#left_parts[@]} - 1)) ]] || return 1
      valid_ipv4 "$part" || return 1
      ((units+=2))
    else
      [[ "$part" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
      ((units+=1))
    fi
  done

  for ((index = 0; index < ${#right_parts[@]}; index++)); do
    part="${right_parts[index]}"
    [[ -n "$part" ]] || return 1

    if [[ "$part" == *.* ]]; then
      [[ $index -eq $((${#right_parts[@]} - 1)) ]] || return 1
      valid_ipv4 "$part" || return 1
      ((units+=2))
    else
      [[ "$part" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
      ((units+=1))
    fi
  done

  if [[ $compressed -eq 1 ]]; then
    ((units < 8))
  else
    ((units == 8))
  fi
}


valid_ipv4_cidr() {
  local value="$1"
  local address=""
  local prefix=""

  [[ "$value" =~ ^([^/]+)/([0-9]{1,2})$ ]] || return 1
  address="${BASH_REMATCH[1]}"
  prefix="${BASH_REMATCH[2]}"

  valid_ipv4 "$address" || return 1
  ((10#$prefix >= 0 && 10#$prefix <= 32))
}

valid_ipv6_cidr() {
  local value="$1"
  local address=""
  local prefix=""

  [[ "$value" =~ ^([^/]+)/([0-9]{1,3})$ ]] || return 1
  address="${BASH_REMATCH[1]}"
  prefix="${BASH_REMATCH[2]}"

  valid_ipv6 "$address" || return 1
  ((10#$prefix >= 0 && 10#$prefix <= 128))
}

valid_local_port() {
  local value="$1"
  [[ "$value" =~ ^[0-9]{1,5}$ ]] || return 1
  ((10#$value >= 1024 && 10#$value <= 65535))
}

valid_node_name() {
  local value="$1"
  local width=""

  [[ -n "$value" ]] || return 1
  text_is_valid_utf8 "$value" || return 1

  [[ ${#value} -le 80 ]] || return 1

  if LC_ALL=C grep -q '[[:cntrl:]]' < <(printf '%s' "$value"); then
    return 1
  fi

  width="$(text_display_width "$value")"
  [[ "$width" =~ ^[0-9]+$ && "$width" -le 160 ]] || return 1

  return 0
}

valid_domain_name() {
  local value="${1%.}"
  local label=""
  local -a labels=()

  [[ -n "$value" \
    && ${#value} -le 253 \
    && "$value" == *.* ]] \
    || return 1

  [[ "$value" =~ ^[A-Za-z0-9.-]+$ ]] \
    || return 1

  IFS='.' read -r \
    -a labels \
    <<< "$value"

  for label in "${labels[@]}"; do
    [[ -n "$label" \
      && ${#label} -le 63 ]] \
      || return 1

    [[ "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] \
      || return 1
  done
}

normalize_preferred_endpoint() {
  local value="$1"
  local a=""
  local b=""
  local c=""
  local d=""

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  if [[ "$value" =~ ^\[(.*)\]$ ]]; then
    value="${BASH_REMATCH[1]}"
  fi

  if valid_ipv4 "$value"; then
    IFS='.' read -r \
      a \
      b \
      c \
      d \
      <<< "$value"

    value="$((10#$a)).$((10#$b)).$((10#$c)).$((10#$d))"
  elif valid_domain_name "$value"; then
    value="${value%.}"
    value="${value,,}"
  fi

  printf '%s' "$value"
}

valid_preferred_endpoint() {
  local value="$1"

  [[ -n "$value" \
    && "$value" != *[[:space:]]* \
    && ${#value} -le 253 ]] \
    || return 1

  if [[ "$value" =~ ^[0-9.]+$ ]]; then
    valid_ipv4 "$value"
    return
  fi

  valid_ipv6 "$value" \
    || valid_domain_name "$value"
}

valid_feature_flag() {
  [[ "$1" == "0" || "$1" == "1" ]]
}

feature_label() {
  if [[ "${1:-0}" == "1" ]]; then
    printf '%s' "已启用"
  else
    printf '%s' "未启用"
  fi
}

normalize_feature_flag() {
  case "${1,,}" in
    1|true|yes|y|on|enable|enabled)
      printf '%s' "1"
      ;;
    0|false|no|n|off|disable|disabled)
      printf '%s' "0"
      ;;
    *)
      return 1
      ;;
  esac
}

read_feature_choice() {
  local variable_name="$1"
  local label="$2"
  local current="$3"
  local input=""
  local normalized=""
  local hint="Y/n"

  [[ "$current" == "1" ]] || hint="y/N"

  while true; do
    read_interactive input "${label} [${hint}]：" "" || input=""

    if [[ -z "$input" ]]; then
      printf -v "$variable_name" '%s' "$current"
      return 0
    fi

    if normalized="$(normalize_feature_flag "$input" 2>/dev/null)"; then
      printf -v "$variable_name" '%s' "$normalized"
      return 0
    fi

    warn "请输入 yes/y 或 no/n；直接回车保留当前值。"
  done
}

valid_outbound_ip_mode() {
  [[ "$1" == "ipv4_only" || "$1" == "prefer_ipv4" ]]
}

normalize_outbound_ip_mode() {
  case "${1,,}" in
    ipv4_only|ipv4-only|only_ipv4|only-ipv4|1)
      printf '%s' "ipv4_only"
      ;;
    prefer_ipv4|prefer-ipv4|ipv4_prefer|ipv4-prefer|2)
      printf '%s' "prefer_ipv4"
      ;;
    *)
      return 1
      ;;
  esac
}

singbox_ip_strategy() {
  case "$OUTBOUND_IP_MODE" in
    ipv4_only)
      printf '%s' "ipv4_only"
      ;;
    prefer_ipv4)
      printf '%s' "prefer_ipv4"
      ;;
    *)
      die "出站策略无效：${OUTBOUND_IP_MODE}"
      ;;
  esac
}

xray_freedom_domain_strategy() {
  case "$OUTBOUND_IP_MODE" in
    ipv4_only)
      printf '%s' "UseIPv4"
      ;;
    prefer_ipv4)
      printf '%s' "UseIPv4v6"
      ;;
    *)
      die "出站策略无效：${OUTBOUND_IP_MODE}"
      ;;
  esac
}

xray_routing_domain_strategy() {
  printf '%s' "IPOnDemand"
}

outbound_ip_mode_label() {
  local mode="${1:-$OUTBOUND_IP_MODE}"

  case "$mode" in
    ipv4_only)
      printf '%s' "仅使用 IPv4"
      ;;
    prefer_ipv4)
      printf '%s' "IPv4 优先（可回退 IPv6）"
      ;;
    *)
      printf '%s' "未设置"
      ;;
  esac
}

read_outbound_ip_mode() {
  local variable_name="$1"
  local current="$2"
  local title="${3:-出站策略}"
  local input=""
  local normalized=""
  local current_label=""

  valid_outbound_ip_mode "$current" || current="$DEFAULT_OUTBOUND_IP_MODE"
  current_label="$(outbound_ip_mode_label "$current")"

  while true; do
    printf '\n%s\n' "${title}（当前：${current_label}）"
    printf '%s\n' "1. 仅使用 IPv4"
    printf '%s\n' "2. IPv4 优先，可回退 IPv6（默认）"
    read_interactive input \
      "请选择 [1-2，直接回车保留当前]：" \
      "" || input=""

    if [[ -z "$input" ]]; then
      printf -v "$variable_name" '%s' "$current"
      return 0
    fi

    if normalized="$(normalize_outbound_ip_mode "$input" 2>/dev/null)"; then
      printf -v "$variable_name" '%s' "$normalized"
      return 0
    fi

    warn "请输入 1（仅使用 IPv4）或 2（IPv4 优先，可回退 IPv6）。"
  done
}

infer_legacy_feature_settings() {
  DOH_ENABLED="0"
  WARP_ENABLED="0"

  [[ -f "$SINGBOX_CONFIG" ]] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  if jq -e '
      .dns.servers? // []
      | any(.tag == "cloudflare-doh" and .type == "https")
    ' "$SINGBOX_CONFIG" >/dev/null 2>&1; then
    DOH_ENABLED="1"
  fi

  if jq -e '
      .endpoints? // []
      | any(.tag == "warp" and .type == "wireguard")
    ' "$SINGBOX_CONFIG" >/dev/null 2>&1; then
    WARP_ENABLED="1"
  fi
}

load_settings() {
  local endpoint=""
  local xray_endpoint=""
  local port=""
  local node=""
  local doh=""
  local warp=""
  local ip_mode=""
  local invalid_file=""

  PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
  XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
  LOCAL_PORT="$DEFAULT_LOCAL_PORT"
  NODE_NAME="$DEFAULT_NODE_NAME"
  DOH_ENABLED="$DEFAULT_DOH_ENABLED"
  WARP_ENABLED="$DEFAULT_WARP_ENABLED"
  OUTBOUND_IP_MODE="$DEFAULT_OUTBOUND_IP_MODE"
  SETTINGS_CONFIGURED=0

  [[ -e "$SETTINGS_JSON" || -L "$SETTINGS_JSON" ]] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  if [[ ! -f "$SETTINGS_JSON" || -L "$SETTINGS_JSON" ]]; then
    warn "设置文件不是普通文件或属于符号链接，已忽略并恢复默认设置：${SETTINGS_JSON}"
    return 0
  fi

  if ! jq -e 'type == "object"' "$SETTINGS_JSON" >/dev/null 2>&1; then
    invalid_file="${SETTINGS_JSON}.invalid.$(date -u +%Y%m%dT%H%M%SZ).$$"
    if mv -- "$SETTINGS_JSON" "$invalid_file" 2>/dev/null; then
      chmod 600 "$invalid_file" 2>/dev/null || true
      warn "设置文件损坏，已隔离到 ${invalid_file}；当前恢复默认设置。"
    else
      warn "设置文件损坏且无法安全隔离；当前忽略该文件并恢复默认设置。"
    fi
    return 0
  fi

  endpoint="$(jq -r '.preferred_endpoint // ""' "$SETTINGS_JSON")"
  xray_endpoint="$(jq -r '.xray_preferred_endpoint // .preferred_endpoint // ""' "$SETTINGS_JSON")"
  port="$(jq -r '.local_port // ""' "$SETTINGS_JSON")"
  node="$(jq -r '.node_name // ""' "$SETTINGS_JSON")"
  doh="$(jq -r '.doh_enabled // ""' "$SETTINGS_JSON")"
  warp="$(jq -r '.warp_enabled // ""' "$SETTINGS_JSON")"
  ip_mode="$(jq -r '.outbound_ip_mode // ""' "$SETTINGS_JSON")"

  [[ -n "$port" ]] || port="$DEFAULT_LOCAL_PORT"
  [[ -n "$node" ]] || node="$DEFAULT_NODE_NAME"
  endpoint="$(normalize_preferred_endpoint "$endpoint")"
  xray_endpoint="$(normalize_preferred_endpoint "$xray_endpoint")"
  [[ -n "$ip_mode" ]] || ip_mode="$DEFAULT_OUTBOUND_IP_MODE"
  ip_mode="$(normalize_outbound_ip_mode "$ip_mode" 2>/dev/null || printf '%s' "invalid")"

  if [[ -z "$doh" || -z "$warp" ]]; then
    infer_legacy_feature_settings
    doh="$DOH_ENABLED"
    warp="$WARP_ENABLED"
  else
    doh="$(normalize_feature_flag "$doh" 2>/dev/null || printf '%s' "invalid")"
    warp="$(normalize_feature_flag "$warp" 2>/dev/null || printf '%s' "invalid")"
  fi

  if valid_preferred_endpoint "$endpoint" \
      && valid_preferred_endpoint "$xray_endpoint" \
      && valid_local_port "$port" \
      && valid_node_name "$node" \
      && valid_feature_flag "$doh" \
      && valid_feature_flag "$warp" \
      && valid_outbound_ip_mode "$ip_mode"; then
    PREFERRED_ENDPOINT="$endpoint"
    XRAY_PREFERRED_ENDPOINT="$xray_endpoint"
    LOCAL_PORT="$((10#$port))"
    NODE_NAME="$node"
    DOH_ENABLED="$doh"
    WARP_ENABLED="$warp"
    OUTBOUND_IP_MODE="$ip_mode"
    SETTINGS_CONFIGURED=1
  else
    warn "设置文件内容无效，当前恢复默认设置。"
  fi
}
save_settings() {
  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR" 2>/dev/null || true
  chmod 750 "$DATA_DIR"

  valid_preferred_endpoint "$PREFERRED_ENDPOINT" \
    || die "sing-box 优选域名/IP 格式无效。"
  valid_preferred_endpoint "$XRAY_PREFERRED_ENDPOINT" \
    || die "Xray 优选域名/IP 格式无效。"
  valid_local_port "$LOCAL_PORT" \
    || die "sing-box 本地端口无效；只允许 1024–65535。"
  valid_node_name "$NODE_NAME" \
    || die "订阅节点名称无效；不能为空、不能包含控制字符，且最多 80 个字符。"
  valid_feature_flag "$DOH_ENABLED" \
    || die "DoH 功能开关无效。"
  valid_feature_flag "$WARP_ENABLED" \
    || die "WARP 功能开关无效。"
  valid_outbound_ip_mode "$OUTBOUND_IP_MODE" \
    || die "出站策略无效。"

  local tmp=""
  tmp="$(mktemp "${DATA_DIR}/.settings.json.XXXXXX")"

  jq -n \
    --argjson schema 5 \
    --arg preferred_endpoint "$PREFERRED_ENDPOINT" \
    --arg xray_preferred_endpoint "$XRAY_PREFERRED_ENDPOINT" \
    --argjson local_port "$LOCAL_PORT" \
    --arg node_name "$NODE_NAME" \
    --argjson doh_enabled "$DOH_ENABLED" \
    --argjson warp_enabled "$WARP_ENABLED" \
    --arg outbound_ip_mode "$OUTBOUND_IP_MODE" \
    --arg updated_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    '{
      schema: $schema,
      preferred_endpoint: $preferred_endpoint,
      xray_preferred_endpoint: $xray_preferred_endpoint,
      local_port: $local_port,
      node_name: $node_name,
      doh_enabled: $doh_enabled,
      warp_enabled: $warp_enabled,
      outbound_ip_mode: $outbound_ip_mode,
      updated_at: $updated_at
    }' > "$tmp"

  chmod 600 "$tmp"
  mv -f "$tmp" "$SETTINGS_JSON"
  SETTINGS_CONFIGURED=1
}
configure_custom_settings() {
  local input=""
  local normalized=""

  load_settings

  printf '\n%s\n' "sing-box 自定义部署"
  printf '%s\n' "直接回车会保留方括号中的当前值。"

  while true; do
    read_interactive input \
      "sing-box 优选域名/IP [${PREFERRED_ENDPOINT}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$PREFERRED_ENDPOINT"
    normalized="$(normalize_preferred_endpoint "$input")"

    if valid_preferred_endpoint "$normalized"; then
      PREFERRED_ENDPOINT="$normalized"
      break
    fi
    warn "优选地址无效，请输入合法域名、IPv4 或 IPv6 地址。"
  done

  while true; do
    read_interactive input \
      "sing-box 本地端口 [${LOCAL_PORT}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$LOCAL_PORT"

    if valid_local_port "$input"; then
      LOCAL_PORT="$((10#$input))"
      break
    fi
    warn "端口无效，请输入 1024–65535 之间的整数。"
  done

  while true; do
    read_interactive input \
      "sing-box 节点名称 [${NODE_NAME}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$NODE_NAME"

    if valid_node_name "$input"; then
      NODE_NAME="$input"
      break
    fi
    warn "节点名称不能为空、不能包含控制字符，且最多 80 个字符。"
  done

  printf '\n%s\n' "sing-box 出站模块"
  read_feature_choice DOH_ENABLED \
    "启用 Cloudflare DoH（1.1.1.1）" \
    "$DOH_ENABLED"
  read_feature_choice WARP_ENABLED \
    "启用 Cloudflare WARP 出站" \
    "$WARP_ENABLED"

  if [[ "$WARP_ENABLED" == "1" ]]; then
    warn "首次启用 WARP 时，脚本会调用第三方 wgcf，并以 --accept-tos 非交互注册 Cloudflare WARP 设备。"
  fi

  read_outbound_ip_mode OUTBOUND_IP_MODE "$OUTBOUND_IP_MODE" "sing-box 出站策略"

  save_settings
  ok "sing-box 自定义设置已保存。"
}

configure_xray_custom_settings() {
  local input=""
  local normalized=""

  load_settings
  load_xray_state

  [[ -n "${XRAY_PREFERRED_ENDPOINT:-}" ]] || XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
  [[ -n "${XRAY_LOCAL_PORT:-}" ]] || XRAY_LOCAL_PORT="$DEFAULT_XRAY_LOCAL_PORT"
  [[ -n "${XRAY_NODE_NAME:-}" ]] || XRAY_NODE_NAME="$DEFAULT_XRAY_NODE_NAME"

  printf '\n%s\n' "Xray 自定义部署"
  printf '%s\n' "Xray 当前仅配置 VLESS-ENC / WS / TLS 直出。"
  printf '%s\n' "直接回车会保留方括号中的当前值。"

  while true; do
    read_interactive input \
      "Xray 优选域名/IP [${XRAY_PREFERRED_ENDPOINT}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$XRAY_PREFERRED_ENDPOINT"
    normalized="$(normalize_preferred_endpoint "$input")"

    if valid_preferred_endpoint "$normalized"; then
      XRAY_PREFERRED_ENDPOINT="$normalized"
      break
    fi
    warn "优选地址无效，请输入合法域名、IPv4 或 IPv6 地址。"
  done

  while true; do
    read_interactive input \
      "Xray 本地端口 [${XRAY_LOCAL_PORT}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$XRAY_LOCAL_PORT"

    if valid_local_port "$input"; then
      XRAY_LOCAL_PORT="$((10#$input))"
      break
    fi
    warn "端口无效，请输入 1024–65535 之间的整数。"
  done

  while true; do
    read_interactive input \
      "Xray 节点名称 [${XRAY_NODE_NAME}]：" \
      "" || input=""
    [[ -n "$input" ]] || input="$XRAY_NODE_NAME"

    if valid_node_name "$input"; then
      XRAY_NODE_NAME="$input"
      break
    fi
    warn "节点名称不能为空、不能包含控制字符，且最多 80 个字符。"
  done

  read_outbound_ip_mode OUTBOUND_IP_MODE "$OUTBOUND_IP_MODE" "Xray 出站策略"

  save_settings
  ok "Xray 自定义设置已保存。"
}
migrate_legacy_state() {
  [[ -f "$LEGACY_STATE_FILE" \
    && ! -f "$STATE_JSON" ]] \
    || return 0

  local old_uuid=""
  local old_path=""
  local old_host=""

  old_uuid="$(
    sed -n \
      "s/^UUID='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  old_path="$(
    sed -n \
      "s/^WSPATH='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  old_host="$(
    sed -n \
      "s/^ARGO_HOST='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  if valid_uuid "$old_uuid" \
      && valid_ws_path "$old_path" \
      && valid_argo_host "$old_host"; then

    UUID="$old_uuid"
    WSPATH="$old_path"
    ARGO_HOST="$old_host"
    CREATED_AT="$(
      date -u +'%Y-%m-%dT%H:%M:%SZ'
    )"

    save_state

    mv -f \
      "$LEGACY_STATE_FILE" \
      "${LEGACY_STATE_FILE}.migrated"

    ok "$(printf '%s' "已将旧版 state.env 安全迁移为 state.json。")"
  else
    warn "$(printf '%s' "发现旧版 state.env，但内容校验失败；不会执行该文件。")"

    mv -f \
      "$LEGACY_STATE_FILE" \
      "${LEGACY_STATE_FILE}.invalid"
  fi
}

load_state() {
  UUID=""
  WSPATH=""
  ARGO_HOST=""
  CREATED_AT=""

  migrate_legacy_state

  [[ -f "$STATE_JSON" ]] || return 0

  jq -e \
    'type == "object"' \
    "$STATE_JSON" \
    >/dev/null 2>&1 \
    || die "$(printf '%s' "状态文件损坏：${STATE_JSON}")"

  UUID="$(
    jq -r \
      '.uuid // ""' \
      "$STATE_JSON"
  )"

  WSPATH="$(
    jq -r \
      '.ws_path // ""' \
      "$STATE_JSON"
  )"

  ARGO_HOST="$(
    jq -r \
      '.argo_host // ""' \
      "$STATE_JSON"
  )"

  CREATED_AT="$(
    jq -r \
      '.created_at // ""' \
      "$STATE_JSON"
  )"

  valid_uuid "$UUID" \
    || die "$(printf '%s' "状态文件中的 UUID 无效：${STATE_JSON}")"

  valid_ws_path "$WSPATH" \
    || die "$(printf '%s' "状态文件中的 WS 路径无效：${STATE_JSON}")"

  valid_argo_host "$ARGO_HOST" \
    || die "$(printf '%s' "状态文件中的临时域名无效：${STATE_JSON}")"
}

save_state() {
  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR" 2>/dev/null || true
  chmod 750 "$DATA_DIR"

  if [[ -z "$CREATED_AT" ]]; then
    CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  fi

  local tmp=""
  tmp="$(mktemp "${DATA_DIR}/.state.json.XXXXXX")"

  jq -n \
    --argjson schema 2 \
    --arg uuid "$UUID" \
    --arg ws_path "$WSPATH" \
    --arg argo_host "$ARGO_HOST" \
    --arg created_at "$CREATED_AT" \
    --arg updated_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    '{
      schema: $schema,
      uuid: $uuid,
      ws_path: $ws_path,
      argo_host: $argo_host,
      created_at: $created_at,
      updated_at: $updated_at
    }' > "$tmp"

  chmod 600 "$tmp"
  mv -f "$tmp" "$STATE_JSON"
}

generate_uuid_v4() {
  local hex=""

  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
    return 0
  fi

  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
    return 0
  fi

  hex="$(openssl rand -hex 16)"

  [[ ${#hex} -eq 32 ]] || return 1

  printf '%s-%s-4%s-8%s-%s\n' \
    "${hex:0:8}" \
    "${hex:8:4}" \
    "${hex:13:3}" \
    "${hex:17:3}" \
    "${hex:20:12}"
}

generate_identity() {
  UUID="$(generate_uuid_v4)" \
    || die "UUID 生成失败。"

  valid_uuid "$UUID" \
    || die "生成的 UUID 未通过格式校验。"

  WSPATH="/$(openssl rand -hex 16)-vmws"
  ARGO_HOST=""
  CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

  rm -f "$VMESS_JSON_FILE" "$VMESS_LINK_FILE" "$ECH_NOTE_FILE"
  save_state
}

service_marker_is_ours() {
  local content=""
  local line_count=""

  [[ "$SERVICE_HOME" == "/var/lib/zdd-argo" ]] || return 1
  [[ "$SERVICE_MARKER" == "${SERVICE_HOME}/.managed-by-zdd-argo" ]] || return 1
  secure_root_file "$SERVICE_MARKER" || return 1

  IFS= read -r content < "$SERVICE_MARKER" || return 1
  [[ "$content" == "$SERVICE_MARKER_CONTENT" ]] || return 1

  line_count="$(wc -l < "$SERVICE_MARKER" 2>/dev/null | tr -d '[:space:]' || true)"
  [[ "$line_count" == "1" ]]
}

service_marker_is_legacy_ours() {
  local content=""
  local line_count=""

  [[ "$SERVICE_HOME" == "/var/lib/zdd-argo" ]] || return 1
  [[ "$SERVICE_MARKER" == "${SERVICE_HOME}/.managed-by-zdd-argo" ]] || return 1
  secure_root_file "$SERVICE_MARKER" || return 1

  IFS= read -r content < "$SERVICE_MARKER" || return 1
  [[ "$content" == "zdd-argo 管理的低权限服务账户" ]] || return 1

  line_count="$(wc -l < "$SERVICE_MARKER" 2>/dev/null | tr -d '[:space:]' || true)"
  [[ "$line_count" == "1" ]]
}

service_marker_is_recognized() {
  service_marker_is_ours || service_marker_is_legacy_ours
}


ensure_service_account() {
  local passwd_line=""
  local existing_home=""
  local existing_gid=""
  local expected_gid=""
  local existing_shell=""
  local marker_tmp=""
  local path=""

  for path in "$SERVICE_HOME" "$CLOUDFLARED_HOME" "$XRAY_CLOUDFLARED_HOME" "$DATA_DIR"; do
    if [[ -e "$path" || -L "$path" ]]; then
      [[ -d "$path" && ! -L "$path" ]] \
        || die "受管目录不是普通目录或属于符号链接，已停止部署：${path}"
    fi
  done

  if getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    service_marker_is_recognized \
      || die "系统中已存在同名服务账户 ${SERVICE_USER}，但无法通过完整归属校验，已停止部署。"

    passwd_line="$(getent passwd "$SERVICE_USER")"
    IFS=':' read -r _ _ _ existing_gid _ existing_home existing_shell <<< "$passwd_line"
    expected_gid="$(getent group "$SERVICE_GROUP" | awk -F: '{print $3}')"

    [[ "$existing_home" == "$SERVICE_HOME" ]] \
      || die "服务账户 ${SERVICE_USER} 的主目录异常，已停止部署。"
    [[ -n "$expected_gid" && "$existing_gid" == "$expected_gid" ]] \
      || die "服务账户 ${SERVICE_USER} 的主组异常，已停止部署。"
    [[ "$existing_shell" == "$SERVICE_SHELL" \
      || "$existing_shell" == "/usr/sbin/nologin" \
      || "$existing_shell" == "/sbin/nologin" \
      || "$existing_shell" == "/bin/false" ]] \
      || die "服务账户 ${SERVICE_USER} 的登录 Shell 异常，已停止部署。"
  else
    if getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
      service_marker_is_recognized \
        || die "系统中已存在同名服务组 ${SERVICE_GROUP}，但无法通过完整归属校验，已停止部署。"
    else
      groupadd --system "$SERVICE_GROUP" \
        || die "无法创建低权限服务组 ${SERVICE_GROUP}。"
    fi

    useradd --system \
      --gid "$SERVICE_GROUP" \
      --home-dir "$SERVICE_HOME" \
      --create-home \
      --shell "$SERVICE_SHELL" \
      "$SERVICE_USER" \
      || die "无法创建低权限服务账户 ${SERVICE_USER}。"
  fi

  mkdir -p "$SERVICE_HOME" "$CLOUDFLARED_HOME" "$XRAY_CLOUDFLARED_HOME" "$DATA_DIR"
  chown root:root "$SERVICE_HOME"
  chmod 755 "$SERVICE_HOME"
  chown "$SERVICE_USER:$SERVICE_GROUP" "$CLOUDFLARED_HOME" "$XRAY_CLOUDFLARED_HOME"
  chmod 700 "$CLOUDFLARED_HOME" "$XRAY_CLOUDFLARED_HOME"
  chown root:"$SERVICE_GROUP" "$DATA_DIR"
  chmod 750 "$DATA_DIR"

  marker_tmp="$(mktemp "${SERVICE_HOME}/.managed-by-zdd-argo.XXXXXX")"
  printf '%s\n' "$SERVICE_MARKER_CONTENT" > "$marker_tmp"
  chown root:root "$marker_tmp"
  chmod 600 "$marker_tmp"
  mv -f -- "$marker_tmp" "$SERVICE_MARKER"

  service_marker_is_ours \
    || die "低权限服务账户归属标记写入后校验失败。"
}

valid_warp_account_file() {
  [[ -f "$WARP_ACCOUNT_FILE" \
    && ! -L "$WARP_ACCOUNT_FILE" \
    && -s "$WARP_ACCOUNT_FILE" ]]
}

valid_warp_profile_file() {
  [[ -f "$WARP_PROFILE_FILE" \
    && ! -L "$WARP_PROFILE_FILE" \
    && -s "$WARP_PROFILE_FILE" ]] \
    || return 1

  grep -Eq '^[[:space:]]*PrivateKey[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*Address[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*PublicKey[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*Endpoint[[:space:]]*=' "$WARP_PROFILE_FILE"
}

ensure_warp_profile() {
  [[ "$WARP_ENABLED" == "1" ]] || return 0

  mkdir -p "$WARP_DIR"
  chown root:root "$WARP_DIR"
  chmod 700 "$WARP_DIR"

  install_wgcf_if_needed
  [[ -n "$WGCF_BIN" ]] || die "未找到 wgcf。"

  if ! valid_warp_account_file; then
    rm -f "$WARP_ACCOUNT_FILE" "$WARP_PROFILE_FILE" "$WARP_CHECK_FILE"
    warn "正在注册新的 Cloudflare WARP 设备；wgcf 是第三方非官方工具。"

    if ! "$WGCF_BIN" \
        --config "$WARP_ACCOUNT_FILE" \
        register \
        --accept-tos; then
      rm -f "$WARP_ACCOUNT_FILE" "$WARP_PROFILE_FILE"
      die "Cloudflare WARP 设备注册失败。"
    fi
  fi

  local profile_tmp=""
  profile_tmp="$(mktemp "${WARP_DIR}/.wgcf-profile.conf.XXXXXX")"

  if ! "$WGCF_BIN" \
      --config "$WARP_ACCOUNT_FILE" \
      generate \
      --profile "$profile_tmp"; then
    rm -f "$profile_tmp"
    die "Cloudflare WARP WireGuard 配置生成失败。"
  fi

  chmod 600 "$WARP_ACCOUNT_FILE" "$profile_tmp"

  if ! valid_warp_account_file; then
    rm -f "$profile_tmp"
    die "wgcf 未生成有效的 WARP 账户文件。"
  fi

  if ! grep -Eq '^[[:space:]]*PrivateKey[[:space:]]*=' "$profile_tmp" \
      || ! grep -Eq '^[[:space:]]*Address[[:space:]]*=' "$profile_tmp" \
      || ! grep -Eq '^[[:space:]]*PublicKey[[:space:]]*=' "$profile_tmp" \
      || ! grep -Eq '^[[:space:]]*Endpoint[[:space:]]*=' "$profile_tmp"; then
    rm -f "$profile_tmp"
    die "wgcf 未生成有效的 WireGuard 配置。"
  fi

  mv -f "$profile_tmp" "$WARP_PROFILE_FILE"
  chmod 600 "$WARP_ACCOUNT_FILE" "$WARP_PROFILE_FILE"
  ok "Cloudflare WARP 设备与 WireGuard 配置已重新生成并覆盖。"
}

strip_ini_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

warp_profile_value() {
  local key="$1"
  local value=""

  value="$(
    awk -F '=' -v wanted="$key" '
      $1 ~ "^[[:space:]]*" wanted "[[:space:]]*$" {
        sub(/^[^=]*=/, "")
        print
        exit
      }
    ' "$WARP_PROFILE_FILE"
  )"

  strip_ini_value "$value"
}

load_warp_profile_parameters() {
  local address_line=""
  local item=""
  local endpoint=""
  local endpoint_host=""
  local mtu=""
  local checked_endpoint=""
  local checked_port=""

  ensure_warp_profile
  valid_warp_profile_file || die "WARP WireGuard 配置不存在或格式不完整。"

  WARP_PRIVATE_KEY="$(warp_profile_value PrivateKey)"
  WARP_PEER_PUBLIC_KEY="$(warp_profile_value PublicKey)"
  address_line="$(warp_profile_value Address)"
  endpoint="$(warp_profile_value Endpoint)"
  mtu="$(warp_profile_value MTU)"

  WARP_IPV4=""
  WARP_IPV6=""
  WARP_ENDPOINT_ADDRESS=""

  while IFS= read -r item; do
    item="$(strip_ini_value "$item")"
    [[ -n "$item" ]] || continue

    if [[ "$item" == *.*/* ]]; then
      WARP_IPV4="$item"
    elif [[ "$item" == *:*/* ]]; then
      WARP_IPV6="$item"
    fi
  done < <(printf '%s\n' "$address_line" | tr ',' '\n')

  [[ "$WARP_PRIVATE_KEY" =~ ^[A-Za-z0-9+/]{43}=$ ]] \
    || die "WARP 私钥格式无效。"
  [[ "$WARP_PEER_PUBLIC_KEY" =~ ^[A-Za-z0-9+/]{43}=$ ]] \
    || die "WARP 对端公钥格式无效。"
  valid_ipv4_cidr "$WARP_IPV4" \
    || die "WARP IPv4 地址格式无效。"
  valid_ipv6_cidr "$WARP_IPV6" \
    || die "WARP IPv6 地址格式无效。"

  if [[ "$endpoint" =~ ^\[([^]]+)\]:([0-9]{1,5})$ ]]; then
    endpoint_host="${BASH_REMATCH[1]}"
    WARP_PROFILE_ENDPOINT_PORT="${BASH_REMATCH[2]}"
  elif [[ "$endpoint" =~ ^([^:]+):([0-9]{1,5})$ ]]; then
    endpoint_host="${BASH_REMATCH[1]}"
    WARP_PROFILE_ENDPOINT_PORT="${BASH_REMATCH[2]}"
  else
    die "WARP Endpoint 格式无效：${endpoint}"
  fi

  ((10#$WARP_PROFILE_ENDPOINT_PORT >= 1 && 10#$WARP_PROFILE_ENDPOINT_PORT <= 65535)) \
    || die "WARP Endpoint 端口无效。"

  WARP_PROFILE_ENDPOINT_PORT="$((10#$WARP_PROFILE_ENDPOINT_PORT))"
  WARP_ENDPOINT_PORT="$WARP_PROFILE_ENDPOINT_PORT"

  if ! valid_ipv4 "$endpoint_host" \
      && ! valid_ipv6 "$endpoint_host" \
      && ! valid_domain_name "$endpoint_host"; then
    die "WARP Endpoint 地址无效：${endpoint_host}"
  fi

  WARP_ENDPOINT_ADDRESS="${endpoint_host%.}"
  WARP_ENDPOINT_ADDRESS="${WARP_ENDPOINT_ADDRESS,,}"

  if [[ -f "$WARP_CHECK_FILE" && ! -L "$WARP_CHECK_FILE" ]]; then
    checked_endpoint="$(jq -r '.endpoint // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
    checked_port="$(jq -r '.port // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"

    if [[ "${checked_endpoint,,}" == "$WARP_ENDPOINT_ADDRESS" \
        && "$checked_port" =~ ^[0-9]{1,5}$ ]] \
        && ((10#$checked_port >= 1 && 10#$checked_port <= 65535)); then
      WARP_ENDPOINT_PORT="$((10#$checked_port))"
    fi
  fi

  if [[ "$mtu" =~ ^[0-9]{3,5}$ ]] \
      && ((10#$mtu >= 576 && 10#$mtu <= 9000)); then
    WARP_MTU="$((10#$mtu))"
  else
    WARP_MTU="1280"
  fi
}

singbox_template_base() {
  jq -n \
    --arg name "$NODE_NAME" \
    --arg uuid "$UUID" \
    --arg path "$WSPATH" \
    --arg ip_strategy "$(singbox_ip_strategy)" \
    --argjson port "$LOCAL_PORT" \
    '{
      log: {
        level: "info",
        timestamp: true
      },
      inbounds: [
        {
          type: "vmess",
          tag: "vmess-ws-in",
          listen: "127.0.0.1",
          listen_port: $port,
          users: [
            {
              name: $name,
              uuid: $uuid,
              alterId: 0
            }
          ],
          transport: {
            type: "ws",
            path: $path
          }
        }
      ],
      dns: {
        servers: [
          {
            type: "local",
            tag: "local-dns"
          }
        ],
        final: "local-dns",
        strategy: $ip_strategy
      },
      outbounds: [
        {
          type: "direct",
          tag: "direct"
        }
      ],
      route: {
        rules: [
          {
            inbound: ["vmess-ws-in"],
            action: "resolve",
            strategy: $ip_strategy
          },
          {
            ip_is_private: true,
            action: "reject",
            method: "drop"
          },
          {
            ip_cidr: [
              "169.254.169.254/32",
              "100.100.100.200/32"
            ],
            action: "reject",
            method: "drop"
          }
        ],
        final: "direct",
        default_domain_resolver: {
          server: "local-dns",
          strategy: $ip_strategy
        }
      }
    }'
}

singbox_template_direct() {
  singbox_template_base
}

singbox_template_doh() {
  singbox_template_base \
    | jq --arg ip_strategy "$(singbox_ip_strategy)" '
      .dns = {
        servers: [
          {
            type: "https",
            tag: "cloudflare-doh",
            server: "1.1.1.1",
            server_port: 443,
            path: "/dns-query",
            tls: {
              enabled: true,
              server_name: "cloudflare-dns.com"
            }
          }
        ],
        final: "cloudflare-doh",
        strategy: $ip_strategy
      }
      | .route.default_domain_resolver = {
          server: "cloudflare-doh",
          strategy: $ip_strategy
        }
    '
}

singbox_template_warp() {
  singbox_template_base \
    | jq \
      --arg ip_strategy "$(singbox_ip_strategy)" \
      --arg private_key "$WARP_PRIVATE_KEY" \
      --arg ipv4 "$WARP_IPV4" \
      --arg ipv6 "$WARP_IPV6" \
      --arg peer_address "$WARP_ENDPOINT_ADDRESS" \
      --argjson peer_port "$WARP_ENDPOINT_PORT" \
      --arg public_key "$WARP_PEER_PUBLIC_KEY" \
      --argjson mtu "$WARP_MTU" \
      '
        .dns = {
          servers: [
            {
              type: "local",
              tag: "local-dns",
              prefer_go: true
            },
            {
              type: "https",
              tag: "warp-bootstrap-doh",
              server: "1.1.1.1",
              server_port: 443,
              path: "/dns-query",
              tls: {
                enabled: true,
                server_name: "cloudflare-dns.com"
              }
            }
          ],
          final: "local-dns",
          strategy: $ip_strategy
        }
        | .endpoints = [
            {
              type: "wireguard",
              tag: "warp",
              system: false,
              mtu: $mtu,
              address: [$ipv4, $ipv6],
              private_key: $private_key,
              peers: [
                {
                  address: $peer_address,
                  port: $peer_port,
                  public_key: $public_key,
                  allowed_ips: ["0.0.0.0/0", "::/0"],
                  persistent_keepalive_interval: 30
                }
              ],
              udp_timeout: "5m",
              connect_timeout: "10s",
              domain_resolver: {
                server: "warp-bootstrap-doh",
                strategy: $ip_strategy
              }
            }
          ]
        | .route.default_domain_resolver = {
            server: "local-dns",
            strategy: $ip_strategy
          }
        | .route.final = "warp"
      '
}

singbox_template_doh_warp() {
  singbox_template_base \
    | jq \
      --arg ip_strategy "$(singbox_ip_strategy)" \
      --arg private_key "$WARP_PRIVATE_KEY" \
      --arg ipv4 "$WARP_IPV4" \
      --arg ipv6 "$WARP_IPV6" \
      --arg peer_address "$WARP_ENDPOINT_ADDRESS" \
      --argjson peer_port "$WARP_ENDPOINT_PORT" \
      --arg public_key "$WARP_PEER_PUBLIC_KEY" \
      --argjson mtu "$WARP_MTU" \
      '
        .dns = {
          servers: [
            {
              type: "https",
              tag: "warp-bootstrap-doh",
              server: "1.1.1.1",
              server_port: 443,
              path: "/dns-query",
              tls: {
                enabled: true,
                server_name: "cloudflare-dns.com"
              }
            },
            {
              type: "https",
              tag: "cloudflare-doh",
              server: "1.1.1.1",
              server_port: 443,
              path: "/dns-query",
              tls: {
                enabled: true,
                server_name: "cloudflare-dns.com"
              },
              detour: "warp"
            }
          ],
          final: "cloudflare-doh",
          strategy: $ip_strategy
        }
        | .endpoints = [
            {
              type: "wireguard",
              tag: "warp",
              system: false,
              mtu: $mtu,
              address: [$ipv4, $ipv6],
              private_key: $private_key,
              peers: [
                {
                  address: $peer_address,
                  port: $peer_port,
                  public_key: $public_key,
                  allowed_ips: ["0.0.0.0/0", "::/0"],
                  persistent_keepalive_interval: 30
                }
              ],
              udp_timeout: "5m",
              connect_timeout: "10s",
              domain_resolver: {
                server: "warp-bootstrap-doh",
                strategy: $ip_strategy
              }
            }
          ]
        | .route.default_domain_resolver = {
            server: "cloudflare-doh",
            strategy: $ip_strategy
          }
        | .route.final = "warp"
      '
}

write_singbox_config() {
  [[ -n "$SINGBOX_BIN" ]] || resolve_singbox_bin
  [[ -n "$SINGBOX_BIN" ]] || die "未找到 sing-box。"

  valid_uuid "$UUID" || die "UUID 为空或格式错误。"
  valid_ws_path "$WSPATH" || die "WS 路径为空或格式错误。"
  valid_local_port "$LOCAL_PORT" || die "本地监听端口无效。"
  valid_node_name "$NODE_NAME" || die "节点名称无效。"
  valid_feature_flag "$DOH_ENABLED" || die "DoH 功能开关无效。"
  valid_feature_flag "$WARP_ENABLED" || die "WARP 功能开关无效。"
  valid_outbound_ip_mode "$OUTBOUND_IP_MODE" || die "出站策略无效。"

  if [[ "$WARP_ENABLED" == "1" ]]; then
    load_warp_profile_parameters
  else
    rm -f "$WARP_CHECK_FILE"
  fi

  local tmp=""
  local expected_sha=""
  local actual_sha=""
  local expected_ip_strategy=""
  tmp="$(mktemp "${DATA_DIR}/.sing-box.json.XXXXXX")"
  expected_ip_strategy="$(singbox_ip_strategy)"

  case "${DOH_ENABLED}:${WARP_ENABLED}" in
    0:0)
      singbox_template_direct > "$tmp"
      ;;
    1:0)
      singbox_template_doh > "$tmp"
      ;;
    0:1)
      singbox_template_warp > "$tmp"
      ;;
    1:1)
      singbox_template_doh_warp > "$tmp"
      ;;
    *)
      rm -f "$tmp"
      die "无法选择 sing-box 配置模板。"
      ;;
  esac

  jq -e \
    --arg name "$NODE_NAME" \
    --arg uuid "$UUID" \
    --arg path "$WSPATH" \
    --arg ip_strategy "$expected_ip_strategy" \
    --argjson port "$LOCAL_PORT" \
    '(.inbounds | type == "array" and length == 1)
      and (.inbounds[0].type == "vmess")
      and (.inbounds[0].tag == "vmess-ws-in")
      and (.inbounds[0].listen == "127.0.0.1")
      and (.inbounds[0].listen_port == $port)
      and (.inbounds[0].users | type == "array" and length == 1)
      and (.inbounds[0].users[0].name == $name)
      and (.inbounds[0].users[0].uuid == $uuid)
      and (.inbounds[0].users[0].alterId == 0)
      and (.inbounds[0].transport.type == "ws")
      and (.inbounds[0].transport.path == $path)
      and any((.outbounds // [])[]?; .type == "direct" and .tag == "direct")
      and (.dns.strategy == $ip_strategy)
      and (.route.default_domain_resolver.strategy == $ip_strategy)
      and any((.route.rules // [])[]?;
        .action == "resolve"
        and (.inbound // []) == ["vmess-ws-in"]
        and .strategy == $ip_strategy)
      and any((.route.rules // [])[]?;
        .ip_is_private == true
        and .action == "reject"
        and .method == "drop")
      and any((.route.rules // [])[]?;
        .action == "reject"
        and .method == "drop"
        and ((.ip_cidr // []) | index("169.254.169.254/32") != null)
        and ((.ip_cidr // []) | index("100.100.100.200/32") != null))
      and ([.. | objects | select(has("domain_strategy"))] | length == 0)' \
    "$tmp" >/dev/null \
    || { rm -f "$tmp"; die "生成的 sing-box 配置未通过通用结构自检。"; }

  case "${DOH_ENABLED}:${WARP_ENABLED}" in
    0:0)
      jq -e '
        (.route.final == "direct")
        and (.dns.final == "local-dns")
        and (.route.default_domain_resolver.server == "local-dns")
        and any((.dns.servers // [])[]?;
          .tag == "local-dns" and .type == "local")
        and ((.endpoints // []) | length == 0)
      ' "$tmp" >/dev/null \
        || { rm -f "$tmp"; die "直接出站模板写入结果不符合预期。"; }
      ;;
    1:0)
      jq -e '
        (.route.final == "direct")
        and (.dns.final == "cloudflare-doh")
        and (.route.default_domain_resolver.server == "cloudflare-doh")
        and any((.dns.servers // [])[]?;
          .tag == "cloudflare-doh"
          and .type == "https"
          and .server == "1.1.1.1"
          and .server_port == 443
          and .path == "/dns-query"
          and .tls.enabled == true
          and .tls.server_name == "cloudflare-dns.com"
          and (has("detour") | not))
        and ((.endpoints // []) | length == 0)
      ' "$tmp" >/dev/null \
        || { rm -f "$tmp"; die "DoH 模板写入结果不符合预期。"; }
      ;;
    0:1)
      jq -e \
        --arg private_key "$WARP_PRIVATE_KEY" \
        --arg ipv4 "$WARP_IPV4" \
        --arg ipv6 "$WARP_IPV6" \
        --arg peer_address "$WARP_ENDPOINT_ADDRESS" \
        --argjson peer_port "$WARP_ENDPOINT_PORT" \
        --arg public_key "$WARP_PEER_PUBLIC_KEY" \
        --argjson mtu "$WARP_MTU" \
        --arg ip_strategy "$expected_ip_strategy" \
        '(.route.final == "warp")
          and (.dns.final == "local-dns")
          and (.route.default_domain_resolver.server == "local-dns")
          and any((.dns.servers // [])[]?;
            .tag == "local-dns"
            and .type == "local"
            and .prefer_go == true)
          and any((.dns.servers // [])[]?;
            .tag == "warp-bootstrap-doh"
            and .type == "https"
            and .server == "1.1.1.1"
            and .server_port == 443
            and .path == "/dns-query"
            and .tls.enabled == true
            and .tls.server_name == "cloudflare-dns.com")
          and any((.endpoints // [])[]?;
            .tag == "warp"
            and .type == "wireguard"
            and .system == false
            and .mtu == $mtu
            and .address == [$ipv4, $ipv6]
            and .private_key == $private_key
            and .domain_resolver.server == "warp-bootstrap-doh"
            and .domain_resolver.strategy == $ip_strategy
            and any((.peers // [])[]?;
              .address == $peer_address
              and .port == $peer_port
              and .public_key == $public_key
              and .allowed_ips == ["0.0.0.0/0", "::/0"]
              and .persistent_keepalive_interval == 30))' \
        "$tmp" >/dev/null \
        || { rm -f "$tmp"; die "WARP 模板写入结果不符合预期。"; }
      ;;
    1:1)
      jq -e \
        --arg private_key "$WARP_PRIVATE_KEY" \
        --arg ipv4 "$WARP_IPV4" \
        --arg ipv6 "$WARP_IPV6" \
        --arg peer_address "$WARP_ENDPOINT_ADDRESS" \
        --argjson peer_port "$WARP_ENDPOINT_PORT" \
        --arg public_key "$WARP_PEER_PUBLIC_KEY" \
        --argjson mtu "$WARP_MTU" \
        --arg ip_strategy "$expected_ip_strategy" \
        '(.route.final == "warp")
          and (.dns.final == "cloudflare-doh")
          and (.route.default_domain_resolver.server == "cloudflare-doh")
          and any((.dns.servers // [])[]?;
            .tag == "warp-bootstrap-doh"
            and .type == "https"
            and .server == "1.1.1.1"
            and .server_port == 443
            and .path == "/dns-query"
            and .tls.enabled == true
            and .tls.server_name == "cloudflare-dns.com"
            and (has("detour") | not))
          and any((.dns.servers // [])[]?;
            .tag == "cloudflare-doh"
            and .type == "https"
            and .server == "1.1.1.1"
            and .server_port == 443
            and .path == "/dns-query"
            and .tls.enabled == true
            and .tls.server_name == "cloudflare-dns.com"
            and .detour == "warp")
          and any((.endpoints // [])[]?;
            .tag == "warp"
            and .type == "wireguard"
            and .system == false
            and .mtu == $mtu
            and .address == [$ipv4, $ipv6]
            and .private_key == $private_key
            and .domain_resolver.server == "warp-bootstrap-doh"
            and .domain_resolver.strategy == $ip_strategy
            and any((.peers // [])[]?;
              .address == $peer_address
              and .port == $peer_port
              and .public_key == $public_key
              and .allowed_ips == ["0.0.0.0/0", "::/0"]
              and .persistent_keepalive_interval == 30))' \
        "$tmp" >/dev/null \
        || { rm -f "$tmp"; die "DoH + WARP 模板写入结果不符合预期。"; }
      ;;
  esac

  chmod 640 "$tmp"
  chown root:"$SERVICE_GROUP" "$tmp"

  if ! "$SINGBOX_BIN" check -c "$tmp"; then
    rm -f "$tmp"

    if [[ "$DOH_ENABLED" == "1" || "$WARP_ENABLED" == "1" ]]; then
      die "新 sing-box 配置校验失败；请先通过菜单 6 更新组件，再重试 DoH/WARP 部署。"
    fi

    die "新 sing-box 配置校验失败。"
  fi

  expected_sha="$(sha256sum "$tmp" | awk '{print $1}')"

  mv -f "$tmp" "$SINGBOX_CONFIG"
  chmod 640 "$SINGBOX_CONFIG"
  chown root:"$SERVICE_GROUP" "$SINGBOX_CONFIG"

  actual_sha="$(sha256sum "$SINGBOX_CONFIG" | awk '{print $1}')"
  [[ -n "$expected_sha" && "$actual_sha" == "$expected_sha" ]] \
    || die "sing-box 配置覆盖后摘要不一致。"

  "$SINGBOX_BIN" check -c "$SINGBOX_CONFIG" \
    || die "已覆盖的 sing-box 配置未通过二次校验。"
}

singbox_config_needs_refresh() {
  [[ -f "$SINGBOX_CONFIG" && ! -L "$SINGBOX_CONFIG" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1

  jq -e \
    '([.. | objects | select(has("domain_strategy"))] | length > 0)
      or ((.dns // null) == null)
      or ((.route.default_domain_resolver // null) == null)
      or ([.route.rules[]? | select(.action == "resolve")] | length == 0)
      or any((.outbounds // [])[]?; .type == "wireguard")' \
    "$SINGBOX_CONFIG" >/dev/null 2>&1
}

find_free_loopback_port() {
  local port=0

  for ((port = 18080; port <= 18179; port++)); do
    if ! ss -ltn 2>/dev/null \
        | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${port}([[:space:]]|$)"; then
      printf '%s\n' "$port"
      return 0
    fi
  done

  return 1
}

stop_checked_process() {
  local pid="$1"
  local recorded_start="$2"
  local actual_start=""
  local i=0

  [[ "$pid" =~ ^[0-9]+$ ]] || return 0
  [[ "$recorded_start" =~ ^[0-9]+$ ]] || return 0

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  [[ "$actual_start" == "$recorded_start" ]] || return 0

  kill -TERM "$pid" 2>/dev/null || true

  for ((i = 0; i < 5; i++)); do
    actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
    if [[ "$actual_start" != "$recorded_start" ]]; then
      wait "$pid" 2>/dev/null || true
      return 0
    fi
    sleep 1
  done

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  if [[ "$actual_start" == "$recorded_start" ]]; then
    kill -KILL "$pid" 2>/dev/null || true
  fi
  wait "$pid" 2>/dev/null || true
}

valid_warp_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]{1,5}$ ]] || return 1
  ((10#$port >= 1 && 10#$port <= 65535))
}

warp_candidate_ports() {
  local port=""
  local seen=""

  for port in \
    "$WARP_ENDPOINT_PORT" \
    "$WARP_PROFILE_ENDPOINT_PORT" \
    2408 \
    500 \
    1701 \
    4500
  do
    valid_warp_port "$port" || continue
    port="$((10#$port))"

    case " ${seen} " in
      *" ${port} "*)
        continue
        ;;
    esac

    printf '%s\n' "$((10#$port))"
    seen="${seen} ${port}"
  done
}

set_warp_peer_port() {
  local port="$1"
  local tmp=""
  local expected_sha=""
  local actual_sha=""

  valid_warp_port "$port" || return 1
  [[ -f "$SINGBOX_CONFIG" && ! -L "$SINGBOX_CONFIG" ]] || return 1
  [[ -n "$SINGBOX_BIN" ]] || return 1

  tmp="$(mktemp "${DATA_DIR}/.sing-box-port.json.XXXXXX")"

  if ! jq \
      --argjson port "$((10#$port))" \
      '
        (.endpoints[] | select(.type == "wireguard" and .tag == "warp") | .peers[0].port) = $port
      ' \
      "$SINGBOX_CONFIG" \
      > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  chmod 640 "$tmp"
  chown root:"$SERVICE_GROUP" "$tmp"

  if ! "$SINGBOX_BIN" check -c "$tmp"; then
    rm -f "$tmp"
    return 1
  fi

  if ! jq -e \
      --argjson port "$((10#$port))" \
      '
        (.endpoints // [])
        | any(
            .type == "wireguard"
            and .tag == "warp"
            and .peers[0].port == $port
          )
      ' \
      "$tmp" \
      >/dev/null; then
    rm -f "$tmp"
    return 1
  fi

  expected_sha="$(sha256sum "$tmp" | awk '{print $1}')"

  mv -f "$tmp" "$SINGBOX_CONFIG"
  chmod 640 "$SINGBOX_CONFIG"
  chown root:"$SERVICE_GROUP" "$SINGBOX_CONFIG"

  actual_sha="$(sha256sum "$SINGBOX_CONFIG" | awk '{print $1}')"
  [[ -n "$expected_sha" && "$actual_sha" == "$expected_sha" ]] || return 1

  "$SINGBOX_BIN" check -c "$SINGBOX_CONFIG" || return 1

  WARP_ENDPOINT_PORT="$((10#$port))"
  return 0
}

verify_warp_runtime() {
  [[ "$WARP_ENABLED" == "1" ]] || return 0

  local test_port=""
  local test_config=""
  local test_log=""
  local test_pid=""
  local test_start=""
  local response=""
  local warp_state=""
  local exit_ip=""
  local colo=""
  local selected_port=""
  local attempted_ports=""
  local chain_label="VMess/WS → WARP"
  local port=""
  local i=0
  local -a candidate_ports=()

  if [[ "$DOH_ENABLED" == "1" ]]; then
    chain_label="VMess/WS → DoH → WARP"
  fi

  service_is_active \
    || die "WARP 自检前发现 sing-box 服务未运行。"
  listener_exact_loopback \
    || die "WARP 自检前发现 127.0.0.1:${LOCAL_PORT} 未监听。"

  mapfile -t candidate_ports < <(warp_candidate_ports)
  ((${#candidate_ports[@]} > 0)) \
    || die "没有可用于 WARP 自检的 Endpoint UDP 端口。"

  test_port="$(find_free_loopback_port)" \
    || die "无法找到用于 WARP 本机自检的空闲回环端口。"

  test_config="$(mktemp "${DATA_DIR}/.warp-client-check.json.XXXXXX")"
  test_log="$(mktemp "${DATA_DIR}/.warp-client-check.log.XXXXXX")"

  jq -n \
    --arg uuid "$UUID" \
    --arg path "$WSPATH" \
    --argjson server_port "$LOCAL_PORT" \
    --argjson listen_port "$test_port" \
    '{
      log: {
        level: "debug",
        timestamp: true
      },
      inbounds: [
        {
          type: "mixed",
          tag: "warp-check-in",
          listen: "127.0.0.1",
          listen_port: $listen_port
        }
      ],
      outbounds: [
        {
          type: "vmess",
          tag: "local-vmess-check",
          server: "127.0.0.1",
          server_port: $server_port,
          uuid: $uuid,
          security: "auto",
          alter_id: 0,
          transport: {
            type: "ws",
            path: $path
          }
        }
      ],
      route: {
        final: "local-vmess-check"
      }
    }' > "$test_config"

  chmod 600 "$test_config"

  "$SINGBOX_BIN" check -c "$test_config" \
    || {
      rm -f "$test_config" "$test_log"
      die "WARP 自检客户端配置未通过 sing-box 校验。"
    }

  "$SINGBOX_BIN" run -c "$test_config" \
    > "$test_log" 2>&1 &
  test_pid=$!
  test_start="$(process_start_time "$test_pid" 2>/dev/null || true)"

  if [[ ! "$test_start" =~ ^[0-9]+$ ]]; then
    kill -TERM "$test_pid" 2>/dev/null || true
    wait "$test_pid" 2>/dev/null || true
    rm -f "$test_config" "$test_log"
    die "无法确认 WARP 自检客户端进程身份。"
  fi

  for ((i = 1; i <= 15; i++)); do
    if ss -ltn 2>/dev/null \
        | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${test_port}([[:space:]]|$)"; then
      break
    fi

    if [[ "$(process_start_time "$test_pid" 2>/dev/null || true)" != "$test_start" ]]; then
      break
    fi

    sleep 1
  done

  if [[ "$(process_start_time "$test_pid" 2>/dev/null || true)" != "$test_start" ]] \
      || ! ss -ltn 2>/dev/null \
        | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${test_port}([[:space:]]|$)"; then
    warn "WARP 自检客户端未能正常启动，日志如下："
    tail -n 100 "$test_log" >&2 || true
    stop_checked_process "$test_pid" "$test_start"
    rm -f "$test_config" "$test_log"
    die "WARP 运行时自检客户端启动失败。"
  fi

  for port in "${candidate_ports[@]}"; do
    if [[ -n "$attempted_ports" ]]; then
      attempted_ports="${attempted_ports},${port}"
    else
      attempted_ports="$port"
    fi

    printf '\n===== WARP Endpoint UDP %s =====\n' "$port" >> "$test_log"
    info "正在测试 WARP Endpoint：${WARP_ENDPOINT_ADDRESS}:${port}/UDP"

    if ! set_warp_peer_port "$port"; then
      warn "无法将 WARP Endpoint 端口切换为 UDP ${port}，跳过该端口。"
      continue
    fi

    if ! service_restart; then
      warn "切换到 UDP ${port} 后 sing-box 重启失败，跳过该端口。"
      service_print_logs 40
      continue
    fi

    if ! wait_for_singbox_ready; then
      warn "切换到 UDP ${port} 后 sing-box 未能正常监听，跳过该端口。"
      service_print_logs 40
      continue
    fi

    response=""
    warp_state=""
    exit_ip=""
    colo=""

    for ((i = 1; i <= 2; i++)); do
      response="$(
        curl \
          --silent \
          --show-error \
          --max-time 15 \
          --connect-timeout 5 \
          --proxy "socks5h://127.0.0.1:${test_port}" \
          https://www.cloudflare.com/cdn-cgi/trace \
          2>> "$test_log" \
          || true
      )"

      warp_state="$(
        printf '%s\n' "$response" \
          | tr -d '\r' \
          | awk -F= '$1 == "warp" {print $2; exit}'
      )"

      if [[ "$warp_state" == "on" || "$warp_state" == "plus" ]]; then
        selected_port="$port"
        break
      fi

      sleep 1
    done

    if [[ -n "$selected_port" ]]; then
      exit_ip="$(
        printf '%s\n' "$response" \
          | tr -d '\r' \
          | awk -F= '$1 == "ip" {print $2; exit}'
      )"
      colo="$(
        printf '%s\n' "$response" \
          | tr -d '\r' \
          | awk -F= '$1 == "colo" {print $2; exit}'
      )"
      break
    fi

    warn "WARP Endpoint UDP ${port} 未通过实际链路自检。"
  done

  stop_checked_process "$test_pid" "$test_start"
  rm -f "$test_config"

  if [[ -z "$selected_port" ]]; then
    warn "已依次测试 WARP WireGuard 的配置端口及 Cloudflare 官方回退端口，均未确认隧道可用。"
    printf '\n%s\n' "WARP 自检客户端日志：" >&2
    tail -n 200 "$test_log" >&2 || true
    printf '\n%s\n' "当前 sing-box 服务日志：" >&2
    service_print_logs 160
    rm -f "$test_log" "$WARP_CHECK_FILE"
    die "WARP 实际链路不可用；常见原因是 VPS 提供商阻断 UDP 2408/500/1701/4500、到 Cloudflare WARP 网段路由异常，或该网络限制 WireGuard。"
  fi

  rm -f "$test_log"

  jq -n \
    --arg checked_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg warp "$warp_state" \
    --arg ip "$exit_ip" \
    --arg colo "$colo" \
    --arg endpoint "$WARP_ENDPOINT_ADDRESS" \
    --arg attempted_ports "$attempted_ports" \
    --argjson port "$selected_port" \
    --argjson profile_port "$WARP_PROFILE_ENDPOINT_PORT" \
    '{
      checked_at: $checked_at,
      warp: $warp,
      exit_ip: $ip,
      colo: $colo,
      endpoint: $endpoint,
      port: $port,
      profile_port: $profile_port,
      attempted_ports: $attempted_ports
    }' > "$WARP_CHECK_FILE"

  chmod 600 "$WARP_CHECK_FILE"
  WARP_ENDPOINT_PORT="$selected_port"
  ok "WARP 实际链路自检通过：${chain_label}，Endpoint=${WARP_ENDPOINT_ADDRESS}:${selected_port}/UDP，warp=${warp_state}，出口=${exit_ip:-未知}，机房=${colo:-未知}。"
}

singbox_unit_is_ours() {
  [[ -f "$SINGBOX_UNIT" && ! -L "$SINGBOX_UNIT" ]] || return 1

  case "$INIT_SYSTEM" in
    systemd)
      grep -Fqx "Description=zdd-argo dedicated sing-box service managed-v0.1.0" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "User=${SERVICE_USER}" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "Group=${SERVICE_GROUP}" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "ExecStart=${MANAGED_SINGBOX_BIN} run -c ${SINGBOX_CONFIG}" "$SINGBOX_UNIT" 2>/dev/null
      ;;
    openrc)
      grep -Fqx 'zdd_argo_managed="0.1.0"' "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command=\"${MANAGED_SINGBOX_BIN}\"" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command_args=\"run -c ${SINGBOX_CONFIG}\"" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command_user=\"${SERVICE_USER}:${SERVICE_GROUP}\"" "$SINGBOX_UNIT" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

singbox_unit_is_legacy_ours() {
  [[ -f "$SINGBOX_UNIT" && ! -L "$SINGBOX_UNIT" ]] || return 1

  case "$INIT_SYSTEM" in
    systemd)
      grep -Fq "zdd-argo" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "User=${SERVICE_USER}" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "Group=${SERVICE_GROUP}" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "ExecStart=${MANAGED_SINGBOX_BIN} run -c ${SINGBOX_CONFIG}" "$SINGBOX_UNIT" 2>/dev/null
      ;;
    openrc)
      grep -Fq "zdd-argo" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command=\"${MANAGED_SINGBOX_BIN}\"" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command_args=\"run -c ${SINGBOX_CONFIG}\"" "$SINGBOX_UNIT" 2>/dev/null \
        && grep -Fqx "command_user=\"${SERVICE_USER}:${SERVICE_GROUP}\"" "$SINGBOX_UNIT" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

write_singbox_service() {
  [[ -n "$SINGBOX_BIN" ]] || die "未找到 sing-box 可执行文件。"
  [[ "$SINGBOX_BIN" == "$MANAGED_SINGBOX_BIN" ]] \
    || die "当前 sing-box 不是脚本专用二进制，拒绝写入受管服务。"
  ensure_service_account

  if [[ -e "$SINGBOX_UNIT" || -L "$SINGBOX_UNIT" ]]; then
    singbox_unit_is_ours || singbox_unit_is_legacy_ours \
      || die "服务路径已被其他程序占用：${SINGBOX_UNIT}"
  fi

  local tmp=""
  tmp="$(mktemp)"

  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    cat > "$tmp" <<EOF
[Unit]
Description=zdd-argo dedicated sing-box service managed-v0.1.0
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
ExecStart=${MANAGED_SINGBOX_BIN} run -c ${SINGBOX_CONFIG}
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576
NoNewPrivileges=true
UMask=0077
CapabilityBoundingSet=
AmbientCapabilities=
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
LockPersonality=true
RestrictSUIDSGID=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
EOF

    install -m 0644 "$tmp" "$SINGBOX_UNIT"
  elif [[ "$INIT_SYSTEM" == "openrc" ]]; then
    printf '%s\n' '#!/sbin/openrc-run' > "$tmp"
    cat >> "$tmp" <<EOF
zdd_argo_managed="0.1.0"
name="zdd-argo 专用 sing-box 服务"
description="zdd-argo dedicated sing-box service"
command="${MANAGED_SINGBOX_BIN}"
command_args="run -c ${SINGBOX_CONFIG}"
command_user="${SERVICE_USER}:${SERVICE_GROUP}"
pidfile="/run/${SERVICE_NAME}.pid"
supervisor="supervise-daemon"
respawn_delay=3
respawn_max=0
output_log="${SINGBOX_LOG_FILE}"
error_log="${SINGBOX_LOG_FILE}"

depend() {
  use net
}

start_pre() {
  checkpath -d -m 0750 -o root:${SERVICE_GROUP} "${DATA_DIR}"
  checkpath -f -m 0640 -o root:${SERVICE_GROUP} "${SINGBOX_CONFIG}"
  checkpath -f -m 0640 -o ${SERVICE_USER}:${SERVICE_GROUP} "${SINGBOX_LOG_FILE}"
}
EOF

    install -m 0755 "$tmp" "$SINGBOX_UNIT"
  else
    rm -f "$tmp"
    die "无法识别服务管理器，不能写入服务文件。"
  fi

  rm -f "$tmp"
  service_daemon_reload
}

render_logrotate_config() {
  cat <<EOF
${LOG_FILE} ${XRAY_LOG_FILE} ${SINGBOX_LOG_FILE} ${XRAY_CORE_LOG_FILE} {
    size 5M
    rotate 3
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su root root
}
EOF
}

logrotate_config_is_ours() {
  local expected=""
  local actual=""

  [[ -f "$LOGROTATE_CONFIG" && ! -L "$LOGROTATE_CONFIG" ]] || return 1
  expected="$(render_logrotate_config)"
  actual="$(cat "$LOGROTATE_CONFIG" 2>/dev/null || true)"
  [[ "$actual" == "$expected" ]]
}

logrotate_config_is_legacy_ours() {
  local actual=""
  local legacy=""

  [[ -f "$LOGROTATE_CONFIG" && ! -L "$LOGROTATE_CONFIG" ]] || return 1

  actual="$(cat "$LOGROTATE_CONFIG" 2>/dev/null || true)"
  legacy="$(cat <<EOF
${LOG_FILE} ${SINGBOX_LOG_FILE} {
    size 5M
    rotate 3
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su root root
}
EOF
)"

  [[ "$actual" == "$legacy" ]] && return 0

  grep -Fqx '# 由 zdd-argo v0.1.0 管理' "$LOGROTATE_CONFIG" 2>/dev/null \
    && { \
      grep -Fqx "${LOG_FILE} ${XRAY_LOG_FILE} ${SINGBOX_LOG_FILE} ${XRAY_CORE_LOG_FILE} {" "$LOGROTATE_CONFIG" 2>/dev/null \
        || grep -Fqx "${LOG_FILE} ${SINGBOX_LOG_FILE} {" "$LOGROTATE_CONFIG" 2>/dev/null; \
    } \
    && grep -Fqx "    copytruncate" "$LOGROTATE_CONFIG" 2>/dev/null
}

write_logrotate_config() {
  if [[ -e "$LOGROTATE_CONFIG" || -L "$LOGROTATE_CONFIG" ]]; then
    logrotate_config_is_ours || logrotate_config_is_legacy_ours \
      || die "日志轮转配置路径已被其他程序占用：${LOGROTATE_CONFIG}"
  fi

  local tmp=""
  tmp="$(mktemp)"
  mkdir -p "$(dirname -- "$LOGROTATE_CONFIG")"

  render_logrotate_config > "$tmp"

  install -m 0644 "$tmp" "$LOGROTATE_CONFIG"
  rm -f "$tmp"
}

ss_listen_tcp_lines() {
  ss -ltn \
    2>/dev/null
}

ss_listen_tcp_process_lines() {
  ss -ltnp \
    2>/dev/null
}

listener_on_local_port() {
  ss_listen_tcp_lines \
    | grep -Eq "(^|[[:space:]])[^[:space:]]*:${LOCAL_PORT}([[:space:]]|$)"
}

listener_exact_loopback() {
  ss_listen_tcp_lines \
    | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${LOCAL_PORT}([[:space:]]|$)"
}

listener_exact_loopback_pid() {
  local line=""
  local pid=""

  line="$(
    ss_listen_tcp_process_lines \
      | grep -E "(^|[[:space:]])127[.]0[.]0[.]1:${LOCAL_PORT}([[:space:]]|$)" \
      | head -n 1 \
      || true
  )"

  [[ -n "$line" ]] || return 1

  pid="$(
    printf '%s\n' "$line" \
      | grep -Eo 'pid=[0-9]+' \
      | head -n 1 \
      | cut -d= -f2 \
      || true
  )"

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "$pid"
}

listener_process_matches_singbox() {
  local pid=""
  local cmdline=""

  pid="$(listener_exact_loopback_pid 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1

  cmdline="$(process_command_line "$pid" 2>/dev/null || true)"
  [[ -n "$cmdline" ]] || return 1

  [[ "$cmdline" == *"${SINGBOX_CONFIG}"* ]] || return 1

  [[ "$cmdline" == *"sing-box"* \
    || ( -n "$SINGBOX_BIN" && "$cmdline" == *"${SINGBOX_BIN}"* ) \
    || "$cmdline" == *"${MANAGED_SINGBOX_BIN}"* ]]
}

wait_for_singbox_ready() {
  local i=0

  for ((i = 1; i <= 15; i++)); do
    if service_is_active \
        && listener_exact_loopback; then
      return 0
    fi

    if [[ "$INIT_SYSTEM" == "openrc" ]] \
        && listener_exact_loopback; then
      return 0
    fi

    sleep 1
  done

  return 1
}

ensure_singbox_running() {
  if listener_on_local_port \
      && ! service_is_active; then

    if [[ "$INIT_SYSTEM" == "openrc" ]] \
        && listener_exact_loopback \
        && listener_process_matches_singbox; then

      service_enable \
        || warn "$(printf '%s' "OpenRC 状态未同步，且暂时无法启用 ${SERVICE_NAME}；继续使用当前已监听的 sing-box。")"

      warn "$(printf '%s' "检测到 sing-box 已监听 127.0.0.1:${LOCAL_PORT}，但 OpenRC 状态尚未同步；按已就绪处理。")"
      return 0
    fi

    warn "$(printf '%s' "端口 ${LOCAL_PORT} 已被其他进程占用：")"

    ss_listen_tcp_process_lines \
      | grep -E \
        "(^|:)${LOCAL_PORT}[[:space:]]" \
      || true

    die "$(printf '%s' "为避免覆盖其他服务，已停止部署。")"
  fi

  service_enable \
    || die "$(printf '%s' "无法启用 ${SERVICE_NAME}。")"

  service_restart \
    || die "$(printf '%s' "无法重启 ${SERVICE_NAME}，拒绝继续使用可能仍在运行的旧配置。")"

  if ! wait_for_singbox_ready; then
    service_print_logs 80

    die "$(printf '%s' "${SERVICE_NAME} 未能在 15 秒内进入正常状态，或本机未监听 127.0.0.1:${LOCAL_PORT}；这不是 NAT 外部端口占用问题。")"
  fi
}

write_cloudflared_runner() {
  [[ -n "$CLOUDFLARED_BIN" ]] || die "未找到 cloudflared。"
  ensure_service_account

  local service_uid=""
  local service_gid=""
  local tmp=""

  service_uid="$(id -u "$SERVICE_USER")"
  service_gid="$(id -g "$SERVICE_USER")"
  [[ "$service_uid" =~ ^[0-9]+$ && "$service_gid" =~ ^[0-9]+$ ]] \
    || die "无法读取低权限服务账户的 UID/GID。"

  tmp="$(mktemp)"

  printf '%s\n' '#!/usr/bin/env bash' > "$tmp"
  cat >> "$tmp" <<EOF
set -Eeuo pipefail
IFS=\$'\\n\\t'
umask 077

export HOME="${CLOUDFLARED_HOME}"
CF_PID=""
CF_START=""

process_start_time() {
  local pid="\$1"
  local stat_line=""
  local remainder=""
  local start_time=""
  local -a fields=()

  [[ "\$pid" =~ ^[0-9]+\$ ]] || return 1
  [[ -r "/proc/\${pid}/stat" ]] || return 1
  IFS= read -r stat_line < "/proc/\${pid}/stat" || return 1
  [[ "\$stat_line" == *") "* ]] || return 1
  remainder="\${stat_line##*) }"
  IFS=' ' read -r -a fields <<< "\$remainder"
  [[ \${#fields[@]} -ge 20 ]] || return 1
  start_time="\${fields[19]}"
  [[ "\$start_time" =~ ^[0-9]+\$ ]] || return 1
  printf '%s\\n' "\$start_time"
}

identity_matches() {
  local pid="\$1"
  local recorded_start="\$2"
  local actual_start=""

  actual_start="\$(process_start_time "\$pid" 2>/dev/null || true)"
  [[ -n "\$actual_start" && "\$actual_start" == "\$recorded_start" ]]
}

signal_verified() {
  local signal_name="\$1"
  local pid="\$2"
  local recorded_start="\$3"

  identity_matches "\$pid" "\$recorded_start" || return 0
  kill "-\${signal_name}" "\$pid" 2>/dev/null || true
}

cleanup() {
  local rc=\$?
  local i=0

  trap - EXIT HUP INT TERM

  if [[ -n "\${CF_PID}" && -n "\${CF_START}" ]]; then
    signal_verified TERM "\${CF_PID}" "\${CF_START}"

    for ((i = 0; i < 8; i++)); do
      identity_matches "\${CF_PID}" "\${CF_START}" || break
      sleep 1
    done

    signal_verified KILL "\${CF_PID}" "\${CF_START}"
    wait "\${CF_PID}" 2>/dev/null || true
  fi

  rm -f "${CLOUDFLARED_PID_FILE}"
  exit "\$rc"
}

trap cleanup EXIT HUP INT TERM

if [[ "${INIT_SYSTEM}" == "openrc" ]]; then
  su-exec ${service_uid}:${service_gid} \
    "${CLOUDFLARED_BIN}" tunnel \
      --url "http://127.0.0.1:${LOCAL_PORT}" \
      --protocol http2 \
      > >(tee -a "${LOG_FILE}") 2>&1 &
else
  setpriv \
    --reuid=${service_uid} \
    --regid=${service_gid} \
    --clear-groups \
    --no-new-privs \
    -- \
    "${CLOUDFLARED_BIN}" tunnel \
      --url "http://127.0.0.1:${LOCAL_PORT}" \
      --protocol http2 \
      > >(tee -a "${LOG_FILE}") 2>&1 &
fi

CF_PID=\$!
CF_START="\$(process_start_time "\${CF_PID}" 2>/dev/null || true)"

if [[ ! "\${CF_START}" =~ ^[0-9]+\$ ]]; then
  wait "\${CF_PID}" 2>/dev/null || true
  exit 1
fi

printf '%s %s\\n' "\${CF_PID}" "\${CF_START}" > "${CLOUDFLARED_PID_FILE}"
chmod 600 "${CLOUDFLARED_PID_FILE}"
wait "\${CF_PID}"
EOF

  install -m 0700 "$tmp" "$CLOUDFLARED_RUNNER"
  rm -f "$tmp"
}

tmux_session_exists() {
  tmux has-session \
    -t "$TMUX_SESSION" \
    2>/dev/null
}

legacy_tmux_session_exists() {
  [[ "$LEGACY_TMUX_SESSION" != "$TMUX_SESSION" ]] || return 1
  tmux has-session \
    -t "$LEGACY_TMUX_SESSION" \
    2>/dev/null
}

tmux_session_has_runner() {
  local session="$1"
  local runner="$2"

  tmux has-session -t "$session" 2>/dev/null || return 1
  tmux list-panes \
    -t "$session" \
    -F '#{pane_start_command}' \
    2>/dev/null \
    | grep -Fq "$runner"
}

active_tunnel_session() {
  if tmux_session_has_runner "$TMUX_SESSION" "$CLOUDFLARED_RUNNER"; then
    printf '%s\n' "$TMUX_SESSION"
    return 0
  fi

  if tmux_session_has_runner "$LEGACY_TMUX_SESSION" "$CLOUDFLARED_RUNNER"; then
    printf '%s\n' "$LEGACY_TMUX_SESSION"
    return 0
  fi

  return 1
}

tunnel_is_running() {
  active_tunnel_session >/dev/null
}

read_cloudflared_pid() {
  local pid=""
  local recorded_start=""
  local extra=""

  [[ -r "$CLOUDFLARED_PID_FILE" && ! -L "$CLOUDFLARED_PID_FILE" ]] || return 1
  IFS=' ' read -r pid recorded_start extra < "$CLOUDFLARED_PID_FILE" || return 1
  [[ "$pid" =~ ^[0-9]+$ && "$recorded_start" =~ ^[0-9]+$ && -z "$extra" ]] || return 1
  printf '%s %s\n' "$pid" "$recorded_start"
}

cloudflared_identity_matches() {
  local pid="$1"
  local recorded_start="$2"
  local actual_start=""
  local state=""
  local cmdline=""
  local uid=""
  local expected_uid=""

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  state="$(process_state "$pid" 2>/dev/null || true)"
  [[ "$actual_start" == "$recorded_start" && "$state" != "Z" && "$state" != "X" ]] || return 1

  expected_uid="$(id -u "$SERVICE_USER" 2>/dev/null || true)"
  uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
  [[ -n "$expected_uid" && "$uid" == "$expected_uid" ]] || return 1

  cmdline="$(process_command_line "$pid" 2>/dev/null || true)"
  [[ "$cmdline" == *"${CLOUDFLARED_BIN}"* \
    && "$cmdline" == *"tunnel"* \
    && "$cmdline" == *"127.0.0.1:${LOCAL_PORT}"* ]]
}

cloudflared_pid_is_ours() {
  local pid=""
  local recorded_start=""

  IFS=' ' read -r pid recorded_start < <(read_cloudflared_pid) || return 1
  cloudflared_identity_matches "$pid" "$recorded_start"
}

singbox_runtime_is_running() {
  [[ -n "$CLOUDFLARED_BIN" ]] || resolve_cloudflared_bin
  [[ -n "$CLOUDFLARED_BIN" ]] || return 1

  service_is_active \
    && listener_exact_loopback \
    && tunnel_is_running \
    && cloudflared_pid_is_ours
}

signal_cloudflared_verified() {
  local signal_name="$1"
  local pid="$2"
  local recorded_start="$3"

  cloudflared_identity_matches "$pid" "$recorded_start" || return 1
  kill "-${signal_name}" "$pid" 2>/dev/null || return 1
}

extract_argo_host() {
  [[ -f "$LOG_FILE" ]] || return 1

  grep -Eo \
    'https://[a-z0-9-]+\.trycloudflare\.com' \
    "$LOG_FILE" \
    2>/dev/null \
    | tail -n 1 \
    | sed 's#^https://##'
}

wait_for_argo_host() {
  local i=0
  local host=""

  for ((i = 1; i <= 90; i++)); do
    host="$(
      extract_argo_host \
        || true
    )"

    if valid_argo_host "$host" \
        && [[ -n "$host" ]]; then
      ARGO_HOST="$host"
      save_state
      return 0
    fi

    if ! tunnel_is_running \
        && ! cloudflared_pid_is_ours; then
      break
    fi

    sleep 1
  done

  return 1
}

generate_vmess_link() {
  valid_uuid "$UUID" || die "UUID 无效，无法生成分享链接。"
  valid_ws_path "$WSPATH" || die "WS 路径无效，无法生成分享链接。"
  valid_argo_host "$ARGO_HOST" || die "临时 Argo 域名无效。"
  [[ -n "$ARGO_HOST" ]] || die "临时 Argo 域名为空。"
  valid_preferred_endpoint "$PREFERRED_ENDPOINT" || die "优选域名/IP 无效。"
  valid_node_name "$NODE_NAME" || die "订阅节点名称无效。"

  local tmp_json=""
  local tmp_link=""
  local encoded=""

  tmp_json="$(mktemp "${DATA_DIR}/.vmess.json.XXXXXX")"
  tmp_link="$(mktemp "${DATA_DIR}/.vmess.txt.XXXXXX")"

  jq -c -n \
    --arg ps "$NODE_NAME" \
    --arg add "$PREFERRED_ENDPOINT" \
    --arg id "$UUID" \
    --arg host "$ARGO_HOST" \
    --arg path "$WSPATH" \
    --arg ech "$ECH_CONFIG" \
    '{
      v: "2",
      ps: $ps,
      add: $add,
      port: "443",
      id: $id,
      aid: "0",
      scy: "auto",
      net: "ws",
      type: "none",
      host: $host,
      path: $path,
      tls: "tls",
      sni: $host,
      alpn: "http/1.1",
      fp: "firefox",
      insecure: "0",
      vcn: $host,
      pcs: "",
      ech: $ech,
      echConfigList: $ech
    }' > "$tmp_json"

  encoded="$(base64 < "$tmp_json" | tr -d '\r\n')"
  printf 'vmess://%s\n' "$encoded" > "$tmp_link"

  if ! base64 -d < <(sed 's#^vmess://##' "$tmp_link") 2>/dev/null \
      | jq -e \
        --arg ps "$NODE_NAME" \
        --arg add "$PREFERRED_ENDPOINT" \
        --arg host "$ARGO_HOST" \
        --arg ech "$ECH_CONFIG" \
        '
          .ps == $ps
          and .add == $add
          and .host == $host
          and .sni == $host
          and .vcn == $host
          and .pcs == ""
          and .ech == $ech
          and .echConfigList == $ech
        ' >/dev/null; then
    rm -f "$tmp_json" "$tmp_link"
    die "生成的 VMess 链接自检失败，未写入磁盘。"
  fi

  chmod 600 "$tmp_json" "$tmp_link"
  mv -f "$tmp_json" "$VMESS_JSON_FILE"
  mv -f "$tmp_link" "$VMESS_LINK_FILE"
  printf '%s\n' "$ECH_CONFIG" > "$ECH_NOTE_FILE"
  chmod 600 "$ECH_NOTE_FILE"
}

stop_tunnel() {
  local stopped=0
  local pid=""
  local recorded_start=""
  local i=0

  resolve_cloudflared_bin

  local session=""

  if session="$(active_tunnel_session 2>/dev/null)"; then
    tmux kill-session -t "$session" 2>/dev/null || true
    stopped=1
  elif tmux_session_exists; then
    warn "发现同名 sing-box tmux 会话，但它不是本脚本创建的；不会将其删除。"
  fi

  sleep 1

  if IFS=' ' read -r pid recorded_start < <(read_cloudflared_pid 2>/dev/null); then
    if cloudflared_identity_matches "$pid" "$recorded_start"; then
      signal_cloudflared_verified TERM "$pid" "$recorded_start" || true

      for ((i = 0; i < 8; i++)); do
        cloudflared_identity_matches "$pid" "$recorded_start" || break
        sleep 1
      done

      if cloudflared_identity_matches "$pid" "$recorded_start"; then
        signal_cloudflared_verified KILL "$pid" "$recorded_start" || true
        sleep 1
      fi

      if cloudflared_identity_matches "$pid" "$recorded_start"; then
        warn "cloudflared 进程仍未退出；为避免误杀其他进程，已保留 PID 文件供排查。"
        return 1
      fi

      stopped=1
    fi
  fi

  rm -f "$CLOUDFLARED_PID_FILE"

  if [[ $stopped -eq 1 ]]; then
    ok "临时 Argo 已停止；旧 trycloudflare.com 域名随之失效。"
  else
    info "没有发现正在运行的 zdd-argo 临时隧道。"
  fi
}

command_stop_singbox_tunnel() {
  warn "$(printf '%s' "此操作仅断开 sing-box 临时 Argo 隧道，并清理旧域名、订阅、日志与 cloudflared 临时缓存。")"
  warn "$(printf '%s' "sing-box 服务、配置、UUID、WS 路径、优选地址和已安装程序都会保留；Xray 不受影响。")"

  if ! confirm_yes "$(printf '%s' "确认断开 sing-box 临时 Argo 请输入 yes：")"; then
    info "$(printf '%s' "已取消。")"
    return 0
  fi

  stop_tunnel || die "无法安全停止 sing-box 临时 Argo。"
  clear_singbox_tunnel_artifacts

  ok "$(printf '%s' "sing-box 临时 Argo 已断开，旧订阅和临时缓存已清理。")"
  info "$(printf '%s' "以后选择自动生成或自定义生成里的 sing-box 可重新创建隧道。")"
}

command_stop_xray_tunnel() {
  warn "$(printf '%s' "此操作仅断开 Xray 临时 Argo 隧道，并清理旧域名、订阅、日志与 cloudflared 临时缓存。")"
  warn "$(printf '%s' "Xray 服务、配置、UUID、WS 路径、优选地址和已安装程序都会保留；sing-box 不受影响。")"

  if ! confirm_yes "$(printf '%s' "确认断开 Xray 临时 Argo 请输入 yes：")"; then
    info "$(printf '%s' "已取消。")"
    return 0
  fi

  stop_xray_tunnel || die "无法安全停止 Xray 临时 Argo。"
  clear_xray_tunnel_artifacts

  ok "$(printf '%s' "Xray 临时 Argo 已断开，旧订阅和临时缓存已清理。")"
  info "$(printf '%s' "以后选择自动生成或自定义生成里的 Xray 可重新创建隧道。")"
}

clear_singbox_tunnel_artifacts() {
  if [[ -f "$STATE_JSON" ]]; then
    load_state
    ARGO_HOST=""
    save_state
  fi

  rm -f     "$CLOUDFLARED_PID_FILE"     "$LOG_FILE"     "$VMESS_JSON_FILE"     "$VMESS_LINK_FILE"     "$ECH_NOTE_FILE"

  rm -rf "$CLOUDFLARED_HOME"
}

clear_xray_tunnel_artifacts() {
  if [[ -f "$XRAY_STATE_JSON" ]]; then
    load_xray_state
    XRAY_ARGO_HOST=""
    save_xray_state
  fi

  rm -f     "$XRAY_CLOUDFLARED_PID_FILE"     "$XRAY_LOG_FILE"     "$XRAY_VLESS_JSON_FILE"     "$XRAY_VLESS_LINK_FILE"

  rm -rf "$XRAY_CLOUDFLARED_HOME"
}

command_stop_clear_cache() {
  warn "$(printf '%s' "此操作会断开 sing-box 与 Xray 两个临时 Argo 隧道，并清理旧域名、订阅、日志及 cloudflared 临时缓存。")"
  warn "$(printf '%s' "两个核心服务、配置、UUID、WS 路径、优选地址和已安装程序都会保留。")"

  if ! confirm_yes "$(printf '%s' "确认全部断开并清理请输入 yes：")"; then
    info "$(printf '%s' "已取消。")"
    return 0
  fi

  stop_tunnel || die "无法安全停止 sing-box 临时 Argo。"
  stop_xray_tunnel || die "无法安全停止 Xray 临时 Argo。"
  clear_singbox_tunnel_artifacts
  clear_xray_tunnel_artifacts

  ok "$(printf '%s' "sing-box 与 Xray 临时 Argo 已断开，旧订阅和临时缓存已清理。")"
  info "$(printf '%s' "以后选择自动生成或自定义生成可重新创建隧道；当前设置会保留。")"
}

start_tunnel() {
  local parsed_host=""
  local attempt=0
  local max_attempts=3
  local retry_delay=5

  if tmux_session_exists \
      && ! tunnel_is_running; then

    die "$(printf '%s' "已存在同名 tmux 会话 ${TMUX_SESSION}，但不是本脚本创建的会话；为避免误伤，请先改名或删除该会话。")"
  fi

  if tunnel_is_running; then
    parsed_host="$(
      extract_argo_host \
        || true
    )"

    if [[ -n "$parsed_host" ]] \
        && valid_argo_host "$parsed_host"; then
      ARGO_HOST="$parsed_host"
      save_state
      generate_vmess_link

      info "$(printf '%s' "现有临时隧道运行正常，未重复创建。")"

      return 0
    fi

    warn "$(printf '%s' "检测到 tmux 会话，但尚未取得有效临时域名，继续等待……")"

    if wait_for_argo_host; then
      generate_vmess_link
      return 0
    fi

    warn "$(printf '%s' "现有临时隧道未返回有效域名，将停止异常会话并重新创建。")"

    stop_tunnel || true
  fi

  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"

  rm -f \
    "$CLOUDFLARED_PID_FILE" \
    "$VMESS_JSON_FILE" \
    "$VMESS_LINK_FILE" \
    "$ECH_NOTE_FILE"

  ARGO_HOST=""
  save_state

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    if ((attempt > 1)); then
      printf '\n===== Argo 重试 %d/%d =====\n' \
        "$attempt" \
        "$max_attempts" \
        >> "$LOG_FILE"
    fi

    info "$(printf '%s' "正在创建临时 Argo（第 ${attempt}/${max_attempts} 次）……")"

    if tmux new-session \
        -d \
        -s "$TMUX_SESSION" \
        "$CLOUDFLARED_RUNNER"; then

      if wait_for_argo_host; then
        generate_vmess_link

        ok "$(printf '%s' "第 ${attempt}/${max_attempts} 次尝试成功取得临时域名。")"

        return 0
      fi
    else
      warn "$(printf '%s' "第 ${attempt}/${max_attempts} 次无法创建 tmux 会话。")"
    fi

    warn "$(printf '%s' "第 ${attempt}/${max_attempts} 次未取得 trycloudflare.com 域名。")"

    stop_tunnel || true

    if ((attempt < max_attempts)); then
      warn "$(printf '%s' "${retry_delay} 秒后自动重试……")"

      sleep "$retry_delay"
    fi
  done

  warn "$(printf '%s' "连续 ${max_attempts} 次创建临时 Argo 均失败，最近日志如下：")"

  tail -n 80 \
    "$LOG_FILE" \
    >&2 \
    || true

  die "$(printf '%s' "临时隧道创建失败，请稍后重试。")"
}

deployment_transaction_exit_handler() {
  local rc="${1:-1}"

  if [[ $TRANSACTION_ACTIVE -eq 1 ]]; then
    if [[ "$rc" -eq 0 ]]; then
      deployment_transaction_rollback "部署流程未正常提交"
    else
      deployment_transaction_rollback "部署失败，正在恢复修改前状态"
    fi
  fi

  release_lock
}

transaction_dir_is_safe() {
  local dir="$1"
  local uid=""
  local mode=""

  [[ "$dir" == /tmp/zdd-argo-transaction.* \
    && -d "$dir" \
    && ! -L "$dir" ]] \
    || return 1

  uid="$(stat -Lc '%u' "$dir" 2>/dev/null || true)"
  mode="$(stat -Lc '%a' "$dir" 2>/dev/null || true)"
  [[ "$uid" == "0" && "$mode" == "700" ]]
}

cleanup_transaction_dir() {
  local dir="${1:-}"

  [[ -n "$dir" ]] || return 0
  transaction_dir_is_safe "$dir" || return 1
  rm -rf -- "$dir"
}



xray_service_is_active() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl is-active --quiet "$XRAY_SERVICE_NAME" 2>/dev/null
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" status >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_enable() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl enable "$XRAY_SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-update add "$XRAY_SERVICE_NAME" default >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_restart() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl restart "$XRAY_SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" restart \
        || rc-service "$XRAY_SERVICE_NAME" start
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_stop() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl stop "$XRAY_SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" stop >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_disable_now() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl disable --now "$XRAY_SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" stop >/dev/null 2>&1 || true
      rc-update del "$XRAY_SERVICE_NAME" default >/dev/null 2>&1 || true
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_enable_now() {
  xray_service_enable || return 1
  case "$INIT_SYSTEM" in
    systemd)
      systemctl start "$XRAY_SERVICE_NAME" >/dev/null 2>&1
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" start >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

xray_service_reset_failed() {
  case "$INIT_SYSTEM" in
    systemd)
      systemctl reset-failed "$XRAY_SERVICE_NAME" >/dev/null 2>&1 || true
      ;;
    openrc)
      :
      ;;
  esac
}

xray_service_print_logs() {
  local lines="${1:-80}"

  case "$INIT_SYSTEM" in
    systemd)
      journalctl -u "$XRAY_SERVICE_NAME" -n "$lines" --no-pager >&2 || true
      ;;
    openrc)
      rc-service "$XRAY_SERVICE_NAME" status >&2 || true
      ss -ltnp 2>/dev/null | grep -E "(^|:)${XRAY_LOCAL_PORT}[[:space:]]" >&2 || true
      if [[ -f "$XRAY_CORE_LOG_FILE" ]]; then
        tail -n "$lines" "$XRAY_CORE_LOG_FILE" >&2 || true
      else
        warn "OpenRC 模式未找到 Xray 日志文件：${XRAY_CORE_LOG_FILE}"
      fi
      ;;
  esac
}

xray_unit_is_ours() {
  [[ -f "$XRAY_UNIT" && ! -L "$XRAY_UNIT" ]] || return 1

  case "$INIT_SYSTEM" in
    systemd)
      grep -Fqx "Description=zdd-argo dedicated Xray VLESS-ENC WS service managed-v0.1.0" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "User=${SERVICE_USER}" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "Group=${SERVICE_GROUP}" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "ExecStart=${MANAGED_XRAY_BIN} run -config ${XRAY_CONFIG}" "$XRAY_UNIT" 2>/dev/null
      ;;
    openrc)
      grep -Fqx 'zdd_argo_xray_managed="0.1.0"' "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command=\"${MANAGED_XRAY_BIN}\"" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command_args=\"run -config ${XRAY_CONFIG}\"" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command_user=\"${SERVICE_USER}:${SERVICE_GROUP}\"" "$XRAY_UNIT" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

xray_unit_is_legacy_ours() {
  [[ -f "$XRAY_UNIT" && ! -L "$XRAY_UNIT" ]] || return 1

  case "$INIT_SYSTEM" in
    systemd)
      grep -Fq "zdd-argo" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "User=${SERVICE_USER}" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "Group=${SERVICE_GROUP}" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "ExecStart=${MANAGED_XRAY_BIN} run -config ${XRAY_CONFIG}" "$XRAY_UNIT" 2>/dev/null
      ;;
    openrc)
      grep -Fq "zdd-argo" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command=\"${MANAGED_XRAY_BIN}\"" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command_args=\"run -config ${XRAY_CONFIG}\"" "$XRAY_UNIT" 2>/dev/null \
        && grep -Fqx "command_user=\"${SERVICE_USER}:${SERVICE_GROUP}\"" "$XRAY_UNIT" 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

write_xray_service() {
  [[ -n "$XRAY_BIN" ]] || die "未找到 Xray 可执行文件。"
  [[ "$XRAY_BIN" == "$MANAGED_XRAY_BIN" ]] \
    || die "当前 Xray 不是脚本专用二进制，拒绝写入受管服务。"
  ensure_service_account

  if [[ -e "$XRAY_UNIT" || -L "$XRAY_UNIT" ]]; then
    xray_unit_is_ours || xray_unit_is_legacy_ours \
      || die "Xray 服务路径已被其他程序占用：${XRAY_UNIT}"
  fi

  local tmp=""
  tmp="$(mktemp)"

  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    cat > "$tmp" <<EOF
[Unit]
Description=zdd-argo dedicated Xray VLESS-ENC WS service managed-v0.1.0
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
ExecStart=${MANAGED_XRAY_BIN} run -config ${XRAY_CONFIG}
Restart=on-failure
RestartSec=3s
LimitNOFILE=1048576
NoNewPrivileges=true
UMask=0077
CapabilityBoundingSet=
AmbientCapabilities=
PrivateTmp=true
PrivateDevices=true
ProtectHome=true
ProtectSystem=strict
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
LockPersonality=true
RestrictSUIDSGID=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6 AF_NETLINK
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
EOF
    install -m 0644 "$tmp" "$XRAY_UNIT"
  elif [[ "$INIT_SYSTEM" == "openrc" ]]; then
    printf '%s\n' '#!/sbin/openrc-run' > "$tmp"
    cat >> "$tmp" <<EOF
zdd_argo_xray_managed="0.1.0"
name="zdd-argo 专用 Xray VLESS-ENC WS 服务"
description="zdd-argo dedicated Xray VLESS-ENC WS service"
command="${MANAGED_XRAY_BIN}"
command_args="run -config ${XRAY_CONFIG}"
command_user="${SERVICE_USER}:${SERVICE_GROUP}"
pidfile="/run/${XRAY_SERVICE_NAME}.pid"
supervisor="supervise-daemon"
respawn_delay=3
respawn_max=0
output_log="${XRAY_CORE_LOG_FILE}"
error_log="${XRAY_CORE_LOG_FILE}"

depend() {
  use net
}

start_pre() {
  checkpath -d -m 0750 -o root:${SERVICE_GROUP} "${DATA_DIR}"
  checkpath -f -m 0640 -o root:${SERVICE_GROUP} "${XRAY_CONFIG}"
  checkpath -f -m 0640 -o ${SERVICE_USER}:${SERVICE_GROUP} "${XRAY_CORE_LOG_FILE}"
}
EOF
    install -m 0755 "$tmp" "$XRAY_UNIT"
  else
    rm -f "$tmp"
    die "无法识别服务管理器，不能写入 Xray 服务文件。"
  fi

  rm -f "$tmp"
  service_daemon_reload
}

valid_xray_ws_path() {
  [[ "$1" =~ ^/?[A-Za-z0-9._~-]+$ ]]
}

valid_xray_vlessenc_value() {
  [[ "$1" =~ ^mlkem768x25519plus\.(native|xorpub|random)\.(0rtt|1rtt|[0-9]+s|[0-9]+-[0-9]+s)(\.[A-Za-z0-9_-]+)+$ ]]
}

load_xray_state() {
  XRAY_UUID=""
  XRAY_WS_PATH=""
  XRAY_ARGO_HOST=""
  XRAY_CREATED_AT=""
  XRAY_VLESS_ENCRYPTION=""
  XRAY_VLESS_DECRYPTION=""
  XRAY_KEY_PRIVATE=""
  XRAY_KEY_PUBLIC=""
  XRAY_PREFERRED_ENDPOINT="${XRAY_PREFERRED_ENDPOINT:-$DEFAULT_XRAY_PREFERRED_ENDPOINT}"
  XRAY_LOCAL_PORT="${XRAY_LOCAL_PORT:-$DEFAULT_XRAY_LOCAL_PORT}"
  XRAY_NODE_NAME="${XRAY_NODE_NAME:-$DEFAULT_XRAY_NODE_NAME}"

  [[ -f "$XRAY_STATE_JSON" ]] || return 0

  jq -e 'type == "object"' "$XRAY_STATE_JSON" >/dev/null 2>&1 \
    || die "Xray 状态文件损坏：${XRAY_STATE_JSON}"

  XRAY_UUID="$(jq -r '.uuid // ""' "$XRAY_STATE_JSON")"
  XRAY_WS_PATH="$(jq -r '.ws_path // .xhttp_path // ""' "$XRAY_STATE_JSON")"
  XRAY_ARGO_HOST="$(jq -r '.argo_host // ""' "$XRAY_STATE_JSON")"
  XRAY_CREATED_AT="$(jq -r '.created_at // ""' "$XRAY_STATE_JSON")"
  XRAY_VLESS_ENCRYPTION="$(jq -r '.vless_encryption // ""' "$XRAY_STATE_JSON")"
  XRAY_VLESS_DECRYPTION="$(jq -r '.vless_decryption // ""' "$XRAY_STATE_JSON")"
  XRAY_KEY_PRIVATE="$(jq -r '.x25519_private_key // ""' "$XRAY_STATE_JSON")"
  XRAY_KEY_PUBLIC="$(jq -r '.x25519_public_key // ""' "$XRAY_STATE_JSON")"
  XRAY_LOCAL_PORT="$(jq -r '.local_port // "'"$DEFAULT_XRAY_LOCAL_PORT"'"' "$XRAY_STATE_JSON")"
  XRAY_NODE_NAME="$(jq -r '.node_name // "'"$DEFAULT_XRAY_NODE_NAME"'"' "$XRAY_STATE_JSON")"
  XRAY_PREFERRED_ENDPOINT="$(jq -r '.preferred_endpoint // "'"$XRAY_PREFERRED_ENDPOINT"'"' "$XRAY_STATE_JSON")"
  XRAY_PREFERRED_ENDPOINT="$(normalize_preferred_endpoint "$XRAY_PREFERRED_ENDPOINT")"

  [[ -z "$XRAY_UUID" ]] || valid_uuid "$XRAY_UUID" || die "Xray 状态文件中的 UUID 无效：${XRAY_STATE_JSON}"
  [[ -z "$XRAY_WS_PATH" ]] || valid_xray_ws_path "$XRAY_WS_PATH" || die "Xray 状态文件中的 WS 路径无效：${XRAY_STATE_JSON}"
  [[ -z "$XRAY_ARGO_HOST" ]] || valid_argo_host "$XRAY_ARGO_HOST" || die "Xray 状态文件中的临时域名无效：${XRAY_STATE_JSON}"
  [[ -z "$XRAY_VLESS_ENCRYPTION" ]] || valid_xray_vlessenc_value "$XRAY_VLESS_ENCRYPTION" || die "Xray 状态文件中的 VLESS-ENC encryption 无效：${XRAY_STATE_JSON}"
  [[ -z "$XRAY_VLESS_DECRYPTION" ]] || valid_xray_vlessenc_value "$XRAY_VLESS_DECRYPTION" || die "Xray 状态文件中的 VLESS-ENC decryption 无效：${XRAY_STATE_JSON}"
  valid_local_port "$XRAY_LOCAL_PORT" || die "Xray 状态文件中的本地端口无效：${XRAY_STATE_JSON}"
  valid_node_name "$XRAY_NODE_NAME" || die "Xray 状态文件中的节点名称无效：${XRAY_STATE_JSON}"
  valid_preferred_endpoint "$XRAY_PREFERRED_ENDPOINT" || die "Xray 状态文件中的优选域名/IP 无效：${XRAY_STATE_JSON}"
}

save_xray_state() {
  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR" 2>/dev/null || true
  chmod 750 "$DATA_DIR"

  if [[ -z "$XRAY_CREATED_AT" ]]; then
    XRAY_CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  fi

  local tmp=""
  tmp="$(mktemp "${DATA_DIR}/.xray-state.json.XXXXXX")"

  jq -n \
    --argjson schema 1 \
    --arg uuid "$XRAY_UUID" \
    --arg ws_path "$XRAY_WS_PATH" \
    --arg argo_host "$XRAY_ARGO_HOST" \
    --arg vless_encryption "$XRAY_VLESS_ENCRYPTION" \
    --arg vless_decryption "$XRAY_VLESS_DECRYPTION" \
    --arg x25519_private_key "$XRAY_KEY_PRIVATE" \
    --arg x25519_public_key "$XRAY_KEY_PUBLIC" \
    --arg local_port "$XRAY_LOCAL_PORT" \
    --arg node_name "$XRAY_NODE_NAME" \
    --arg preferred_endpoint "$XRAY_PREFERRED_ENDPOINT" \
    --arg created_at "$XRAY_CREATED_AT" \
    --arg updated_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    '{
      schema: $schema,
      uuid: $uuid,
      ws_path: $ws_path,
      argo_host: $argo_host,
      vless_encryption: $vless_encryption,
      vless_decryption: $vless_decryption,
      x25519_private_key: $x25519_private_key,
      x25519_public_key: $x25519_public_key,
      local_port: ($local_port | tonumber),
      node_name: $node_name,
      preferred_endpoint: $preferred_endpoint,
      created_at: $created_at,
      updated_at: $updated_at
    }' > "$tmp"

  chmod 600 "$tmp"
  mv -f "$tmp" "$XRAY_STATE_JSON"
}

parse_xray_key_line() {
  local label="$1"
  awk -v label="$label" '''
    index(tolower($0), tolower(label)) {
      for (i = NF; i >= 1; i--) {
        if ($i ~ /^[A-Za-z0-9_-]+$/) {
          print $i
          exit
        }
      }
    }
  '''
}

extract_xray_vlessenc_values() {
  local key="$1"
  awk -v key="$key" '''
    {
      marker = "\"" key "\""
      pos = index($0, marker)
      if (pos == 0) {
        next
      }
      rest = substr($0, pos + length(marker))
      if (match(rest, /:[[:space:]]*"mlkem768x25519plus[.](native|xorpub|random)[.][^"]+"/)) {
        value = substr(rest, RSTART, RLENGTH)
        sub(/^:[[:space:]]*"/, "", value)
        sub(/"$/, "", value)
        print value
      }
    }
  '''
}

normalize_xray_vlessenc_xorpub() {
  local value="$1"
  case "$value" in
    mlkem768x25519plus.xorpub.*)
      printf '%s\n' "$value"
      ;;
    mlkem768x25519plus.native.*)
      printf '%s\n' "${value/#mlkem768x25519plus.native./mlkem768x25519plus.xorpub.}"
      ;;
    mlkem768x25519plus.random.*)
      printf '%s\n' "${value/#mlkem768x25519plus.random./mlkem768x25519plus.xorpub.}"
      ;;
    *)
      return 1
      ;;
  esac
}

choose_xray_vlessenc_value() {
  local value=""

  for value in "$@"; do
    if [[ "$value" == mlkem768x25519plus.xorpub.* ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done

  for value in "$@"; do
    if [[ "$value" == mlkem768x25519plus.native.* || "$value" == mlkem768x25519plus.random.* ]]; then
      normalize_xray_vlessenc_xorpub "$value"
      return 0
    fi
  done

  return 1
}

generate_xray_identity() {
  local enc_output=""
  local desired_port="${XRAY_LOCAL_PORT:-$DEFAULT_XRAY_LOCAL_PORT}"
  local desired_node="${XRAY_NODE_NAME:-$DEFAULT_XRAY_NODE_NAME}"
  local desired_endpoint="${XRAY_PREFERRED_ENDPOINT:-$DEFAULT_XRAY_PREFERRED_ENDPOINT}"
  local -a dec_values=()
  local -a enc_values=()

  [[ -n "$XRAY_BIN" ]] || die "未找到 Xray，无法生成 VLESS-ENC 密钥。"

  XRAY_UUID="$(generate_uuid_v4)" || die "Xray UUID 生成失败。"
  valid_uuid "$XRAY_UUID" || die "生成的 Xray UUID 未通过格式校验。"

  enc_output="$($XRAY_BIN vlessenc 2>/dev/null || true)"
  mapfile -t dec_values < <(printf '%s\n' "$enc_output" | extract_xray_vlessenc_values "decryption")
  mapfile -t enc_values < <(printf '%s\n' "$enc_output" | extract_xray_vlessenc_values "encryption")

  XRAY_VLESS_DECRYPTION="$(choose_xray_vlessenc_value "${dec_values[@]}" 2>/dev/null || true)"
  XRAY_VLESS_ENCRYPTION="$(choose_xray_vlessenc_value "${enc_values[@]}" 2>/dev/null || true)"

  valid_xray_vlessenc_value "$XRAY_VLESS_DECRYPTION" || die "Xray vlessenc 未输出可用的 VLESS-ENC decryption。"
  valid_xray_vlessenc_value "$XRAY_VLESS_ENCRYPTION" || die "Xray vlessenc 未输出可用的 VLESS-ENC encryption。"
  [[ "$XRAY_VLESS_DECRYPTION" == mlkem768x25519plus.xorpub.* ]] || die "Xray VLESS-ENC decryption 未转换为 xorpub。"
  [[ "$XRAY_VLESS_ENCRYPTION" == mlkem768x25519plus.xorpub.* ]] || die "Xray VLESS-ENC encryption 未转换为 xorpub。"

  XRAY_KEY_PRIVATE=""
  XRAY_KEY_PUBLIC=""
  XRAY_WS_PATH="/${XRAY_UUID}-vw"
  XRAY_ARGO_HOST=""
  XRAY_CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  XRAY_LOCAL_PORT="$desired_port"
  XRAY_NODE_NAME="$desired_node"
  XRAY_PREFERRED_ENDPOINT="$desired_endpoint"

  valid_xray_ws_path "$XRAY_WS_PATH" || die "生成的 WS 路径无效。"
  valid_xray_vlessenc_value "$XRAY_VLESS_DECRYPTION" || die "生成的 Xray decryption 无效。"
  valid_xray_vlessenc_value "$XRAY_VLESS_ENCRYPTION" || die "生成的 Xray encryption 无效。"

  rm -f "$XRAY_VLESS_JSON_FILE" "$XRAY_VLESS_LINK_FILE"
  save_xray_state
}
xray_template_direct() {
  jq -n \
    --argjson port "$XRAY_LOCAL_PORT" \
    --arg uuid "$XRAY_UUID" \
    --arg node "$XRAY_NODE_NAME" \
    --arg path "$XRAY_WS_PATH" \
    --arg decryption "$XRAY_VLESS_DECRYPTION" \
    --arg freedom_strategy "$(xray_freedom_domain_strategy)" \
    --arg routing_strategy "$(xray_routing_domain_strategy)" \
    '{
      log: {
        loglevel: "warning"
      },
      inbounds: [
        {
          tag: "vless-enc-ws-in",
          listen: "127.0.0.1",
          port: $port,
          protocol: "vless",
          settings: {
            clients: [
              {
                id: $uuid,
                level: 0,
                email: $node,
                flow: "xtls-rprx-vision"
              }
            ],
            decryption: $decryption
          },
          streamSettings: {
            network: "ws",
            security: "none",
            wsSettings: {
              path: $path
            }
          },
          sniffing: {
            enabled: true,
            destOverride: ["http", "tls", "quic"],
            metadataOnly: false
          }
        }
      ],
      outbounds: [
        {
          tag: "direct",
          protocol: "freedom",
          settings: {
            domainStrategy: $freedom_strategy
          }
        },
        {
          tag: "block",
          protocol: "blackhole"
        }
      ],
      routing: {
        domainStrategy: $routing_strategy,
        rules: [
          {
            type: "field",
            ip: [
              "0.0.0.0/8",
              "10.0.0.0/8",
              "100.64.0.0/10",
              "127.0.0.0/8",
              "169.254.0.0/16",
              "172.16.0.0/12",
              "192.0.0.0/24",
              "192.0.2.0/24",
              "192.168.0.0/16",
              "198.18.0.0/15",
              "198.51.100.0/24",
              "203.0.113.0/24",
              "224.0.0.0/4",
              "240.0.0.0/4",
              "::1/128",
              "fc00::/7",
              "fe80::/10",
              "169.254.169.254/32",
              "100.100.100.200/32"
            ],
            outboundTag: "block"
          }
        ]
      }
    }'
}
write_xray_config() {
  [[ -n "$XRAY_BIN" ]] || die "未找到 Xray。"
  valid_uuid "$XRAY_UUID" || die "Xray UUID 无效。"
  valid_xray_ws_path "$XRAY_WS_PATH" || die "WS 路径无效。"
  valid_xray_vlessenc_value "$XRAY_VLESS_DECRYPTION" || die "VLESS-ENC decryption 无效。"
  valid_local_port "$XRAY_LOCAL_PORT" || die "Xray 本地端口无效。"
  valid_outbound_ip_mode "$OUTBOUND_IP_MODE" || die "出站策略无效。"

  local tmp=""
  tmp="$(mktemp "${DATA_DIR}/.xray-config.XXXXXX.json")"

  xray_template_direct > "$tmp"

  jq -e \
    --argjson port "$XRAY_LOCAL_PORT" \
    --arg uuid "$XRAY_UUID" \
    --arg path "$XRAY_WS_PATH" \
    --arg decryption "$XRAY_VLESS_DECRYPTION" \
    --arg freedom_strategy "$(xray_freedom_domain_strategy)" \
    --arg routing_strategy "$(xray_routing_domain_strategy)" \
    '.inbounds[0].port == $port
      and .inbounds[0].settings.clients[0].id == $uuid
      and .inbounds[0].settings.decryption == $decryption
      and .inbounds[0].settings.clients[0].flow == "xtls-rprx-vision"
      and .inbounds[0].streamSettings.network == "ws"
      and .inbounds[0].streamSettings.wsSettings.path == $path
      and (.inbounds[0].streamSettings.wsSettings | has("mode") | not)
      and (.inbounds[0].streamSettings.wsSettings | has("host") | not)
      and any((.outbounds // [])[]?;
        .tag == "direct"
        and .protocol == "freedom"
        and .settings.domainStrategy == $freedom_strategy)
      and any((.outbounds // [])[]?;
        .tag == "block" and .protocol == "blackhole")
      and .routing.domainStrategy == $routing_strategy
      and any((.routing.rules // [])[]?;
        .type == "field"
        and .outboundTag == "block"
        and ((.ip // []) | index("127.0.0.0/8") != null)
        and ((.ip // []) | index("169.254.169.254/32") != null)
        and ((.ip // []) | index("100.100.100.200/32") != null))' \
    "$tmp" >/dev/null \
    || { rm -f "$tmp"; die "生成的 Xray 配置未通过结构自检。"; }

  "$XRAY_BIN" run -test -config "$tmp" \
    || { rm -f "$tmp"; die "Xray 配置校验失败。"; }

  chown root:"$SERVICE_GROUP" "$tmp" 2>/dev/null || true
  chmod 640 "$tmp"
  mv -f "$tmp" "$XRAY_CONFIG"

  "$XRAY_BIN" run -test -config "$XRAY_CONFIG" \
    || die "写入后的 Xray 配置校验失败。"
}

xray_listener_exact_loopback() {
  ss_listen_tcp_lines \
    | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${XRAY_LOCAL_PORT}([[:space:]]|$)"
}

wait_for_xray_ready() {
  local i=0

  for ((i = 1; i <= 15; i++)); do
    if xray_service_is_active && xray_listener_exact_loopback; then
      return 0
    fi

    if [[ "$INIT_SYSTEM" == "openrc" ]] && xray_listener_exact_loopback; then
      return 0
    fi

    sleep 1
  done

  return 1
}

ensure_xray_running() {
  if ss_listen_tcp_lines | grep -Eq "(^|[[:space:]])[^[:space:]]*:${XRAY_LOCAL_PORT}([[:space:]]|$)" \
      && ! xray_service_is_active; then
    warn "端口 ${XRAY_LOCAL_PORT} 已被其他进程占用："
    ss_listen_tcp_process_lines | grep -E "(^|:)${XRAY_LOCAL_PORT}[[:space:]]" || true
    die "为避免覆盖其他服务，已停止 Xray 部署。"
  fi

  xray_service_enable || die "无法启用 ${XRAY_SERVICE_NAME}。"
  xray_service_restart || die "无法重启 ${XRAY_SERVICE_NAME}。"

  if ! wait_for_xray_ready; then
    xray_service_print_logs 80
    die "${XRAY_SERVICE_NAME} 未能在 15 秒内进入正常状态，或本机未监听 127.0.0.1:${XRAY_LOCAL_PORT}。"
  fi
}

write_xray_cloudflared_runner() {
  [[ -n "$CLOUDFLARED_BIN" ]] || die "未找到 cloudflared。"
  ensure_service_account

  local service_uid=""
  local service_gid=""
  local tmp=""

  service_uid="$(id -u "$SERVICE_USER")"
  service_gid="$(id -g "$SERVICE_USER")"
  [[ "$service_uid" =~ ^[0-9]+$ && "$service_gid" =~ ^[0-9]+$ ]] \
    || die "无法读取低权限服务账户的 UID/GID。"

  tmp="$(mktemp)"
  printf '%s\n' '#!/usr/bin/env bash' > "$tmp"
  cat >> "$tmp" <<EOF
set -Eeuo pipefail
IFS=\$'\\n\\t'
umask 077

export HOME="${XRAY_CLOUDFLARED_HOME}"
CF_PID=""
CF_START=""

process_start_time() {
  local pid="\$1"
  local stat_line=""
  local remainder=""
  local start_time=""
  local -a fields=()

  [[ "\$pid" =~ ^[0-9]+\$ ]] || return 1
  [[ -r "/proc/\${pid}/stat" ]] || return 1
  IFS= read -r stat_line < "/proc/\${pid}/stat" || return 1
  [[ "\$stat_line" == *") "* ]] || return 1
  remainder="\${stat_line##*) }"
  IFS=' ' read -r -a fields <<< "\$remainder"
  [[ \${#fields[@]} -ge 20 ]] || return 1
  start_time="\${fields[19]}"
  [[ "\$start_time" =~ ^[0-9]+\$ ]] || return 1
  printf '%s\\n' "\$start_time"
}

identity_matches() {
  local pid="\$1"
  local recorded_start="\$2"
  local actual_start=""
  actual_start="\$(process_start_time "\$pid" 2>/dev/null || true)"
  [[ -n "\$actual_start" && "\$actual_start" == "\$recorded_start" ]]
}

signal_verified() {
  local signal_name="\$1"
  local pid="\$2"
  local recorded_start="\$3"
  identity_matches "\$pid" "\$recorded_start" || return 0
  kill "-\${signal_name}" "\$pid" 2>/dev/null || true
}

cleanup() {
  local rc=\$?
  local i=0
  trap - EXIT HUP INT TERM
  if [[ -n "\${CF_PID}" && -n "\${CF_START}" ]]; then
    signal_verified TERM "\${CF_PID}" "\${CF_START}"
    for ((i = 0; i < 8; i++)); do
      identity_matches "\${CF_PID}" "\${CF_START}" || break
      sleep 1
    done
    signal_verified KILL "\${CF_PID}" "\${CF_START}"
    wait "\${CF_PID}" 2>/dev/null || true
  fi
  rm -f "${XRAY_CLOUDFLARED_PID_FILE}"
  exit "\$rc"
}

trap cleanup EXIT HUP INT TERM

if [[ "${INIT_SYSTEM}" == "openrc" ]]; then
  su-exec ${service_uid}:${service_gid} \
    "${CLOUDFLARED_BIN}" tunnel \
      --url "http://127.0.0.1:${XRAY_LOCAL_PORT}" \
      --edge-ip-version auto \
      --no-autoupdate \
      --protocol http2 \
      > >(tee -a "${XRAY_LOG_FILE}") 2>&1 &
else
  setpriv \
    --reuid=${service_uid} \
    --regid=${service_gid} \
    --clear-groups \
    --no-new-privs \
    -- \
    "${CLOUDFLARED_BIN}" tunnel \
      --url "http://127.0.0.1:${XRAY_LOCAL_PORT}" \
      --edge-ip-version auto \
      --no-autoupdate \
      --protocol http2 \
      > >(tee -a "${XRAY_LOG_FILE}") 2>&1 &
fi

CF_PID=\$!
CF_START="\$(process_start_time "\${CF_PID}" 2>/dev/null || true)"
if [[ ! "\${CF_START}" =~ ^[0-9]+\$ ]]; then
  wait "\${CF_PID}" 2>/dev/null || true
  exit 1
fi
printf '%s %s\\n' "\${CF_PID}" "\${CF_START}" > "${XRAY_CLOUDFLARED_PID_FILE}"
chmod 600 "${XRAY_CLOUDFLARED_PID_FILE}"
wait "\${CF_PID}"
EOF

  install -m 0700 "$tmp" "$XRAY_CLOUDFLARED_RUNNER"
  rm -f "$tmp"
}

xray_tmux_session_exists() {
  tmux has-session -t "$XRAY_TMUX_SESSION" 2>/dev/null
}

xray_tunnel_is_running() {
  xray_tmux_session_exists || return 1
  tmux list-panes -t "$XRAY_TMUX_SESSION" -F '#{pane_start_command}' 2>/dev/null \
    | grep -Fq "$XRAY_CLOUDFLARED_RUNNER"
}

read_xray_cloudflared_pid() {
  local pid=""
  local recorded_start=""
  local extra=""

  [[ -r "$XRAY_CLOUDFLARED_PID_FILE" && ! -L "$XRAY_CLOUDFLARED_PID_FILE" ]] || return 1
  IFS=' ' read -r pid recorded_start extra < "$XRAY_CLOUDFLARED_PID_FILE" || return 1
  [[ "$pid" =~ ^[0-9]+$ && "$recorded_start" =~ ^[0-9]+$ && -z "$extra" ]] || return 1
  printf '%s %s\n' "$pid" "$recorded_start"
}

xray_cloudflared_identity_matches() {
  local pid="$1"
  local recorded_start="$2"
  local actual_start=""
  local state=""
  local cmdline=""
  local uid=""
  local expected_uid=""

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  state="$(process_state "$pid" 2>/dev/null || true)"
  [[ "$actual_start" == "$recorded_start" && "$state" != "Z" && "$state" != "X" ]] || return 1

  expected_uid="$(id -u "$SERVICE_USER" 2>/dev/null || true)"
  uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
  [[ -n "$expected_uid" && "$uid" == "$expected_uid" ]] || return 1

  cmdline="$(process_command_line "$pid" 2>/dev/null || true)"
  [[ "$cmdline" == *"${CLOUDFLARED_BIN}"* \
    && "$cmdline" == *"tunnel"* \
    && "$cmdline" == *"127.0.0.1:${XRAY_LOCAL_PORT}"* ]]
}

xray_cloudflared_pid_is_ours() {
  local pid=""
  local recorded_start=""

  IFS=' ' read -r pid recorded_start < <(read_xray_cloudflared_pid) || return 1
  xray_cloudflared_identity_matches "$pid" "$recorded_start"
}

xray_runtime_is_running() {
  [[ -n "$CLOUDFLARED_BIN" ]] || resolve_cloudflared_bin
  [[ -n "$CLOUDFLARED_BIN" ]] || return 1

  xray_service_is_active \
    && xray_listener_exact_loopback \
    && xray_tunnel_is_running \
    && xray_cloudflared_pid_is_ours
}

signal_xray_cloudflared_verified() {
  local signal_name="$1"
  local pid="$2"
  local recorded_start="$3"

  xray_cloudflared_identity_matches "$pid" "$recorded_start" || return 1
  kill "-${signal_name}" "$pid" 2>/dev/null || return 1
}

extract_xray_argo_host() {
  [[ -f "$XRAY_LOG_FILE" ]] || return 1
  grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$XRAY_LOG_FILE" 2>/dev/null \
    | tail -n 1 \
    | sed 's#^https://##'
}

wait_for_xray_argo_host() {
  local i=0
  local host=""

  for ((i = 1; i <= 90; i++)); do
    host="$(extract_xray_argo_host || true)"
    if valid_argo_host "$host" && [[ -n "$host" ]]; then
      XRAY_ARGO_HOST="$host"
      save_xray_state
      return 0
    fi

    if ! xray_tunnel_is_running && ! xray_cloudflared_pid_is_ours; then
      break
    fi
    sleep 1
  done

  return 1
}

stop_xray_tunnel() {
  local stopped=0
  local pid=""
  local recorded_start=""
  local i=0

  resolve_cloudflared_bin

  if xray_tunnel_is_running; then
    tmux kill-session -t "$XRAY_TMUX_SESSION" 2>/dev/null || true
    stopped=1
  elif xray_tmux_session_exists; then
    warn "发现同名 Xray tmux 会话，但它不是本脚本创建的；不会将其删除。"
  fi

  sleep 1

  if IFS=' ' read -r pid recorded_start < <(read_xray_cloudflared_pid 2>/dev/null); then
    if xray_cloudflared_identity_matches "$pid" "$recorded_start"; then
      signal_xray_cloudflared_verified TERM "$pid" "$recorded_start" || true
      for ((i = 0; i < 8; i++)); do
        xray_cloudflared_identity_matches "$pid" "$recorded_start" || break
        sleep 1
      done
      if xray_cloudflared_identity_matches "$pid" "$recorded_start"; then
        signal_xray_cloudflared_verified KILL "$pid" "$recorded_start" || true
        sleep 1
      fi
      if xray_cloudflared_identity_matches "$pid" "$recorded_start"; then
        warn "Xray cloudflared 进程仍未退出；为避免误杀其他进程，已保留 PID 文件供排查。"
        return 1
      fi
      stopped=1
    fi
  fi

  rm -f "$XRAY_CLOUDFLARED_PID_FILE"
  if [[ $stopped -eq 1 ]]; then
    ok "Xray 临时 Argo 已停止；旧 trycloudflare.com 域名随之失效。"
  else
    info "没有发现正在运行的 Xray 临时隧道。"
  fi
}

start_xray_tunnel() {
  local parsed_host=""
  local attempt=0
  local max_attempts=3
  local retry_delay=5

  if xray_tmux_session_exists && ! xray_tunnel_is_running; then
    die "已存在同名 tmux 会话 ${XRAY_TMUX_SESSION}，但不是本脚本创建的会话；为避免误伤，请先改名或删除该会话。"
  fi

  if xray_tunnel_is_running; then
    parsed_host="$(extract_xray_argo_host || true)"
    if [[ -n "$parsed_host" ]] && valid_argo_host "$parsed_host"; then
      XRAY_ARGO_HOST="$parsed_host"
      save_xray_state
      generate_xray_vless_link
      ok "Xray 临时 Argo 已在运行：${XRAY_ARGO_HOST}"
      return 0
    fi
  fi

  : > "$XRAY_LOG_FILE"
  chmod 600 "$XRAY_LOG_FILE"
  rm -f "$XRAY_CLOUDFLARED_PID_FILE" "$XRAY_VLESS_JSON_FILE" "$XRAY_VLESS_LINK_FILE"
  XRAY_ARGO_HOST=""
  save_xray_state
  mkdir -p "$XRAY_CLOUDFLARED_HOME"
  chown "$SERVICE_USER:$SERVICE_GROUP" "$XRAY_CLOUDFLARED_HOME" 2>/dev/null || true
  chmod 700 "$XRAY_CLOUDFLARED_HOME"

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    tmux new-session -d -s "$XRAY_TMUX_SESSION" "$XRAY_CLOUDFLARED_RUNNER" \
      || die "无法启动 Xray cloudflared tmux 会话。"

    if wait_for_xray_argo_host; then
      generate_xray_vless_link
      ok "Xray 临时 Argo 已启动：${XRAY_ARGO_HOST}"
      return 0
    fi

    stop_xray_tunnel || true
    if ((attempt < max_attempts)); then
      warn "未能获取 Xray 临时域名，${retry_delay} 秒后重试（${attempt}/${max_attempts}）。"
      sleep "$retry_delay"
    fi
  done

  if [[ -f "$XRAY_LOG_FILE" ]]; then
    warn "Xray cloudflared 最近日志："
    tail -n 80 "$XRAY_LOG_FILE" >&2 || true
  fi
  die "Xray cloudflared 未能在 90 秒内输出临时 trycloudflare.com 域名。"
}

url_encode() {
  jq -rn --arg value "$1" '$value | @uri'
}

generate_xray_vless_link() {
  valid_uuid "$XRAY_UUID" || die "Xray UUID 无效，无法生成 VLESS 链接。"
  valid_xray_ws_path "$XRAY_WS_PATH" || die "WS 路径无效，无法生成 VLESS 链接。"
  valid_argo_host "$XRAY_ARGO_HOST" || die "Xray 临时 Argo 域名无效。"
  [[ -n "$XRAY_ARGO_HOST" ]] || die "Xray 临时 Argo 域名为空。"
  valid_preferred_endpoint "$XRAY_PREFERRED_ENDPOINT" || die "Xray 优选域名/IP 无效。"
  valid_node_name "$XRAY_NODE_NAME" || die "Xray 节点名称无效。"
  valid_xray_vlessenc_value "$XRAY_VLESS_ENCRYPTION" || die "Xray VLESS-ENC encryption 无效。"

  local tmp_json=""
  local tmp_link=""
  local enc_encryption=""
  local enc_sni=""
  local enc_path=""
  local enc_node=""
  local enc_ech=""
  local node_name=""

  tmp_json="$(mktemp "${DATA_DIR}/.vless-ws.json.XXXXXX")"
  tmp_link="$(mktemp "${DATA_DIR}/.vless-ws.txt.XXXXXX")"

  node_name="${XRAY_NODE_NAME}"

  enc_encryption="$(url_encode "$XRAY_VLESS_ENCRYPTION")"
  enc_sni="$(url_encode "$XRAY_ARGO_HOST")"
  enc_path="$(url_encode "$XRAY_WS_PATH")"
  enc_node="$(url_encode "$node_name")"
  enc_ech="$(url_encode "$ECH_CONFIG")"

  jq -n \
    --arg protocol "vless" \
    --arg ps "$node_name" \
    --arg add "$XRAY_PREFERRED_ENDPOINT" \
    --arg port "443" \
    --arg id "$XRAY_UUID" \
    --arg encryption "$XRAY_VLESS_ENCRYPTION" \
    --arg security "tls" \
    --arg sni "$XRAY_ARGO_HOST" \
    --arg host "$XRAY_ARGO_HOST" \
    --arg path "$XRAY_WS_PATH" \
    --arg type "ws" \
    --arg flow "xtls-rprx-vision" \
    --arg ech "$ECH_CONFIG" \
    '{
      protocol: $protocol,
      ps: $ps,
      add: $add,
      port: ($port | tonumber),
      id: $id,
      encryption: $encryption,
      security: $security,
      sni: $sni,
      vcn: $sni,
      host: $host,
      path: $path,
      type: $type,
      flow: $flow,
      alpn: "http/1.1",
      fp: "firefox",
      ech: $ech,
      echConfigList: $ech
    }' > "$tmp_json"

  printf 'vless://%s@%s:443?encryption=%s&flow=xtls-rprx-vision&security=tls&sni=%s&vcn=%s&fp=firefox&type=ws&host=%s&path=%s&alpn=http%%2F1.1&ech=%s&echConfigList=%s#%s\n' \
    "$XRAY_UUID" \
    "$XRAY_PREFERRED_ENDPOINT" \
    "$enc_encryption" \
    "$enc_sni" \
    "$enc_sni" \
    "$enc_sni" \
    "$enc_path" \
    "$enc_ech" \
    "$enc_ech" \
    "$enc_node" \
    > "$tmp_link"

  if ! jq -e \
      --arg ps "$node_name" \
      --arg add "$XRAY_PREFERRED_ENDPOINT" \
      --arg host "$XRAY_ARGO_HOST" \
      --arg path "$XRAY_WS_PATH" \
      --arg encryption "$XRAY_VLESS_ENCRYPTION" \
      --arg ech "$ECH_CONFIG" \
      '.ps == $ps
        and .add == $add
        and .host == $host
        and .sni == $host
        and .vcn == $host
        and .path == $path
        and .type == "ws"
        and .flow == "xtls-rprx-vision"
        and .alpn == "http/1.1"
        and .encryption == $encryption
        and .ech == $ech
        and .echConfigList == $ech' \
      "$tmp_json" >/dev/null \
      || ! grep -Fq "&vcn=${enc_sni}" "$tmp_link"; then
    rm -f "$tmp_json" "$tmp_link"
    die "生成的 VLESS-ENC + WS 链接自检失败，未写入磁盘。"
  fi

  chmod 600 "$tmp_json" "$tmp_link"
  mv -f "$tmp_json" "$XRAY_VLESS_JSON_FILE"
  mv -f "$tmp_link" "$XRAY_VLESS_LINK_FILE"
  printf '%s\n' "$ECH_CONFIG" > "$ECH_NOTE_FILE"
  chmod 600 "$ECH_NOTE_FILE"
}
prepare_xray_deployment() {
  load_settings
  install_xray_if_needed
  install_cloudflared_if_needed
  ensure_service_account

  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR"
  chmod 750 "$DATA_DIR"

  if [[ $SETTINGS_CONFIGURED -ne 1 ]]; then
    PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
    XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
    LOCAL_PORT="$DEFAULT_LOCAL_PORT"
    NODE_NAME="$DEFAULT_NODE_NAME"
    DOH_ENABLED="$DEFAULT_DOH_ENABLED"
    WARP_ENABLED="$DEFAULT_WARP_ENABLED"
    OUTBOUND_IP_MODE="$DEFAULT_OUTBOUND_IP_MODE"
    save_settings
  fi

  [[ -n "${XRAY_PREFERRED_ENDPOINT:-}" ]] || XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
  load_xray_state
  if [[ -z "${XRAY_NODE_NAME:-}" || "$XRAY_NODE_NAME" == "zdd-argo-xray" ]]; then
    XRAY_NODE_NAME="$NODE_NAME"
  fi
}

rebuild_xray_deployment_after_stop() {
  generate_xray_identity

  xray_service_stop || true
  xray_service_reset_failed

  write_xray_config
  write_xray_service
  write_xray_cloudflared_runner
  write_logrotate_config

  ensure_xray_running
  start_xray_tunnel
}

command_generate_xray_vlessenc_ws() {
  deployment_transaction_begin xray
  prepare_xray_deployment

  stop_xray_tunnel || die "无法安全停止现有 Xray 临时隧道。"
  rebuild_xray_deployment_after_stop

  deployment_transaction_commit
  ok "Xray VLESS-ENC + WS 临时 Argo 已完成全新生成；现在可以直接断开 SSH。"
  show_xray_subscription
}

command_generate_xray_custom() {
  deployment_transaction_begin xray
  prepare_xray_deployment

  stop_xray_tunnel || die "无法安全停止现有 Xray 临时隧道。"
  configure_xray_custom_settings
  rebuild_xray_deployment_after_stop

  deployment_transaction_commit
  ok "Xray 自定义临时 Argo 已完成全新生成；现在可以直接断开 SSH。"
  show_xray_subscription
}

show_xray_subscription() {
  load_settings
  load_xray_state

  local running="否"
  local parsed_host=""

  if xray_runtime_is_running; then
    running="是"
    parsed_host="$(extract_xray_argo_host || true)"
    if [[ -n "$parsed_host" ]] && valid_argo_host "$parsed_host"; then
      if [[ "$XRAY_ARGO_HOST" != "$parsed_host" ]]; then
        XRAY_ARGO_HOST="$parsed_host"
        save_xray_state
      fi
    fi
    if [[ -n "$XRAY_ARGO_HOST" ]] && valid_argo_host "$XRAY_ARGO_HOST"; then
      generate_xray_vless_link
    fi
  fi

  print_section_header "zdd-argo Xray VLESS-ENC + WS" "$C_GREEN" 78
  print_kv "节点名称：" "${XRAY_NODE_NAME:-$NODE_NAME}" 18
  print_kv "优选域名/IP：" "${XRAY_PREFERRED_ENDPOINT:-未设置}" 18
  print_kv "传输方式：" "VLESS-ENC / WS / TLS" 18
  print_kv "出站策略：" "$(outbound_ip_mode_label)" 18
  print_kv "后台运行：" "$running" 18
  print_kv "加密参数：" "0rtt + xorpub，已隐藏" 18
  print_section_footer "$C_GREEN" 78

  if [[ -f "$XRAY_VLESS_LINK_FILE" ]]; then
    if ! xray_runtime_is_running; then
      warn "Xray 或其临时 Argo 隧道当前未完整运行；下面是保存的旧链接，目前不可用。"
    fi

    printf '\n%sXray 分享链接：%s\n' "$C_CYAN" "$C_RESET"
    cat "$XRAY_VLESS_LINK_FILE"
    printf '\n保存位置： %s\n' "$XRAY_VLESS_LINK_FILE"
    printf '\n%s\n' "导入后应显示 type=ws，alpn=http/1.1，SNI/Host 为临时 Argo 域名。"
  else
    warn "尚未生成临时 argo 隧道"
  fi
}
show_all_subscriptions() {
  if [[ -f "$STATE_JSON" ]]; then
    show_subscription
  else
    warn "sing-box：尚未生成临时 argo 隧道"
  fi

  printf '\n'

  if [[ -f "$XRAY_STATE_JSON" ]]; then
    show_xray_subscription
  else
    warn "Xray：尚未生成临时 argo 隧道"
  fi
}

deployment_transaction_begin() {
  local scope="${1:-all}"

  [[ "$scope" == "all" || "$scope" == "xray" ]] || scope="all"
  [[ $TRANSACTION_ACTIVE -eq 0 ]] || die "部署事务已经处于活动状态。"

  TRANSACTION_SCOPE="$scope"
  TRANSACTION_DIR="$(mktemp -d /tmp/zdd-argo-transaction.XXXXXX)"
  TRANSACTION_OLD_SERVICE_ACTIVE=0
  TRANSACTION_OLD_TUNNEL_RUNNING=0
  TRANSACTION_OLD_XRAY_SERVICE_ACTIVE=0
  TRANSACTION_OLD_XRAY_TUNNEL_RUNNING=0
  TRANSACTION_OLD_SERVICE_ACCOUNT=0
  TRANSACTION_OLD_SERVICE_GROUP=0
  TRANSACTION_OLD_SERVICE_HOME=0

  if getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    TRANSACTION_OLD_SERVICE_ACCOUNT=1
  fi
  if getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
    TRANSACTION_OLD_SERVICE_GROUP=1
  fi
  if [[ -d "$SERVICE_HOME" && ! -L "$SERVICE_HOME" ]]; then
    TRANSACTION_OLD_SERVICE_HOME=1
  fi

  if service_is_active; then
    TRANSACTION_OLD_SERVICE_ACTIVE=1
  fi
  if tunnel_is_running; then
    TRANSACTION_OLD_TUNNEL_RUNNING=1
  fi
  if xray_service_is_active; then
    TRANSACTION_OLD_XRAY_SERVICE_ACTIVE=1
  fi
  if xray_tunnel_is_running; then
    TRANSACTION_OLD_XRAY_TUNNEL_RUNNING=1
  fi

  if [[ -d "$DATA_DIR" ]]; then
    if ! cp -a "$DATA_DIR" "${TRANSACTION_DIR}/data"; then
      cleanup_transaction_dir "$TRANSACTION_DIR" || true
      TRANSACTION_DIR=""
      die "无法备份现有 zdd-argo 数据目录，部署尚未修改系统。"
    fi
    : > "${TRANSACTION_DIR}/had-data"
  fi

  if [[ -d "$BIN_DIR" ]]; then
    if ! cp -a "$BIN_DIR" "${TRANSACTION_DIR}/bin"; then
      cleanup_transaction_dir "$TRANSACTION_DIR" || true
      TRANSACTION_DIR=""
      die "无法备份现有 zdd-argo 程序目录，部署尚未修改系统。"
    fi
    : > "${TRANSACTION_DIR}/had-bin"
  fi

  if [[ -f "$SINGBOX_UNIT" || -L "$SINGBOX_UNIT" ]]; then
    if ! cp -a "$SINGBOX_UNIT" "${TRANSACTION_DIR}/sing-box.service"; then
      cleanup_transaction_dir "$TRANSACTION_DIR" || true
      TRANSACTION_DIR=""
      die "无法备份现有 sing-box 服务文件，部署尚未修改系统。"
    fi
    : > "${TRANSACTION_DIR}/had-unit"
  fi

  if [[ -f "$XRAY_UNIT" || -L "$XRAY_UNIT" ]]; then
    if ! cp -a "$XRAY_UNIT" "${TRANSACTION_DIR}/xray.service"; then
      cleanup_transaction_dir "$TRANSACTION_DIR" || true
      TRANSACTION_DIR=""
      die "无法备份现有 Xray 服务文件，部署尚未修改系统。"
    fi
    : > "${TRANSACTION_DIR}/had-xray-unit"
  fi

  if [[ -f "$LOGROTATE_CONFIG" || -L "$LOGROTATE_CONFIG" ]]; then
    if ! cp -a "$LOGROTATE_CONFIG" "${TRANSACTION_DIR}/logrotate"; then
      cleanup_transaction_dir "$TRANSACTION_DIR" || true
      TRANSACTION_DIR=""
      die "无法备份现有日志轮转配置，部署尚未修改系统。"
    fi
    : > "${TRANSACTION_DIR}/had-logrotate"
  fi

  TRANSACTION_ACTIVE=1
}

deployment_transaction_commit() {
  [[ $TRANSACTION_ACTIVE -eq 1 ]] || return 0
  TRANSACTION_ACTIVE=0

  if ! cleanup_transaction_dir "$TRANSACTION_DIR"; then
    warn "部署已提交，但事务临时目录无法通过安全校验或清理失败：${TRANSACTION_DIR}"
  fi

  TRANSACTION_SCOPE="all"
  TRANSACTION_DIR=""
}

deployment_transaction_rollback() {
  local reason="${1:-部署失败}"

  [[ $TRANSACTION_ACTIVE -eq 1 ]] || return 0
  TRANSACTION_ACTIVE=0

  warn "${reason}。"

  if ! managed_paths_are_safe; then
    warn "受管路径安全校验失败，未执行破坏性回滚；事务备份保留在：${TRANSACTION_DIR}"
    TRANSACTION_DIR=""
    return 0
  fi

  if [[ "${TRANSACTION_SCOPE:-all}" == "xray" ]]; then
    local rel=""

    (stop_xray_tunnel) >/dev/null 2>&1 || true

    if xray_unit_is_ours || xray_unit_is_legacy_ours; then
      xray_service_disable_now || true
    fi

    mkdir -p "$DATA_DIR"
    for rel in \
      "$(basename "$XRAY_CONFIG")" \
      "$(basename "$XRAY_STATE_JSON")" \
      "$(basename "$XRAY_CLOUDFLARED_RUNNER")" \
      "$(basename "$XRAY_CLOUDFLARED_PID_FILE")" \
      "$(basename "$XRAY_VLESS_JSON_FILE")" \
      "$(basename "$XRAY_VLESS_LINK_FILE")" \
      "$(basename "$SETTINGS_JSON")" \
      "$(basename "$ECH_NOTE_FILE")"
    do
      if [[ -f "${TRANSACTION_DIR}/had-data" \
          && ( -e "${TRANSACTION_DIR}/data/${rel}" \
            || -L "${TRANSACTION_DIR}/data/${rel}" ) ]]; then
        cp -a "${TRANSACTION_DIR}/data/${rel}" "${DATA_DIR}/${rel}" \
          || warn "回滚 Xray 数据文件失败：${DATA_DIR}/${rel}"
      else
        rm -f "${DATA_DIR}/${rel}"
      fi
    done

    mkdir -p "$BIN_DIR"
    for rel in \
      "$(basename "$MANAGED_XRAY_BIN")" \
      "$(basename "$XRAY_RELEASE_META")" \
      "$(basename "$MANAGED_CLOUDFLARED_BIN")" \
      "$(basename "$CLOUDFLARED_RELEASE_META")"
    do
      if [[ -f "${TRANSACTION_DIR}/had-bin" \
          && ( -e "${TRANSACTION_DIR}/bin/${rel}" \
            || -L "${TRANSACTION_DIR}/bin/${rel}" ) ]]; then
        cp -a "${TRANSACTION_DIR}/bin/${rel}" "${BIN_DIR}/${rel}" \
          || warn "回滚 Xray 程序文件失败：${BIN_DIR}/${rel}"
      else
        rm -f "${BIN_DIR}/${rel}"
      fi
    done

    rm -f -- "$XRAY_UNIT" "$LOGROTATE_CONFIG"
    if [[ -f "${TRANSACTION_DIR}/had-xray-unit" ]]; then
      cp -a "${TRANSACTION_DIR}/xray.service" "$XRAY_UNIT" \
        || warn "回滚 Xray 服务文件失败：${XRAY_UNIT}"
    fi
    if [[ -f "${TRANSACTION_DIR}/had-logrotate" ]]; then
      cp -a "${TRANSACTION_DIR}/logrotate" "$LOGROTATE_CONFIG" \
        || warn "回滚日志轮转配置失败：${LOGROTATE_CONFIG}"
    fi

    service_daemon_reload
    hash -r
    load_settings
    resolve_xray_bin
    resolve_cloudflared_bin

    if [[ $TRANSACTION_OLD_XRAY_SERVICE_ACTIVE -eq 1 ]] \
        && (xray_unit_is_ours || xray_unit_is_legacy_ours); then
      xray_service_enable_now || true
    fi

    if [[ $TRANSACTION_OLD_XRAY_TUNNEL_RUNNING -eq 1 \
        && -x "$XRAY_CLOUDFLARED_RUNNER" \
        && -f "$XRAY_STATE_JSON" ]]; then
      (
        load_xray_state
        if xray_service_is_active; then
          start_xray_tunnel
        fi
      ) >/dev/null 2>&1 || true
    fi

    if [[ $TRANSACTION_OLD_SERVICE_ACCOUNT -eq 0 ]]; then
      (remove_service_account) >/dev/null 2>&1 || true

      if ! getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
        if [[ $TRANSACTION_OLD_SERVICE_GROUP -eq 0 ]] \
            && getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
          groupdel "$SERVICE_GROUP" >/dev/null 2>&1 || true
        fi

        if [[ $TRANSACTION_OLD_SERVICE_HOME -eq 0 \
            && -d "$SERVICE_HOME" \
            && ! -L "$SERVICE_HOME" ]]; then
          rm -rf -- "$SERVICE_HOME"
        fi
      fi
    fi

    if [[ ! -f "${TRANSACTION_DIR}/had-data" ]]; then
      rmdir "$DATA_DIR" 2>/dev/null || true
    fi

    if ! cleanup_transaction_dir "$TRANSACTION_DIR"; then
      warn "Xray 回滚已完成，但临时备份目录未能安全清理：${TRANSACTION_DIR}"
    fi
    TRANSACTION_SCOPE="all"
    TRANSACTION_DIR=""
    warn "已执行 Xray 专项回滚；sing-box 服务和隧道未被回滚流程改动。"
    return 0
  fi

  (stop_tunnel) >/dev/null 2>&1 || true
  (stop_xray_tunnel) >/dev/null 2>&1 || true

  if singbox_unit_is_ours || singbox_unit_is_legacy_ours; then
    service_disable_now || true
  fi
  if xray_unit_is_ours || xray_unit_is_legacy_ours; then
    xray_service_disable_now || true
  fi

  rm -rf -- "$DATA_DIR"
  rm -rf -- "$BIN_DIR"
  rm -f -- "$SINGBOX_UNIT" "$XRAY_UNIT" "$LOGROTATE_CONFIG"

  if [[ -f "${TRANSACTION_DIR}/had-data" ]]; then
    cp -a "${TRANSACTION_DIR}/data" "$DATA_DIR" \
      || warn "回滚数据目录失败：${DATA_DIR}"
  fi
  if [[ -f "${TRANSACTION_DIR}/had-bin" ]]; then
    cp -a "${TRANSACTION_DIR}/bin" "$BIN_DIR" \
      || warn "回滚程序目录失败：${BIN_DIR}"
  fi
  if [[ -f "${TRANSACTION_DIR}/had-unit" ]]; then
    cp -a "${TRANSACTION_DIR}/sing-box.service" "$SINGBOX_UNIT" \
      || warn "回滚服务文件失败：${SINGBOX_UNIT}"
  fi
  if [[ -f "${TRANSACTION_DIR}/had-xray-unit" ]]; then
    cp -a "${TRANSACTION_DIR}/xray.service" "$XRAY_UNIT" \
      || warn "回滚 Xray 服务文件失败：${XRAY_UNIT}"
  fi
  if [[ -f "${TRANSACTION_DIR}/had-logrotate" ]]; then
    cp -a "${TRANSACTION_DIR}/logrotate" "$LOGROTATE_CONFIG" \
      || warn "回滚日志轮转配置失败：${LOGROTATE_CONFIG}"
  fi

  service_daemon_reload
  load_settings
  resolve_singbox_bin
  resolve_xray_bin
  resolve_cloudflared_bin

  if [[ $TRANSACTION_OLD_SERVICE_ACTIVE -eq 1 ]] \
      && (singbox_unit_is_ours || singbox_unit_is_legacy_ours); then
    service_enable_now || true
  fi

  if [[ $TRANSACTION_OLD_TUNNEL_RUNNING -eq 1 \
      && -x "$CLOUDFLARED_RUNNER" \
      && -f "$STATE_JSON" ]]; then
    (
      load_state
      if service_is_active; then
        start_tunnel
      fi
    ) >/dev/null 2>&1 || true
  fi

  if [[ $TRANSACTION_OLD_XRAY_SERVICE_ACTIVE -eq 1 ]] \
      && (xray_unit_is_ours || xray_unit_is_legacy_ours); then
    xray_service_enable_now || true
  fi

  if [[ $TRANSACTION_OLD_XRAY_TUNNEL_RUNNING -eq 1 \
      && -x "$XRAY_CLOUDFLARED_RUNNER" \
      && -f "$XRAY_STATE_JSON" ]]; then
    (
      load_xray_state
      if xray_service_is_active; then
        start_xray_tunnel
      fi
    ) >/dev/null 2>&1 || true
  fi

  if [[ $TRANSACTION_OLD_SERVICE_ACCOUNT -eq 0 ]]; then
    (remove_service_account) >/dev/null 2>&1 || true

    if ! getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
      if [[ $TRANSACTION_OLD_SERVICE_GROUP -eq 0 ]] \
          && getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
        groupdel "$SERVICE_GROUP" >/dev/null 2>&1 || true
      fi

      if [[ $TRANSACTION_OLD_SERVICE_HOME -eq 0 \
          && -d "$SERVICE_HOME" \
          && ! -L "$SERVICE_HOME" ]]; then
        rm -rf -- "$SERVICE_HOME"
      fi
    fi
  fi

  if ! cleanup_transaction_dir "$TRANSACTION_DIR"; then
    warn "事务回滚已完成，但临时备份目录未能安全清理：${TRANSACTION_DIR}"
  fi
  TRANSACTION_SCOPE="all"
  TRANSACTION_DIR=""

  warn "已执行回滚；Quick Tunnel 域名无法原样恢复，若旧隧道曾运行，脚本已尽力重新创建。"
}

prepare_deployment() {
  load_settings
  install_singbox_if_needed
  install_cloudflared_if_needed
  ensure_service_account

  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR"
  chmod 750 "$DATA_DIR"

  if [[ $SETTINGS_CONFIGURED -ne 1 ]]; then
    PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
    XRAY_PREFERRED_ENDPOINT="$DEFAULT_XRAY_PREFERRED_ENDPOINT"
    LOCAL_PORT="$DEFAULT_LOCAL_PORT"
    NODE_NAME="$DEFAULT_NODE_NAME"
    DOH_ENABLED="$DEFAULT_DOH_ENABLED"
    WARP_ENABLED="$DEFAULT_WARP_ENABLED"
    OUTBOUND_IP_MODE="$DEFAULT_OUTBOUND_IP_MODE"
    save_settings
  fi

  load_state
}

rebuild_deployment_after_stop() {
  generate_identity

  service_stop || true
  service_reset_failed

  write_singbox_config
  write_singbox_service
  write_cloudflared_runner
  write_logrotate_config

  ensure_singbox_running
  verify_warp_runtime
  start_tunnel
}

command_generate_noninteractive() {
  deployment_transaction_begin
  prepare_deployment

  stop_tunnel || die "无法安全停止现有临时隧道。"

  DOH_ENABLED="0"
  WARP_ENABLED="0"
  save_settings

  rebuild_deployment_after_stop

  deployment_transaction_commit
  ok "临时 Argo 已完成全新生成，当前使用直接出站；现在可以直接断开 SSH。"
  show_subscription
}

command_generate_noninteractive_doh_warp() {
  deployment_transaction_begin
  prepare_deployment

  stop_tunnel || die "无法安全停止现有临时隧道。"

  DOH_ENABLED="1"
  WARP_ENABLED="1"
  save_settings
  warn "本次无交互部署将启用 Cloudflare DoH（1.1.1.1）和 WARP；首次注册会调用第三方 wgcf 并使用 --accept-tos。"

  rebuild_deployment_after_stop

  deployment_transaction_commit
  ok "临时 Argo 已完成全新生成，并已启用 DoH 与 WARP 出站；现在可以直接断开 SSH。"
  show_subscription
}

command_generate_custom() {
  deployment_transaction_begin
  prepare_deployment

  stop_tunnel || die "无法安全停止现有临时隧道。"
  configure_custom_settings
  rebuild_deployment_after_stop

  deployment_transaction_commit
  ok "自定义临时 Argo 已完成全新生成；现在可以直接断开 SSH。"
  show_subscription
}

show_subscription() {
  load_settings
  load_state

  local running="否"
  local parsed_host=""

  if singbox_runtime_is_running; then
    running="是"
    parsed_host="$(extract_argo_host || true)"

    if [[ -n "$parsed_host" ]] && valid_argo_host "$parsed_host"; then
      if [[ "$ARGO_HOST" != "$parsed_host" ]]; then
        ARGO_HOST="$parsed_host"
        save_state
      fi
    fi

    if [[ -n "$ARGO_HOST" ]] && valid_argo_host "$ARGO_HOST"; then
      generate_vmess_link
    fi
  fi

  print_section_header "zdd-argo sing-box VMess/WS" "$C_GREEN" 78
  print_kv "节点名称：" "$NODE_NAME" 20
  print_kv "优选域名/IP：" "${PREFERRED_ENDPOINT:-未设置}" 20
  print_kv "临时 Argo 域名：" "${ARGO_HOST:-尚未生成}" 20
  print_kv "UUID：" "${UUID:-尚未生成}" 20
  print_kv "WS 路径：" "${WSPATH:-尚未生成}" 20
  print_kv "本地监听：" "127.0.0.1:${LOCAL_PORT}" 20
  print_kv "出站策略：" "$(outbound_ip_mode_label)" 20
  if [[ "$DOH_ENABLED" == "1" ]]; then
    print_kv "Cloudflare DoH：" "已启用（1.1.1.1）" 20
  else
    print_kv "Cloudflare DoH：" "未启用" 20
  fi
  print_kv "Cloudflare WARP：" "$(feature_label "$WARP_ENABLED")" 20
  print_kv "后台隧道运行：" "$running" 20
  print_kv "ECHConfigList：" "$ECH_CONFIG" 20
  print_section_footer "$C_GREEN" 78
  printf '\n'

  if [[ -f "$VMESS_LINK_FILE" ]]; then
    if ! singbox_runtime_is_running; then
      warn "sing-box 或其临时 Argo 隧道当前未完整运行；下面是保存的旧链接，目前不可用。"
    fi

    printf '%ssing-box 分享链接：%s\n' "$C_CYAN" "$C_RESET"
    cat "$VMESS_LINK_FILE"
    printf '\n保存位置： %s\n' "$VMESS_LINK_FILE"
    printf '\n%sECH 兼容提示：%s\n' "$C_YELLOW" "$C_RESET"
    printf '%s\n' "脚本已同时写入 JSON 字段 ech 与 echConfigList。"
    printf '%s导入 Xray 客户端后，请检查 EchConfigList 是否为：%s\n' "$C_YELLOW" "$C_RESET"
    printf '%s%s%s\n' "$C_YELLOW" "$ECH_CONFIG" "$C_RESET"
    printf '%s\n' "若客户端忽略旧式 VMess JSON 的扩展字段，请手动粘贴这一行。"
  else
    warn "尚未生成临时 argo 隧道"
  fi
}

show_status() {
  load_settings

  if command -v jq >/dev/null 2>&1; then
    load_state
    load_xray_state
  else
    UUID=""
    WSPATH=""
    ARGO_HOST=""
    CREATED_AT=""
    XRAY_UUID=""
    XRAY_WS_PATH=""
    XRAY_ARGO_HOST=""
  fi

  resolve_singbox_bin
  resolve_xray_bin
  resolve_cloudflared_bin
  resolve_wgcf_bin

  print_section_header "zdd-argo 运行状态" "$C_CYAN" 78

  print_kv "脚本版本：" "v ${SCRIPT_VERSION}" 22
  print_kv "运行平台：" "$(runtime_label)" 22
  print_kv "优选域名/IP：" "${PREFERRED_ENDPOINT:-未设置}" 22
  print_kv "节点名称：" "$NODE_NAME" 22
  print_kv "出站策略：" "$(outbound_ip_mode_label)" 22
  if [[ "$DOH_ENABLED" == "1" ]]; then
    print_kv "Cloudflare DoH：" "已启用（1.1.1.1）" 22
  else
    print_kv "Cloudflare DoH：" "未启用" 22
  fi
  print_kv "Cloudflare WARP：" "$(feature_label "$WARP_ENABLED")" 22

  if [[ "$WARP_ENABLED" == "1" && -f "$WARP_CHECK_FILE" ]]; then
    local warp_checked=""
    local warp_exit_ip=""
    local warp_colo=""
    local warp_state=""

    warp_checked="$(jq -r '.checked_at // "未知"' "$WARP_CHECK_FILE" 2>/dev/null || printf '%s' "未知")"
    warp_exit_ip="$(jq -r '.exit_ip // "未知"' "$WARP_CHECK_FILE" 2>/dev/null || printf '%s' "未知")"
    warp_colo="$(jq -r '.colo // "未知"' "$WARP_CHECK_FILE" 2>/dev/null || printf '%s' "未知")"
    warp_state="$(jq -r '.warp // "未知"' "$WARP_CHECK_FILE" 2>/dev/null || printf '%s' "未知")"

    print_kv "WARP 自检：" "${warp_state} / ${warp_exit_ip} / ${warp_colo}" 22
    print_kv "WARP 自检时间：" "$warp_checked" 22
  fi

  print_aligned_label "sing-box：" 22
  if [[ -n "$SINGBOX_BIN" ]]; then
    "$SINGBOX_BIN" version \
      2>/dev/null \
      | head -n 1 \
      || printf '%s\n' "已安装"

    print_aligned_label "sing-box 路径：" 22
    printf '%s' "$SINGBOX_BIN"

    if [[ "$SINGBOX_BIN" == "$MANAGED_SINGBOX_BIN" ]]; then
      printf ' %s\n' "（脚本专用，SHA-256 已校验）"
    else
      printf ' %s\n' "（外部安装）"
    fi
  else
    printf '%s%s%s\n' "$C_RED" "未安装" "$C_RESET"
  fi

  print_aligned_label "Xray：" 22
  if [[ -n "$XRAY_BIN" ]]; then
    "$XRAY_BIN" version \
      2>/dev/null \
      | head -n 1 \
      || printf '%s\n' "已安装"

    print_aligned_label "Xray 路径：" 22
    printf '%s' "$XRAY_BIN"

    if [[ "$XRAY_BIN" == "$MANAGED_XRAY_BIN" ]]; then
      printf ' %s\n' "（脚本专用，SHA-256 已校验）"
    else
      printf ' %s\n' "（外部安装）"
    fi
  else
    printf '%s%s%s\n' "$C_RED" "未安装" "$C_RESET"
  fi

  print_aligned_label "cloudflared：" 22
  if [[ -n "$CLOUDFLARED_BIN" ]]; then
    "$CLOUDFLARED_BIN" --version \
      2>/dev/null \
      || printf '%s\n' "已安装"

    print_aligned_label "cloudflared 路径：" 22
    printf '%s' "$CLOUDFLARED_BIN"

    if [[ "$CLOUDFLARED_BIN" == "$MANAGED_CLOUDFLARED_BIN" ]]; then
      printf ' %s\n' "（脚本专用，SHA-256 已校验）"
    else
      printf ' %s\n' "（外部安装）"
    fi
  else
    printf '%s%s%s\n' "$C_RED" "未安装" "$C_RESET"
  fi

  print_aligned_label "wgcf：" 22
  if [[ -n "$WGCF_BIN" ]]; then
    if [[ -f "$WGCF_RELEASE_META" ]]; then
      printf '%s\n' "$(jq -r '.tag // \"已安装\"' "$WGCF_RELEASE_META" 2>/dev/null || printf '%s' "已安装")"
    else
      printf '%s\n' "已安装（外部版本）"
    fi

    print_kv "WARP 配置：" "$([[ -f "$WARP_PROFILE_FILE" ]] && printf '%s' "已生成" || printf '%s' "未生成")" 22
  else
    printf '%s%s%s\n' "$C_RED" "未安装" "$C_RESET"
  fi

  print_aligned_label "sing-box 服务：" 22
  if service_is_active; then
    printf '%s%s%s\n' "$C_GREEN" "运行中" "$C_RESET"
  else
    printf '%s%s%s\n' "$C_RED" "未运行" "$C_RESET"
  fi

  print_aligned_label "本地端口：" 22
  if listener_exact_loopback; then
    printf '%s127.0.0.1:%s 正常%s\n' "$C_GREEN" "$LOCAL_PORT" "$C_RESET"
  else
    printf '%s%s%s\n' "$C_RED" "未检测到正确监听" "$C_RESET"
  fi

  print_aligned_label "Argo / tmux：" 22
  if singbox_runtime_is_running; then
    printf '%s运行中%s（会话：%s）\n' "$C_GREEN" "$C_RESET" "$(active_tunnel_session 2>/dev/null || printf '%s' "$TMUX_SESSION")"
  else
    printf '%s未运行%s\n' "$C_RED" "$C_RESET"
  fi

  print_kv "临时域名：" "${ARGO_HOST:-尚未生成}" 22

  if [[ -f "$XRAY_STATE_JSON" ]]; then
    printf '
'
    print_kv "Xray 节点名称：" "${XRAY_NODE_NAME:-未设置}" 22
    print_kv "Xray 本地监听：" "127.0.0.1:${XRAY_LOCAL_PORT:-$DEFAULT_XRAY_LOCAL_PORT}" 22
    if xray_service_is_active; then
      print_kv "Xray 服务：" "运行中" 22
    else
      print_kv "Xray 服务：" "未运行" 22
    fi
    if xray_runtime_is_running; then
      print_kv "Xray Argo：" "运行中" 22
    else
      print_kv "Xray Argo：" "未运行" 22
    fi
    print_kv "Xray 当前域名：" "${XRAY_ARGO_HOST:-—}" 22
  fi

  local resolved_zargo=""
  resolved_zargo="$(type -P zargo 2>/dev/null || true)"

  print_aligned_label "管理命令：" 22
  if resolved_zdd_is_ours "$resolved_zargo"; then
    printf '%szargo%s（%s）\n' "$C_GREEN" "$C_RESET" "$resolved_zargo"
  elif [[ -n "$resolved_zargo" ]]; then
    printf '%s被其他程序占用%s（%s）\n' "$C_RED" "$C_RESET" "$resolved_zargo"
  else
    printf '%s未找到%s\n' "$C_RED" "$C_RESET"
  fi

  print_section_footer "$C_CYAN" 78

  printf '\n%s\n' "最近 30 行 sing-box 日志："
  service_print_logs 30

  if [[ -f "$LOG_FILE" ]]; then
    printf '\n%s\n' "最近 20 行 cloudflared 日志："
    tail -n 20 "$LOG_FILE" || true
  fi
}

command_update_singbox() {
  local had_deployment=0
  local config_refresh=0

  load_settings

  if [[ -f "$SINGBOX_CONFIG" \
      || -f "$SINGBOX_UNIT" ]]; then
    had_deployment=1
    if singbox_config_needs_refresh; then
      config_refresh=1
    fi
  fi

  install_or_update_singbox
  resolve_singbox_bin

  if [[ $had_deployment -eq 1 \
      && -f "$SINGBOX_CONFIG" ]]; then
    load_state

    if [[ $config_refresh -eq 1 ]]; then
      ensure_service_account
      write_singbox_config
    else
      "$SINGBOX_BIN" check \
        -c "$SINGBOX_CONFIG" \
        || die "$(printf '%s' "更新后的 sing-box 无法通过现有 zdd-argo 配置校验。")"
    fi

    write_singbox_service

    service_restart \
      || die "$(printf '%s' "sing-box 已更新，但服务重启失败；拒绝继续使用旧进程。")"

    if ! wait_for_singbox_ready; then
      ensure_singbox_running
    fi

    ok "$(printf '%s' "脚本专用 sing-box 已更新，zdd-argo 服务运行正常。")"
  else
    ok "$(printf '%s' "脚本专用 sing-box 已安装或更新；当前未发现 zdd-argo 部署。")"
  fi
}


command_update_xray() {
  local had_deployment=0

  load_settings

  if [[ -f "$XRAY_CONFIG" || -f "$XRAY_UNIT" ]]; then
    had_deployment=1
  fi

  install_or_update_xray
  resolve_xray_bin

  if [[ $had_deployment -eq 1 && -f "$XRAY_CONFIG" ]]; then
    load_xray_state
    write_xray_config
    "$XRAY_BIN" run -test -config "$XRAY_CONFIG" \
      || die "更新后的 Xray 无法通过现有 VLESS-ENC + WS 配置校验。"

    write_xray_service

    xray_service_restart \
      || die "Xray 已更新，但服务重启失败；拒绝继续使用旧进程。"

    if ! wait_for_xray_ready; then
      ensure_xray_running
    fi

    ok "脚本专用 Xray 已更新，Xray VLESS-ENC + WS 服务运行正常。"
  else
    ok "脚本专用 Xray 已安装或更新；当前未发现 Xray 部署。"
  fi
}

command_update_cloudflared() {
  local had_deployment=0

  load_settings

  if [[ -f "$CLOUDFLARED_RUNNER" \
      || -f "$STATE_JSON" ]]; then
    had_deployment=1
  fi

  install_or_update_cloudflared
  resolve_cloudflared_bin

  if [[ $had_deployment -eq 1 ]]; then
    if [[ -f "$STATE_JSON" || -f "$CLOUDFLARED_RUNNER" ]]; then
      write_cloudflared_runner
    fi
    if [[ -f "$XRAY_STATE_JSON" || -f "$XRAY_CLOUDFLARED_RUNNER" ]]; then
      load_xray_state
      write_xray_cloudflared_runner
    fi

    ok "$(printf '%s' "脚本专用 cloudflared 已更新；当前正在运行的隧道不会中断，下次重建时使用新版本。")"
  else
    ok "$(printf '%s' "脚本专用 cloudflared 已安装或更新；当前未发现 zdd-argo 部署。")"
  fi
}

command_update_wgcf() {
  load_settings

  if [[ "$WARP_ENABLED" != "1" \
      && ! -x "$MANAGED_WGCF_BIN" ]]; then
    info "WARP 未启用且脚本专用 wgcf 未安装，跳过 wgcf 更新。"
    return 0
  fi

  install_or_update_wgcf
  resolve_wgcf_bin
  ok "脚本专用 wgcf 已安装或更新；下次启用 WARP 时会直接刷新并覆盖 WireGuard profile。"
}

command_update_components() {
  info "开始更新 sing-box、Xray、cloudflared 和已启用的 WARP 工具……"
  deployment_transaction_begin

  command_update_singbox
  command_update_xray
  command_update_cloudflared
  command_update_wgcf

  if singbox_runtime_is_running; then
    load_state
    generate_vmess_link
  fi
  if xray_runtime_is_running; then
    load_xray_state
    generate_xray_vless_link
  fi

  deployment_transaction_commit
  ok "sing-box、Xray、cloudflared 与 WARP 工具已完成更新检查。"
}

remove_zdd_components() {
  assert_safe_managed_paths
  load_settings
  resolve_singbox_bin
  resolve_xray_bin
  resolve_cloudflared_bin
  stop_tunnel || true
  stop_xray_tunnel || true

  if [[ -e "$SINGBOX_UNIT" || -L "$SINGBOX_UNIT" ]]; then
    if singbox_unit_is_ours || singbox_unit_is_legacy_ours; then
      service_disable_now || true
      rm -f "$SINGBOX_UNIT"
    else
      die "服务文件不是本项目创建的，拒绝继续卸载：${SINGBOX_UNIT}"
    fi
  fi

  if [[ -e "$XRAY_UNIT" || -L "$XRAY_UNIT" ]]; then
    if xray_unit_is_ours || xray_unit_is_legacy_ours; then
      xray_service_disable_now || true
      rm -f "$XRAY_UNIT"
    else
      die "Xray 服务文件不是本项目创建的，拒绝继续卸载：${XRAY_UNIT}"
    fi
  fi

  if [[ -e "$LOGROTATE_CONFIG" || -L "$LOGROTATE_CONFIG" ]]; then
    if logrotate_config_is_ours || logrotate_config_is_legacy_ours; then
      rm -f "$LOGROTATE_CONFIG"
    else
      warn "日志轮转配置不是本项目创建的，未删除：${LOGROTATE_CONFIG}"
    fi
  fi

  service_daemon_reload
  service_reset_failed
  xray_service_reset_failed

  rm -rf -- "$DATA_DIR"
  rm -f -- \
    "$LOG_FILE" \
    "$LOG_FILE".* \
    "$XRAY_LOG_FILE" \
    "$XRAY_LOG_FILE".* \
    "$SINGBOX_LOG_FILE" \
    "$SINGBOX_LOG_FILE".* \
    "$XRAY_CORE_LOG_FILE" \
    "$XRAY_CORE_LOG_FILE".*
}

confirm_yes() {
  local prompt="$1"
  local answer=""

  read_interactive answer "$prompt" "" \
    || die "$(printf '%s' "此操作必须在交互式终端中执行。")"

  answer="${answer#"${answer%%[![:space:]]*}"}"
  answer="${answer%"${answer##*[![:space:]]}"}"

  [[ "${answer,,}" == "yes" ]]
}

resolve_recorded_source() {
  local -a lines=()

  secure_root_file "$SOURCE_RECORD_FILE" || return 1
  mapfile -t lines < "$SOURCE_RECORD_FILE"

  [[ ${#lines[@]} -eq 2 ]] || return 1
  [[ "${lines[0]}" == /* \
    && "${lines[0]}" != "$MANAGED_SCRIPT_PATH" \
    && "${lines[0]}" != *$'\n'* \
    && "${lines[0]}" != *$'\r'* ]] \
    || return 1
  [[ "${lines[1]}" =~ ^[0-9a-fA-F]{64}$ ]] || return 1

  printf '%s\n%s\n' "${lines[0]}" "${lines[1],,}"
}

remove_downloaded_source_if_confirmed() {
  local record=""
  local -a lines=()
  local source=""
  local expected_sha=""
  local actual_sha=""
  local owner_uid=""

  if ! record="$(resolve_recorded_source 2>/dev/null)"; then
    info "未找到可信且完整的安装源记录，不自动定位或删除 root 目录中的其他脚本。"
    return 0
  fi

  mapfile -t lines <<< "$record"
  [[ ${#lines[@]} -eq 2 ]] || return 0
  source="${lines[0]}"
  expected_sha="${lines[1]}"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    info "已记录的安装源文件不存在：${source}"
    return 0
  fi

  if [[ ! -f "$source" || -L "$source" ]]; then
    warn "安装源路径不是普通文件或属于符号链接，未删除：${source}"
    return 0
  fi

  owner_uid="$(stat -Lc '%u' "$source" 2>/dev/null || true)"
  if [[ "$owner_uid" != "0" ]]; then
    warn "安装源文件不属于 root，未删除：${source}"
    return 0
  fi

  if ! script_file_is_ours "$source"; then
    warn "安装源文件未通过项目标识校验，未删除：${source}"
    return 0
  fi

  actual_sha="$(sha256sum "$source" | awk '{print $1}')"
  if [[ ! "$actual_sha" =~ ^[0-9a-fA-F]{64}$ \
      || "${actual_sha,,}" != "$expected_sha" ]]; then
    warn "安装源文件内容与安装时记录不一致，未删除：${source}"
    return 0
  fi

  rm -f -- "$source" \
    || die "无法删除安装源文件：${source}"

  ok "安装源文件已删除：${source}"
}

remove_shortcuts() {
  local path=""

  for path in \
    "$SHORTCUT_FALLBACK_PATH" \
    "$SHORTCUT_COMPAT_PATH" \
    "$SHORTCUT_PATH" \
    "${LEGACY_ZDD_PATHS[@]}" \
    "$LEGACY_SHORTCUT_PATH" \
    "$LEGACY_SHORTCUT_BIN"
  do
    [[ -e "$path" || -L "$path" ]] || continue

    if [[ \
      ( "$path" == "$SHORTCUT_COMPAT_PATH" \
        || "$path" == "$SHORTCUT_FALLBACK_PATH" ) \
      && -L "$path" \
    ]] && [[ \
      "$(readlink "$path" 2>/dev/null || true)" \
        == "$SHORTCUT_PATH" \
    ]]; then
      rm -f "$path"
    elif path_is_replaceable_zdd_launcher "$path"; then
      rm -f "$path"
    else
      info "检测到非本项目创建的快捷命令，出于安全已保留：${path}"
    fi
  done
}

remove_managed_script() {
  if [[ -e "$MANAGED_SCRIPT_PATH" ]]; then
    if script_file_is_ours "$MANAGED_SCRIPT_PATH"; then
      rm -f \
        "$MANAGED_SCRIPT_PATH" \
        "${MANAGED_SCRIPT_PATH}.new."*
    else
      warn "$(printf '%s' "已安装脚本副本未通过项目标识校验，未删除：${MANAGED_SCRIPT_PATH}")"
    fi
  fi
}

snapshot_service_account_processes() {
  local service_uid="$1"
  local status=""
  local pid=""
  local uid=""
  local start=""

  for status in /proc/[0-9]*/status; do
    [[ -r "$status" ]] || continue
    pid="${status#/proc/}"
    pid="${pid%/status}"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue

    uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
    [[ "$uid" == "$service_uid" ]] || continue

    start="$(process_start_time "$pid" 2>/dev/null || true)"
    [[ "$start" =~ ^[0-9]+$ ]] || continue
    printf '%s %s\n' "$pid" "$start"
  done
}

service_process_identity_matches() {
  local pid="$1"
  local recorded_start="$2"
  local expected_uid="$3"
  local actual_start=""
  local actual_uid=""
  local state=""

  actual_start="$(process_start_time "$pid" 2>/dev/null || true)"
  actual_uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
  state="$(process_state "$pid" 2>/dev/null || true)"

  [[ "$actual_start" == "$recorded_start" \
    && "$actual_uid" == "$expected_uid" \
    && "$state" != "Z" \
    && "$state" != "X" ]]
}

signal_service_process_snapshot() {
  local signal_name="$1"
  local snapshot_file="$2"
  local expected_uid="$3"
  local pid=""
  local recorded_start=""

  while IFS=' ' read -r pid recorded_start; do
    [[ "$pid" =~ ^[0-9]+$ && "$recorded_start" =~ ^[0-9]+$ ]] || continue
    service_process_identity_matches "$pid" "$recorded_start" "$expected_uid" || continue
    kill "-${signal_name}" "$pid" 2>/dev/null || true
  done < "$snapshot_file"
}

service_process_snapshot_has_live_processes() {
  local snapshot_file="$1"
  local expected_uid="$2"
  local pid=""
  local recorded_start=""

  while IFS=' ' read -r pid recorded_start; do
    [[ "$pid" =~ ^[0-9]+$ && "$recorded_start" =~ ^[0-9]+$ ]] || continue
    if service_process_identity_matches "$pid" "$recorded_start" "$expected_uid"; then
      return 0
    fi
  done < "$snapshot_file"

  return 1
}

stop_service_account_processes() {
  local service_uid="$1"
  local snapshot_file=""
  local i=0

  snapshot_file="$(mktemp)"
  snapshot_service_account_processes "$service_uid" > "$snapshot_file"

  if [[ ! -s "$snapshot_file" ]]; then
    rm -f "$snapshot_file"
    return 0
  fi

  warn "检测到低权限服务账户仍有残留进程，正在安全终止。"
  signal_service_process_snapshot TERM "$snapshot_file" "$service_uid"

  for ((i = 0; i < 8; i++)); do
    service_process_snapshot_has_live_processes "$snapshot_file" "$service_uid" || break
    sleep 1
  done

  if service_process_snapshot_has_live_processes "$snapshot_file" "$service_uid"; then
    signal_service_process_snapshot KILL "$snapshot_file" "$service_uid"

    for ((i = 0; i < 3; i++)); do
      service_process_snapshot_has_live_processes "$snapshot_file" "$service_uid" || break
      sleep 1
    done
  fi

  if service_process_snapshot_has_live_processes "$snapshot_file" "$service_uid"; then
    warn "以下残留进程在复核 PID、启动时间和 UID 后仍未退出："
    cat "$snapshot_file" >&2
    rm -f "$snapshot_file"
    return 1
  fi

  rm -f "$snapshot_file"
  return 0
}

validate_service_account_removal() {
  local passwd_line=""
  local existing_home=""
  local existing_gid=""
  local expected_gid=""

  if getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    service_marker_is_recognized \
      || die "低权限服务账户无法通过完整归属校验，卸载尚未修改系统：${SERVICE_USER}"

    passwd_line="$(getent passwd "$SERVICE_USER")"
    IFS=':' read -r _ _ _ existing_gid _ existing_home _ <<< "$passwd_line"
    expected_gid="$(getent group "$SERVICE_GROUP" | awk -F: '{print $3}')"

    [[ "$existing_home" == "$SERVICE_HOME" ]] \
      || die "低权限服务账户主目录不匹配，卸载尚未修改系统：${SERVICE_USER}"
    [[ -n "$expected_gid" && "$existing_gid" == "$expected_gid" ]] \
      || die "低权限服务账户主组不匹配，卸载尚未修改系统：${SERVICE_USER}"
  elif [[ -e "$SERVICE_MARKER" || -L "$SERVICE_MARKER" ]]; then
    service_marker_is_recognized \
      || die "服务账户标记无法通过完整归属校验，卸载尚未修改系统：${SERVICE_MARKER}"
    [[ -d "$SERVICE_HOME" && ! -L "$SERVICE_HOME" ]] \
      || die "低权限服务主目录不是普通目录，卸载尚未修改系统：${SERVICE_HOME}"
  fi
}

remove_service_account() {
  local passwd_line=""
  local existing_home=""
  local existing_gid=""
  local expected_gid=""
  local service_uid=""
  local userdel_error=""

  [[ "$SERVICE_HOME" == "/var/lib/zdd-argo" ]] \
    || die "低权限服务账户主目录常量异常，拒绝卸载账户。"

  if ! getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    if [[ -e "$SERVICE_MARKER" || -L "$SERVICE_MARKER" ]]; then
      service_marker_is_recognized \
        || die "检测到无法确认归属的服务账户标记，已保留服务组和主目录：${SERVICE_MARKER}"

      if getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
        groupdel "$SERVICE_GROUP" >/dev/null 2>&1 \
          || die "无法删除低权限服务组 ${SERVICE_GROUP}。"
      fi

      [[ -d "$SERVICE_HOME" && ! -L "$SERVICE_HOME" ]] \
        || die "低权限服务主目录不是普通目录，拒绝删除：${SERVICE_HOME}"
      rm -rf -- "$SERVICE_HOME"
    fi
    return 0
  fi

  service_marker_is_recognized \
    || die "低权限服务账户无法通过完整归属校验，已停止卸载：${SERVICE_USER}"

  passwd_line="$(getent passwd "$SERVICE_USER")"
  IFS=':' read -r _ _ service_uid existing_gid _ existing_home _ <<< "$passwd_line"
  expected_gid="$(getent group "$SERVICE_GROUP" | awk -F: '{print $3}')"

  [[ "$existing_home" == "$SERVICE_HOME" ]] \
    || die "低权限服务账户主目录不匹配，已停止卸载：${SERVICE_USER}"
  [[ -n "$expected_gid" && "$existing_gid" == "$expected_gid" ]] \
    || die "低权限服务账户主组不匹配，已停止卸载：${SERVICE_USER}"
  [[ "$service_uid" =~ ^[0-9]+$ ]] \
    || die "无法读取低权限服务账户 ${SERVICE_USER} 的 UID。"

  service_stop || true
  xray_service_stop || true
  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    systemctl kill --kill-who=all --signal=TERM "$SERVICE_NAME" >/dev/null 2>&1 || true
    systemctl kill --kill-who=all --signal=TERM "$XRAY_SERVICE_NAME" >/dev/null 2>&1 || true
  fi
  stop_service_account_processes "$service_uid" \
    || die "无法安全终止低权限服务账户 ${SERVICE_USER} 的残留进程。"

  userdel_error="$(mktemp)"
  if ! userdel "$SERVICE_USER" 2> "$userdel_error"; then
    stop_service_account_processes "$service_uid" || true

    if ! userdel "$SERVICE_USER" 2>> "$userdel_error"; then
      cat "$userdel_error" >&2 || true
      rm -f "$userdel_error"
      die "无法删除低权限服务账户 ${SERVICE_USER}。"
    fi
  fi
  rm -f "$userdel_error"

  if getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
    groupdel "$SERVICE_GROUP" >/dev/null 2>&1 \
      || die "无法删除低权限服务组 ${SERVICE_GROUP}。"
  fi

  [[ -d "$SERVICE_HOME" && ! -L "$SERVICE_HOME" ]] \
    || die "低权限服务主目录不是普通目录，拒绝删除：${SERVICE_HOME}"
  rm -rf -- "$SERVICE_HOME"
}

command_uninstall_all() {
  warn "此操作会停止临时 Argo，并删除 zdd-argo 配置、日志、订阅、WARP 账户、快捷命令、低权限账户及脚本专用 sing-box/Xray/cloudflared/wgcf。"
  warn "不会删除 apt、apk 或其他脚本安装的共享程序和系统依赖。"

  if ! confirm_yes "确认完整卸载请输入 yes："; then
    info "已取消。"
    return 0
  fi

  validate_service_account_removal
  remove_zdd_components
  remove_service_account
  remove_singbox_program
  remove_xray_program
  remove_cloudflared_program
  remove_wgcf_program
  remove_shortcuts
  remove_managed_script
  service_daemon_reload
  remove_downloaded_source_if_confirmed
  cleanup_bin_dir

  ok "zdd-argo 及脚本专用 sing-box、Xray、cloudflared、wgcf 已完整卸载。"

  if [[ $MENU_MODE -eq 1 ]]; then
    return 10
  fi
}

remove_singbox_program() {
  rm -f \
    "$MANAGED_SINGBOX_BIN" \
    "$SINGBOX_RELEASE_META" \
    "${MANAGED_SINGBOX_BIN}.new."* \
    "${MANAGED_SINGBOX_BIN}.backup."* \
    "${SINGBOX_RELEASE_META}.backup."*

  hash -r
}

remove_xray_program() {
  rm -f \
    "$MANAGED_XRAY_BIN" \
    "$XRAY_RELEASE_META" \
    "${MANAGED_XRAY_BIN}.new."* \
    "${MANAGED_XRAY_BIN}.backup."* \
    "${XRAY_RELEASE_META}.backup."*

  hash -r
}

remove_cloudflared_program() {
  rm -f \
    "$MANAGED_CLOUDFLARED_BIN" \
    "$CLOUDFLARED_RELEASE_META" \
    "${MANAGED_CLOUDFLARED_BIN}.new."* \
    "${MANAGED_CLOUDFLARED_BIN}.backup."* \
    "${CLOUDFLARED_RELEASE_META}.backup."*

  hash -r
}

remove_wgcf_program() {
  rm -f \
    "$MANAGED_WGCF_BIN" \
    "$WGCF_RELEASE_META" \
    "${MANAGED_WGCF_BIN}.new."* \
    "${MANAGED_WGCF_BIN}.backup."* \
    "${WGCF_RELEASE_META}.backup."*

  hash -r
}

cleanup_bin_dir() {
  rm -f -- "$SOURCE_RECORD_FILE" "${SOURCE_RECORD_FILE}.new."*
  rmdir "$BIN_DIR" \
    2>/dev/null \
    || true
}

status_running_color() {
  local value="$1"

  if [[ "$value" == "运行中" ]]; then
    printf '%s' "$C_YELLOW"
  fi
}

status_print_value() {
  local value="$1"
  local color=""

  color="$(status_running_color "$value")"
  printf '%s%s%s' "$color" "$value" "$C_RESET"
}

status_core_line() {
  local label="$1"
  local version="$2"
  local state="$3"
  local label_width="12"
  local version_width="32"

  print_aligned_label "$label" "$label_width"
  print_aligned_label "$version" "$version_width"
  status_print_value "$state"
  printf '\n'
}

print_menu_row() {
  local index="$1"
  local title="$2"
  local desc="$3"
  local desc_column=44
  local prefix="${index}. "
  local prefix_width=""
  local title_width=""

  prefix_width="$(text_display_width "$prefix")"
  [[ "$prefix_width" =~ ^[0-9]+$ ]] || prefix_width="${#prefix}"
  title_width=$((desc_column - prefix_width))
  ((title_width >= 1)) || title_width=1

  printf '%s' "$prefix"
  print_aligned_label "$title" "$title_width"
  printf '%s\n' "$desc"
}

menu_header_status() {
  local sb_version="未安装"
  local xr_version="未安装"
  local sb_state="未运行"
  local xr_state="未运行"

  resolve_singbox_bin
  resolve_xray_bin

  if [[ -n "$SINGBOX_BIN" ]]; then
    sb_version="$(
      "$SINGBOX_BIN" version 2>/dev/null \
        | awk 'NR == 1 {
            if ($1 == "sing-box" && $2 == "version" && $3 != "") {
              print "v" $3
            } else {
              print "已安装"
            }
          }' \
        || true
    )"
    [[ -n "$sb_version" ]] || sb_version="已安装"
  fi

  if [[ -n "$XRAY_BIN" ]]; then
    xr_version="$(
      "$XRAY_BIN" version 2>/dev/null \
        | awk 'NR == 1 {
            if ($1 == "Xray" && $2 != "") {
              print "v" $2
            } else {
              print "已安装"
            }
          }' \
        || true
    )"
    [[ -n "$xr_version" ]] || xr_version="已安装"
  fi

  if singbox_runtime_is_running; then
    sb_state="运行中"
  fi
  if xray_runtime_is_running; then
    xr_state="运行中"
  fi

  print_section_header "zargo 临时隧道" "$C_YELLOW" 78
  status_core_line "sing-box：" "$sb_version" "$sb_state"
  status_core_line "Xray：" "$xr_version" "$xr_state"
  print_section_footer "$C_CYAN" 78
}

run_menu_action() {
  local fn="$1"
  local rc=0

  shift
  set +e

  (
    set -Eeuo pipefail
    "$fn" "$@"
  )

  rc=$?
  set -e

  if [[ $rc -eq 10 ]]; then
    printf '\n%s' "卸载流程已经完成。按 Enter 后退出并清空屏幕……"
    local ignored=""
    read_interactive ignored "" "" || true
    clear_screen
    exit 0
  elif [[ $rc -ne 0 ]]; then
    error "操作失败，退出码：${rc}"
  fi

  pause_screen
}

select_runtime_auto() {
  local choice=""

  while true; do
    clear_screen
    print_section_header "自动生成" "$C_YELLOW" 78
    print_menu_row "1" "sing-box · VMess/WS" "直出"
    print_menu_row "2" "Xray · VLESS-ENC/WS" "直出"
    print_menu_row "0" "返回" "主菜单"
    print_section_footer "$C_CYAN" 78

    read_interactive choice "选择内核 [0-2]：" "0" || choice="0"
    clear_screen

    case "$choice" in
      1)
        run_menu_action run_with_lock command_generate_noninteractive
        return 0
        ;;
      2)
        run_menu_action run_with_lock command_generate_xray_vlessenc_ws
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        warn "无效选择：${choice}"
        pause_screen
        ;;
    esac
  done
}

select_runtime_custom() {
  local choice=""

  while true; do
    clear_screen
    print_section_header "自定义生成" "$C_YELLOW" 78
    print_menu_row "1" "sing-box · VMess/WS" "端口 / 名称 / DoH / WARP"
    print_menu_row "2" "Xray · VLESS-ENC/WS" "端口 / 名称 / 优选"
    print_menu_row "0" "返回" "主菜单"
    print_section_footer "$C_CYAN" 78

    read_interactive choice "选择内核 [0-2]：" "0" || choice="0"
    clear_screen

    case "$choice" in
      1)
        run_menu_action run_with_lock command_generate_custom
        return 0
        ;;
      2)
        run_menu_action run_with_lock command_generate_xray_custom
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        warn "无效选择：${choice}"
        pause_screen
        ;;
    esac
  done
}

select_stop_scope() {
  local choice=""

  while true; do
    clear_screen
    print_section_header "停止隧道" "$C_YELLOW" 78
    print_menu_row "1" "sing-box" "仅断开 sing-box 临时 Argo"
    print_menu_row "2" "Xray" "仅断开 Xray 临时 Argo"
    print_menu_row "3" "全部" "断开 sing-box / Xray"
    print_menu_row "0" "返回" "主菜单"
    print_section_footer "$C_CYAN" 78

    read_interactive choice "选择范围 [0-3]：" "0" || choice="0"
    clear_screen

    case "$choice" in
      1)
        run_menu_action run_with_lock command_stop_singbox_tunnel
        return 0
        ;;
      2)
        run_menu_action run_with_lock command_stop_xray_tunnel
        return 0
        ;;
      3)
        run_menu_action run_with_lock command_stop_clear_cache
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        warn "无效选择：${choice}"
        pause_screen
        ;;
    esac
  done
}

interactive_menu() {
  MENU_MODE=1
  trap 'clear_screen; exit 130' INT TERM

  while true; do
    clear_screen
    menu_header_status

    print_menu_row "1" "自动生成" "选择 sing-box / Xray"
    print_menu_row "2" "自定义生成" "分别配置 sing-box / Xray"
    print_menu_row "3" "查看订阅" "sing-box / Xray"
    print_menu_row "4" "状态日志" "服务 / 端口 / 隧道"
    print_menu_row "5" "停止隧道" "sing-box / Xray"
    print_menu_row "6" "更新组件" "sing-box / Xray / cloudflared"
    print_menu_row "7" "完整卸载" "含 sing-box / Xray"
    print_menu_row "0" "退出" ""

    printf '%s%s%s\n' "$C_CYAN" \
      '==============================================================================' \
      "$C_RESET"
    printf '%s%s%s\n' "$C_YELLOW" "提示：退出后输入 zargo 可重新打开菜单。" "$C_RESET"

    local choice=""
    read_interactive choice "选择操作 [0-7]：" "0" || choice="0"
    clear_screen

    case "$choice" in
      1)
        select_runtime_auto
        ;;
      2)
        select_runtime_custom
        ;;
      3)
        run_menu_action run_with_lock show_all_subscriptions
        ;;
      4)
        run_menu_action show_status
        ;;
      5)
        select_stop_scope
        ;;
      6)
        run_menu_action run_with_lock command_update_components
        ;;
      7)
        run_menu_action run_with_lock command_uninstall_all
        ;;
      0)
        clear_screen
        exit 0
        ;;
      *)
        warn "无效选择：${choice}"
        pause_screen
        ;;
    esac
  done
}
managed_paths_are_safe() {
  [[ "$DATA_DIR" == "/etc/zdd-argo" \
    && "$BIN_DIR" == "/usr/local/lib/zdd-argo" \
    && "$SERVICE_HOME" == "/var/lib/zdd-argo" \
    && "$LOCK_DIR" == "/run/lock/zdd-argo.lock.d" \
    && "$SINGBOX_SYSTEMD_UNIT" == "/etc/systemd/system/zdd-argo-singbox.service" \
    && "$SINGBOX_OPENRC_SERVICE" == "/etc/init.d/zdd-argo-singbox" \
    && "$XRAY_SYSTEMD_UNIT" == "/etc/systemd/system/zdd-argo-xray.service" \
    && "$XRAY_OPENRC_SERVICE" == "/etc/init.d/zdd-argo-xray" \
    && "$LOGROTATE_CONFIG" == "/etc/logrotate.d/zdd-argo-cloudflared" ]] \
    || return 1

  local path=""
  for path in "$DATA_DIR" "$BIN_DIR" "$SERVICE_HOME"; do
    [[ ! -L "$path" ]] || return 1
  done
}

assert_safe_managed_paths() {
  managed_paths_are_safe \
    || die "受管路径常量异常或路径属于符号链接，拒绝继续。"
}

bootstrap() {
  require_root
  check_os
  assert_safe_managed_paths
  install_dependencies
  install_shortcut
}

main() {
  ensure_utf8_locale
  resolve_script_path

  if [[ "$#" -ne 0 ]]; then
    die "本项目安装后只提供一个无参数管理命令：zargo"
  fi

  bootstrap
  interactive_menu
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
