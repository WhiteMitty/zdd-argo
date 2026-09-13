#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

SCRIPT_VERSION="0.2.0"
BUILD_ID="DUAL-CORE-REFACTOR-20260913"
MIN_SINGBOX_VERSION="1.12.0"
MIN_XRAY_VERSION="25.10.0"

DEFAULT_NODE_NAME="zdd-argo"
DEFAULT_PREFERRED_ENDPOINT="saas.sin.fan"
DEFAULT_SB_PORT="10000"
DEFAULT_XR_PORT="10001"
DEFAULT_IP_MODE="prefer_ipv4"
DEFAULT_ECH_CONFIG="cloudflare-ech.com+https://doh.pub/dns-query"
WS_EARLY_DATA="2048"

DATA_DIR="/etc/zdd-argo"
BIN_DIR="/usr/local/lib/zdd-argo"
SERVICE_HOME="/var/lib/zdd-argo"
SERVICE_USER="zdd-argo-svc"
SERVICE_GROUP="zdd-argo-svc"
SERVICE_MARKER="${SERVICE_HOME}/.managed-by-zdd-argo"
SERVICE_MARKER_CONTENT="zdd-argo-service-account-v0.1.0"
SERVICE_SHELL="/usr/sbin/nologin"

SETTINGS_JSON="${DATA_DIR}/settings.json"
WARP_DIR="${DATA_DIR}/warp"
WARP_ACCOUNT_FILE="${WARP_DIR}/wgcf-account.toml"
WARP_PROFILE_FILE="${WARP_DIR}/wgcf-profile.conf"
WARP_CHECK_FILE="${WARP_DIR}/warp-check.json"
LOGROTATE_CONFIG="/etc/logrotate.d/zdd-argo-cloudflared"
LOCK_FILE="/run/lock/zdd-argo.lock"
LEGACY_LOCK_DIR="/run/lock/zdd-argo.lock.d"

SHORTCUT_PATH="/usr/local/bin/zargo"
SHORTCUT_COMPAT_PATH="/usr/local/sbin/zargo"
SHORTCUT_FALLBACK_PATH="/usr/bin/zargo"
LEGACY_SHORTCUT_PATHS=(
  "/usr/bin/zdd" "/usr/local/sbin/zdd" "/usr/local/bin/zdd"
  "/usr/local/sbin/zdd-argo" "/usr/local/bin/zdd-argo"
)

MANAGED_SCRIPT_PATH="${BIN_DIR}/zdd-argo.sh"
SOURCE_RECORD_FILE="${BIN_DIR}/source-record"
MANAGED_SINGBOX_BIN="${BIN_DIR}/sing-box"
MANAGED_XRAY_BIN="${BIN_DIR}/xray"
MANAGED_CLOUDFLARED_BIN="${BIN_DIR}/cloudflared"
MANAGED_WGCF_BIN="${BIN_DIR}/wgcf"
SINGBOX_RELEASE_META="${BIN_DIR}/sing-box.release.json"
XRAY_RELEASE_META="${BIN_DIR}/xray.release.json"
CLOUDFLARED_RELEASE_META="${BIN_DIR}/cloudflared.release.json"
WGCF_RELEASE_META="${BIN_DIR}/wgcf.release.json"
GITHUB_API_BASE="https://api.github.com"

SB_LABEL="sing-box"
SB_PROTO="VMess-WS"
SB_CONFIG="${DATA_DIR}/sing-box.json"
SB_STATE="${DATA_DIR}/state.json"
SB_SERVICE="zdd-argo-singbox"
SB_RUNNER="${DATA_DIR}/run-cloudflared.sh"
SB_CF_HOME="${SERVICE_HOME}/cloudflared-home"
SB_TUNNEL_LOG="/var/log/zdd-argo-cloudflared.log"
SB_CORE_LOG="/var/log/zdd-argo-singbox.log"
SB_SESSION="zdd-argo-singbox"
SB_LINK="${DATA_DIR}/vmess.txt"
SB_LINK_JSON="${DATA_DIR}/vmess.json"

XR_LABEL="Xray"
XR_PROTO="VLESS-ENC-WS"
XR_CONFIG="${DATA_DIR}/xray-vlessenc-ws.json"
XR_STATE="${DATA_DIR}/xray-state.json"
XR_SERVICE="zdd-argo-xray"
XR_RUNNER="${DATA_DIR}/run-cloudflared-xray.sh"
XR_CF_HOME="${SERVICE_HOME}/cloudflared-home-xray"
XR_TUNNEL_LOG="/var/log/zdd-argo-xray-cloudflared.log"
XR_CORE_LOG="/var/log/zdd-argo-xray.log"
XR_SESSION="zdd-argo-xr"
XR_LINK="${DATA_DIR}/vless-ws.txt"
XR_LINK_JSON="${DATA_DIR}/vless-ws.json"

LEGACY_SESSIONS=("zdd-argo")
LEGACY_DATA_FILES=(
  "${DATA_DIR}/ech.txt" "${DATA_DIR}/state.env" "${DATA_DIR}/state.env.migrated"
  "${DATA_DIR}/state.env.invalid" "${DATA_DIR}/cloudflared.pid" "${DATA_DIR}/cloudflared-xray.pid"
)

INIT_SYSTEM=""
SCRIPT_PATH=""
MENU_MODE=0
LOCK_FD=""
IP_MODE_CHANGED=0

IP_MODE="$DEFAULT_IP_MODE"
SB_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
SB_PORT="$DEFAULT_SB_PORT"
SB_NODE="$DEFAULT_NODE_NAME"
SB_DOH="0"
SB_WARP="0"
XR_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
XR_PORT="$DEFAULT_XR_PORT"
XR_NODE="$DEFAULT_NODE_NAME"
XR_ECH="$DEFAULT_ECH_CONFIG"

SB_UUID="" SB_WS_PATH="" SB_ARGO_HOST="" SB_CREATED_AT=""
XR_UUID="" XR_WS_PATH="" XR_ARGO_HOST="" XR_CREATED_AT=""
XR_ENC=""
XR_DEC=""

WARP_PRIVATE_KEY=""
WARP_IPV4=""
WARP_IPV6=""
WARP_PEER_PUBLIC_KEY=""
WARP_ENDPOINT_ADDRESS=""
WARP_ENDPOINT_PORT=""
WARP_PROFILE_ENDPOINT_PORT=""
WARP_MTU="1280"

CORE=""
P=""
CORE_LABEL=""
CORE_PROTO=""
CORE_CONFIG=""
CORE_STATE=""
CORE_SERVICE=""
CORE_UNIT=""
CORE_RUNNER=""
CORE_CF_HOME=""
CORE_TUNNEL_LOG=""
CORE_CORE_LOG=""
CORE_SESSION=""
CORE_LINK=""
CORE_LINK_JSON=""
CORE_BIN=""

UI_WIDTH=78
UI_INDENT="  "
UI_LABEL_WIDTH=16
UI_MENU_WIDTH=14

if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_HL=$'\033[1;93m'
  C_RESET=$'\033[0m'
else
  C_GREEN="" C_YELLOW="" C_RED="" C_CYAN="" C_DIM="" C_BOLD="" C_HL="" C_RESET=""
fi

info()  { printf '%s[信息]%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }
ok()    { printf '%s[完成]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s[注意]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
error() { printf '%s[错误]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()   { error "$*"; exit 1; }
hint()  { printf '%s%s%s%s\n' "$UI_INDENT" "$C_DIM" "$*" "$C_RESET"; }

clear_screen() {
  [[ -t 1 ]] && printf '\033[2J\033[H'
  return 0
}

text_width() {
  local value="$1"
  local chars=${#value}
  local bytes=0
  bytes="$(LC_ALL=C; printf '%s' "${#value}")"
  printf '%s' "$((chars + (bytes - chars) / 2))"
}

pad_text() {
  local value="$1"
  local width="$2"
  local actual=0
  actual="$(text_width "$value")"
  printf '%s' "$value"
  ((width > actual)) && printf '%*s' "$((width - actual))" ''
  return 0
}

repeat_char() {
  local char="$1"
  local count="$2"
  local buffer=""
  ((count > 0)) || return 0
  printf -v buffer '%*s' "$count" ''
  printf '%s' "${buffer// /$char}"
}

ui_line() {
  printf '%s' "$C_CYAN"
  repeat_char '=' "$UI_WIDTH"
  printf '%s\n' "$C_RESET"
}

ui_title() {
  local title="$1"
  local color="${2:-$C_BOLD}"
  local width=0
  local left=0
  local right=0

  width="$(text_width "$title")"
  if ((width + 2 >= UI_WIDTH)); then
    printf '%s%s%s\n' "$color" "$title" "$C_RESET"
    return 0
  fi

  left=$(((UI_WIDTH - width - 2) / 2))
  right=$((UI_WIDTH - width - 2 - left))
  printf '%s' "$C_CYAN"
  repeat_char '=' "$left"
  printf ' %s%s%s ' "$color" "$title" "$C_CYAN"
  repeat_char '=' "$right"
  printf '%s\n' "$C_RESET"
}

ui_kv() {
  local label="$1"
  local value="$2"
  local color="${3:-}"

  [[ -n "$value" ]] || value="-"
  printf '%s' "$UI_INDENT"
  pad_text "$label" "$UI_LABEL_WIDTH"
  printf '%s%s%s\n' "$color" "$value" "$C_RESET"
}

ui_menu_row() {
  local index="$1"
  local title="$2"
  local desc="${3:-}"

  printf '%s%s%s%s  ' "$UI_INDENT" "$C_BOLD" "$index" "$C_RESET"
  if [[ -n "$desc" ]]; then
    pad_text "$title" "$UI_MENU_WIDTH"
    printf '%s%s%s\n' "$C_DIM" "$desc" "$C_RESET"
  else
    printf '%s\n' "$title"
  fi
}

ui_text() {
  printf '%s%s\n' "$UI_INDENT" "$*"
}

state_text() {
  if [[ "${1:-0}" == "1" ]]; then
    printf '%s开启%s' "$C_HL" "$C_RESET"
  else
    printf '%s关闭%s' "$C_DIM" "$C_RESET"
  fi
}

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

  if ! IFS= read -r -u "$input_fd" -p "${UI_INDENT}${prompt}" value; then
    value="$default_value"
  fi
  [[ $input_fd -ne 0 ]] && exec {input_fd}<&-

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf -v "$variable_name" '%s' "$value"
}

pause_screen() {
  local choice=""

  [[ -t 0 || -r /dev/tty ]] || return 0
  printf '\n'
  while true; do
    read_interactive choice "输入 0 返回菜单：" "" || return 0
    [[ "$choice" == "0" ]] && return 0
    warn "请输入 0。"
  done
}

confirm_yn() {
  local prompt="$1"
  local answer=""

  read_interactive answer "${prompt} [y/N]：" "" || die "此操作必须在交互式终端中执行。"
  [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

confirm_yes() {
  local prompt="$1"
  local answer=""

  read_interactive answer "$prompt" "" || die "此操作必须在交互式终端中执行。"
  [[ "${answer,,}" == "yes" ]]
}

ensure_utf8_locale() {
  local current=""
  local candidate=""

  if command -v locale >/dev/null 2>&1; then
    current="$(locale charmap 2>/dev/null || true)"
    [[ "${current^^}" == "UTF-8" || "${current^^}" == "UTF8" ]] && return 0
    for candidate in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
      current="$(LC_ALL="$candidate" locale charmap 2>/dev/null || true)"
      if [[ "${current^^}" == "UTF-8" || "${current^^}" == "UTF8" ]]; then
        export LANG="$candidate" LC_ALL="$candidate"
        return 0
      fi
    done
  fi
  export LANG=C.UTF-8 LC_ALL=C.UTF-8
}

resolve_script_path() {
  local candidate="${BASH_SOURCE[0]:-}"
  local dir=""

  [[ -n "$candidate" ]] || return 0
  [[ "$candidate" != /* ]] && candidate="$(pwd)/$candidate"
  dir="$(dirname -- "$candidate")"
  dir="$(cd -- "$dir" 2>/dev/null && pwd -P || printf '%s' "$dir")"
  SCRIPT_PATH="${dir}/$(basename -- "$candidate")"
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "请使用 root 运行此脚本。"
}

utc_now() {
  date -u +'%Y-%m-%dT%H:%M:%SZ'
}

file_sha256() {
  sha256sum "$1" 2>/dev/null | awk '{print tolower($1)}'
}

version_ge() {
  local -a va=() vb=()
  local i=0 x=0 y=0

  IFS='.' read -r -a va <<< "${1//[^0-9.]/}"
  IFS='.' read -r -a vb <<< "${2//[^0-9.]/}"
  for ((i = 0; i < 3; i++)); do
    x="${va[i]:-0}"
    y="${vb[i]:-0}"
    ((10#$x > 10#$y)) && return 0
    ((10#$x < 10#$y)) && return 1
  done
  return 0
}

write_file_atomic() {
  local target="$1"
  local mode="$2"
  local owner="${3:-root:root}"
  local tmp=""

  mkdir -p "$(dirname -- "$target")"
  tmp="$(mktemp "$(dirname -- "$target")/.$(basename -- "$target").XXXXXX")"
  cat > "$tmp" || { rm -f "$tmp"; return 1; }
  chmod "$mode" "$tmp"
  chown "$owner" "$tmp" 2>/dev/null || true
  mv -f "$tmp" "$target"
}

process_start_time() {
  local pid="$1"
  local stat_line=""
  local -a fields=()

  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/${pid}/stat" ]] || return 1
  IFS= read -r stat_line < "/proc/${pid}/stat" || return 1
  [[ "$stat_line" == *") "* ]] || return 1
  IFS=' ' read -r -a fields <<< "${stat_line##*) }"
  [[ ${#fields[@]} -ge 20 && "${fields[19]}" =~ ^[0-9]+$ ]] || return 1
  printf '%s\n' "${fields[19]}"
}

process_state() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/${pid}/status" ]] || return 1
  awk '$1 == "State:" { print substr($2, 1, 1); exit }' "/proc/${pid}/status" 2>/dev/null
}

process_command_line() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/${pid}/cmdline" ]] || return 1
  tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null
}

process_effective_uid() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ && -r "/proc/${pid}/status" ]] || return 1
  awk '$1 == "Uid:" { print $3; exit }' "/proc/${pid}/status" 2>/dev/null
}

process_is_alive() {
  local state=""
  state="$(process_state "$1" 2>/dev/null || true)"
  [[ -n "$state" && "$state" != "Z" && "$state" != "X" ]]
}

process_children() {
  local parent="$1"
  local status="" child="" ppid=""

  for status in /proc/[0-9]*/status; do
    [[ -r "$status" ]] || continue
    child="${status#/proc/}"
    child="${child%/status}"
    ppid="$(awk '$1 == "PPid:" { print $2; exit }' "$status" 2>/dev/null || true)"
    [[ "$ppid" == "$parent" ]] && printf '%s\n' "$child"
  done
  return 0
}

stop_process_verified() {
  local pid="$1"
  local recorded_start="$2"
  local wait_seconds="${3:-8}"
  local i=0

  [[ "$pid" =~ ^[0-9]+$ && "$recorded_start" =~ ^[0-9]+$ ]] || return 0
  [[ "$(process_start_time "$pid" 2>/dev/null || true)" == "$recorded_start" ]] || return 0

  kill -TERM "$pid" 2>/dev/null || true
  for ((i = 0; i < wait_seconds; i++)); do
    [[ "$(process_start_time "$pid" 2>/dev/null || true)" == "$recorded_start" ]] && process_is_alive "$pid" || return 0
    sleep 1
  done

  if [[ "$(process_start_time "$pid" 2>/dev/null || true)" == "$recorded_start" ]]; then
    kill -KILL "$pid" 2>/dev/null || true
    sleep 1
  fi
  [[ "$(process_start_time "$pid" 2>/dev/null || true)" == "$recorded_start" ]] && process_is_alive "$pid" && return 1
  return 0
}

secure_root_file() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || return 1
  [[ "$(stat -Lc '%u' "$path" 2>/dev/null)" == "0" && "$(stat -Lc '%a' "$path" 2>/dev/null)" == "600" ]]
}

check_os() {
  [[ -r /etc/os-release ]] || die "无法识别操作系统，仅支持 Debian / Ubuntu / Alpine。"
  source /etc/os-release

  case "${ID:-}" in
    debian|ubuntu) INIT_SYSTEM="systemd" ;;
    alpine)        INIT_SYSTEM="openrc" ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*) INIT_SYSTEM="systemd" ;;
        *) die "当前系统为 ${PRETTY_NAME:-未知}，本脚本仅支持 Debian / Ubuntu / Alpine。" ;;
      esac
      ;;
  esac

  if [[ "$INIT_SYSTEM" == "openrc" ]]; then
    SERVICE_SHELL="/bin/false"
    [[ -x /sbin/nologin ]] && SERVICE_SHELL="/sbin/nologin"
    SB_UNIT="/etc/init.d/${SB_SERVICE}"
    XR_UNIT="/etc/init.d/${XR_SERVICE}"
  else
    SB_UNIT="/etc/systemd/system/${SB_SERVICE}.service"
    XR_UNIT="/etc/systemd/system/${XR_SERVICE}.service"
  fi
}

runtime_label() {
  case "$INIT_SYSTEM" in
    systemd) printf 'Debian/Ubuntu + systemd' ;;
    openrc)  printf 'Alpine + OpenRC' ;;
    *)       printf '未知' ;;
  esac
}

wget_is_usable() {
  command -v wget >/dev/null 2>&1 && wget --version >/dev/null 2>&1
}

download_tool_available() {
  command -v curl >/dev/null 2>&1 || wget_is_usable
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a APT_LISTCHANGES_FRONTEND=none
  apt-get update || die "apt-get update 失败。"
  apt-get install -y "$@" || die "依赖安装失败：$*"
}

ensure_alpine_community_repo() {
  local repo_file="/etc/apk/repositories"
  local branch="edge"
  local release=""

  [[ -f "$repo_file" ]] || return 1
  grep -Eq '^[[:space:]]*https?://.*/community([[:space:]]|$)' "$repo_file" && return 0

  release="$(cat /etc/alpine-release 2>/dev/null || true)"
  [[ "$release" =~ ^([0-9]+)\.([0-9]+) ]] && branch="v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
  warn "未检测到 Alpine community 仓库，正在追加 ${branch}/community。"
  printf 'https://dl-cdn.alpinelinux.org/alpine/%s/community\n' "$branch" >> "$repo_file" || return 1
  apk update >/dev/null 2>&1 || true
}

ensure_alpine_binary_compat() {
  [[ "$INIT_SYSTEM" == "openrc" ]] || return 0
  command -v apk >/dev/null 2>&1 || return 1

  if apk info -e gcompat >/dev/null 2>&1 || apk info -e libc6-compat >/dev/null 2>&1; then
    apk info -e libstdc++ >/dev/null 2>&1 || apk add --no-cache libstdc++ >/dev/null 2>&1 || true
    return 0
  fi

  info "Alpine 正在安装二进制兼容库（gcompat / libstdc++）……"
  apk add --no-cache gcompat libstdc++ >/dev/null 2>&1 && return 0
  ensure_alpine_community_repo || true
  apk add --no-cache gcompat libstdc++ >/dev/null 2>&1 && return 0
  apk add --no-cache libc6-compat libstdc++ >/dev/null 2>&1 && return 0
  warn "无法自动安装 Alpine 二进制兼容库；如二进制自检失败，请手动安装 gcompat。"
  return 1
}

install_dependencies() {
  local missing=0
  local cmd=""
  local -a required=(
    curl jq openssl tmux ss base64 awk sed grep tar unzip sha256sum find
    install mktemp readlink stat getent useradd groupadd userdel groupdel flock logrotate
  )

  [[ -n "$INIT_SYSTEM" ]] || check_os

  case "$INIT_SYSTEM" in
    systemd)
      [[ -d /run/systemd/system ]] || die "当前系统不是由 systemd 管理，无法创建后台服务。"
      command -v systemctl >/dev/null 2>&1 || die "未找到 systemctl。"
      command -v journalctl >/dev/null 2>&1 || die "未找到 journalctl。"
      required+=(setpriv)
      ;;
    openrc)
      command -v apk >/dev/null 2>&1 || die "Alpine 模式未找到 apk。"
      if ! command -v rc-service >/dev/null 2>&1 || ! command -v rc-update >/dev/null 2>&1; then
        info "正在安装 openrc……"
        apk add --no-cache openrc || die "Alpine openrc 安装失败。"
      fi
      required+=(su-exec)
      ;;
    *)
      die "无法识别服务管理器：${INIT_SYSTEM:-unknown}。"
      ;;
  esac

  for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || { missing=1; break; }
  done
  download_tool_available || missing=1
  if [[ $missing -eq 0 ]]; then
    if [[ "$INIT_SYSTEM" == "openrc" ]]; then ensure_alpine_binary_compat || true; fi
    return 0
  fi

  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    info "安装 Debian / Ubuntu 基础依赖……"
    command -v apt-get >/dev/null 2>&1 || die "未找到 apt-get，无法自动安装依赖。"
    apt_install curl wget jq openssl ca-certificates tmux iproute2 coreutils tar unzip \
      findutils grep sed gawk passwd util-linux logrotate libc-bin
  else
    info "安装 Alpine / OpenRC 基础依赖……"
    apk add --no-cache bash curl wget jq openssl ca-certificates tmux iproute2 coreutils tar unzip \
      findutils grep sed gawk shadow su-exec logrotate musl-utils \
      || die "Alpine 基础依赖安装失败。"
    ensure_alpine_binary_compat || true
  fi

  for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || die "依赖安装后仍未找到命令：${cmd}"
  done
}

lock_owner_alive() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  process_is_alive "$pid" || return 1
  [[ "$(process_command_line "$pid" 2>/dev/null || true)" == *zdd-argo* ]]
}

acquire_lock() {
  local owner="" attempt=0

  [[ -n "$LOCK_FD" ]] && return 0
  mkdir -p "$(dirname -- "$LOCK_FILE")"

  for attempt in 1 2; do
    exec {LOCK_FD}>>"$LOCK_FILE"
    chmod 600 "$LOCK_FILE" 2>/dev/null || true
    if flock -n "$LOCK_FD"; then
      : > "$LOCK_FILE"
      printf '%s\n' "$BASHPID" > "$LOCK_FILE"
      return 0
    fi
    owner="$(head -n 1 "$LOCK_FILE" 2>/dev/null || true)"
    exec {LOCK_FD}>&-
    LOCK_FD=""
    if [[ $attempt -eq 1 ]] && ! lock_owner_alive "$owner"; then
      rm -f -- "$LOCK_FILE"
      continue
    fi
    warn "另一个 zargo 操作正在进行${owner:+（PID ${owner}）}，请等待它结束后再试。"
    exit 1
  done
}

run_without_lock_fd() {
  if [[ -n "$LOCK_FD" ]]; then
    "$@" {LOCK_FD}>&-
  else
    "$@"
  fi
}

spawn_detached() {
  if [[ -n "$LOCK_FD" ]]; then
    exec "$@" {LOCK_FD}>&-
  else
    exec "$@"
  fi
}

run_with_lock() {
  local fn="$1"
  shift
  acquire_lock
  install_dependencies
  "$fn" "$@"
}

script_file_is_ours() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || return 1
  grep -Eq '^SCRIPT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$' "$path" 2>/dev/null || return 1
  grep -Eq '^BUILD_ID="[A-Z0-9_.-]+"$' "$path" 2>/dev/null || return 1
  grep -Fq 'MANAGED_SCRIPT_PATH="${BIN_DIR}/zdd-argo.sh"' "$path" 2>/dev/null
}

path_is_zdd_launcher() {
  local path="$1"
  [[ -f "$path" ]] || return 1
  grep -Fqx 'ZDD_ARGO_LAUNCHER=1' "$path" 2>/dev/null || grep -Fq '# zdd-argo launcher' "$path" 2>/dev/null || return 1
  grep -Fq "$MANAGED_SCRIPT_PATH" "$path" 2>/dev/null
}

path_is_legacy_zdd_launcher() {
  local path="$1"
  [[ -f "$path" ]] || return 1
  grep -Fq 'zdd argo' "$path" 2>/dev/null && grep -Fq 'exec /usr/bin/env bash' "$path" 2>/dev/null \
    && grep -Fq 'zdd-argo.sh' "$path" 2>/dev/null
}

path_is_replaceable_launcher() {
  path_is_zdd_launcher "$1" || path_is_legacy_zdd_launcher "$1"
}

link_points_to_shortcut() {
  [[ -L "$1" && "$(readlink "$1" 2>/dev/null || true)" == "$SHORTCUT_PATH" ]]
}

record_source_file() {
  local sha=""

  [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "$MANAGED_SCRIPT_PATH" ]] || return 0
  [[ "$SCRIPT_PATH" != *$'\n'* && -f "$SCRIPT_PATH" && ! -L "$SCRIPT_PATH" ]] || return 0
  sha="$(file_sha256 "$SCRIPT_PATH")"
  [[ "$sha" =~ ^[0-9a-f]{64}$ ]] || return 0
  printf '%s\n%s\n' "$SCRIPT_PATH" "$sha" | write_file_atomic "$SOURCE_RECORD_FILE" 600
}

shortcut_is_current() {
  local resolved=""

  [[ -f "$MANAGED_SCRIPT_PATH" && -x "$MANAGED_SCRIPT_PATH" ]] || return 1
  [[ "$(file_sha256 "$SCRIPT_PATH")" == "$(file_sha256 "$MANAGED_SCRIPT_PATH")" ]] || return 1
  path_is_zdd_launcher "$SHORTCUT_PATH" || return 1
  link_points_to_shortcut "$SHORTCUT_COMPAT_PATH" || return 1
  resolved="$(type -P zargo 2>/dev/null || true)"
  [[ -n "$resolved" ]] && path_is_zdd_launcher "$resolved"
}

install_shortcut() {
  local existing="" path="" resolved=""

  [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]] || die "无法识别当前脚本文件，不能安装快捷命令。"
  script_file_is_ours "$SCRIPT_PATH" || die "当前文件未通过 zdd-argo 脚本标识校验。"
  shortcut_is_current && return 0
  bash -n "$SCRIPT_PATH" || die "当前脚本未通过 Bash 语法检查，拒绝安装。"

  existing="$(type -P zargo 2>/dev/null || true)"
  if [[ -n "$existing" ]] && ! path_is_replaceable_launcher "$existing"; then
    die "当前 PATH 中的 zargo 已被其他程序占用：${existing}"
  fi
  for path in "$SHORTCUT_PATH" "$SHORTCUT_COMPAT_PATH" "$SHORTCUT_FALLBACK_PATH"; do
    [[ -e "$path" || -L "$path" ]] || continue
    link_points_to_shortcut "$path" && continue
    path_is_replaceable_launcher "$path" || die "快捷命令路径已被其他程序占用：${path}"
  done
  if [[ -e "$MANAGED_SCRIPT_PATH" ]] && ! script_file_is_ours "$MANAGED_SCRIPT_PATH"; then
    die "目标路径已存在非 zdd-argo 文件：${MANAGED_SCRIPT_PATH}"
  fi

  mkdir -p "$BIN_DIR" "$(dirname -- "$SHORTCUT_PATH")" "$(dirname -- "$SHORTCUT_COMPAT_PATH")"
  chmod 0755 "$BIN_DIR"
  record_source_file

  if [[ "$SCRIPT_PATH" != "$MANAGED_SCRIPT_PATH" ]]; then
    install -m 0755 "$SCRIPT_PATH" "${MANAGED_SCRIPT_PATH}.new.$$"
    mv -f "${MANAGED_SCRIPT_PATH}.new.$$" "$MANAGED_SCRIPT_PATH"
  else
    chmod 0755 "$MANAGED_SCRIPT_PATH"
  fi

  cat <<EOF | write_file_atomic "$SHORTCUT_PATH" 755
#!/usr/bin/env bash
# zdd-argo launcher
set -Eeuo pipefail
ZDD_ARGO_LAUNCHER=1

if [[ "\$#" -ne 0 ]]; then
  printf '%s\n' '用法：zargo' >&2
  exit 2
fi

exec /usr/bin/env bash ${MANAGED_SCRIPT_PATH@Q}
EOF

  rm -f "$SHORTCUT_COMPAT_PATH"
  ln -s "$SHORTCUT_PATH" "$SHORTCUT_COMPAT_PATH"
  hash -r

  resolved="$(type -P zargo 2>/dev/null || true)"
  if [[ -z "$resolved" ]] || ! path_is_zdd_launcher "$resolved"; then
    if [[ -e "$SHORTCUT_FALLBACK_PATH" || -L "$SHORTCUT_FALLBACK_PATH" ]] \
        && ! link_points_to_shortcut "$SHORTCUT_FALLBACK_PATH" \
        && ! path_is_replaceable_launcher "$SHORTCUT_FALLBACK_PATH"; then
      die "当前 PATH 找不到 ${SHORTCUT_PATH}，且备用路径已被其他程序占用：${SHORTCUT_FALLBACK_PATH}"
    fi
    rm -f "$SHORTCUT_FALLBACK_PATH"
    ln -s "$SHORTCUT_PATH" "$SHORTCUT_FALLBACK_PATH"
    hash -r
    resolved="$(type -P zargo 2>/dev/null || true)"
  fi

  bash -n "$SHORTCUT_PATH" || die "快捷启动器语法检查失败。"
  if [[ -z "$resolved" ]] || ! path_is_zdd_launcher "$resolved"; then
    die "快捷命令已写入，但当前 shell 未解析到本项目的 zargo，请检查 PATH。"
  fi

  for path in "${LEGACY_SHORTCUT_PATHS[@]}"; do
    [[ -e "$path" || -L "$path" ]] || continue
    if path_is_replaceable_launcher "$path" || grep -Fq 'zdd-argo' "$path" 2>/dev/null; then
      rm -f "$path"
    else
      warn "发现同名旧快捷路径但无法确认归属，未删除：${path}"
    fi
  done
}

safe_download() {
  local url="$1"
  local output="$2"
  local mode="${3:-file}"
  local -a curl_extra=(--max-time 300 --progress-bar)
  local -a wget_extra=(--timeout=300 -q --show-progress)

  if [[ "$mode" == "api" ]]; then
    curl_extra=(--max-time 120 -sS -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28')
    wget_extra=(--timeout=120 -q --header='Accept: application/vnd.github+json' --header='X-GitHub-Api-Version: 2022-11-28')
  fi

  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --user-agent "zdd-argo/${SCRIPT_VERSION}" -fL \
      --retry 4 --retry-all-errors --connect-timeout 15 "${curl_extra[@]}" "$url" -o "$output"
  elif wget_is_usable; then
    wget --https-only --secure-protocol=TLSv1_2 --user-agent="zdd-argo/${SCRIPT_VERSION}" \
      --tries=5 "${wget_extra[@]}" -O "$output" "$url"
  else
    die "未检测到可用的 curl 或 GNU wget，无法下载：${url}"
  fi
}

github_latest_asset_info() {
  local repo="$1"
  local asset_regex="$2"
  local api_file=""
  local result=""

  api_file="$(mktemp)"
  safe_download "${GITHUB_API_BASE}/repos/${repo}/releases/latest" "$api_file" api \
    || { rm -f "$api_file"; die "无法读取 ${repo} 的 GitHub 最新稳定版信息。"; }

  jq -e 'type == "object" and (.tag_name | type == "string") and (.assets | type == "array")' \
    "$api_file" >/dev/null 2>&1 || { rm -f "$api_file"; die "${repo} 的 GitHub Release 响应格式异常。"; }

  result="$(
    jq -er --arg re "$asset_regex" '
      [.assets[] | select(.name | test($re))] as $m
      | if ($m | length) == 1
        then [$m[0].name, $m[0].browser_download_url, ($m[0].digest // ""), .tag_name] | @tsv
        else error("asset count \($m | length)") end' "$api_file" 2>/dev/null
  )" || { rm -f "$api_file"; die "${repo} 最新稳定版中未找到唯一匹配的安装文件。"; }

  rm -f "$api_file"
  printf '%s\n' "$result"
}

verify_github_asset() {
  local repo="$1" asset_name="$2" asset_url="$3" digest="$4" file="$5"

  [[ "$asset_url" == "https://github.com/${repo}/releases/download/"* ]] \
    || die "GitHub 下载地址异常，已拒绝安装：${asset_url}"
  [[ "$digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]] \
    || die "${asset_name} 没有可用的 GitHub SHA-256 摘要，已拒绝无校验安装。"
  digest="${digest#sha256:}"
  [[ "$(file_sha256 "$file")" == "${digest,,}" ]] \
    || die "${asset_name} 的 SHA-256 校验失败，已拒绝安装。"
}

write_release_metadata() {
  local output="$1" repo="$2" tag="$3" asset="$4" digest="$5"
  jq -n --arg repo "$repo" --arg tag "$tag" --arg asset "$asset" --arg digest "$digest" \
    --arg installed_at "$(utc_now)" \
    '{repository: $repo, tag: $tag, asset: $asset, digest: $digest, installed_at: $installed_at}' \
    | write_file_atomic "$output" 644
}

archive_is_safe() {
  ! grep -Eq '(^/|(^|/)\.\.(/|$))' "$1"
}

singbox_version_of() {
  local line=""
  line="$("$1" version 2>/dev/null | head -n 1 || true)"
  [[ "$line" =~ ^sing-box\ version\ ([0-9][0-9A-Za-z.+-]*) ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

xray_version_of() {
  local line=""
  line="$("$1" version 2>/dev/null | head -n 1 || true)"
  [[ "$line" =~ ^Xray\ ([0-9][0-9A-Za-z.+-]*) ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

cloudflared_version_of() {
  local line=""
  line="$("$1" --version 2>/dev/null | head -n 1 || true)"
  [[ "${line,,}" =~ ^cloudflared\ version\ ([0-9][0-9A-Za-z.+-]*) ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

wgcf_version_ok() {
  local help_text=""
  help_text="$("$1" --help 2>&1 || true)"
  [[ "$help_text" == *"WireGuard Cloudflare Warp utility"* || "$help_text" == *"wgcf is a utility for Cloudflare Warp"* ]]
}

component_version_ok() {
  local component="$1"
  local binary="$2"
  local version=""

  case "$component" in
    singbox)
      version="$(singbox_version_of "$binary")" || return 1
      version_ge "$version" "$MIN_SINGBOX_VERSION"
      ;;
    xray)
      version="$(xray_version_of "$binary")" || return 1
      version_ge "$version" "$MIN_XRAY_VERSION"
      ;;
    cloudflared) cloudflared_version_of "$binary" >/dev/null ;;
    wgcf)        wgcf_version_ok "$binary" ;;
    *) return 1 ;;
  esac
}

component_min_version() {
  case "$1" in
    singbox) printf '%s' "$MIN_SINGBOX_VERSION" ;;
    xray)    printf '%s' "$MIN_XRAY_VERSION" ;;
    *)       printf '' ;;
  esac
}

component_label() {
  case "$1" in
    singbox)     printf 'sing-box' ;;
    xray)        printf 'Xray' ;;
    cloudflared) printf 'cloudflared' ;;
    wgcf)        printf 'wgcf' ;;
  esac
}

component_bin_path() {
  case "$1" in
    singbox)     printf '%s' "$MANAGED_SINGBOX_BIN" ;;
    xray)        printf '%s' "$MANAGED_XRAY_BIN" ;;
    cloudflared) printf '%s' "$MANAGED_CLOUDFLARED_BIN" ;;
    wgcf)        printf '%s' "$MANAGED_WGCF_BIN" ;;
  esac
}

component_meta_path() {
  case "$1" in
    singbox)     printf '%s' "$SINGBOX_RELEASE_META" ;;
    xray)        printf '%s' "$XRAY_RELEASE_META" ;;
    cloudflared) printf '%s' "$CLOUDFLARED_RELEASE_META" ;;
    wgcf)        printf '%s' "$WGCF_RELEASE_META" ;;
  esac
}

component_repo() {
  case "$1" in
    singbox)     printf 'SagerNet/sing-box' ;;
    xray)        printf 'XTLS/Xray-core' ;;
    cloudflared) printf 'cloudflare/cloudflared' ;;
    wgcf)        printf 'ViRb3/wgcf' ;;
  esac
}

component_asset_regex() {
  local component="$1"
  local arch=""

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)  arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "暂不支持 CPU 架构：${arch}；当前脚本支持 amd64 与 arm64。" ;;
  esac

  case "$component" in
    singbox)     printf '^sing-box-.*-linux-%s\\.tar\\.gz$' "$arch" ;;
    cloudflared) printf '^cloudflared-linux-%s$' "$arch" ;;
    wgcf)        printf '^wgcf_[0-9][0-9.]*_linux_%s$' "$arch" ;;
    xray)
      if [[ "$arch" == "amd64" ]]; then printf '^Xray-linux-64\\.zip$'; else printf '^Xray-linux-arm64-v8a\\.zip$'; fi
      ;;
  esac
}

component_installed_version() {
  local component="$1"
  local binary=""
  binary="$(component_bin_path "$component")"
  [[ -x "$binary" ]] || { printf '未安装'; return 0; }
  case "$component" in
    singbox)     singbox_version_of "$binary" 2>/dev/null || printf '已安装' ;;
    xray)        xray_version_of "$binary" 2>/dev/null || printf '已安装' ;;
    cloudflared) cloudflared_version_of "$binary" 2>/dev/null || printf '已安装' ;;
    wgcf)        jq -r '.tag // "已安装"' "$WGCF_RELEASE_META" 2>/dev/null || printf '已安装' ;;
  esac
}

extract_component_binary() {
  local component="$1"
  local archive="$2"
  local work="$3"
  local list_file="${work}/archive.list"
  local extract_dir="${work}/extract"
  local -a candidates=()

  mkdir -p "$extract_dir"
  case "$component" in
    singbox)
      tar -tzf "$archive" > "$list_file" || die "无法读取 sing-box 压缩包目录。"
      archive_is_safe "$list_file" || die "sing-box 压缩包包含不安全路径，已拒绝解压。"
      tar -xzf "$archive" -C "$extract_dir" || die "sing-box 压缩包解压失败。"
      mapfile -t candidates < <(find "$extract_dir" -type f -name sing-box -print)
      ;;
    xray)
      unzip -Z1 "$archive" > "$list_file" || die "无法读取 Xray 压缩包目录。"
      archive_is_safe "$list_file" || die "Xray 压缩包包含不安全路径，已拒绝解压。"
      unzip -q "$archive" -d "$extract_dir" || die "Xray 压缩包解压失败。"
      mapfile -t candidates < <(find "$extract_dir" -type f -name xray -print)
      ;;
    cloudflared|wgcf)
      candidates=("$archive")
      ;;
  esac

  [[ ${#candidates[@]} -eq 1 ]] || die "$(component_label "$component") 安装包内未找到唯一可执行文件。"
  chmod 0755 "${candidates[0]}"
  printf '%s\n' "${candidates[0]}"
}

install_or_update_component() {
  local component="$1"
  local label="" repo="" regex="" info_line="" asset_name="" asset_url="" digest="" tag=""
  local work="" candidate="" target="" meta="" backup="" meta_backup="" before="" after=""
  local min_version=""

  label="$(component_label "$component")"
  repo="$(component_repo "$component")"
  regex="$(component_asset_regex "$component")"
  target="$(component_bin_path "$component")"
  meta="$(component_meta_path "$component")"
  min_version="$(component_min_version "$component")"
  before="$(component_installed_version "$component")"
  [[ -n "$regex" ]] || die "无法确定 ${label} 的安装包。"

  info "查询 ${label} 的 GitHub 最新稳定版……"
  info_line="$(github_latest_asset_info "$repo" "$regex")"
  IFS=$'\t' read -r asset_name asset_url digest tag <<< "$info_line"
  [[ -n "$asset_name" && -n "$asset_url" && -n "$tag" ]] || die "${label} Release 信息不完整。"

  if [[ -x "$target" && -f "$meta" && "$(jq -r '.tag // empty' "$meta" 2>/dev/null)" == "$tag" ]] \
      && component_version_ok "$component" "$target"; then
    ok "${label} 已是最新稳定版 ${tag}。"
    return 0
  fi

  work="$(mktemp -d)"
  safe_download "$asset_url" "${work}/${asset_name}" || { rm -rf "$work"; die "${label} 下载失败。"; }
  verify_github_asset "$repo" "$asset_name" "$asset_url" "$digest" "${work}/${asset_name}"
  candidate="$(extract_component_binary "$component" "${work}/${asset_name}" "$work")"

  if ! component_version_ok "$component" "$candidate"; then
    if [[ "$INIT_SYSTEM" == "openrc" ]]; then ensure_alpine_binary_compat || true; fi
    if ! component_version_ok "$component" "$candidate"; then
      "$candidate" version >/dev/null 2>&1 || "$candidate" --version >/dev/null 2>&1 \
        || warn "二进制无法运行：$("$candidate" version 2>&1 | head -n 1 || true)"
      rm -rf "$work"
      die "${label} 新二进制未通过自检${min_version:+（要求 ≥ ${min_version}）}。"
    fi
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"
  backup="${target}.backup.$$"
  meta_backup="${meta}.backup.$$"
  [[ -x "$target" ]] && cp -a "$target" "$backup"
  [[ -f "$meta" ]] && cp -a "$meta" "$meta_backup"

  install -m 0755 "$candidate" "${target}.new.$$"
  mv -f "${target}.new.$$" "$target"
  rm -rf "$work"

  if ! write_release_metadata "$meta" "$repo" "$tag" "$asset_name" "$digest" \
      || ! component_version_ok "$component" "$target"; then
    warn "${label} 安装后校验失败，正在回滚……"
    if [[ -f "$backup" ]]; then mv -f "$backup" "$target"; else rm -f "$target"; fi
    if [[ -f "$meta_backup" ]]; then mv -f "$meta_backup" "$meta"; else rm -f "$meta"; fi
    hash -r
    die "${label} 更新失败，已恢复更新前状态。"
  fi

  rm -f "$backup" "$meta_backup"
  hash -r
  after="$(component_installed_version "$component")"
  if [[ "$before" == "未安装" ]]; then
    ok "${label} 已安装：${after}（GitHub Release SHA-256 已校验）。"
  else
    ok "${label} 已更新：${before} → ${after}（GitHub Release SHA-256 已校验）。"
  fi
}

ensure_component() {
  local component="$1"
  local target=""

  target="$(component_bin_path "$component")"
  if [[ -x "$target" ]] && component_version_ok "$component" "$target"; then
    return 0
  fi
  if [[ -x "$target" ]]; then
    warn "$(component_label "$component") 版本低于要求（≥ $(component_min_version "$component")），将自动更新。"
  else
    info "安装脚本专用 $(component_label "$component")，不影响系统中其他方式安装的同名程序。"
  fi
  install_or_update_component "$component"
}

valid_uuid() {
  [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}

valid_ws_path() {
  [[ "$1" =~ ^/[A-Za-z0-9._~-]+$ ]]
}

valid_argo_host() {
  [[ -z "$1" || "$1" =~ ^[a-z0-9-]+\.trycloudflare\.com$ ]]
}

valid_ipv4() {
  local a="" b="" c="" d="" extra="" part=""

  IFS='.' read -r a b c d extra <<< "$1"
  [[ -z "${extra:-}" && -n "${a:-}" && -n "${b:-}" && -n "${c:-}" && -n "${d:-}" ]] || return 1
  for part in "$a" "$b" "$c" "$d"; do
    [[ "$part" =~ ^[0-9]{1,3}$ ]] || return 1
    ((10#$part <= 255)) || return 1
  done
}

valid_ipv6() {
  local value="$1" left="" right="" part=""
  local compressed=0 units=0 index=0
  local -a left_parts=() right_parts=()

  [[ -n "$value" && "$value" == *:* && "$value" =~ ^[0-9A-Fa-f:.]+$ && "$value" != *:::* ]] || return 1

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
      ((units += 2))
    else
      [[ "$part" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
      ((units += 1))
    fi
  done
  for ((index = 0; index < ${#right_parts[@]}; index++)); do
    part="${right_parts[index]}"
    [[ -n "$part" ]] || return 1
    if [[ "$part" == *.* ]]; then
      [[ $index -eq $((${#right_parts[@]} - 1)) ]] || return 1
      valid_ipv4 "$part" || return 1
      ((units += 2))
    else
      [[ "$part" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
      ((units += 1))
    fi
  done

  if [[ $compressed -eq 1 ]]; then ((units < 8)); else ((units == 8)); fi
}

valid_ipv4_cidr() {
  local address="" prefix=""
  [[ "$1" =~ ^([^/]+)/([0-9]{1,2})$ ]] || return 1
  address="${BASH_REMATCH[1]}"; prefix="${BASH_REMATCH[2]}"
  valid_ipv4 "$address" && ((10#$prefix <= 32))
}

valid_ipv6_cidr() {
  local address="" prefix=""
  [[ "$1" =~ ^([^/]+)/([0-9]{1,3})$ ]] || return 1
  address="${BASH_REMATCH[1]}"; prefix="${BASH_REMATCH[2]}"
  valid_ipv6 "$address" && ((10#$prefix <= 128))
}

valid_local_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] && ((10#$1 >= 1024 && 10#$1 <= 65535))
}

valid_node_name() {
  local value="$1"
  [[ -n "$value" && ${#value} -le 80 ]] || return 1
  if command -v iconv >/dev/null 2>&1; then
    printf '%s' "$value" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1 || return 1
  fi
  ! LC_ALL=C grep -q '[[:cntrl:]]' < <(printf '%s' "$value")
}

valid_domain_name() {
  local value="${1%.}" label=""
  local -a labels=()

  [[ -n "$value" && ${#value} -le 253 && "$value" == *.* && "$value" =~ ^[A-Za-z0-9.-]+$ ]] || return 1
  IFS='.' read -r -a labels <<< "$value"
  for label in "${labels[@]}"; do
    [[ -n "$label" && ${#label} -le 63 && "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || return 1
  done
}

normalize_preferred_endpoint() {
  local value="$1" a="" b="" c="" d=""

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  [[ "$value" =~ ^\[(.*)\]$ ]] && value="${BASH_REMATCH[1]}"

  if valid_ipv4 "$value"; then
    IFS='.' read -r a b c d <<< "$value"
    value="$((10#$a)).$((10#$b)).$((10#$c)).$((10#$d))"
  elif valid_domain_name "$value"; then
    value="${value%.}"
    value="${value,,}"
  fi
  printf '%s' "$value"
}

valid_preferred_endpoint() {
  local value="$1"
  [[ -n "$value" && "$value" != *[[:space:]]* && ${#value} -le 253 ]] || return 1
  if [[ "$value" =~ ^[0-9.]+$ ]]; then valid_ipv4 "$value"; return; fi
  valid_ipv6 "$value" || valid_domain_name "$value"
}

uri_host() {
  if valid_ipv6 "$1"; then printf '[%s]' "$1"; else printf '%s' "$1"; fi
}

valid_flag() {
  [[ "$1" == "0" || "$1" == "1" ]]
}

normalize_flag() {
  case "${1,,}" in
    1|true|yes|y|on|enable|enabled|开|开启)   printf '1' ;;
    0|false|no|n|off|disable|disabled|关|关闭) printf '0' ;;
    *) return 1 ;;
  esac
}

valid_ip_mode() {
  [[ "$1" == "ipv4_only" || "$1" == "prefer_ipv4" ]]
}

normalize_ip_mode() {
  case "${1,,}" in
    ipv4_only|ipv4-only|only_ipv4|1)      printf 'ipv4_only' ;;
    prefer_ipv4|prefer-ipv4|ipv4_prefer|2) printf 'prefer_ipv4' ;;
    *) return 1 ;;
  esac
}

ip_mode_label() {
  case "$IP_MODE" in
    ipv4_only)   printf '仅 IPv4' ;;
    prefer_ipv4) printf 'IPv4 优先' ;;
    *)           printf '未设置' ;;
  esac
}

singbox_ip_strategy() {
  valid_ip_mode "$IP_MODE" || die "出站策略无效：${IP_MODE}"
  printf '%s' "$IP_MODE"
}

xray_freedom_strategy() {
  case "$IP_MODE" in
    ipv4_only)   printf 'UseIPv4' ;;
    prefer_ipv4) printf 'UseIPv4v6' ;;
    *) die "出站策略无效：${IP_MODE}" ;;
  esac
}

valid_vlessenc_value() {
  [[ "$1" =~ ^mlkem768x25519plus\.(native|xorpub|random)\.[0-9A-Za-z._-]+$ ]]
}

generate_uuid_v4() {
  local hex=""
  if [[ -r /proc/sys/kernel/random/uuid ]]; then cat /proc/sys/kernel/random/uuid; return 0; fi
  hex="$(openssl rand -hex 16)"
  [[ ${#hex} -eq 32 ]] || return 1
  printf '%s-%s-4%s-8%s-%s\n' "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" "${hex:17:3}" "${hex:20:12}"
}

use_core() {
  case "$1" in
    singbox)
      CORE="singbox"; P="SB"
      CORE_LABEL="$SB_LABEL"; CORE_PROTO="$SB_PROTO"; CORE_CONFIG="$SB_CONFIG"; CORE_STATE="$SB_STATE"
      CORE_SERVICE="$SB_SERVICE"; CORE_UNIT="$SB_UNIT"; CORE_RUNNER="$SB_RUNNER"; CORE_CF_HOME="$SB_CF_HOME"
      CORE_TUNNEL_LOG="$SB_TUNNEL_LOG"; CORE_CORE_LOG="$SB_CORE_LOG"; CORE_SESSION="$SB_SESSION"
      CORE_LINK="$SB_LINK"; CORE_LINK_JSON="$SB_LINK_JSON"; CORE_BIN="$MANAGED_SINGBOX_BIN"
      ;;
    xray)
      CORE="xray"; P="XR"
      CORE_LABEL="$XR_LABEL"; CORE_PROTO="$XR_PROTO"; CORE_CONFIG="$XR_CONFIG"; CORE_STATE="$XR_STATE"
      CORE_SERVICE="$XR_SERVICE"; CORE_UNIT="$XR_UNIT"; CORE_RUNNER="$XR_RUNNER"; CORE_CF_HOME="$XR_CF_HOME"
      CORE_TUNNEL_LOG="$XR_TUNNEL_LOG"; CORE_CORE_LOG="$XR_CORE_LOG"; CORE_SESSION="$XR_SESSION"
      CORE_LINK="$XR_LINK"; CORE_LINK_JSON="$XR_LINK_JSON"; CORE_BIN="$MANAGED_XRAY_BIN"
      ;;
    *) die "未知内核：$1" ;;
  esac
}

other_core() {
  if [[ "$CORE" == "singbox" ]]; then printf 'xray'; else printf 'singbox'; fi
}

cget() {
  local name="${P}_$1"
  printf '%s' "${!name}"
}

cset() {
  printf -v "${P}_$1" '%s' "$2"
}

reset_settings_defaults() {
  IP_MODE="$DEFAULT_IP_MODE"
  SB_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"; SB_PORT="$DEFAULT_SB_PORT"; SB_NODE="$DEFAULT_NODE_NAME"
  SB_DOH="0"; SB_WARP="0"
  XR_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"; XR_PORT="$DEFAULT_XR_PORT"; XR_NODE="$DEFAULT_NODE_NAME"
  XR_ECH="$DEFAULT_ECH_CONFIG"
}

valid_ech_config() {
  local value="$1"
  local pattern='^[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+$'
  [[ -z "$value" ]] && return 0
  [[ ${#value} -le 200 && "$value" =~ $pattern ]]
}

normalize_ech_config() {
  case "${1,,}" in
    none|off|no|关闭|不用) printf '' ;;
    *) printf '%s' "$1" ;;
  esac
}

settings_field() {
  jq -r "$1 // empty" "$SETTINGS_JSON" 2>/dev/null || true
}

load_settings() {
  local schema="" v="" invalid_file=""

  reset_settings_defaults
  [[ -e "$SETTINGS_JSON" || -L "$SETTINGS_JSON" ]] || return 0

  if [[ ! -f "$SETTINGS_JSON" || -L "$SETTINGS_JSON" ]]; then
    warn "设置文件不是普通文件，已忽略并使用默认设置：${SETTINGS_JSON}"
    return 0
  fi
  if ! jq -e 'type == "object"' "$SETTINGS_JSON" >/dev/null 2>&1; then
    invalid_file="${SETTINGS_JSON}.invalid.$(date -u +%Y%m%dT%H%M%SZ)"
    mv -f -- "$SETTINGS_JSON" "$invalid_file" 2>/dev/null && { chmod 600 "$invalid_file" 2>/dev/null || true; }
    warn "设置文件损坏，已隔离到 ${invalid_file}，当前使用默认设置。"
    return 0
  fi

  schema="$(settings_field '.schema')"
  if [[ "$schema" =~ ^[0-9]+$ ]] && ((schema >= 6)); then
    v="$(settings_field '.outbound_ip_mode')";      v="$(normalize_ip_mode "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && IP_MODE="$v"
    v="$(settings_field '.singbox.preferred_endpoint')"; v="$(normalize_preferred_endpoint "$v")"; valid_preferred_endpoint "$v" && SB_ENDPOINT="$v"
    v="$(settings_field '.singbox.local_port')";    valid_local_port "$v" && SB_PORT="$((10#$v))"
    v="$(settings_field '.singbox.node_name')";     valid_node_name "$v" && SB_NODE="$v"
    v="$(settings_field '.singbox.doh_enabled')";   v="$(normalize_flag "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && SB_DOH="$v"
    v="$(settings_field '.singbox.warp_enabled')";  v="$(normalize_flag "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && SB_WARP="$v"
    v="$(settings_field '.xray.preferred_endpoint')"; v="$(normalize_preferred_endpoint "$v")"; valid_preferred_endpoint "$v" && XR_ENDPOINT="$v"
    v="$(settings_field '.xray.local_port')";       valid_local_port "$v" && XR_PORT="$((10#$v))"
    v="$(settings_field '.xray.node_name')";        valid_node_name "$v" && XR_NODE="$v"
    if jq -e '.xray | has("ech_config")' "$SETTINGS_JSON" >/dev/null 2>&1; then
      v="$(settings_field '.xray.ech_config')";     valid_ech_config "$v" && XR_ECH="$v"
    fi
    return 0
  fi

  v="$(settings_field '.outbound_ip_mode')";       v="$(normalize_ip_mode "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && IP_MODE="$v"
  v="$(settings_field '.preferred_endpoint')";     v="$(normalize_preferred_endpoint "$v")"; valid_preferred_endpoint "$v" && SB_ENDPOINT="$v"
  v="$(settings_field '.local_port')";             valid_local_port "$v" && SB_PORT="$((10#$v))"
  v="$(settings_field '.node_name')";              valid_node_name "$v" && SB_NODE="$v"
  v="$(settings_field '.doh_enabled')";            v="$(normalize_flag "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && SB_DOH="$v"
  v="$(settings_field '.warp_enabled')";           v="$(normalize_flag "$v" 2>/dev/null || true)"; [[ -n "$v" ]] && SB_WARP="$v"
  v="$(settings_field '.xray_preferred_endpoint')"; v="$(normalize_preferred_endpoint "$v")"; valid_preferred_endpoint "$v" && XR_ENDPOINT="$v"
  if [[ -f "$XR_STATE" && ! -L "$XR_STATE" ]]; then
    v="$(jq -r '.local_port // empty' "$XR_STATE" 2>/dev/null || true)"; valid_local_port "$v" && XR_PORT="$((10#$v))"
    v="$(jq -r '.node_name // empty' "$XR_STATE" 2>/dev/null || true)"; valid_node_name "$v" && XR_NODE="$v"
  fi
  info "检测到旧版设置文件，已自动升级为新格式。"
  save_settings
}

save_settings() {
  valid_ip_mode "$IP_MODE" || die "出站策略无效。"
  valid_preferred_endpoint "$SB_ENDPOINT" || die "sing-box 优选域名/IP 无效。"
  valid_preferred_endpoint "$XR_ENDPOINT" || die "Xray 优选域名/IP 无效。"
  valid_local_port "$SB_PORT" || die "sing-box 本地端口无效，只允许 1024–65535。"
  valid_local_port "$XR_PORT" || die "Xray 本地端口无效，只允许 1024–65535。"
  valid_node_name "$SB_NODE" || die "sing-box 节点名称无效。"
  valid_node_name "$XR_NODE" || die "Xray 节点名称无效。"
  valid_flag "$SB_DOH" && valid_flag "$SB_WARP" || die "DoH / WARP 开关无效。"
  valid_ech_config "$XR_ECH" || die "Xray ECH 配置无效。"

  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR" 2>/dev/null || true
  chmod 750 "$DATA_DIR"

  jq -n --argjson schema 6 --arg ip_mode "$IP_MODE" --arg updated_at "$(utc_now)" \
    --arg sb_endpoint "$SB_ENDPOINT" --argjson sb_port "$SB_PORT" --arg sb_node "$SB_NODE" \
    --argjson sb_doh "$SB_DOH" --argjson sb_warp "$SB_WARP" \
    --arg xr_endpoint "$XR_ENDPOINT" --argjson xr_port "$XR_PORT" --arg xr_node "$XR_NODE" --arg xr_ech "$XR_ECH" \
    '{
      schema: $schema,
      outbound_ip_mode: $ip_mode,
      singbox: {preferred_endpoint: $sb_endpoint, local_port: $sb_port, node_name: $sb_node,
                doh_enabled: $sb_doh, warp_enabled: $sb_warp},
      xray:    {preferred_endpoint: $xr_endpoint, local_port: $xr_port, node_name: $xr_node, ech_config: $xr_ech},
      updated_at: $updated_at
    }' | write_file_atomic "$SETTINGS_JSON" 600
}

load_state() {
  local v=""

  cset UUID ""; cset WS_PATH ""; cset ARGO_HOST ""; cset CREATED_AT ""
  [[ "$CORE" == "xray" ]] && { XR_ENC=""; XR_DEC=""; }
  [[ -f "$CORE_STATE" && ! -L "$CORE_STATE" ]] || return 0
  if ! jq -e 'type == "object"' "$CORE_STATE" >/dev/null 2>&1; then
    warn "状态文件损坏，已按未部署处理：${CORE_STATE}"
    return 0
  fi

  v="$(jq -r '.uuid // ""' "$CORE_STATE")";       valid_uuid "$v" && cset UUID "$v"
  v="$(jq -r '.ws_path // ""' "$CORE_STATE")";    valid_ws_path "$v" && cset WS_PATH "$v"
  v="$(jq -r '.argo_host // ""' "$CORE_STATE")";  valid_argo_host "$v" && cset ARGO_HOST "$v"
  v="$(jq -r '.created_at // ""' "$CORE_STATE")"; cset CREATED_AT "$v"
  if [[ "$CORE" == "xray" ]]; then
    v="$(jq -r '.encryption // ""' "$CORE_STATE")"; valid_vlessenc_value "$v" && XR_ENC="$v"
    v="$(jq -r '.decryption // ""' "$CORE_STATE")"; valid_vlessenc_value "$v" && XR_DEC="$v"
  fi
  return 0
}

save_state() {
  local created=""

  created="$(cget CREATED_AT)"
  [[ -n "$created" ]] || { created="$(utc_now)"; cset CREATED_AT "$created"; }
  mkdir -p "$DATA_DIR"
  chown root:"$SERVICE_GROUP" "$DATA_DIR" 2>/dev/null || true
  chmod 750 "$DATA_DIR"

  jq -n --argjson schema 3 --arg uuid "$(cget UUID)" --arg ws_path "$(cget WS_PATH)" \
    --arg argo_host "$(cget ARGO_HOST)" --arg created_at "$created" --arg updated_at "$(utc_now)" \
    --arg enc "$XR_ENC" --arg dec "$XR_DEC" --arg core "$CORE" \
    '{schema: $schema, uuid: $uuid, ws_path: $ws_path, argo_host: $argo_host,
      created_at: $created_at, updated_at: $updated_at}
     + (if $core == "xray" then {encryption: $enc, decryption: $dec} else {} end)' \
    | write_file_atomic "$CORE_STATE" 600
}

core_is_deployed() {
  [[ -f "$CORE_CONFIG" || -f "$CORE_STATE" || -e "$CORE_UNIT" ]]
}

port_conflicts_with_other_core() {
  local port="$1" other="" other_port=""

  other="$(other_core)"
  if [[ "$other" == "singbox" ]]; then
    [[ -f "$SB_CONFIG" || -f "$SB_STATE" || -e "${SB_UNIT:-/nonexistent}" ]] || return 1
    other_port="$SB_PORT"
  else
    [[ -f "$XR_CONFIG" || -f "$XR_STATE" || -e "${XR_UNIT:-/nonexistent}" ]] || return 1
    other_port="$XR_PORT"
  fi
  [[ "$((10#$port))" == "$((10#$other_port))" ]]
}

prompt_setting() {
  local variable_name="$1" prompt="$2" current="$3" validator="$4" normalizer="${5:-}" hint_text="${6:-}"
  local input="" normalized=""

  while true; do
    read_interactive input "${prompt} [${current}]：" "" || input=""
    [[ -n "$input" ]] || input="$current"
    normalized="$input"
    [[ -n "$normalizer" ]] && normalized="$("$normalizer" "$input" 2>/dev/null || printf '%s' "$input")"
    if "$validator" "$normalized"; then
      printf -v "$variable_name" '%s' "$normalized"
      return 0
    fi
    warn "${hint_text:-输入无效，请重试。}"
  done
}

prompt_flag() {
  local variable_name="$1" label="$2" current="$3"
  local input="" normalized="" hint="y/N"

  [[ "$current" == "1" ]] && hint="Y/n"
  while true; do
    read_interactive input "${label} [${hint}]：" "" || input=""
    if [[ -z "$input" ]]; then printf -v "$variable_name" '%s' "$current"; return 0; fi
    if normalized="$(normalize_flag "$input" 2>/dev/null)"; then
      printf -v "$variable_name" '%s' "$normalized"
      return 0
    fi
    warn "请输入 y 或 n，直接回车保留当前值。"
  done
}

prompt_ip_mode() {
  local input="" normalized=""

  printf '\n'
  ui_text "出站策略（当前：$(ip_mode_label)）"
  ui_text "1  仅 IPv4"
  ui_text "2  IPv4 优先，可回退 IPv6"
  while true; do
    read_interactive input "请选择 [1-2，回车保留当前]：" "" || input=""
    [[ -n "$input" ]] || return 0
    if normalized="$(normalize_ip_mode "$input" 2>/dev/null)"; then
      IP_MODE="$normalized"
      return 0
    fi
    warn "请输入 1 或 2。"
  done
}

configure_core_settings() {
  local endpoint="" port="" node="" doh="" warp="" ech="" old_mode="$IP_MODE"

  printf '\n'
  ui_text "${C_BOLD}${CORE_LABEL} · ${CORE_PROTO} 自定义部署${C_RESET}"
  hint "直接回车保留方括号中的当前值。"
  printf '\n'

  prompt_setting endpoint "优选域名/IP" "$(cget ENDPOINT)" valid_preferred_endpoint normalize_preferred_endpoint \
    "请输入合法域名、IPv4 或 IPv6 地址。"
  while true; do
    read_interactive port "本地监听端口 [$(cget PORT)]：" "" || port=""
    [[ -n "$port" ]] || port="$(cget PORT)"
    if ! valid_local_port "$port"; then
      warn "端口无效，请输入 1024–65535 之间的整数。"
    elif port_conflicts_with_other_core "$port"; then
      warn "端口 $((10#$port)) 已被 $(component_label "$(other_core)") 使用，两个内核必须使用不同端口。"
    else
      break
    fi
  done
  prompt_setting node "节点名称" "$(cget NODE)" valid_node_name "" "节点名称不能为空、不能包含控制字符，且最多 80 个字符。"
  cset ENDPOINT "$endpoint"
  cset PORT "$((10#$port))"
  cset NODE "$node"

  if [[ "$CORE" == "singbox" ]]; then
    printf '\n'
    prompt_flag doh "开启 Cloudflare DoH（1.1.1.1）" "$SB_DOH"
    prompt_flag warp "开启 Cloudflare WARP 全局出站" "$SB_WARP"
    SB_DOH="$doh"
    SB_WARP="$warp"
    [[ "$SB_WARP" == "1" ]] && warn "首次开启 WARP 会调用第三方工具 wgcf，以 --accept-tos 注册 Cloudflare WARP 设备。"
  else
    printf '\n'
    hint "ECH 配置写入 Xray 分享链接（格式：域名+DoH 地址），输入 off 表示不写入。"
    prompt_setting ech "ECH 配置" "${XR_ECH:-off}" valid_ech_config normalize_ech_config \
      "ECH 配置不能包含空格或非法字符。"
    [[ "$ech" == "off" ]] && ech=""
    XR_ECH="$ech"
  fi

  prompt_ip_mode
  save_settings
  ok "${CORE_LABEL} 设置已保存。"
  [[ "$old_mode" != "$IP_MODE" ]] && IP_MODE_CHANGED=1
  return 0
}

warp_profile_valid() {
  [[ -s "$WARP_PROFILE_FILE" && ! -L "$WARP_PROFILE_FILE" ]] || return 1
  grep -Eq '^[[:space:]]*PrivateKey[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*Address[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*PublicKey[[:space:]]*=' "$WARP_PROFILE_FILE" \
    && grep -Eq '^[[:space:]]*Endpoint[[:space:]]*=' "$WARP_PROFILE_FILE"
}

WARP_API_HOST="api.cloudflareclient.com"
WARP_API_VERSION="v0a2158"
WARP_API_CLIENT="a-6.10-2158"
WARP_LAST_ERROR=""

warp_error_is_ratelimit() {
  [[ "$1" == *"Too Many Requests"* || "$1" == *" 429"* ]]
}

warp_generate_profile_from_account() {
  local binary="$1" profile_tmp=""

  profile_tmp="$(mktemp "${WARP_DIR}/.wgcf-profile.conf.XXXXXX")"
  if ! "$binary" --config "$WARP_ACCOUNT_FILE" generate --profile "$profile_tmp" >/dev/null 2>&1; then
    rm -f "$profile_tmp"
    return 1
  fi
  chmod 600 "$WARP_ACCOUNT_FILE" "$profile_tmp"
  mv -f "$profile_tmp" "$WARP_PROFILE_FILE"
  warp_profile_valid
}

warp_register_wgcf() {
  local binary="$1" output=""

  rm -f "$WARP_ACCOUNT_FILE"
  if output="$("$binary" --config "$WARP_ACCOUNT_FILE" register --accept-tos 2>&1)" && [[ -s "$WARP_ACCOUNT_FILE" ]]; then
    WARP_LAST_ERROR=""
    warp_generate_profile_from_account "$binary" && return 0
    WARP_LAST_ERROR="wgcf generate failed"
    return 1
  fi
  rm -f "$WARP_ACCOUNT_FILE"
  WARP_LAST_ERROR="$output"
  return 1
}

warp_register_api() {
  local ip_version="$1" key_pem="" private_key="" public_key="" response="" http_code="" peer_key="" endpoint="" v4="" v6=""

  command -v curl >/dev/null 2>&1 || { WARP_LAST_ERROR="curl missing"; return 1; }
  key_pem="$(openssl genpkey -algorithm X25519 2>/dev/null)" || { WARP_LAST_ERROR="openssl X25519 unsupported"; return 1; }
  private_key="$(printf '%s\n' "$key_pem" | openssl pkey -outform DER 2>/dev/null | tail -c 32 | base64 | tr -d '\n')"
  public_key="$(printf '%s\n' "$key_pem" | openssl pkey -pubout -outform DER 2>/dev/null | tail -c 32 | base64 | tr -d '\n')"
  [[ "$private_key" =~ ^[A-Za-z0-9+/]{43}=$ && "$public_key" =~ ^[A-Za-z0-9+/]{43}=$ ]] || { WARP_LAST_ERROR="key generation failed"; return 1; }

  response="$(curl "-${ip_version}" -sS --max-time 30 --connect-timeout 10 -X POST \
    "https://${WARP_API_HOST}/${WARP_API_VERSION}/reg" \
    -H 'User-Agent: okhttp/3.12.1' -H "CF-Client-Version: ${WARP_API_CLIENT}" -H 'Content-Type: application/json' \
    --data "{\"key\":\"${public_key}\",\"install_id\":\"\",\"fcm_token\":\"\",\"tos\":\"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",\"model\":\"PC\",\"serial_number\":\"\",\"locale\":\"zh_CN\"}" \
    -w '\n%{http_code}' 2>&1)" || { WARP_LAST_ERROR="$response"; return 1; }

  http_code="${response##*$'\n'}"
  response="${response%$'\n'*}"
  if [[ "$http_code" != "200" ]]; then
    WARP_LAST_ERROR="HTTP ${http_code} $(printf '%s' "$response" | head -c 200)"
    [[ "$http_code" == "429" ]] && WARP_LAST_ERROR="429 Too Many Requests"
    return 1
  fi

  peer_key="$(printf '%s' "$response" | jq -r '.config.peers[0].public_key // empty' 2>/dev/null)"
  endpoint="$(printf '%s' "$response" | jq -r '.config.peers[0].endpoint.host // empty' 2>/dev/null)"
  v4="$(printf '%s' "$response" | jq -r '.config.interface.addresses.v4 // empty' 2>/dev/null)"
  v6="$(printf '%s' "$response" | jq -r '.config.interface.addresses.v6 // empty' 2>/dev/null)"
  [[ "$peer_key" =~ ^[A-Za-z0-9+/]{43}=$ ]] && valid_ipv4 "$v4" && valid_ipv6 "$v6" \
    || { WARP_LAST_ERROR="unexpected API response"; return 1; }
  [[ -n "$endpoint" ]] || endpoint="engage.cloudflareclient.com:2408"

  rm -f "$WARP_ACCOUNT_FILE"
  printf '[Interface]\nPrivateKey = %s\nAddress = %s/32, %s/128\nDNS = 1.1.1.1\nMTU = 1280\n\n[Peer]\nPublicKey = %s\nAllowedIPs = 0.0.0.0/0, ::/0\nEndpoint = %s\n' \
    "$private_key" "$v4" "$v6" "$peer_key" "$endpoint" | write_file_atomic "$WARP_PROFILE_FILE" 600
  WARP_LAST_ERROR=""
  warp_profile_valid
}

host_has_ipv6() {
  ip -6 route show default 2>/dev/null | grep -q . || ip -6 route get 2606:4700::1111 >/dev/null 2>&1
}

warp_register_account() {
  local external="" delay=0

  rm -f "$WARP_PROFILE_FILE" "$WARP_CHECK_FILE"
  warp_register_wgcf "$MANAGED_WGCF_BIN" && return 0
  if ! warp_error_is_ratelimit "$WARP_LAST_ERROR"; then
    printf '%s\n' "$WARP_LAST_ERROR" | grep -vE '^[[:space:]]*(\||--|github\.com|runtime|main\.|Wraps|Error types)' | tail -n 4 >&2
    return 1
  fi
  warn "Cloudflare 限制了本机通过 wgcf 注册的频率（429），改用备用方式注册……"

  external="$(command -v wgcf 2>/dev/null || true)"
  if [[ -n "$external" && "$external" != "$MANAGED_WGCF_BIN" ]] && wgcf_version_ok "$external"; then
    info "尝试系统已安装的 wgcf：${external}"
    warp_register_wgcf "$external" && return 0
  fi

  info "尝试通过 Cloudflare API 直接注册（IPv4）……"
  warp_register_api 4 && return 0
  if host_has_ipv6; then
    info "尝试通过 Cloudflare API 直接注册（IPv6）……"
    warp_register_api 6 && return 0
  fi

  for delay in 30 60; do
    warn "仍被限流，${delay} 秒后再试……"
    sleep "$delay"
    warp_register_wgcf "$MANAGED_WGCF_BIN" && return 0
    warp_error_is_ratelimit "$WARP_LAST_ERROR" || break
    warp_register_api 4 && return 0
  done

  error "Cloudflare 对本机 IP 的 WARP 设备注册限流，所有注册方式均未通过。"
  hint "请等待一段时间再试，或更换网络出口后再试；注册成功后账户会保存在 ${WARP_DIR}，重装时可选择保留复用。"
  return 1
}

ensure_warp_profile() {
  mkdir -p "$WARP_DIR"
  chown root:root "$WARP_DIR"
  chmod 700 "$WARP_DIR"
  warp_profile_valid && return 0
  ensure_component wgcf
  [[ -x "$MANAGED_WGCF_BIN" ]] || die "未找到 wgcf。"

  if [[ -s "$WARP_ACCOUNT_FILE" && ! -L "$WARP_ACCOUNT_FILE" ]]; then
    if warp_generate_profile_from_account "$MANAGED_WGCF_BIN"; then
      ok "已用现有 WARP 账户生成 WireGuard 配置。"
      return 0
    fi
    warn "现有 WARP 账户已失效，将重新注册。"
  fi

  info "正在注册 Cloudflare WARP 设备……"
  warp_register_account || die "Cloudflare WARP 设备注册失败，现有部署未被改动。"
  ok "Cloudflare WARP 设备注册成功，WireGuard 配置已生成。"
}

warp_profile_value() {
  local value=""
  value="$(awk -F '=' -v wanted="$1" '$1 ~ "^[[:space:]]*" wanted "[[:space:]]*$" { sub(/^[^=]*=/, ""); print; exit }' "$WARP_PROFILE_FILE")"
  value="${value#"${value%%[![:space:]]*}"}"
  printf '%s' "${value%"${value##*[![:space:]]}"}"
}

load_warp_profile_parameters() {
  local address_line="" item="" endpoint="" endpoint_host="" mtu="" checked_endpoint="" checked_port=""

  ensure_warp_profile
  WARP_PRIVATE_KEY="$(warp_profile_value PrivateKey)"
  WARP_PEER_PUBLIC_KEY="$(warp_profile_value PublicKey)"
  address_line="$(warp_profile_value Address)"
  endpoint="$(warp_profile_value Endpoint)"
  mtu="$(warp_profile_value MTU)"
  WARP_IPV4=""; WARP_IPV6=""

  while IFS= read -r item; do
    item="${item#"${item%%[![:space:]]*}"}"
    item="${item%"${item##*[![:space:]]}"}"
    [[ -n "$item" ]] || continue
    if [[ "$item" == *.*/* ]]; then WARP_IPV4="$item"; elif [[ "$item" == *:*/* ]]; then WARP_IPV6="$item"; fi
  done < <(printf '%s\n' "$address_line" | tr ',' '\n')

  [[ "$WARP_PRIVATE_KEY" =~ ^[A-Za-z0-9+/]{43}=$ ]] || die "WARP 私钥格式无效。"
  [[ "$WARP_PEER_PUBLIC_KEY" =~ ^[A-Za-z0-9+/]{43}=$ ]] || die "WARP 对端公钥格式无效。"
  valid_ipv4_cidr "$WARP_IPV4" || die "WARP IPv4 地址格式无效。"
  valid_ipv6_cidr "$WARP_IPV6" || die "WARP IPv6 地址格式无效。"

  if [[ "$endpoint" =~ ^\[([^]]+)\]:([0-9]{1,5})$ || "$endpoint" =~ ^([^:]+):([0-9]{1,5})$ ]]; then
    endpoint_host="${BASH_REMATCH[1]}"
    WARP_PROFILE_ENDPOINT_PORT="$((10#${BASH_REMATCH[2]}))"
  else
    die "WARP Endpoint 格式无效：${endpoint}"
  fi
  ((WARP_PROFILE_ENDPOINT_PORT >= 1 && WARP_PROFILE_ENDPOINT_PORT <= 65535)) || die "WARP Endpoint 端口无效。"
  valid_ipv4 "$endpoint_host" || valid_ipv6 "$endpoint_host" || valid_domain_name "$endpoint_host" \
    || die "WARP Endpoint 地址无效：${endpoint_host}"
  WARP_ENDPOINT_ADDRESS="${endpoint_host%.}"
  WARP_ENDPOINT_ADDRESS="${WARP_ENDPOINT_ADDRESS,,}"
  WARP_ENDPOINT_PORT="$WARP_PROFILE_ENDPOINT_PORT"

  if [[ -f "$WARP_CHECK_FILE" && ! -L "$WARP_CHECK_FILE" ]]; then
    checked_endpoint="$(jq -r '.endpoint // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
    checked_port="$(jq -r '.port // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
    if [[ "${checked_endpoint,,}" == "$WARP_ENDPOINT_ADDRESS" && "$checked_port" =~ ^[0-9]{1,5}$ ]] \
        && ((10#$checked_port >= 1 && 10#$checked_port <= 65535)); then
      WARP_ENDPOINT_PORT="$((10#$checked_port))"
    fi
  fi

  WARP_MTU="1280"
  [[ "$mtu" =~ ^[0-9]{3,5}$ ]] && ((10#$mtu >= 576 && 10#$mtu <= 9000)) && WARP_MTU="$((10#$mtu))"
  return 0
}

singbox_doh_server() {
  local tag="$1" detour="${2:-}"
  jq -n --arg tag "$tag" --arg detour "$detour" '
    {type: "https", tag: $tag, server: "1.1.1.1", server_port: 443, path: "/dns-query",
     tls: {enabled: true, server_name: "cloudflare-dns.com"}}
    + (if $detour != "" then {detour: $detour} else {} end)'
}

singbox_warp_endpoint() {
  jq -n --arg ip_strategy "$(singbox_ip_strategy)" --arg private_key "$WARP_PRIVATE_KEY" \
    --arg ipv4 "$WARP_IPV4" --arg ipv6 "$WARP_IPV6" --arg peer "$WARP_ENDPOINT_ADDRESS" \
    --argjson peer_port "$WARP_ENDPOINT_PORT" --arg public_key "$WARP_PEER_PUBLIC_KEY" --argjson mtu "$WARP_MTU" '
    {type: "wireguard", tag: "warp", system: false, mtu: $mtu, address: [$ipv4, $ipv6],
     private_key: $private_key,
     peers: [{address: $peer, port: $peer_port, public_key: $public_key,
              allowed_ips: ["0.0.0.0/0", "::/0"], persistent_keepalive_interval: 30}],
     udp_timeout: "5m", connect_timeout: "10s",
     domain_resolver: {server: "warp-bootstrap-doh", strategy: $ip_strategy}}'
}

singbox_render_config() {
  local ip_strategy="" dns_servers="[]" dns_final="local-dns" endpoints="[]" route_final="direct"
  local doh_direct="" doh_bootstrap="" doh_via_warp=""

  ip_strategy="$(singbox_ip_strategy)"
  case "${SB_DOH}:${SB_WARP}" in
    0:0)
      dns_servers='[{"type":"local","tag":"local-dns"}]'
      ;;
    1:0)
      doh_direct="$(singbox_doh_server cloudflare-doh)"
      dns_servers="[${doh_direct}]"
      dns_final="cloudflare-doh"
      ;;
    0:1)
      doh_bootstrap="$(singbox_doh_server warp-bootstrap-doh)"
      dns_servers="[{\"type\":\"local\",\"tag\":\"local-dns\"},${doh_bootstrap}]"
      endpoints="[$(singbox_warp_endpoint)]"
      route_final="warp"
      ;;
    1:1)
      doh_bootstrap="$(singbox_doh_server warp-bootstrap-doh)"
      doh_via_warp="$(singbox_doh_server cloudflare-doh warp)"
      dns_servers="[${doh_bootstrap},${doh_via_warp}]"
      dns_final="cloudflare-doh"
      endpoints="[$(singbox_warp_endpoint)]"
      route_final="warp"
      ;;
    *) die "DoH / WARP 开关组合无效。" ;;
  esac

  jq -n --arg name "$SB_NODE" --arg uuid "$SB_UUID" --arg path "$SB_WS_PATH" --argjson port "$SB_PORT" \
    --arg ip_strategy "$ip_strategy" --argjson early_data "$WS_EARLY_DATA" \
    --argjson dns_servers "$dns_servers" --arg dns_final "$dns_final" \
    --argjson endpoints "$endpoints" --arg route_final "$route_final" '
    {
      log: {level: "info", timestamp: true},
      inbounds: [{
        type: "vmess", tag: "vmess-ws-in", listen: "127.0.0.1", listen_port: $port,
        users: [{name: $name, uuid: $uuid, alterId: 0}],
        transport: {type: "ws", path: $path, max_early_data: $early_data,
                    early_data_header_name: "Sec-WebSocket-Protocol"}
      }],
      dns: {servers: $dns_servers, final: $dns_final, strategy: $ip_strategy},
      outbounds: [{type: "direct", tag: "direct"}],
      route: {
        rules: [
          {inbound: ["vmess-ws-in"], action: "resolve", strategy: $ip_strategy},
          {ip_is_private: true, action: "reject", method: "drop"},
          {ip_cidr: ["169.254.169.254/32", "100.100.100.200/32"], action: "reject", method: "drop"}
        ],
        final: $route_final,
        default_domain_resolver: {server: $dns_final, strategy: $ip_strategy}
      }
    }
    + (if ($endpoints | length) > 0 then {endpoints: $endpoints} else {} end)'
}

singbox_config_self_check() {
  jq -e --arg uuid "$SB_UUID" --arg path "$SB_WS_PATH" --argjson port "$SB_PORT" \
    --arg ip_strategy "$(singbox_ip_strategy)" --arg warp "$SB_WARP" --arg doh "$SB_DOH" '
    (.inbounds | length == 1)
    and .inbounds[0].type == "vmess" and .inbounds[0].listen == "127.0.0.1"
    and .inbounds[0].listen_port == $port and .inbounds[0].users[0].uuid == $uuid
    and .inbounds[0].transport.type == "ws" and .inbounds[0].transport.path == $path
    and .dns.strategy == $ip_strategy
    and any(.route.rules[]; .action == "resolve" and .inbound == ["vmess-ws-in"])
    and any(.route.rules[]; .ip_is_private == true and .action == "reject")
    and (if $warp == "1" then .route.final == "warp" and any(.endpoints[]; .tag == "warp" and .type == "wireguard")
         else .route.final == "direct" and ((.endpoints // []) | length == 0) end)
    and (if $doh == "1" then .dns.final == "cloudflare-doh" else .dns.final == "local-dns" end)' "$1" >/dev/null
}

write_singbox_config() {
  local tmp=""

  [[ -x "$MANAGED_SINGBOX_BIN" ]] || die "未找到 sing-box。"
  valid_uuid "$SB_UUID" || die "sing-box UUID 无效。"
  valid_ws_path "$SB_WS_PATH" || die "sing-box WS 路径无效。"
  valid_local_port "$SB_PORT" || die "sing-box 本地端口无效。"
  valid_node_name "$SB_NODE" || die "sing-box 节点名称无效。"

  if [[ "$SB_WARP" == "1" ]]; then load_warp_profile_parameters; else rm -f "$WARP_CHECK_FILE"; fi

  tmp="$(mktemp "${DATA_DIR}/.sing-box.json.XXXXXX")"
  singbox_render_config > "$tmp" || { rm -f "$tmp"; die "sing-box 配置渲染失败。"; }
  singbox_config_self_check "$tmp" || { rm -f "$tmp"; die "生成的 sing-box 配置未通过结构自检。"; }
  chmod 640 "$tmp"
  chown root:"$SERVICE_GROUP" "$tmp"
  "$MANAGED_SINGBOX_BIN" check -c "$tmp" || { rm -f "$tmp"; die "sing-box 配置校验失败。"; }
  singbox_probe_config "$tmp" || { rm -f "$tmp"; die "sing-box 配置启动自检失败。"; }
  mv -f "$tmp" "$SB_CONFIG"
}

singbox_probe_config() {
  local config="$1" log="" pid="" i=0

  listener_on_port "$SB_PORT" && return 0
  log="$(mktemp)"
  spawn_detached "$MANAGED_SINGBOX_BIN" run -c "$config" > "$log" 2>&1 &
  pid=$!
  for i in 1 2 3; do
    sleep 1
    process_is_alive "$pid" || break
  done
  if process_is_alive "$pid"; then
    kill -TERM "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -f "$log"
    return 0
  fi
  wait "$pid" 2>/dev/null || true
  grep -E 'FATAL|ERROR|error' "$log" | tail -n 3 >&2
  rm -f "$log"
  return 1
}

find_free_loopback_port() {
  local port=0
  for ((port = 18080; port <= 18179; port++)); do
    ss -ltn 2>/dev/null | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${port}([[:space:]]|$)" || { printf '%s\n' "$port"; return 0; }
  done
  return 1
}

warp_candidate_ports() {
  local port="" seen=" "
  for port in "$WARP_ENDPOINT_PORT" "$WARP_PROFILE_ENDPOINT_PORT" 2408 500 1701 4500; do
    [[ "$port" =~ ^[0-9]{1,5}$ ]] || continue
    port="$((10#$port))"
    [[ "$seen" == *" ${port} "* ]] && continue
    seen="${seen}${port} "
    printf '%s\n' "$port"
  done
}

current_warp_peer_port() {
  jq -r '(.endpoints // [])[] | select(.tag == "warp") | .peers[0].port // empty' "$SB_CONFIG" 2>/dev/null || true
}

set_warp_peer_port() {
  local port="$1" tmp=""

  tmp="$(mktemp "${DATA_DIR}/.sing-box-port.json.XXXXXX")"
  jq --argjson port "$port" '(.endpoints[] | select(.tag == "warp") | .peers[0].port) = $port' "$SB_CONFIG" > "$tmp" \
    || { rm -f "$tmp"; return 1; }
  chmod 640 "$tmp"
  chown root:"$SERVICE_GROUP" "$tmp"
  "$MANAGED_SINGBOX_BIN" check -c "$tmp" >/dev/null 2>&1 || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$SB_CONFIG"
  WARP_ENDPOINT_PORT="$port"
}

verify_warp_runtime() {
  local test_port="" test_config="" test_log="" test_pid="" test_start="" response=""
  local warp_state="" exit_ip="" colo="" selected_port="" attempted="" port="" i=0
  local -a candidates=()

  [[ "$SB_WARP" == "1" ]] || return 0
  use_core singbox
  service_is_active || die "WARP 自检前发现 sing-box 服务未运行。"
  listener_exact_loopback "$SB_PORT" || die "WARP 自检前发现 127.0.0.1:${SB_PORT} 未监听。"

  mapfile -t candidates < <(warp_candidate_ports)
  ((${#candidates[@]} > 0)) || die "没有可用于 WARP 自检的 Endpoint UDP 端口。"
  test_port="$(find_free_loopback_port)" || die "无法找到用于 WARP 自检的空闲回环端口。"
  test_config="$(mktemp "${DATA_DIR}/.warp-check.json.XXXXXX")"
  test_log="$(mktemp "${DATA_DIR}/.warp-check.log.XXXXXX")"

  jq -n --arg uuid "$SB_UUID" --arg path "$SB_WS_PATH" --argjson server_port "$SB_PORT" --argjson listen_port "$test_port" '
    {log: {level: "warn"},
     inbounds: [{type: "mixed", tag: "check-in", listen: "127.0.0.1", listen_port: $listen_port}],
     outbounds: [{type: "vmess", tag: "check-out", server: "127.0.0.1", server_port: $server_port,
                  uuid: $uuid, security: "auto", alter_id: 0, transport: {type: "ws", path: $path}}],
     route: {final: "check-out"}}' > "$test_config"
  chmod 600 "$test_config"

  "$MANAGED_SINGBOX_BIN" check -c "$test_config" || { rm -f "$test_config" "$test_log"; die "WARP 自检客户端配置未通过校验。"; }
  spawn_detached "$MANAGED_SINGBOX_BIN" run -c "$test_config" > "$test_log" 2>&1 &
  test_pid=$!
  test_start="$(process_start_time "$test_pid" 2>/dev/null || true)"

  for ((i = 1; i <= 15; i++)); do
    ss -ltn 2>/dev/null | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${test_port}([[:space:]]|$)" && break
    process_is_alive "$test_pid" || break
    sleep 1
  done
  if ! ss -ltn 2>/dev/null | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${test_port}([[:space:]]|$)"; then
    warn "WARP 自检客户端未能启动，日志如下："
    tail -n 60 "$test_log" >&2 || true
    stop_process_verified "$test_pid" "$test_start" 5 || true
    rm -f "$test_config" "$test_log"
    die "WARP 自检客户端启动失败。"
  fi

  for port in "${candidates[@]}"; do
    attempted="${attempted:+${attempted},}${port}"
    info "正在测试 WARP Endpoint ${WARP_ENDPOINT_ADDRESS}:${port}/UDP……"

    if [[ "$(current_warp_peer_port)" != "$port" ]]; then
      set_warp_peer_port "$port" || { warn "无法切换到 UDP ${port}，跳过。"; continue; }
      service_restart || { warn "切换到 UDP ${port} 后 sing-box 重启失败，跳过。"; continue; }
      wait_for_service_ready "$SB_PORT" || { warn "切换到 UDP ${port} 后 sing-box 未能正常监听，跳过。"; continue; }
    fi

    response=""; warp_state=""
    for ((i = 1; i <= 2; i++)); do
      response="$(curl -sS --max-time 15 --connect-timeout 5 --proxy "socks5h://127.0.0.1:${test_port}" \
        https://www.cloudflare.com/cdn-cgi/trace 2>> "$test_log" || true)"
      warp_state="$(printf '%s\n' "$response" | tr -d '\r' | awk -F= '$1 == "warp" {print $2; exit}')"
      [[ "$warp_state" == "on" || "$warp_state" == "plus" ]] && { selected_port="$port"; break; }
      sleep 1
    done
    [[ -n "$selected_port" ]] && break
    warn "WARP Endpoint UDP ${port} 未通过链路自检。"
  done

  stop_process_verified "$test_pid" "$test_start" 5 || true
  rm -f "$test_config"

  if [[ -z "$selected_port" ]]; then
    warn "已依次测试配置端口与 Cloudflare 回退端口，均未确认 WARP 可用。自检客户端日志："
    tail -n 100 "$test_log" >&2 || true
    rm -f "$test_log" "$WARP_CHECK_FILE"
    die "WARP 链路不可用。常见原因：VPS 阻断 UDP 2408/500/1701/4500，或该网络限制 WireGuard。"
  fi
  rm -f "$test_log"

  exit_ip="$(printf '%s\n' "$response" | tr -d '\r' | awk -F= '$1 == "ip" {print $2; exit}')"
  colo="$(printf '%s\n' "$response" | tr -d '\r' | awk -F= '$1 == "colo" {print $2; exit}')"
  jq -n --arg checked_at "$(utc_now)" --arg warp "$warp_state" --arg ip "$exit_ip" --arg colo "$colo" \
    --arg endpoint "$WARP_ENDPOINT_ADDRESS" --argjson port "$selected_port" \
    --argjson profile_port "$WARP_PROFILE_ENDPOINT_PORT" --arg attempted "$attempted" \
    '{checked_at: $checked_at, warp: $warp, exit_ip: $ip, colo: $colo, endpoint: $endpoint,
      port: $port, profile_port: $profile_port, attempted_ports: $attempted}' \
    | write_file_atomic "$WARP_CHECK_FILE" 600
  WARP_ENDPOINT_PORT="$selected_port"
  ok "WARP 链路自检通过：Endpoint ${WARP_ENDPOINT_ADDRESS}:${selected_port}/UDP，warp=${warp_state}，出口 ${exit_ip:-未知}（${colo:-未知}）。"
}

warp_check_summary() {
  local state="" ip="" colo=""
  [[ -f "$WARP_CHECK_FILE" ]] || { printf ''; return 0; }
  state="$(jq -r '.warp // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
  ip="$(jq -r '.exit_ip // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
  colo="$(jq -r '.colo // empty' "$WARP_CHECK_FILE" 2>/dev/null || true)"
  [[ -n "$state" ]] && printf '%s · %s · %s' "$state" "${ip:-?}" "${colo:-?}"
  return 0
}

xray_vlessenc_pair() {
  local output="" dec="" enc=""

  output="$("$MANAGED_XRAY_BIN" vlessenc 2>/dev/null || true)"
  dec="$(printf '%s\n' "$output" | grep -Eo '"decryption": "mlkem768x25519plus\.[^"]+"' | head -n 1 | sed -E 's/.*: "([^"]+)"/\1/')"
  enc="$(printf '%s\n' "$output" | grep -Eo '"encryption": "mlkem768x25519plus\.[^"]+"' | head -n 1 | sed -E 's/.*: "([^"]+)"/\1/')"
  [[ -n "$dec" && -n "$enc" ]] || die "xray vlessenc 未输出可用的 VLESS-ENC 密钥。"
  dec="$(printf '%s' "$dec" | sed -E 's/^mlkem768x25519plus\.(native|random)\./mlkem768x25519plus.xorpub./')"
  enc="$(printf '%s' "$enc" | sed -E 's/^mlkem768x25519plus\.(native|random)\./mlkem768x25519plus.xorpub./')"
  valid_vlessenc_value "$dec" && valid_vlessenc_value "$enc" || die "VLESS-ENC 密钥格式无效。"
  printf '%s\n%s\n' "$dec" "$enc"
}

xray_render_config() {
  jq -n --argjson port "$XR_PORT" --arg uuid "$XR_UUID" --arg node "$XR_NODE" --arg path "$XR_WS_PATH" \
    --arg decryption "$XR_DEC" --arg freedom_strategy "$(xray_freedom_strategy)" '
    {
      log: {loglevel: "warning"},
      inbounds: [{
        tag: "vless-enc-ws-in", listen: "127.0.0.1", port: $port, protocol: "vless",
        settings: {clients: [{id: $uuid, level: 0, email: $node, flow: "xtls-rprx-vision"}], decryption: $decryption},
        streamSettings: {network: "ws", security: "none", wsSettings: {path: $path}},
        sniffing: {enabled: true, destOverride: ["http", "tls", "quic"], metadataOnly: false}
      }],
      outbounds: [
        {tag: "direct", protocol: "freedom", settings: {domainStrategy: $freedom_strategy}},
        {tag: "block", protocol: "blackhole"}
      ],
      routing: {
        domainStrategy: "IPOnDemand",
        rules: [{
          type: "field", outboundTag: "block",
          ip: ["0.0.0.0/8", "10.0.0.0/8", "100.64.0.0/10", "127.0.0.0/8", "169.254.0.0/16", "172.16.0.0/12",
               "192.0.0.0/24", "192.0.2.0/24", "192.168.0.0/16", "198.18.0.0/15", "198.51.100.0/24",
               "203.0.113.0/24", "224.0.0.0/4", "240.0.0.0/4", "::1/128", "fc00::/7", "fe80::/10",
               "169.254.169.254/32", "100.100.100.200/32"]
        }]
      }
    }'
}

write_xray_config() {
  local tmp="" output=""

  [[ -x "$MANAGED_XRAY_BIN" ]] || die "未找到 Xray。"
  valid_uuid "$XR_UUID" || die "Xray UUID 无效。"
  valid_ws_path "$XR_WS_PATH" || die "Xray WS 路径无效。"
  valid_vlessenc_value "$XR_DEC" || die "VLESS-ENC decryption 无效。"
  valid_local_port "$XR_PORT" || die "Xray 本地端口无效。"

  tmp="$(mktemp "${DATA_DIR}/.xray.XXXXXX.json")"
  xray_render_config > "$tmp" || { rm -f "$tmp"; die "Xray 配置渲染失败。"; }
  jq -e --argjson port "$XR_PORT" --arg uuid "$XR_UUID" --arg path "$XR_WS_PATH" '
    .inbounds[0].port == $port and .inbounds[0].settings.clients[0].id == $uuid
    and .inbounds[0].streamSettings.network == "ws" and .inbounds[0].streamSettings.wsSettings.path == $path
    and any(.routing.rules[]; .outboundTag == "block" and (.ip | index("127.0.0.0/8") != null))' "$tmp" >/dev/null \
    || { rm -f "$tmp"; die "生成的 Xray 配置未通过结构自检。"; }
  chmod 640 "$tmp"
  chown root:"$SERVICE_GROUP" "$tmp"
  if ! output="$("$MANAGED_XRAY_BIN" run -test -config "$tmp" 2>&1)"; then
    printf '%s\n' "$output" >&2
    rm -f "$tmp"
    die "Xray 配置校验失败。"
  fi
  mv -f "$tmp" "$XR_CONFIG"
}

generate_identity() {
  local uuid="" pair=""

  uuid="$(generate_uuid_v4)" && valid_uuid "$uuid" || die "UUID 生成失败。"
  cset UUID "$uuid"
  cset ARGO_HOST ""
  cset CREATED_AT "$(utc_now)"
  if [[ "$CORE" == "singbox" ]]; then
    cset WS_PATH "/$(openssl rand -hex 16)-vmws"
  else
    cset WS_PATH "/${uuid}-vw"
    pair="$(xray_vlessenc_pair)"
    XR_DEC="$(printf '%s\n' "$pair" | sed -n '1p')"
    XR_ENC="$(printf '%s\n' "$pair" | sed -n '2p')"
  fi
  rm -f "$CORE_LINK" "$CORE_LINK_JSON"
  save_state
}

write_core_config() {
  if [[ "$CORE" == "singbox" ]]; then write_singbox_config; else write_xray_config; fi
}

service_marker_ok() {
  local content=""
  secure_root_file "$SERVICE_MARKER" || return 1
  IFS= read -r content < "$SERVICE_MARKER" || return 1
  [[ "$content" == "$SERVICE_MARKER_CONTENT" || "$content" == "zdd-argo 管理的低权限服务账户" ]]
}

ensure_service_account() {
  local passwd_line="" existing_home="" existing_gid="" expected_gid="" existing_shell="" path=""

  for path in "$SERVICE_HOME" "$SB_CF_HOME" "$XR_CF_HOME" "$DATA_DIR"; do
    if [[ -e "$path" || -L "$path" ]]; then
      [[ -d "$path" && ! -L "$path" ]] || die "受管目录不是普通目录或属于符号链接：${path}"
    fi
  done

  if getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    service_marker_ok || die "系统中已存在同名账户 ${SERVICE_USER}，但无法确认归属，已停止部署。"
    passwd_line="$(getent passwd "$SERVICE_USER")"
    IFS=':' read -r _ _ _ existing_gid _ existing_home existing_shell <<< "$passwd_line"
    expected_gid="$(getent group "$SERVICE_GROUP" | awk -F: '{print $3}')"
    [[ "$existing_home" == "$SERVICE_HOME" ]] || die "账户 ${SERVICE_USER} 的主目录异常，已停止部署。"
    [[ -n "$expected_gid" && "$existing_gid" == "$expected_gid" ]] || die "账户 ${SERVICE_USER} 的主组异常，已停止部署。"
    case "$existing_shell" in
      "$SERVICE_SHELL"|/usr/sbin/nologin|/sbin/nologin|/bin/false) ;;
      *) die "账户 ${SERVICE_USER} 的登录 Shell 异常，已停止部署。" ;;
    esac
  else
    if getent group "$SERVICE_GROUP" >/dev/null 2>&1; then
      service_marker_ok || die "系统中已存在同名组 ${SERVICE_GROUP}，但无法确认归属，已停止部署。"
    else
      groupadd --system "$SERVICE_GROUP" || die "无法创建服务组 ${SERVICE_GROUP}。"
    fi
    useradd --system --gid "$SERVICE_GROUP" --home-dir "$SERVICE_HOME" --create-home \
      --shell "$SERVICE_SHELL" "$SERVICE_USER" || die "无法创建服务账户 ${SERVICE_USER}。"
  fi

  mkdir -p "$SERVICE_HOME" "$SB_CF_HOME" "$XR_CF_HOME" "$DATA_DIR"
  chown root:root "$SERVICE_HOME"
  chmod 755 "$SERVICE_HOME"
  chown "$SERVICE_USER:$SERVICE_GROUP" "$SB_CF_HOME" "$XR_CF_HOME"
  chmod 700 "$SB_CF_HOME" "$XR_CF_HOME"
  chown root:"$SERVICE_GROUP" "$DATA_DIR"
  chmod 750 "$DATA_DIR"
  printf '%s\n' "$SERVICE_MARKER_CONTENT" | write_file_atomic "$SERVICE_MARKER" 600
  service_marker_ok || die "服务账户归属标记写入后校验失败。"
}

service_uid() {
  id -u "$SERVICE_USER" 2>/dev/null || true
}

service_is_active() {
  case "$INIT_SYSTEM" in
    systemd) systemctl is-active --quiet "$CORE_SERVICE" 2>/dev/null ;;
    openrc)  rc-service "$CORE_SERVICE" status >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

service_enable() {
  case "$INIT_SYSTEM" in
    systemd) systemctl enable "$CORE_SERVICE" >/dev/null 2>&1 ;;
    openrc)  rc-update add "$CORE_SERVICE" default >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

service_restart() {
  case "$INIT_SYSTEM" in
    systemd) systemctl restart "$CORE_SERVICE" >/dev/null 2>&1 ;;
    openrc)  rc-service "$CORE_SERVICE" restart >/dev/null 2>&1 || rc-service "$CORE_SERVICE" start >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

service_stop() {
  case "$INIT_SYSTEM" in
    systemd) systemctl stop "$CORE_SERVICE" >/dev/null 2>&1 ;;
    openrc)  rc-service "$CORE_SERVICE" stop >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

service_disable_now() {
  case "$INIT_SYSTEM" in
    systemd) systemctl disable --now "$CORE_SERVICE" >/dev/null 2>&1 ;;
    openrc)
      rc-service "$CORE_SERVICE" stop >/dev/null 2>&1 || true
      rc-update del "$CORE_SERVICE" default >/dev/null 2>&1 || true
      ;;
  esac
  return 0
}

service_daemon_reload() {
  [[ "$INIT_SYSTEM" == "systemd" ]] && { systemctl daemon-reload >/dev/null 2>&1 || true; }
  return 0
}

service_reset_failed() {
  [[ "$INIT_SYSTEM" == "systemd" ]] && { systemctl reset-failed "$CORE_SERVICE" >/dev/null 2>&1 || true; }
  return 0
}

service_print_logs() {
  local lines="${1:-60}"
  case "$INIT_SYSTEM" in
    systemd) journalctl -u "$CORE_SERVICE" -n "$lines" --no-pager 2>/dev/null || true ;;
    openrc)
      if [[ -f "$CORE_CORE_LOG" ]]; then tail -n "$lines" "$CORE_CORE_LOG" || true
      else warn "未找到 ${CORE_LABEL} 日志文件：${CORE_CORE_LOG}"; fi
      ;;
  esac
}

service_log_hint() {
  case "$INIT_SYSTEM" in
    systemd) printf 'journalctl -u %s -n 200 --no-pager' "$CORE_SERVICE" ;;
    *)       printf 'tail -n 200 %s' "$CORE_CORE_LOG" ;;
  esac
}

listener_exact_loopback() {
  ss -ltn 2>/dev/null | grep -Eq "(^|[[:space:]])127[.]0[.]0[.]1:${1}([[:space:]]|$)"
}

listener_on_port() {
  ss -ltn 2>/dev/null | grep -Eq "(^|[[:space:]])[^[:space:]]*:${1}([[:space:]]|$)"
}

wait_for_service_ready() {
  local port="$1" i=0
  for ((i = 1; i <= 15; i++)); do
    if listener_exact_loopback "$port" && { service_is_active || [[ "$INIT_SYSTEM" == "openrc" ]]; }; then
      return 0
    fi
    sleep 1
  done
  return 1
}

listener_pid_on_port() {
  ss -ltnp 2>/dev/null | grep -E "(^|[[:space:]])[^[:space:]]*:${1}([[:space:]]|$)" | grep -Eo 'pid=[0-9]+' | head -n 1 | cut -d= -f2
}

pid_is_our_core() {
  local cmdline=""
  [[ "$1" =~ ^[0-9]+$ ]] || return 1
  cmdline="$(process_command_line "$1" 2>/dev/null || true)"
  [[ "$cmdline" == *"${CORE_BIN}"* || "$cmdline" == *"${CORE_CONFIG}"* ]]
}

clear_stale_core_process() {
  local port="$1" pid="" start="" i=0

  for ((i = 0; i < 3; i++)); do
    listener_on_port "$port" || return 0
    service_is_active && return 0
    pid="$(listener_pid_on_port "$port" || true)"
    pid_is_our_core "$pid" || return 1
    warn "发现残留的 ${CORE_LABEL} 进程（PID ${pid}）占用端口 ${port}，正在清理……"
    start="$(process_start_time "$pid" 2>/dev/null || true)"
    stop_process_verified "$pid" "$start" 5 || true
    sleep 1
  done
  ! listener_on_port "$port"
}

ensure_core_running() {
  local port=""
  port="$(cget PORT)"

  if ! clear_stale_core_process "$port"; then
    warn "端口 ${port} 已被其他进程占用："
    ss -ltnp 2>/dev/null | grep -E "(^|:)${port}[[:space:]]" || true
    die "为避免覆盖其他服务，已停止 ${CORE_LABEL} 部署。"
  fi
  service_enable || die "无法启用 ${CORE_SERVICE}。"
  service_restart || die "无法重启 ${CORE_SERVICE}。"
  if ! wait_for_service_ready "$port"; then
    service_print_logs 60 >&2
    die "${CORE_SERVICE} 未能在 15 秒内正常监听 127.0.0.1:${port}。"
  fi
}

core_exec_args() {
  if [[ "$CORE" == "singbox" ]]; then printf 'run -c %s' "$CORE_CONFIG"; else printf 'run -config %s' "$CORE_CONFIG"; fi
}

unit_is_ours() {
  [[ -f "$CORE_UNIT" && ! -L "$CORE_UNIT" ]] || return 1
  grep -Fq 'zdd-argo' "$CORE_UNIT" 2>/dev/null || return 1
  case "$INIT_SYSTEM" in
    systemd) grep -Fqx "ExecStart=${CORE_BIN} $(core_exec_args)" "$CORE_UNIT" 2>/dev/null \
               && grep -Fqx "User=${SERVICE_USER}" "$CORE_UNIT" 2>/dev/null ;;
    openrc)  grep -Fqx "command=\"${CORE_BIN}\"" "$CORE_UNIT" 2>/dev/null \
               && grep -Fqx "command_user=\"${SERVICE_USER}:${SERVICE_GROUP}\"" "$CORE_UNIT" 2>/dev/null ;;
    *) return 1 ;;
  esac
}

write_core_unit() {
  [[ -x "$CORE_BIN" ]] || die "未找到 ${CORE_LABEL} 可执行文件。"
  ensure_service_account
  if [[ -e "$CORE_UNIT" || -L "$CORE_UNIT" ]]; then
    unit_is_ours || die "服务路径已被其他程序占用：${CORE_UNIT}"
  fi

  if [[ "$INIT_SYSTEM" == "systemd" ]]; then
    cat <<EOF | write_file_atomic "$CORE_UNIT" 644
[Unit]
Description=zdd-argo ${CORE_LABEL} ${CORE_PROTO} service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
ExecStart=${CORE_BIN} $(core_exec_args)
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
  else
    cat <<EOF | write_file_atomic "$CORE_UNIT" 755
#!/sbin/openrc-run
# zdd-argo managed service
name="zdd-argo ${CORE_LABEL} ${CORE_PROTO}"
description="zdd-argo ${CORE_LABEL} ${CORE_PROTO} service"
command="${CORE_BIN}"
command_args="$(core_exec_args)"
command_user="${SERVICE_USER}:${SERVICE_GROUP}"
pidfile="/run/${CORE_SERVICE}.pid"
supervisor="supervise-daemon"
respawn_delay=3
respawn_max=0
output_log="${CORE_CORE_LOG}"
error_log="${CORE_CORE_LOG}"

depend() {
  use net
}

start_pre() {
  checkpath -d -m 0750 -o root:${SERVICE_GROUP} "${DATA_DIR}"
  checkpath -f -m 0640 -o root:${SERVICE_GROUP} "${CORE_CONFIG}"
  checkpath -f -m 0640 -o ${SERVICE_USER}:${SERVICE_GROUP} "${CORE_CORE_LOG}"
}
EOF
  fi
  service_daemon_reload
}

render_logrotate_config() {
  cat <<EOF
# zdd-argo managed
${SB_TUNNEL_LOG} ${XR_TUNNEL_LOG} ${SB_CORE_LOG} ${XR_CORE_LOG} {
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
  [[ -f "$LOGROTATE_CONFIG" && ! -L "$LOGROTATE_CONFIG" ]] || return 1
  grep -Fq 'zdd-argo' "$LOGROTATE_CONFIG" 2>/dev/null || grep -Fq "$SB_TUNNEL_LOG" "$LOGROTATE_CONFIG" 2>/dev/null
}

write_logrotate_config() {
  if [[ -e "$LOGROTATE_CONFIG" || -L "$LOGROTATE_CONFIG" ]]; then
    logrotate_config_is_ours || die "日志轮转配置路径已被其他程序占用：${LOGROTATE_CONFIG}"
  fi
  render_logrotate_config | write_file_atomic "$LOGROTATE_CONFIG" 644
}

write_cloudflared_runner() {
  local uid="" gid="" port="" launcher=""

  [[ -x "$MANAGED_CLOUDFLARED_BIN" ]] || die "未找到 cloudflared。"
  ensure_service_account
  uid="$(id -u "$SERVICE_USER")"
  gid="$(id -g "$SERVICE_USER")"
  [[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || die "无法读取服务账户的 UID/GID。"
  port="$(cget PORT)"

  if [[ "$INIT_SYSTEM" == "openrc" ]]; then
    launcher="exec su-exec ${uid}:${gid}"
  else
    launcher="exec setpriv --reuid=${uid} --regid=${gid} --clear-groups --no-new-privs --"
  fi

  cat <<EOF | write_file_atomic "$CORE_RUNNER" 700
#!/usr/bin/env bash
# zdd-argo cloudflared runner (${CORE_LABEL})
set -Eeuo pipefail
export HOME=${CORE_CF_HOME@Q}
${launcher} ${MANAGED_CLOUDFLARED_BIN@Q} tunnel \\
  --url "http://127.0.0.1:${port}" \\
  --edge-ip-version auto \\
  --no-autoupdate \\
  --protocol http2 \\
  --logfile ${CORE_TUNNEL_LOG@Q}
EOF
  bash -n "$CORE_RUNNER" || die "生成的 cloudflared 启动器未通过语法检查。"
}

tmux_session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

tunnel_pid() {
  local session="${1:-$CORE_SESSION}" pane_pid="" pid="" child=""

  tmux_session_exists "$session" || return 1
  pane_pid="$(tmux list-panes -t "$session" -F '#{pane_pid}' 2>/dev/null | head -n 1 || true)"
  [[ "$pane_pid" =~ ^[0-9]+$ ]] || return 1

  for pid in "$pane_pid" $(process_children "$pane_pid") ; do
    if cloudflared_pid_matches "$pid"; then printf '%s\n' "$pid"; return 0; fi
    for child in $(process_children "$pid"); do
      if cloudflared_pid_matches "$child"; then printf '%s\n' "$child"; return 0; fi
    done
  done
  return 1
}

cloudflared_pid_matches() {
  local pid="$1" cmdline="" uid=""
  process_is_alive "$pid" || return 1
  uid="$(process_effective_uid "$pid" 2>/dev/null || true)"
  [[ -n "$uid" && "$uid" == "$(service_uid)" ]] || return 1
  cmdline="$(process_command_line "$pid" 2>/dev/null || true)"
  [[ "$cmdline" == *"${MANAGED_CLOUDFLARED_BIN}"* && "$cmdline" == *"tunnel"* && "$cmdline" == *"127.0.0.1:$(cget PORT)"* ]]
}

tunnel_is_running() {
  tunnel_pid >/dev/null 2>&1
}

core_runtime_is_running() {
  [[ -x "$MANAGED_CLOUDFLARED_BIN" ]] && service_is_active && listener_exact_loopback "$(cget PORT)" && tunnel_is_running
}

extract_argo_host() {
  [[ -f "$CORE_TUNNEL_LOG" ]] || return 1
  grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$CORE_TUNNEL_LOG" 2>/dev/null | tail -n 1 | sed 's#^https://##'
}

wait_for_argo_host() {
  local i=0 host=""
  for ((i = 1; i <= 90; i++)); do
    host="$(extract_argo_host || true)"
    if [[ -n "$host" ]] && valid_argo_host "$host"; then
      cset ARGO_HOST "$host"
      save_state
      return 0
    fi
    if ((i > 5)) && ! tunnel_is_running; then break; fi
    sleep 1
  done
  return 1
}

stop_tunnel() {
  local session="" pid="" start="" stopped=0

  for session in "$CORE_SESSION" "${LEGACY_SESSIONS[@]}"; do
    [[ "$CORE" == "singbox" || "$session" == "$CORE_SESSION" ]] || continue
    tmux_session_exists "$session" || continue
    pid="$(tunnel_pid "$session" 2>/dev/null || true)"
    if [[ -z "$pid" ]]; then
      if tmux list-panes -t "$session" -F '#{pane_start_command}' 2>/dev/null | grep -Fq 'zdd-argo'; then
        pid=""
      else
        warn "发现同名 tmux 会话 ${session}，但不是本脚本创建的，已保留。"
        continue
      fi
    fi
    start="$(process_start_time "${pid:-0}" 2>/dev/null || true)"
    tmux kill-session -t "$session" 2>/dev/null || true
    if [[ -n "$pid" ]]; then
      stop_process_verified "$pid" "$start" 8 || { warn "cloudflared 进程 ${pid} 仍未退出，请手动检查。"; return 1; }
    fi
    stopped=1
  done

  [[ $stopped -eq 1 ]] && ok "${CORE_LABEL} 临时隧道已停止，旧域名随之失效。"
  return 0
}

prepare_tunnel_log() {
  : > "$CORE_TUNNEL_LOG"
  chown "$SERVICE_USER:$SERVICE_GROUP" "$CORE_TUNNEL_LOG"
  chmod 600 "$CORE_TUNNEL_LOG"
}

start_tunnel() {
  local attempt=0 max_attempts=3 host=""

  if tmux_session_exists "$CORE_SESSION" && ! tunnel_is_running; then
    die "已存在同名 tmux 会话 ${CORE_SESSION} 但不是本脚本创建的，请先改名或删除该会话。"
  fi

  if tunnel_is_running; then
    host="$(extract_argo_host || true)"
    if [[ -n "$host" ]] && valid_argo_host "$host"; then
      cset ARGO_HOST "$host"
      save_state
      generate_link
      info "现有临时隧道运行正常，未重复创建。"
      return 0
    fi
    warn "现有隧道尚未取得有效域名，将重新创建。"
    stop_tunnel || true
  fi

  mkdir -p "$CORE_CF_HOME"
  chown "$SERVICE_USER:$SERVICE_GROUP" "$CORE_CF_HOME"
  chmod 700 "$CORE_CF_HOME"
  rm -f "$CORE_LINK" "$CORE_LINK_JSON"
  cset ARGO_HOST ""
  save_state

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    prepare_tunnel_log
    info "正在创建临时隧道（第 ${attempt}/${max_attempts} 次）……"
    if run_without_lock_fd tmux new-session -d -s "$CORE_SESSION" "$CORE_RUNNER" && wait_for_argo_host; then
      generate_link
      ok "临时隧道已建立：$(cget ARGO_HOST)"
      return 0
    fi
    warn "第 ${attempt}/${max_attempts} 次未取得 trycloudflare.com 域名。"
    stop_tunnel >/dev/null 2>&1 || true
    ((attempt < max_attempts)) && sleep 5
  done

  warn "连续 ${max_attempts} 次创建临时隧道失败，最近日志："
  tail -n 40 "$CORE_TUNNEL_LOG" >&2 || true
  die "临时隧道创建失败，请稍后重试。"
}

clear_tunnel_artifacts() {
  if [[ -f "$CORE_STATE" ]]; then
    load_state
    cset ARGO_HOST ""
    save_state
  fi
  rm -f "$CORE_TUNNEL_LOG" "$CORE_LINK" "$CORE_LINK_JSON"
  rm -rf "$CORE_CF_HOME"
}

url_encode() {
  jq -rn --arg value "$1" '$value | @uri'
}

generate_link() {
  local host="" path="" node="" endpoint="" uuid="" encoded="" link=""

  host="$(cget ARGO_HOST)"; path="$(cget WS_PATH)"; node="$(cget NODE)"; endpoint="$(cget ENDPOINT)"; uuid="$(cget UUID)"
  valid_uuid "$uuid" || die "${CORE_LABEL} UUID 无效，无法生成链接。"
  valid_ws_path "$path" || die "${CORE_LABEL} WS 路径无效，无法生成链接。"
  [[ -n "$host" ]] && valid_argo_host "$host" || die "${CORE_LABEL} 临时域名无效，无法生成链接。"
  valid_preferred_endpoint "$endpoint" || die "${CORE_LABEL} 优选域名/IP 无效。"
  valid_node_name "$node" || die "${CORE_LABEL} 节点名称无效。"
  path="${path}?ed=${WS_EARLY_DATA}"

  if [[ "$CORE" == "singbox" ]]; then
    jq -c -n --arg ps "$node" --arg add "$endpoint" --arg id "$uuid" --arg host "$host" --arg path "$path" '
      {v: "2", ps: $ps, add: $add, port: "443", id: $id, aid: "0", scy: "auto", net: "ws", type: "none",
       host: $host, path: $path, tls: "tls", sni: $host, alpn: "http/1.1", fp: "firefox"}' \
      | write_file_atomic "$CORE_LINK_JSON" 600
    encoded="$(tr -d '\n' < "$CORE_LINK_JSON" | base64 | tr -d '\r\n')"
    link="vmess://${encoded}"
    base64 -d <<< "$encoded" 2>/dev/null | jq -e --arg host "$host" '.host == $host and .sni == $host' >/dev/null \
      || die "生成的 VMess 链接自检失败。"
  else
    valid_vlessenc_value "$XR_ENC" || die "VLESS-ENC encryption 无效。"
    valid_ech_config "$XR_ECH" || die "Xray ECH 配置无效。"
    jq -n --arg ps "$node" --arg add "$endpoint" --arg id "$uuid" --arg host "$host" --arg path "$path" \
      --arg enc "$XR_ENC" --arg ech "$XR_ECH" '
      {protocol: "vless", ps: $ps, add: $add, port: 443, id: $id, encryption: $enc, flow: "xtls-rprx-vision",
       security: "tls", sni: $host, vcn: $host, host: $host, path: $path, type: "ws", alpn: "http/1.1", fp: "firefox"}
      + (if $ech != "" then {ech: $ech, echConfigList: $ech} else {} end)' \
      | write_file_atomic "$CORE_LINK_JSON" 600
    link="vless://${uuid}@$(uri_host "$endpoint"):443?encryption=$(url_encode "$XR_ENC")&flow=xtls-rprx-vision"
    link+="&security=tls&sni=$(url_encode "$host")&vcn=$(url_encode "$host")&fp=firefox&type=ws&host=$(url_encode "$host")"
    link+="&path=$(url_encode "$path")&alpn=http%2F1.1"
    [[ -n "$XR_ECH" ]] && link+="&ech=$(url_encode "$XR_ECH")&echConfigList=$(url_encode "$XR_ECH")"
    link+="#$(url_encode "$node")"
  fi

  printf '%s\n' "$link" | write_file_atomic "$CORE_LINK" 600
}

prepare_core_deployment() {
  load_settings
  ensure_component "$CORE"
  ensure_component cloudflared
  ensure_service_account
  load_state
}

apply_ip_mode_to_other_core() {
  local current="$CORE" other=""

  [[ $IP_MODE_CHANGED -eq 1 ]] || return 0
  IP_MODE_CHANGED=0
  other="$(other_core)"
  use_core "$other"
  if [[ -f "$CORE_CONFIG" && -x "$CORE_BIN" ]]; then
    load_state
    if [[ -n "$(cget UUID)" ]]; then
      info "出站策略已变更，同步重写 ${CORE_LABEL} 配置……"
      write_core_config
      service_is_active && { service_restart || warn "${CORE_LABEL} 重启失败，请在状态页检查。"; }
    fi
  fi
  use_core "$current"
}

rebuild_core() {
  generate_identity
  service_stop || true
  service_reset_failed
  write_core_config
  write_core_unit
  write_cloudflared_runner
  write_logrotate_config
  ensure_core_running
  [[ "$CORE" == "singbox" ]] && verify_warp_runtime
  start_tunnel
}

deploy_core() {
  local core="$1" mode="$2"

  use_core "$core"
  prepare_core_deployment

  if [[ "$mode" == "auto" ]]; then
    if [[ "$CORE" == "singbox" ]]; then
      SB_DOH="0"
      SB_WARP="0"
      save_settings
    fi
    port_conflicts_with_other_core "$(cget PORT)" \
      && die "本地端口 $(cget PORT) 已被 $(component_label "$(other_core)") 使用，请改用自定义生成更换端口。"
  fi

  [[ "$mode" == "custom" ]] && configure_core_settings
  [[ "$CORE" == "singbox" && "$SB_WARP" == "1" ]] && ensure_warp_profile
  stop_tunnel || die "无法安全停止现有 ${CORE_LABEL} 临时隧道。"

  rebuild_core
  apply_ip_mode_to_other_core
  ok "${CORE_LABEL} · ${CORE_PROTO} 临时隧道已就绪，可以安全断开 SSH。"
  show_core_subscription
}

refresh_core_link_if_running() {
  local host=""
  core_runtime_is_running || return 1
  host="$(extract_argo_host || true)"
  if [[ -n "$host" ]] && valid_argo_host "$host" && [[ "$host" != "$(cget ARGO_HOST)" ]]; then
    cset ARGO_HOST "$host"
    save_state
  fi
  [[ -n "$(cget ARGO_HOST)" ]] && generate_link
  return 0
}

show_core_subscription() {
  local running=0 warp_line=""

  load_settings
  load_state
  refresh_core_link_if_running && running=1

  printf '\n'
  ui_title "${CORE_LABEL} · ${CORE_PROTO}" "$C_GREEN"
  ui_kv "节点名称" "$(cget NODE)"
  ui_kv "优选域名/IP" "$(cget ENDPOINT)"
  ui_kv "临时域名" "$(cget ARGO_HOST)"
  ui_kv "UUID" "$(cget UUID)"
  ui_kv "WS 路径" "$(cget WS_PATH)?ed=${WS_EARLY_DATA}"
  ui_kv "本地监听" "127.0.0.1:$(cget PORT)"
  if [[ "$CORE" == "singbox" ]]; then
    warp_line="$(warp_check_summary)"
    ui_kv "出站策略" "$(ip_mode_label)$([[ "$SB_WARP" == "1" ]] && printf ' · WARP 全局')"
    ui_kv "DoH" "$(state_text "$SB_DOH")"
    ui_kv "WARP" "$(state_text "$SB_WARP")${warp_line:+  ${C_DIM}${warp_line}${C_RESET}}"
  else
    ui_kv "出站策略" "$(ip_mode_label)"
    ui_kv "加密" "VLESS-ENC · xorpub · 0-RTT"
    ui_kv "ECH" "${XR_ECH:-未写入}"
  fi
  ui_kv "隧道状态" "$(state_text "$running")"
  ui_line

  if [[ -f "$CORE_LINK" ]]; then
    [[ $running -eq 1 ]] || warn "${CORE_LABEL} 服务或隧道未完整运行，下面是保存的旧链接，当前不可用。"
    printf '\n'
    ui_text "$(cat "$CORE_LINK")"
    printf '\n'
    hint "已保存：${CORE_LINK}"
    if [[ "$CORE" == "singbox" ]]; then
      hint "导入后应为 ws · tls · alpn http/1.1，SNI/Host 均为临时域名。"
    else
      hint "导入后应为 ws · tls · alpn http/1.1，SNI / Host / 证书校验名均为临时域名。"
      [[ -n "$XR_ECH" ]] && hint "EchConfigList 应为：${XR_ECH}"
      hint "客户端需使用支持 VLESS Encryption 的 Xray 内核。"
    fi
  else
    warn "${CORE_LABEL} 尚未生成临时隧道。"
  fi
}

cmd_show_subscriptions() {
  local shown=0 core=""
  for core in singbox xray; do
    use_core "$core"
    core_is_deployed || continue
    show_core_subscription
    shown=1
  done
  [[ $shown -eq 1 ]] || warn "尚未部署任何内核，请先使用自动生成或自定义生成。"
}

core_status_row() {
  local version="" tun=0

  use_core "$1"
  version="$(component_installed_version "$CORE")"
  if [[ "$version" =~ ^[0-9] ]]; then version="v${version}"; else version="-"; fi
  if core_is_deployed; then
    load_state
    tunnel_is_running && tun=1
  fi
  printf '%s   ' "$UI_INDENT"
  pad_text "$CORE_LABEL" "$UI_MENU_WIDTH"
  pad_text "$version" 13
  printf '隧道 %s\n' "$(state_text "$tun")"
}

status_table() {
  core_status_row singbox
  core_status_row xray
}

show_log() {
  local core="$1" kind="$2" lines=60

  use_core "$core"
  printf '\n'
  if [[ "$kind" == "service" ]]; then
    ui_title "${CORE_LABEL} 服务日志 · 最近 ${lines} 行"
    service_print_logs "$lines"
    ui_line
    hint "完整日志：$(service_log_hint)"
  else
    ui_title "${CORE_LABEL} 隧道日志 · 最近 ${lines} 行"
    if [[ -f "$CORE_TUNNEL_LOG" ]]; then tail -n "$lines" "$CORE_TUNNEL_LOG" || true
    else warn "隧道日志不存在：${CORE_TUNNEL_LOG}"; fi
    ui_line
    hint "完整日志：tail -n 200 ${CORE_TUNNEL_LOG}"
  fi
}

stop_core_tunnel() {
  use_core "$1"
  load_settings
  tunnel_is_running || info "${CORE_LABEL} 当前没有运行中的临时隧道，仅清理残留文件。"
  stop_tunnel || die "无法安全停止 ${CORE_LABEL} 临时隧道。"
  clear_tunnel_artifacts
}

cmd_stop_tunnel() {
  local scope="$1" core=""

  case "$scope" in
    singbox|xray) use_core "$scope"; warn "将断开 ${CORE_LABEL} 临时隧道并清理旧域名、链接与隧道日志；服务、配置和设置保留。" ;;
    all)          warn "将断开 sing-box 与 Xray 两个临时隧道并清理旧域名、链接与隧道日志；服务、配置和设置保留。" ;;
  esac
  confirm_yn "确认断开" || { info "已取消。"; return 0; }

  if [[ "$scope" == "all" ]]; then
    for core in singbox xray; do stop_core_tunnel "$core"; done
  else
    stop_core_tunnel "$scope"
  fi
  ok "临时隧道已断开，之后可通过自动生成或自定义生成重新创建。"
}

update_core_component() {
  local core="$1" was_active=0

  use_core "$core"
  load_settings
  core_is_deployed && service_is_active && was_active=1
  install_or_update_component "$core"

  [[ -f "$CORE_CONFIG" ]] || return 0
  load_state
  [[ -n "$(cget UUID)" ]] || return 0
  write_core_config
  write_core_unit
  if [[ $was_active -eq 1 ]]; then
    service_restart || die "${CORE_LABEL} 已更新，但服务重启失败。"
    wait_for_service_ready "$(cget PORT)" || { service_print_logs 40 >&2; die "${CORE_LABEL} 更新后未能正常监听。"; }
    ok "${CORE_LABEL} 服务已按新版本重启。"
  fi
}

cmd_update_components() {
  local core=""

  install_or_update_component cloudflared
  for core in singbox xray; do
    use_core "$core"
    if core_is_deployed || [[ -x "$CORE_BIN" ]]; then
      update_core_component "$core"
      [[ -f "$CORE_STATE" ]] && write_cloudflared_runner
    else
      info "${CORE_LABEL} 未安装，跳过。"
    fi
  done

  load_settings
  if [[ "$SB_WARP" == "1" || -x "$MANAGED_WGCF_BIN" ]]; then
    install_or_update_component wgcf
  else
    info "WARP 未开启且未安装 wgcf，跳过。"
  fi

  for core in singbox xray; do
    use_core "$core"
    core_is_deployed || continue
    load_state
    refresh_core_link_if_running || true
  done
  hint "正在运行的隧道不会中断，新版 cloudflared 在下次重建隧道时生效。"
  ok "组件更新完成。"
}

kill_service_account_processes() {
  local uid="$1" pid="" i=0
  local -a pids=()

  [[ "$uid" =~ ^[0-9]+$ ]] || return 0
  mapfile -t pids < <(for pid in /proc/[0-9]*; do pid="${pid#/proc/}"; [[ "$(process_effective_uid "$pid" 2>/dev/null || true)" == "$uid" ]] && printf '%s\n' "$pid"; done)
  ((${#pids[@]} > 0)) || return 0

  warn "服务账户仍有 ${#pids[@]} 个残留进程，正在终止……"
  for pid in "${pids[@]}"; do kill -TERM "$pid" 2>/dev/null || true; done
  for ((i = 0; i < 8; i++)); do
    mapfile -t pids < <(for pid in "${pids[@]}"; do process_is_alive "$pid" && printf '%s\n' "$pid"; done)
    ((${#pids[@]} > 0)) || return 0
    sleep 1
  done
  for pid in "${pids[@]}"; do kill -KILL "$pid" 2>/dev/null || true; done
  sleep 1
  return 0
}

remove_service_account() {
  local uid=""

  if getent passwd "$SERVICE_USER" >/dev/null 2>&1; then
    service_marker_ok || [[ "$(getent passwd "$SERVICE_USER" | cut -d: -f6)" == "$SERVICE_HOME" ]] \
      || die "账户 ${SERVICE_USER} 无法确认归属，未删除。"
    uid="$(service_uid)"
    kill_service_account_processes "$uid"
    userdel "$SERVICE_USER" 2>/dev/null || { kill_service_account_processes "$uid"; userdel -f "$SERVICE_USER" 2>/dev/null || true; }
  fi
  getent group "$SERVICE_GROUP" >/dev/null 2>&1 && { groupdel "$SERVICE_GROUP" 2>/dev/null || true; }
  [[ -d "$SERVICE_HOME" && ! -L "$SERVICE_HOME" ]] && rm -rf -- "$SERVICE_HOME"
  return 0
}

remove_source_file_if_recorded() {
  local -a lines=()
  local source="" sha=""

  secure_root_file "$SOURCE_RECORD_FILE" || return 0
  mapfile -t lines < "$SOURCE_RECORD_FILE"
  [[ ${#lines[@]} -eq 2 ]] || return 0
  source="${lines[0]}"; sha="${lines[1],,}"
  [[ "$source" == /* && "$source" != "$MANAGED_SCRIPT_PATH" && -f "$source" && ! -L "$source" ]] || return 0
  [[ "$(stat -Lc '%u' "$source" 2>/dev/null)" == "0" ]] || { warn "安装源文件不属于 root，未删除：${source}"; return 0; }
  script_file_is_ours "$source" || { warn "安装源文件未通过标识校验，未删除：${source}"; return 0; }
  [[ "$(file_sha256 "$source")" == "$sha" ]] || { warn "安装源文件已被修改，未删除：${source}"; return 0; }
  rm -f -- "$source" && ok "已删除安装源文件：${source}"
}

remove_shortcuts() {
  local path=""
  for path in "$SHORTCUT_FALLBACK_PATH" "$SHORTCUT_COMPAT_PATH" "$SHORTCUT_PATH" "${LEGACY_SHORTCUT_PATHS[@]}"; do
    [[ -e "$path" || -L "$path" ]] || continue
    if link_points_to_shortcut "$path" || path_is_replaceable_launcher "$path" || grep -Fq 'zdd-argo' "$path" 2>/dev/null; then
      rm -f "$path"
    else
      info "快捷命令不是本项目创建的，已保留：${path}"
    fi
  done
}

cmd_uninstall_all() {
  local core="" session="" keep_warp=0 warp_backup=""

  printf '\n'
  warn "完整卸载会删除：两个内核的服务与配置、临时隧道、订阅链接、日志、WARP 账户、"
  warn "低权限账户、快捷命令 zargo，以及脚本专用的 sing-box / Xray / cloudflared / wgcf。"
  hint "通过 apt / apk 安装的系统依赖不会被删除。"
  printf '\n'
  confirm_yes "确认完整卸载请输入 yes：" || { info "已取消。"; return 0; }
  if [[ -s "$WARP_ACCOUNT_FILE" || -s "$WARP_PROFILE_FILE" ]]; then
    printf '\n'
    hint "Cloudflare 对 WARP 设备注册有频率限制，保留账户可让重装时直接复用、无需重新注册。"
    if confirm_yn "保留 WARP 账户文件（${WARP_DIR}）"; then keep_warp=1; fi
  fi

  load_settings
  for core in singbox xray; do
    use_core "$core"
    stop_tunnel >/dev/null 2>&1 || true
    if [[ -e "$CORE_UNIT" || -L "$CORE_UNIT" ]]; then
      unit_is_ours || die "服务文件不是本项目创建的，拒绝继续卸载：${CORE_UNIT}"
      service_disable_now
      [[ "$INIT_SYSTEM" == "systemd" ]] && { systemctl kill --signal=KILL "$CORE_SERVICE" >/dev/null 2>&1 || true; }
      rm -f "$CORE_UNIT"
      service_reset_failed
    fi
    rm -f "/run/${CORE_SERVICE}.pid"
  done
  for session in "$SB_SESSION" "$XR_SESSION" "${LEGACY_SESSIONS[@]}"; do
    tmux kill-session -t "$session" 2>/dev/null || true
  done
  service_daemon_reload

  if [[ -e "$LOGROTATE_CONFIG" || -L "$LOGROTATE_CONFIG" ]]; then
    if logrotate_config_is_ours; then rm -f "$LOGROTATE_CONFIG"; else warn "日志轮转配置不是本项目创建的，已保留：${LOGROTATE_CONFIG}"; fi
  fi

  remove_service_account
  if [[ $keep_warp -eq 1 ]]; then
    warp_backup="$(mktemp -d)"
    cp -a "$WARP_ACCOUNT_FILE" "$WARP_PROFILE_FILE" "$warp_backup"/ 2>/dev/null || true
  fi
  rm -rf -- "$DATA_DIR"
  if [[ $keep_warp -eq 1 ]]; then
    mkdir -p "$WARP_DIR"
    chmod 700 "$DATA_DIR" "$WARP_DIR"
    cp -a "$warp_backup"/. "$WARP_DIR"/ 2>/dev/null || true
    chmod 600 "$WARP_DIR"/* 2>/dev/null || true
    rm -rf -- "$warp_backup"
  fi
  rm -f -- "$SB_TUNNEL_LOG" "$SB_TUNNEL_LOG".* "$XR_TUNNEL_LOG" "$XR_TUNNEL_LOG".* \
    "$SB_CORE_LOG" "$SB_CORE_LOG".* "$XR_CORE_LOG" "$XR_CORE_LOG".*
  remove_shortcuts
  remove_source_file_if_recorded
  rm -rf -- "$BIN_DIR" "$LEGACY_LOCK_DIR" "$LEGACY_LOCK_DIR".stale.* /tmp/zdd-argo-transaction.*
  rm -f -- "$LOCK_FILE"
  hash -r
  service_daemon_reload

  if [[ $keep_warp -eq 1 ]]; then
    ok "zdd-argo 已完整卸载，仅保留 WARP 账户：${WARP_DIR}"
  else
    ok "zdd-argo 已完整卸载。"
  fi
  [[ $MENU_MODE -eq 1 ]] && return 10
  return 0
}

run_menu_action() {
  local rc=0

  set +e
  ( set -Eeuo pipefail; "$@" )
  rc=$?
  set -e

  if [[ $rc -eq 10 ]]; then
    printf '\n'
    ui_text "卸载已完成，按 Enter 退出。"
    read_interactive _ignored "" "" || true
    clear_screen
    exit 0
  elif [[ $rc -ne 0 ]]; then
    error "操作未完成（退出码 ${rc}），请查看上方提示。"
  fi
  pause_screen
}

SELECTED_CORE=""
select_core() {
  local title="$1" choice=""

  SELECTED_CORE=""
  while true; do
    clear_screen
    printf '\n'
    ui_title "$title"
    ui_menu_row 1 "sing-box" "VMess-WS"
    ui_menu_row 2 "Xray" "VLESS-ENC-WS"
    ui_menu_row 0 "返回"
    ui_line
    read_interactive choice "选择内核 [0-2]：" "0" || choice="0"
    case "$choice" in
      1) SELECTED_CORE="singbox"; return 0 ;;
      2) SELECTED_CORE="xray"; return 0 ;;
      0) return 1 ;;
      *) warn "无效选择：${choice}"; pause_screen ;;
    esac
  done
}

menu_deploy() {
  local mode="$1" title="自定义生成"

  [[ "$mode" == "auto" ]] && title="自动生成"
  select_core "$title" || return 0
  clear_screen
  run_menu_action run_with_lock deploy_core "$SELECTED_CORE" "$mode"
}

menu_logs() {
  local choice=""

  while true; do
    clear_screen
    printf '\n'
    ui_title "查看日志"
    ui_menu_row 1 "sing-box" "服务日志"
    ui_menu_row 2 "sing-box" "隧道日志（cloudflared）"
    ui_menu_row 3 "Xray" "服务日志"
    ui_menu_row 4 "Xray" "隧道日志（cloudflared）"
    ui_menu_row 0 "返回"
    ui_line
    read_interactive choice "选择 [0-4]：" "0" || choice="0"
    clear_screen
    case "$choice" in
      1) run_menu_action show_log singbox service; return 0 ;;
      2) run_menu_action show_log singbox tunnel; return 0 ;;
      3) run_menu_action show_log xray service; return 0 ;;
      4) run_menu_action show_log xray tunnel; return 0 ;;
      0) return 0 ;;
      *) warn "无效选择：${choice}"; pause_screen ;;
    esac
  done
}

menu_stop() {
  local choice=""

  while true; do
    clear_screen
    printf '\n'
    ui_title "停止隧道"
    ui_menu_row 1 "sing-box" "仅断开 sing-box 临时隧道"
    ui_menu_row 2 "Xray" "仅断开 Xray 临时隧道"
    ui_menu_row 3 "全部" "断开两个内核的临时隧道"
    ui_menu_row 0 "返回"
    ui_line
    read_interactive choice "选择范围 [0-3]：" "0" || choice="0"
    clear_screen
    case "$choice" in
      1) run_menu_action run_with_lock cmd_stop_tunnel singbox; return 0 ;;
      2) run_menu_action run_with_lock cmd_stop_tunnel xray; return 0 ;;
      3) run_menu_action run_with_lock cmd_stop_tunnel all; return 0 ;;
      0) return 0 ;;
      *) warn "无效选择：${choice}"; pause_screen ;;
    esac
  done
}

menu_header() {
  load_settings
  ui_title "zargo · 临时 Argo 隧道 v${SCRIPT_VERSION}" "$C_BOLD"
  status_table
  ui_line
}

interactive_menu() {
  local choice=""

  MENU_MODE=1
  trap 'clear_screen; exit 130' INT TERM

  while true; do
    clear_screen
    printf '\n'
    menu_header
    ui_menu_row 1 "自动生成" "默认参数一键部署"
    ui_menu_row 2 "自定义生成" "端口 · 名称 · 优选 · DoH · WARP · ECH"
    printf '\n'
    ui_menu_row 3 "查看订阅" "分享链接与节点参数"
    ui_menu_row 4 "查看日志" "服务日志 · 隧道日志"
    printf '\n'
    ui_menu_row 5 "停止隧道" "断开临时隧道，保留配置"
    ui_menu_row 6 "更新组件" "sing-box · Xray · cloudflared · wgcf"
    ui_menu_row 7 "完整卸载" "清除全部文件、账户与程序"
    printf '\n'
    ui_menu_row 0 "退出"
    ui_line
    hint "退出后输入 zargo 可重新打开菜单。"
    printf '\n'

    read_interactive choice "请选择 [0-7]：" "0" || choice="0"
    clear_screen
    case "$choice" in
      1) menu_deploy auto ;;
      2) menu_deploy custom ;;
      3) run_menu_action run_with_lock cmd_show_subscriptions ;;
      4) menu_logs ;;
      5) menu_stop ;;
      6) run_menu_action run_with_lock cmd_update_components ;;
      7) run_menu_action run_with_lock cmd_uninstall_all ;;
      0) clear_screen; exit 0 ;;
      *) warn "无效选择：${choice}"; pause_screen ;;
    esac
  done
}

assert_safe_managed_paths() {
  local path=""
  [[ "$DATA_DIR" == "/etc/zdd-argo" && "$BIN_DIR" == "/usr/local/lib/zdd-argo" \
    && "$SERVICE_HOME" == "/var/lib/zdd-argo" && "$LOCK_FILE" == "/run/lock/zdd-argo.lock" ]] \
    || die "受管路径常量异常，拒绝继续。"
  for path in "$DATA_DIR" "$BIN_DIR" "$SERVICE_HOME"; do
    [[ ! -L "$path" ]] || die "受管路径是符号链接，拒绝继续：${path}"
  done
}

cleanup_legacy_files() {
  local path=""
  for path in "${LEGACY_DATA_FILES[@]}"; do
    [[ -e "$path" || -L "$path" ]] && rm -f -- "$path"
  done
  [[ -d "$LEGACY_LOCK_DIR" ]] && rm -rf -- "$LEGACY_LOCK_DIR"
  return 0
}

bootstrap() {
  require_root
  check_os
  assert_safe_managed_paths
  install_dependencies
  install_shortcut
  cleanup_legacy_files
}

main() {
  ensure_utf8_locale
  resolve_script_path
  [[ "$#" -eq 0 ]] || die "本脚本只提供一个无参数管理命令：zargo"
  bootstrap
  interactive_menu
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
