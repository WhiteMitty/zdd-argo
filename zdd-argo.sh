#!/usr/bin/env bash
# zdd-argo: Debian / Ubuntu temporary Cloudflare Quick Tunnel + VMess/WS manager
# GitHub release edition: bilingual interactive menu; installed command: zargo

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_VERSION="0.1.0"
NODE_NAME="zdd-argo"
LOCAL_PORT="10000"
DEFAULT_PREFERRED_ENDPOINT="saas.sin.fan"
PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
ECH_CONFIG="cloudflare-ech.com+https://dns.jhb.ovh/joeyblog"
LANGUAGE="zh"
ENDPOINT_CONFIGURED=0
TMUX_SESSION="zdd-argo"
SERVICE_NAME="zdd-argo-singbox"

DATA_DIR="/etc/zdd-argo"
STATE_JSON="${DATA_DIR}/state.json"
LEGACY_STATE_FILE="${DATA_DIR}/state.env"
SINGBOX_CONFIG="${DATA_DIR}/sing-box.json"
SINGBOX_UNIT="/etc/systemd/system/${SERVICE_NAME}.service"
CLOUDFLARED_RUNNER="${DATA_DIR}/run-cloudflared.sh"
CLOUDFLARED_HOME="${DATA_DIR}/cloudflared-home"
CLOUDFLARED_PID_FILE="${DATA_DIR}/cloudflared.pid"
LOG_FILE="/var/log/zdd-argo-cloudflared.log"
VMESS_JSON_FILE="${DATA_DIR}/vmess.json"
VMESS_LINK_FILE="${DATA_DIR}/vmess.txt"
ECH_NOTE_FILE="${DATA_DIR}/ech.txt"
SETTINGS_JSON="${DATA_DIR}/settings.json"
LOCK_FILE="/run/lock/zdd-argo-write.lock"
SHORTCUT_PATH="/usr/local/bin/zargo"
SHORTCUT_COMPAT_PATH="/usr/local/sbin/zargo"
SHORTCUT_FALLBACK_PATH="/usr/bin/zargo"
LEGACY_ZDD_PATHS=("/usr/bin/zdd" "/usr/local/sbin/zdd" "/usr/local/bin/zdd")
LEGACY_SHORTCUT_PATH="/usr/local/sbin/zdd-argo"
LEGACY_SHORTCUT_BIN="/usr/local/bin/zdd-argo"

# 脚本使用独立目录保存经过 GitHub Release SHA-256 摘要校验的二进制，
# 不覆盖系统中可能由 apt 或其他脚本维护的 sing-box / cloudflared。
BIN_DIR="/usr/local/lib/zdd-argo"
MANAGED_SCRIPT_PATH="${BIN_DIR}/zdd-argo.sh"
MANAGED_SINGBOX_BIN="${BIN_DIR}/sing-box"
MANAGED_CLOUDFLARED_BIN="${BIN_DIR}/cloudflared"
SINGBOX_RELEASE_META="${BIN_DIR}/sing-box.release.json"
CLOUDFLARED_RELEASE_META="${BIN_DIR}/cloudflared.release.json"
GITHUB_API_BASE="https://api.github.com"

SCRIPT_PATH=""
UUID=""
WSPATH=""
ARGO_HOST=""
CREATED_AT=""
SINGBOX_BIN=""
CLOUDFLARED_BIN=""
MENU_MODE=0
LOCK_HELD=0

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

T() {
  if [[ "$LANGUAGE" == "en" ]]; then
    printf '%s' "$2"
  else
    printf '%s' "$1"
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
    exec {input_fd} 2>/dev/null </dev/tty || {
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

choose_language() {
  local choice=""
  local probe_fd=0

  if [[ ! -t 0 ]]; then
    if ! exec {probe_fd} 2>/dev/null </dev/tty; then
      LANGUAGE="en"
      return 0
    fi
    exec {probe_fd}<&-
  fi

  clear_screen
  printf '%s\n' 'Select language / 选择语言'
  printf '%s\n' '1) 中文'
  printf '%s\n' '2) English'
  printf '%s\n' '────────────────────────────────────────'

  while true; do
    if ! read_interactive choice '请选择 / Select [1-2]: ' ''; then
      LANGUAGE="en"
      return 0
    fi

    case "$choice" in
      1)
        LANGUAGE="zh"
        break
        ;;
      2)
        LANGUAGE="en"
        break
        ;;
      *)
        printf '%s\n' '请输入 1 或 2 / Please enter 1 or 2.'
        ;;
    esac
  done

  clear_screen
}

info() {
  printf '%s[%s]%s %s\n' \
    "$C_CYAN" "$(T "信息" "INFO")" "$C_RESET" "$*"
}

ok() {
  printf '%s[%s]%s %s\n' \
    "$C_GREEN" "$(T "完成" "OK")" "$C_RESET" "$*"
}

warn() {
  printf '%s[%s] %s%s\n' \
    "$C_YELLOW" "$(T "注意" "NOTICE")" "$*" "$C_RESET"
}

error() {
  printf '%s[%s]%s %s\n' \
    "$C_RED" "$(T "错误" "ERROR")" "$C_RESET" "$*" >&2
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

    warn "$(T "请输入 0。" "Please enter 0.")"
  done
}

pause_screen() {
  printf '\n'
  wait_for_zero "$(T \
    "输入 0 返回菜单：" \
    "Enter 0 to return to the menu: ")"
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
  dir="$(cd -- "$dir" 2>/dev/null && pwd -P || printf '%s' "$dir")"

  SCRIPT_PATH="${dir}/${base}"
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] \
    || die "$(T \
      "请使用 root 运行此脚本。" \
      "Please run this script as root.")"
}

check_os() {
  [[ -r /etc/os-release ]] \
    || die "$(T \
      "无法识别操作系统，仅支持 Debian / Ubuntu。" \
      "Unable to identify the operating system. Only Debian and Ubuntu are supported.")"

  # shellcheck disable=SC1091
  source /etc/os-release

  case "${ID:-}" in
    debian|ubuntu)
      ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*)
          ;;
        *)
          die "$(T \
            "当前系统为 ${PRETTY_NAME:-未知}，本脚本仅支持 Debian / Ubuntu。" \
            "Current system: ${PRETTY_NAME:-unknown}. This script only supports Debian and Ubuntu.")"
          ;;
      esac
      ;;
  esac
}

install_dependencies() {
  local missing=0
  local cmd=""

  [[ -d /run/systemd/system ]] \
    || die "$(T \
      "当前系统不是由 systemd 管理，无法创建后台服务。" \
      "This system is not managed by systemd, so the background service cannot be created.")"

  command -v systemctl >/dev/null 2>&1 \
    || die "$(T "未找到 systemctl。" "systemctl was not found.")"

  command -v journalctl >/dev/null 2>&1 \
    || die "$(T "未找到 journalctl。" "journalctl was not found.")"

  for cmd in \
    curl jq openssl tmux ss base64 flock awk sed grep \
    tar sha256sum find install mktemp readlink
  do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing=1
      break
    fi
  done

  if [[ $missing -eq 1 ]]; then
    info "$(T \
      "安装基础依赖……" \
      "Installing required packages...")"

    export DEBIAN_FRONTEND=noninteractive
    export NEEDRESTART_MODE=a
    export APT_LISTCHANGES_FRONTEND=none

    apt-get update \
      || die "$(T \
        "apt-get update 失败。" \
        "apt-get update failed.")"

    apt-get install -y \
      curl \
      jq \
      openssl \
      ca-certificates \
      tmux \
      iproute2 \
      coreutils \
      util-linux \
      tar \
      findutils \
      grep \
      sed \
      gawk \
      || die "$(T \
        "基础依赖安装失败。" \
        "Failed to install required packages.")"
  fi
}

acquire_lock() {
  if [[ $LOCK_HELD -eq 1 ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$LOCK_FILE")"

  exec 9>"$LOCK_FILE"

  flock -n 9 \
    || die "$(T \
      "另一个 zdd-argo 写操作正在运行，请稍后再试。" \
      "Another zdd-argo write operation is running. Please try again later.")"

  LOCK_HELD=1
}

run_with_lock() {
  local fn="$1"
  shift

  acquire_lock
  "$fn" "$@"
}

path_is_zdd_launcher() {
  local path="$1"

  [[ -f "$path" ]] \
    && grep -Fq '# zdd-argo launcher' "$path" 2>/dev/null \
    && grep -Fq "$MANAGED_SCRIPT_PATH" "$path" 2>/dev/null
}

path_is_legacy_zdd_launcher() {
  local path="$1"

  [[ -f "$path" ]] \
    && grep -Fq 'zdd argo' "$path" 2>/dev/null \
    && grep -Fq 'exec /usr/bin/env bash' "$path" 2>/dev/null \
    && grep -Fq 'zdd-argo.sh' "$path" 2>/dev/null
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

install_shortcut() {
  [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]] \
    || die "$(T \
      "无法识别当前脚本文件，不能安装快捷命令。" \
      "Unable to identify the current script file; the launcher cannot be installed.")"

  grep -q '^# zdd-argo' "$SCRIPT_PATH" \
    || die "$(T \
      "当前文件未通过 zdd-argo 脚本标识校验。" \
      "The current file failed the zdd-argo script identity check.")"

  bash -n "$SCRIPT_PATH" \
    || die "$(T \
      "当前脚本未通过 Bash 语法检查，拒绝安装。" \
      "The current script failed its Bash syntax check and will not be installed.")"

  local existing_zargo=""
  local path=""
  local managed_tmp=""
  local tmp=""
  local launcher_new=""
  local resolved_zargo=""

  existing_zargo="$(type -P zargo 2>/dev/null || true)"

  if [[ -n "$existing_zargo" ]] \
      && ! path_is_replaceable_zdd_launcher "$existing_zargo"; then
    die "$(T \
      "当前 PATH 中的 zargo 已被其他程序占用：${existing_zargo}；为避免覆盖，未进行安装。" \
      "The zargo command in the current PATH is already owned by another program: ${existing_zargo}. Nothing was installed.")"
  fi

  for path in \
    "$SHORTCUT_PATH" \
    "$SHORTCUT_COMPAT_PATH" \
    "$SHORTCUT_FALLBACK_PATH"
  do
    [[ -e "$path" || -L "$path" ]] || continue

    if [[ "$path" == "$SHORTCUT_COMPAT_PATH" || "$path" == "$SHORTCUT_FALLBACK_PATH" ]] \
        && [[ -L "$path" ]] \
        && [[ "$(readlink "$path" 2>/dev/null || true)" == "$SHORTCUT_PATH" ]]; then
      continue
    fi

    path_is_replaceable_zdd_launcher "$path" \
      || die "$(T \
        "快捷命令路径已被其他程序占用：${path}" \
        "The launcher path is already used by another program: ${path}")"
  done

  if [[ -e "$MANAGED_SCRIPT_PATH" ]] \
      && ! grep -q '^# zdd-argo' "$MANAGED_SCRIPT_PATH" 2>/dev/null; then
    die "$(T \
      "目标路径已存在非 zdd-argo 文件：${MANAGED_SCRIPT_PATH}" \
      "A non-zdd-argo file already exists at: ${MANAGED_SCRIPT_PATH}")"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  if [[ "$SCRIPT_PATH" != "$MANAGED_SCRIPT_PATH" ]]; then
    managed_tmp="${MANAGED_SCRIPT_PATH}.new.$$"
    install -m 0755 "$SCRIPT_PATH" "$managed_tmp"
    mv -f "$managed_tmp" "$MANAGED_SCRIPT_PATH"
  else
    chmod 0755 "$MANAGED_SCRIPT_PATH"
  fi

  tmp="$(mktemp)"

  cat > "$tmp" <<EOF
#!/usr/bin/env bash
# zdd-argo launcher
set -Eeuo pipefail

if [[ "\$#" -ne 0 ]]; then
  printf '%s\n' '用法 / Usage: zargo' >&2
  exit 2
fi

exec /usr/bin/env bash ${MANAGED_SCRIPT_PATH@Q}
EOF

  launcher_new="${SHORTCUT_PATH}.new.$$"
  install -m 0755 "$tmp" "$launcher_new"
  rm -f "$tmp"
  mv -f "$launcher_new" "$SHORTCUT_PATH"

  rm -f "$SHORTCUT_COMPAT_PATH"
  ln -s "$SHORTCUT_PATH" "$SHORTCUT_COMPAT_PATH"

  hash -r
  resolved_zargo="$(type -P zargo 2>/dev/null || true)"

  if [[ -n "$resolved_zargo" ]] \
      && [[ -e "$SHORTCUT_FALLBACK_PATH" || -L "$SHORTCUT_FALLBACK_PATH" ]]; then
    if path_is_replaceable_zdd_launcher "$SHORTCUT_FALLBACK_PATH"; then
      rm -f "$SHORTCUT_FALLBACK_PATH"
      ln -s "$SHORTCUT_PATH" "$SHORTCUT_FALLBACK_PATH"
    fi
  fi

  if [[ -z "$resolved_zargo" ]]; then
    if [[ -e "$SHORTCUT_FALLBACK_PATH" || -L "$SHORTCUT_FALLBACK_PATH" ]]; then
      if [[ -L "$SHORTCUT_FALLBACK_PATH" ]] \
          && [[ "$(readlink "$SHORTCUT_FALLBACK_PATH" 2>/dev/null || true)" == "$SHORTCUT_PATH" ]]; then
        :
      elif path_is_replaceable_zdd_launcher "$SHORTCUT_FALLBACK_PATH"; then
        rm -f "$SHORTCUT_FALLBACK_PATH"
        ln -s "$SHORTCUT_PATH" "$SHORTCUT_FALLBACK_PATH"
      else
        die "$(T \
          "当前 PATH 无法找到 /usr/local/bin/zargo，且备用路径已被其他程序占用：${SHORTCUT_FALLBACK_PATH}" \
          "The current PATH cannot resolve /usr/local/bin/zargo, and the fallback path is already used by another program: ${SHORTCUT_FALLBACK_PATH}")"
      fi
    else
      ln -s "$SHORTCUT_PATH" "$SHORTCUT_FALLBACK_PATH"
    fi

    hash -r
    resolved_zargo="$(type -P zargo 2>/dev/null || true)"
  fi

  [[ -x "$MANAGED_SCRIPT_PATH" ]] \
    || die "$(T \
      "已安装脚本副本不可执行。" \
      "The managed script copy is not executable.")"

  [[ -x "$SHORTCUT_PATH" ]] \
    || die "$(T \
      "快捷启动器安装失败。" \
      "Failed to install the launcher.")"

  bash -n "$SHORTCUT_PATH" \
    || die "$(T \
      "快捷启动器语法检查失败。" \
      "The launcher failed its Bash syntax check.")"

  resolved_zdd_is_ours "$resolved_zargo" \
    || die "$(T \
      "快捷命令已写入磁盘，但当前 shell 未解析到本项目的 zargo；请检查 PATH。" \
      "The launcher was written to disk, but the current shell does not resolve zargo to this project. Check PATH.")"

  for path in "${LEGACY_ZDD_PATHS[@]}"; do
    [[ -e "$path" || -L "$path" ]] || continue

    if path_is_replaceable_zdd_launcher "$path"; then
      rm -f "$path"
    fi
  done

  for path in "$LEGACY_SHORTCUT_PATH" "$LEGACY_SHORTCUT_BIN"; do
    [[ -e "$path" || -L "$path" ]] || continue

    if path_is_replaceable_zdd_launcher "$path" \
        || grep -Fq 'zdd-argo' "$path" 2>/dev/null; then
      rm -f "$path"
    else
      warn "$(T \
        "发现同名旧快捷路径但无法确认归属，未删除：${path}" \
        "A legacy shortcut path exists but could not be identified as this project, so it was not removed: ${path}")"
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

safe_download() {
  local url="$1"
  local output="$2"

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
}

safe_download_github_api() {
  local url="$1"
  local output="$2"

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

    die "$(T \
      "无法读取 ${repo} 的 GitHub 最新稳定版信息。" \
      "Unable to read the latest stable GitHub release information for ${repo}.")"
  fi

  if ! jq -e '
      type == "object"
      and (.tag_name | type == "string")
      and (.assets | type == "array")
    ' "$api_file" >/dev/null 2>&1; then
    rm -f "$api_file"

    die "$(T \
      "${repo} 的 GitHub Release 响应格式异常。" \
      "The GitHub Release response format for ${repo} is invalid.")"
  fi

  if ! result="$(jq -er --arg re "$asset_regex" '
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
    ' "$api_file" 2>/dev/null)"; then
    rm -f "$api_file"

    die "$(T \
      "${repo} 最新稳定版中未找到唯一匹配的安装文件。" \
      "The latest stable ${repo} release did not contain exactly one matching asset.")"
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
      die "$(T \
        "GitHub 资源下载地址异常，已拒绝安装：${asset_url}" \
        "Unexpected GitHub asset URL; installation refused: ${asset_url}")"
      ;;
  esac

  [[ "$digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]] \
    || die "$(T \
      "${asset_name} 没有可用的 GitHub SHA-256 摘要，已拒绝无校验安装。" \
      "${asset_name} has no usable GitHub SHA-256 digest; unverified installation was refused.")"

  expected="${digest#sha256:}"
  expected="${expected,,}"
  actual="$(sha256sum "$file" | awk '{print tolower($1)}')"

  [[ "$actual" == "$expected" ]] \
    || die "$(T \
      "${asset_name} 的 SHA-256 校验失败，已拒绝安装。" \
      "SHA-256 verification failed for ${asset_name}; installation was refused.")"
}

write_release_metadata() {
  local output="$1"
  local repo="$2"
  local tag="$3"
  local asset="$4"
  local digest="$5"
  local tmp=""

  mkdir -p "$BIN_DIR" || return 1
  tmp="$(mktemp "${BIN_DIR}/.release.XXXXXX")" || return 1

  if ! jq -n \
      --arg repo "$repo" \
      --arg tag "$tag" \
      --arg asset "$asset" \
      --arg digest "$digest" \
      --arg installed_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      '{
        repository: $repo,
        tag: $tag,
        asset: $asset,
        digest: $digest,
        installed_at: $installed_at
      }' > "$tmp"; then
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
  local -a sb_candidates=()

  arch="$(uname -m)"

  case "$arch" in
    x86_64|amd64)
      asset_regex='^sing-box-.*-linux-amd64\.tar\.gz$'
      ;;
    aarch64|arm64)
      asset_regex='^sing-box-.*-linux-arm64\.tar\.gz$'
      ;;
    *)
      die "$(T \
        "暂不支持 CPU 架构：${arch}；当前脚本支持 amd64 与 arm64。" \
        "Unsupported CPU architecture: ${arch}. This script supports amd64 and arm64.")"
      ;;
  esac

  resolve_singbox_bin

  before="$(T "未安装" "not installed")"

  if [[ -n "$SINGBOX_BIN" ]]; then
    before="$("$SINGBOX_BIN" version 2>/dev/null | head -n 1 || true)"
  fi

  info "$(T \
    "查询 sing-box 官方 GitHub 最新稳定版……" \
    "Checking the latest stable sing-box release on official GitHub...")"

  info_line="$(github_latest_asset_info \
    "SagerNet/sing-box" \
    "$asset_regex")"

  IFS=$'\t' read -r \
    asset_name \
    asset_url \
    digest \
    release_tag \
    <<< "$info_line"

  [[ -n "$asset_name" && -n "$asset_url" && -n "$release_tag" ]] \
    || die "$(T \
      "sing-box Release 信息不完整。" \
      "Incomplete sing-box release information.")"

  work="$(mktemp -d)"
  archive="${work}/${asset_name}"
  extract_dir="${work}/extract"

  mkdir -p "$extract_dir"

  if ! safe_download "$asset_url" "$archive"; then
    rm -rf "$work"

    die "$(T \
      "sing-box 安装包下载失败。" \
      "Failed to download the sing-box archive.")"
  fi

  verify_github_asset \
    "SagerNet/sing-box" \
    "$asset_name" \
    "$asset_url" \
    "$digest" \
    "$archive"

  list_file="${work}/archive.list"

  if ! tar -tzf "$archive" > "$list_file"; then
    rm -rf "$work"

    die "$(T \
      "无法读取 sing-box 压缩包目录。" \
      "Unable to read the sing-box archive listing.")"
  fi

  if grep -Eq '(^/|(^|/)\.\.(/|$))' "$list_file"; then
    rm -rf "$work"

    die "$(T \
      "sing-box 压缩包包含不安全路径，已拒绝解压。" \
      "The sing-box archive contains unsafe paths and will not be extracted.")"
  fi

  if ! tar -xzf "$archive" -C "$extract_dir"; then
    rm -rf "$work"

    die "$(T \
      "sing-box 压缩包解压失败。" \
      "Failed to extract the sing-box archive.")"
  fi

  mapfile -t sb_candidates < <(
    find "$extract_dir" -type f -name sing-box -print
  )

  if [[ ${#sb_candidates[@]} -ne 1 ]]; then
    rm -rf "$work"

    die "$(T \
      "sing-box 压缩包内未找到唯一可执行文件。" \
      "The sing-box archive did not contain exactly one sing-box executable.")"
  fi

  candidate="${sb_candidates[0]}"
  chmod 0755 "$candidate"

  if ! "$candidate" version 2>/dev/null \
      | head -n 1 \
      | grep -q '^sing-box version '; then
    rm -rf "$work"

    die "$(T \
      "sing-box 新二进制无法通过版本自检。" \
      "The new sing-box binary failed its version self-check.")"
  fi

  if [[ -f "$SINGBOX_CONFIG" ]] \
      && ! "$candidate" check -c "$SINGBOX_CONFIG"; then
    rm -rf "$work"

    die "$(T \
      "新版 sing-box 无法通过现有 zdd-argo 配置校验，未执行更新。" \
      "The new sing-box version cannot validate the existing zdd-argo configuration; no update was applied.")"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  new_binary="${MANAGED_SINGBOX_BIN}.new.$$"
  backup="${MANAGED_SINGBOX_BIN}.backup.$$"

  if [[ -x "$MANAGED_SINGBOX_BIN" ]]; then
    cp -a "$MANAGED_SINGBOX_BIN" "$backup"
    had_managed=1
  fi

  if [[ -f "$SINGBOX_RELEASE_META" ]]; then
    meta_backup="${SINGBOX_RELEASE_META}.backup.$$"
    cp -a "$SINGBOX_RELEASE_META" "$meta_backup"
  fi

  if [[ -f "$SINGBOX_UNIT" ]]; then
    had_unit=1
  fi

  if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    was_active=1
  fi

  install -m 0755 "$candidate" "$new_binary"
  mv -f "$new_binary" "$MANAGED_SINGBOX_BIN"

  if ! write_release_metadata \
      "$SINGBOX_RELEASE_META" \
      "SagerNet/sing-box" \
      "$release_tag" \
      "$asset_name" \
      "$digest"; then
    warn "$(T \
      "sing-box 元数据写入失败，正在回滚……" \
      "Failed to write sing-box metadata; rolling back...")"

    if [[ $had_managed -eq 1 && -f "$backup" ]]; then
      mv -f "$backup" "$MANAGED_SINGBOX_BIN"
    else
      rm -f "$MANAGED_SINGBOX_BIN"
    fi

    if [[ -n "$meta_backup" && -f "$meta_backup" ]]; then
      mv -f "$meta_backup" "$SINGBOX_RELEASE_META"
    else
      rm -f "$SINGBOX_RELEASE_META"
    fi

    rm -rf "$work"
    hash -r
    resolve_singbox_bin

    die "$(T \
      "sing-box 更新失败，已恢复更新前状态。" \
      "The sing-box update failed; the pre-update state was restored.")"
  fi

  rm -rf "$work"

  hash -r
  resolve_singbox_bin

  [[ "$SINGBOX_BIN" == "$MANAGED_SINGBOX_BIN" ]] \
    || die "$(T \
      "sing-box 安装完成后未能切换到脚本专用二进制。" \
      "The installation did not switch to the script-managed sing-box binary.")"

  if [[ $had_unit -eq 1 && -f "$SINGBOX_CONFIG" ]]; then
    write_singbox_service

    if [[ $was_active -eq 1 ]]; then
      systemctl restart "$SERVICE_NAME" >/dev/null 2>&1 || true

      if ! wait_for_singbox_ready; then
        warn "$(T \
          "新版 sing-box 启动失败，正在回滚……" \
          "The new sing-box failed to start; rolling back...")"

        if [[ $had_managed -eq 1 && -f "$backup" ]]; then
          mv -f "$backup" "$MANAGED_SINGBOX_BIN"
        else
          rm -f "$MANAGED_SINGBOX_BIN"
        fi

        if [[ -n "$meta_backup" && -f "$meta_backup" ]]; then
          mv -f "$meta_backup" "$SINGBOX_RELEASE_META"
        else
          rm -f "$SINGBOX_RELEASE_META"
        fi

        hash -r
        resolve_singbox_bin

        if [[ -n "$SINGBOX_BIN" ]]; then
          write_singbox_service
          systemctl restart "$SERVICE_NAME" >/dev/null 2>&1 || true
        fi

        if ! wait_for_singbox_ready; then
          journalctl \
            -u "$SERVICE_NAME" \
            -n 80 \
            --no-pager >&2 \
            || true

          die "$(T \
            "新版启动失败，且旧版回滚后也未恢复，请检查日志。" \
            "The new version failed, and the rolled-back version also failed to recover. Check the logs.")"
        fi

        journalctl \
          -u "$SERVICE_NAME" \
          -n 40 \
          --no-pager >&2 \
          || true

        die "$(T \
          "sing-box 更新后启动失败，已成功恢复旧版本。" \
          "The sing-box update failed to start; the previous version was restored successfully.")"
      fi
    fi
  fi

  rm -f "$backup" "$meta_backup"

  after="$("$SINGBOX_BIN" version 2>/dev/null | head -n 1 || true)"

  printf '%s %s\n%s %s\n' \
    "$(T "更新前：" "Before:")" "$before" \
    "$(T "更新后：" "After:")" \
    "${after:-$(T "未知" "unknown")}"

  ok "$(T \
    "sing-box 已通过 GitHub Release SHA-256 摘要校验。" \
    "sing-box passed GitHub Release SHA-256 digest verification.")"
}

install_singbox_if_needed() {
  if [[ -x "$MANAGED_SINGBOX_BIN" ]]; then
    resolve_singbox_bin
    return 0
  fi

  info "$(T \
    "安装脚本专用 sing-box；不会覆盖系统包管理器维护的版本。" \
    "Installing the script-managed sing-box without replacing package-manager installations.")"

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
      die "$(T \
        "暂不支持 CPU 架构：${arch}；当前脚本支持 amd64 与 arm64。" \
        "Unsupported CPU architecture: ${arch}. This script supports amd64 and arm64.")"
      ;;
  esac

  resolve_cloudflared_bin

  before="$(T "未安装" "not installed")"

  if [[ -n "$CLOUDFLARED_BIN" ]]; then
    before="$("$CLOUDFLARED_BIN" --version 2>/dev/null | head -n 1 || true)"
  fi

  info "$(T \
    "查询 cloudflared 官方 GitHub 最新稳定版……" \
    "Checking the latest stable cloudflared release on official GitHub...")"

  info_line="$(github_latest_asset_info \
    "cloudflare/cloudflared" \
    "$asset_regex")"

  IFS=$'\t' read -r \
    asset_name \
    asset_url \
    digest \
    release_tag \
    <<< "$info_line"

  [[ -n "$asset_name" && -n "$asset_url" && -n "$release_tag" ]] \
    || die "$(T \
      "cloudflared Release 信息不完整。" \
      "Incomplete cloudflared release information.")"

  tmp_file="$(mktemp)"

  if ! safe_download "$asset_url" "$tmp_file"; then
    rm -f "$tmp_file"

    die "$(T \
      "cloudflared 下载失败。" \
      "Failed to download cloudflared.")"
  fi

  verify_github_asset \
    "cloudflare/cloudflared" \
    "$asset_name" \
    "$asset_url" \
    "$digest" \
    "$tmp_file"

  chmod 0755 "$tmp_file"

  if ! "$tmp_file" --version 2>/dev/null \
      | grep -qi '^cloudflared version '; then
    rm -f "$tmp_file"

    die "$(T \
      "cloudflared 新二进制无法通过版本自检。" \
      "The new cloudflared binary failed its version self-check.")"
  fi

  mkdir -p "$BIN_DIR"
  chmod 0755 "$BIN_DIR"

  new_binary="${MANAGED_CLOUDFLARED_BIN}.new.$$"
  backup="${MANAGED_CLOUDFLARED_BIN}.backup.$$"
  meta_backup="${CLOUDFLARED_RELEASE_META}.backup.$$"

  if [[ -x "$MANAGED_CLOUDFLARED_BIN" ]]; then
    cp -a "$MANAGED_CLOUDFLARED_BIN" "$backup"
    had_managed=1
  fi

  if [[ -f "$CLOUDFLARED_RELEASE_META" ]]; then
    cp -a "$CLOUDFLARED_RELEASE_META" "$meta_backup"
  fi

  install -m 0755 "$tmp_file" "$new_binary"
  rm -f "$tmp_file"
  mv -f "$new_binary" "$MANAGED_CLOUDFLARED_BIN"

  if ! write_release_metadata \
      "$CLOUDFLARED_RELEASE_META" \
      "cloudflare/cloudflared" \
      "$release_tag" \
      "$asset_name" \
      "$digest"; then
    warn "$(T \
      "cloudflared 元数据写入失败，正在回滚……" \
      "Failed to write cloudflared metadata; rolling back...")"

    if [[ $had_managed -eq 1 && -f "$backup" ]]; then
      mv -f "$backup" "$MANAGED_CLOUDFLARED_BIN"
    else
      rm -f "$MANAGED_CLOUDFLARED_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f "$meta_backup" "$CLOUDFLARED_RELEASE_META"
    else
      rm -f "$CLOUDFLARED_RELEASE_META"
    fi

    die "$(T \
      "cloudflared 更新失败，已恢复旧版本。" \
      "cloudflared update failed; the previous version was restored.")"
  fi

  hash -r
  resolve_cloudflared_bin

  if [[ "$CLOUDFLARED_BIN" != "$MANAGED_CLOUDFLARED_BIN" ]] \
      || ! "$CLOUDFLARED_BIN" --version >/dev/null 2>&1; then
    warn "$(T \
      "新版 cloudflared 安装后校验失败，正在回滚……" \
      "The installed cloudflared failed verification; rolling back...")"

    if [[ $had_managed -eq 1 && -f "$backup" ]]; then
      mv -f "$backup" "$MANAGED_CLOUDFLARED_BIN"
    else
      rm -f "$MANAGED_CLOUDFLARED_BIN"
    fi

    if [[ -f "$meta_backup" ]]; then
      mv -f "$meta_backup" "$CLOUDFLARED_RELEASE_META"
    else
      rm -f "$CLOUDFLARED_RELEASE_META"
    fi

    hash -r
    resolve_cloudflared_bin

    die "$(T \
      "cloudflared 更新失败，已恢复旧版本。" \
      "cloudflared update failed; the previous version was restored.")"
  fi

  rm -f "$backup" "$meta_backup"

  after="$("$CLOUDFLARED_BIN" --version 2>/dev/null | head -n 1 || true)"

  printf '%s %s\n%s %s\n' \
    "$(T "更新前：" "Before:")" "$before" \
    "$(T "更新后：" "After:")" \
    "${after:-$(T "未知" "unknown")}"

  ok "$(T \
    "cloudflared 已通过 GitHub Release SHA-256 摘要校验。" \
    "cloudflared passed GitHub Release SHA-256 digest verification.")"
}

install_cloudflared_if_needed() {
  if [[ -x "$MANAGED_CLOUDFLARED_BIN" ]]; then
    resolve_cloudflared_bin
    return 0
  fi

  info "$(T \
    "安装脚本专用 cloudflared；不会覆盖系统包管理器维护的版本。" \
    "Installing the script-managed cloudflared without replacing package-manager installations.")"

  install_or_update_cloudflared
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
  local value="$1"
  local a=""
  local b=""
  local c=""
  local d=""
  local extra=""
  local part=""

  IFS='.' read -r a b c d extra <<< "$value"

  [[ -z "${extra:-}" ]] || return 1
  [[ -n "${a:-}" ]] || return 1
  [[ -n "${b:-}" ]] || return 1
  [[ -n "${c:-}" ]] || return 1
  [[ -n "${d:-}" ]] || return 1

  for part in "$a" "$b" "$c" "$d"; do
    [[ "$part" =~ ^[0-9]{1,3}$ ]] || return 1
    ((10#$part >= 0 && 10#$part <= 255)) || return 1
  done
}

valid_ipv6() {
  local value="$1"
  local work=""
  local remainder=""
  local part=""
  local count=0
  local has_double=0
  local ipv4_tail=""
  local -a parts=()

  [[ "$value" == *:* ]] || return 1
  [[ "$value" =~ ^[0-9A-Fa-f:.]+$ ]] || return 1

  work="$value"

  if [[ "$work" == *.* ]]; then
    ipv4_tail="${work##*:}"
    valid_ipv4 "$ipv4_tail" || return 1
    work="${work%:*}:0:0"
  fi

  [[ "$work" != *:::* ]] || return 1

  if [[ "$work" == *::* ]]; then
    has_double=1
    remainder="${work#*::}"
    [[ "$remainder" != *::* ]] || return 1
    work="${work/::/:Z:}"
  fi

  IFS=':' read -r -a parts <<< "$work"

  for part in "${parts[@]}"; do
    if [[ -z "$part" || "$part" == "Z" ]]; then
      continue
    fi

    [[ "$part" =~ ^[0-9A-Fa-f]{1,4}$ ]] || return 1
    ((count += 1))
  done

  if [[ $has_double -eq 1 ]]; then
    ((count < 8))
  else
    ((count == 8))
  fi
}

valid_domain_name() {
  local value="${1%.}"
  local label=""
  local -a labels=()

  [[ -n "$value" ]] || return 1
  [[ ${#value} -le 253 ]] || return 1
  [[ "$value" == *.* ]] || return 1
  [[ "$value" =~ ^[A-Za-z0-9.-]+$ ]] || return 1

  IFS='.' read -r -a labels <<< "$value"

  for label in "${labels[@]}"; do
    [[ -n "$label" ]] || return 1
    [[ ${#label} -le 63 ]] || return 1
    [[ "$label" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || return 1
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

  [[ -n "$value" ]] || return 1
  [[ "$value" != *[[:space:]]* ]] || return 1
  [[ ${#value} -le 253 ]] || return 1

  if [[ "$value" =~ ^[0-9.]+$ ]]; then
    valid_ipv4 "$value"
    return
  fi

  valid_ipv6 "$value" \
    || valid_domain_name "$value"
}

load_settings() {
  PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
  ENDPOINT_CONFIGURED=0

  [[ -f "$SETTINGS_JSON" ]] || return 0

  command -v jq >/dev/null 2>&1 || return 0

  if ! jq -e 'type == "object"' "$SETTINGS_JSON" >/dev/null 2>&1; then
    warn "$(T \
      "设置文件损坏，已移走；当前使用默认优选域名 ${DEFAULT_PREFERRED_ENDPOINT}。" \
      "The settings file is invalid and was moved aside; using the default preferred domain ${DEFAULT_PREFERRED_ENDPOINT}.")"

    mv -f \
      "$SETTINGS_JSON" \
      "${SETTINGS_JSON}.invalid.$(date +%s)"

    return 0
  fi

  local value=""

  value="$(jq -r '.preferred_endpoint // ""' "$SETTINGS_JSON")"
  value="$(normalize_preferred_endpoint "$value")"

  if valid_preferred_endpoint "$value"; then
    PREFERRED_ENDPOINT="$value"
    ENDPOINT_CONFIGURED=1
  else
    warn "$(T \
      "设置文件中的优选域名/IP 无效；当前使用默认优选域名 ${DEFAULT_PREFERRED_ENDPOINT}。" \
      "The preferred domain/IP in the settings file is invalid; using the default preferred domain ${DEFAULT_PREFERRED_ENDPOINT}.")"
  fi
}

save_settings() {
  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"

  valid_preferred_endpoint "$PREFERRED_ENDPOINT" \
    || die "$(T \
      "优选域名/IP 格式无效。" \
      "The preferred domain/IP format is invalid.")"

  local tmp=""

  tmp="$(mktemp "${DATA_DIR}/.settings.json.XXXXXX")"

  umask 077

  jq -n \
    --argjson schema 1 \
    --arg preferred_endpoint "$PREFERRED_ENDPOINT" \
    --arg updated_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    '{
      schema: $schema,
      preferred_endpoint: $preferred_endpoint,
      updated_at: $updated_at
    }' > "$tmp"

  chmod 600 "$tmp"
  mv -f "$tmp" "$SETTINGS_JSON"

  ENDPOINT_CONFIGURED=1
}

migrate_legacy_state() {
  [[ -f "$LEGACY_STATE_FILE" ]] || return 0
  [[ ! -f "$STATE_JSON" ]] || return 0

  local old_uuid=""
  local old_path=""
  local old_host=""

  old_uuid="$(
    sed -n "s/^UUID='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  old_path="$(
    sed -n "s/^WSPATH='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  old_host="$(
    sed -n "s/^ARGO_HOST='\([^']*\)'$/\1/p" \
      "$LEGACY_STATE_FILE" \
      | head -n 1
  )"

  if valid_uuid "$old_uuid" \
      && valid_ws_path "$old_path" \
      && valid_argo_host "$old_host"; then
    UUID="$old_uuid"
    WSPATH="$old_path"
    ARGO_HOST="$old_host"
    CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    save_state

    mv -f \
      "$LEGACY_STATE_FILE" \
      "${LEGACY_STATE_FILE}.migrated"

    ok "$(T \
      "已将旧版 state.env 安全迁移为 state.json。" \
      "The legacy state.env file was safely migrated to state.json.")"
  else
    warn "$(T \
      "发现旧版 state.env，但内容校验失败；不会执行该文件。" \
      "A legacy state.env file was found but failed validation; it will not be executed.")"

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

  jq -e 'type == "object"' "$STATE_JSON" >/dev/null 2>&1 \
    || die "$(T \
      "状态文件损坏：${STATE_JSON}" \
      "State file is invalid: ${STATE_JSON}")"

  UUID="$(jq -r '.uuid // ""' "$STATE_JSON")"
  WSPATH="$(jq -r '.ws_path // ""' "$STATE_JSON")"
  ARGO_HOST="$(jq -r '.argo_host // ""' "$STATE_JSON")"
  CREATED_AT="$(jq -r '.created_at // ""' "$STATE_JSON")"

  valid_uuid "$UUID" \
    || die "$(T \
      "状态文件中的 UUID 无效：${STATE_JSON}" \
      "Invalid UUID in state file: ${STATE_JSON}")"

  valid_ws_path "$WSPATH" \
    || die "$(T \
      "状态文件中的 WS 路径无效：${STATE_JSON}" \
      "Invalid WebSocket path in state file: ${STATE_JSON}")"

  valid_argo_host "$ARGO_HOST" \
    || die "$(T \
      "状态文件中的临时域名无效：${STATE_JSON}" \
      "Invalid temporary hostname in state file: ${STATE_JSON}")"
}

save_state() {
  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"

  if [[ -z "$CREATED_AT" ]]; then
    CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  fi

  local tmp=""

  tmp="$(mktemp "${DATA_DIR}/.state.json.XXXXXX")"

  umask 077

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
    || die "$(T \
      "UUID 生成失败。" \
      "Failed to generate a UUID.")"

  valid_uuid "$UUID" \
    || die "$(T \
      "生成的 UUID 未通过格式校验。" \
      "The generated UUID failed format validation.")"

  WSPATH="/$(openssl rand -hex 16)-vmws"
  ARGO_HOST=""
  CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

  rm -f \
    "$VMESS_JSON_FILE" \
    "$VMESS_LINK_FILE" \
    "$ECH_NOTE_FILE"

  save_state
}

write_singbox_config() {
  if [[ -z "$SINGBOX_BIN" ]]; then
    resolve_singbox_bin
  fi

  [[ -n "$SINGBOX_BIN" ]] \
    || die "$(T \
      "未找到 sing-box。" \
      "sing-box was not found.")"

  valid_uuid "$UUID" \
    || die "$(T \
      "UUID 为空或格式错误。" \
      "UUID is empty or invalid.")"

  valid_ws_path "$WSPATH" \
    || die "$(T \
      "WS 路径为空或格式错误。" \
      "WebSocket path is empty or invalid.")"

  local tmp=""

  tmp="$(mktemp "${DATA_DIR}/.sing-box.json.XXXXXX")"

  umask 077

  jq -n \
    --arg name "$NODE_NAME" \
    --arg uuid "$UUID" \
    --arg path "$WSPATH" \
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
      outbounds: [
        {
          type: "direct",
          tag: "direct"
        },
        {
          type: "block",
          tag: "block"
        }
      ],
      route: {
        final: "direct"
      }
    }' > "$tmp"

  chmod 600 "$tmp"

  if ! "$SINGBOX_BIN" check -c "$tmp"; then
    rm -f "$tmp"

    die "$(T \
      "新 sing-box 配置校验失败，未覆盖现有配置。" \
      "The new sing-box configuration failed validation; the existing configuration was not replaced.")"
  fi

  mv -f "$tmp" "$SINGBOX_CONFIG"
}

write_singbox_service() {
  [[ -n "$SINGBOX_BIN" ]] \
    || die "$(T \
      "未找到 sing-box 可执行文件。" \
      "The sing-box executable was not found.")"

  local tmp=""

  tmp="$(mktemp)"

  cat > "$tmp" <<EOF
[Unit]
Description=zdd-argo dedicated sing-box service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${SINGBOX_BIN} run -c ${SINGBOX_CONFIG}
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
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
LockPersonality=true
RestrictSUIDSGID=true

[Install]
WantedBy=multi-user.target
EOF

  install -m 0644 "$tmp" "$SINGBOX_UNIT"
  rm -f "$tmp"

  systemctl daemon-reload
}

listener_on_local_port() {
  ss -H -ltn 2>/dev/null \
    | awk '{print $4}' \
    | grep -Eq "(^|:)${LOCAL_PORT}$"
}

listener_exact_loopback() {
  ss -H -ltn 2>/dev/null \
    | awk '{print $4}' \
    | grep -qx "127.0.0.1:${LOCAL_PORT}"
}

wait_for_singbox_ready() {
  local i=0

  for ((i = 1; i <= 15; i++)); do
    if systemctl is-active --quiet "$SERVICE_NAME" \
        && listener_exact_loopback; then
      return 0
    fi

    sleep 1
  done

  return 1
}

ensure_singbox_running() {
  if listener_on_local_port \
      && ! systemctl is-active --quiet "$SERVICE_NAME"; then
    warn "$(T \
      "端口 ${LOCAL_PORT} 已被其他进程占用：" \
      "Port ${LOCAL_PORT} is already used by another process:")"

    ss -ltnp 2>/dev/null \
      | grep -E "(^|:)${LOCAL_PORT}[[:space:]]" \
      || true

    die "$(T \
      "为避免覆盖其他服务，已停止部署。" \
      "Deployment stopped to avoid interfering with another service.")"
  fi

  systemctl enable "$SERVICE_NAME" >/dev/null 2>&1 \
    || die "$(T \
      "无法启用 ${SERVICE_NAME}。" \
      "Unable to enable ${SERVICE_NAME}.")"

  systemctl restart "$SERVICE_NAME" >/dev/null 2>&1 || true

  if ! wait_for_singbox_ready; then
    journalctl \
      -u "$SERVICE_NAME" \
      -n 80 \
      --no-pager >&2 \
      || true

    die "$(T \
      "${SERVICE_NAME} 未能在 15 秒内进入正常状态，或未监听 127.0.0.1:${LOCAL_PORT}。" \
      "${SERVICE_NAME} did not become ready within 15 seconds or did not listen on 127.0.0.1:${LOCAL_PORT}.")"
  fi
}

write_cloudflared_runner() {
  [[ -n "$CLOUDFLARED_BIN" ]] \
    || die "$(T \
      "未找到 cloudflared。" \
      "cloudflared was not found.")"

  mkdir -p "$CLOUDFLARED_HOME"
  chmod 700 "$CLOUDFLARED_HOME"

  local tmp=""

  tmp="$(mktemp)"

  cat > "$tmp" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

export HOME="${CLOUDFLARED_HOME}"

CF_PID=""
CF_START=""

cleanup() {
  local rc=\$?

  trap - EXIT HUP INT TERM

  if [[ -n "\${CF_PID}" ]] \
      && kill -0 "\${CF_PID}" 2>/dev/null; then
    kill "\${CF_PID}" 2>/dev/null || true
    wait "\${CF_PID}" 2>/dev/null || true
  fi

  rm -f "${CLOUDFLARED_PID_FILE}"

  exit "\$rc"
}

trap cleanup EXIT HUP INT TERM

"${CLOUDFLARED_BIN}" tunnel \
  --url "http://127.0.0.1:${LOCAL_PORT}" \
  --protocol http2 \
  > >(tee -a "${LOG_FILE}") 2>&1 &

CF_PID=\$!

CF_START="\$(
  awk '{print \$22}' \
    "/proc/\${CF_PID}/stat" \
    2>/dev/null \
    || true
)"

if [[ "\${CF_START}" =~ ^[0-9]+$ ]]; then
  printf '%s %s\n' \
    "\${CF_PID}" \
    "\${CF_START}" \
    > "${CLOUDFLARED_PID_FILE}"
else
  printf '%s\n' \
    "\${CF_PID}" \
    > "${CLOUDFLARED_PID_FILE}"
fi

chmod 600 "${CLOUDFLARED_PID_FILE}"

wait "\${CF_PID}"
EOF

  install -m 0700 "$tmp" "$CLOUDFLARED_RUNNER"
  rm -f "$tmp"
}

tmux_session_exists() {
  tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

tunnel_is_running() {
  tmux_session_exists || return 1

  tmux list-panes \
    -t "$TMUX_SESSION" \
    -F '#{pane_start_command}' \
    2>/dev/null \
    | grep -Fq "$CLOUDFLARED_RUNNER"
}

cloudflared_pid_is_ours() {
  [[ -r "$CLOUDFLARED_PID_FILE" ]] || return 1

  local pid=""
  local recorded_start=""
  local actual_start=""
  local cmdline=""

  read -r pid recorded_start < "$CLOUDFLARED_PID_FILE" \
    || return 1

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1

  if [[ -n "$recorded_start" ]]; then
    [[ "$recorded_start" =~ ^[0-9]+$ ]] || return 1

    actual_start="$(
      awk '{print $22}' \
        "/proc/${pid}/stat" \
        2>/dev/null \
        || true
    )"

    [[ "$actual_start" == "$recorded_start" ]] || return 1
  fi

  cmdline="$(
    tr '\0' ' ' \
      < "/proc/${pid}/cmdline" \
      2>/dev/null \
      || true
  )"

  [[ "$cmdline" == *"cloudflared"* ]] \
    && [[ "$cmdline" == *"127.0.0.1:${LOCAL_PORT}"* ]]
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
    host="$(extract_argo_host || true)"

    if [[ -n "$host" ]] \
        && valid_argo_host "$host"; then
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
  valid_uuid "$UUID" \
    || die "$(T \
      "UUID 无效，无法生成分享链接。" \
      "Invalid UUID; unable to generate the share link.")"

  valid_ws_path "$WSPATH" \
    || die "$(T \
      "WS 路径无效，无法生成分享链接。" \
      "Invalid WebSocket path; unable to generate the share link.")"

  valid_argo_host "$ARGO_HOST" \
    || die "$(T \
      "临时 Argo 域名无效。" \
      "The temporary Argo hostname is invalid.")"

  [[ -n "$ARGO_HOST" ]] \
    || die "$(T \
      "临时 Argo 域名为空。" \
      "The temporary Argo hostname is empty.")"

  valid_preferred_endpoint "$PREFERRED_ENDPOINT" \
    || die "$(T \
      "优选域名/IP 无效。" \
      "The preferred domain/IP is invalid.")"

  [[ "$NODE_NAME" == "zdd-argo" ]] \
    || die "$(T \
      "节点名称必须固定为 zdd-argo。" \
      "The node name must remain zdd-argo.")"

  local tmp_json=""
  local tmp_link=""
  local encoded=""

  tmp_json="$(mktemp "${DATA_DIR}/.vmess.json.XXXXXX")"
  tmp_link="$(mktemp "${DATA_DIR}/.vmess.txt.XXXXXX")"

  umask 077

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

  encoded="$(
    base64 < "$tmp_json" \
      | tr -d '\r\n'
  )"

  printf 'vmess://%s\n' "$encoded" > "$tmp_link"

  if ! base64 -d \
      < <(sed 's#^vmess://##' "$tmp_link") \
      2>/dev/null \
      | jq -e \
        --arg add "$PREFERRED_ENDPOINT" \
        --arg host "$ARGO_HOST" \
        --arg ech "$ECH_CONFIG" \
        '
          .ps == "zdd-argo"
          and .add == $add
          and .host == $host
          and .sni == $host
          and .vcn == $host
          and .pcs == ""
          and .ech == $ech
          and .echConfigList == $ech
        ' >/dev/null; then
    rm -f "$tmp_json" "$tmp_link"

    die "$(T \
      "生成的 VMess 链接自检失败，未写入磁盘。" \
      "The generated VMess link failed self-validation and was not saved.")"
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

  if tunnel_is_running; then
    tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
    stopped=1
  elif tmux_session_exists; then
    warn "$(T \
      "发现同名 tmux 会话，但它不是本脚本创建的；不会将其删除。" \
      "A tmux session with the same name exists, but it was not created by this script and will not be removed.")"
  fi

  sleep 1

  if cloudflared_pid_is_ours; then
    read -r pid _ < "$CLOUDFLARED_PID_FILE" || pid=""

    kill "$pid" 2>/dev/null || true

    for _ in 1 2 3 4 5; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done

    kill -9 "$pid" 2>/dev/null || true
    stopped=1
  fi

  rm -f "$CLOUDFLARED_PID_FILE"

  if [[ $stopped -eq 1 ]]; then
    ok "$(T \
      "临时 Argo 已停止；旧 trycloudflare.com 域名随之失效。" \
      "The temporary Argo tunnel was stopped; the previous trycloudflare.com hostname is now invalid.")"
  else
    info "$(T \
      "没有发现正在运行的 zdd-argo 临时隧道。" \
      "No running zdd-argo temporary tunnel was found.")"
  fi
}

command_stop_clear_cache() {
  warn "$(T \
    "此操作会断开当前临时 Argo，并删除旧域名、订阅、日志及 cloudflared 临时缓存。" \
    "This will disconnect the current temporary Argo tunnel and delete its old hostname, subscription, logs, and temporary cloudflared cache.")"

  warn "$(T \
    "UUID、WS 路径、优选地址、sing-box 配置和已安装程序都会保留。" \
    "The UUID, WebSocket path, preferred endpoint, sing-box configuration, and installed programs will be preserved.")"

  if ! confirm_yes "$(T \
      "确认断开并清理请输入 yes：" \
      "Type yes to disconnect and clear temporary data: ")"; then
    info "$(T "已取消。" "Cancelled.")"
    return 0
  fi

  stop_tunnel

  if [[ -f "$STATE_JSON" ]]; then
    load_state
    ARGO_HOST=""
    save_state
  fi

  rm -f \
    "$CLOUDFLARED_PID_FILE" \
    "$LOG_FILE" \
    "$VMESS_JSON_FILE" \
    "$VMESS_LINK_FILE" \
    "$ECH_NOTE_FILE"

  rm -rf "$CLOUDFLARED_HOME"

  ok "$(T \
    "当前临时 Argo 已断开，旧订阅和临时缓存已清理。" \
    "The current temporary Argo tunnel was disconnected, and the old subscription and temporary cache were cleared.")"

  info "$(T \
    "以后选择菜单 1 可重新生成 Argo；UUID、WS 路径和优选地址保持不变。" \
    "Choose menu item 1 later to create a new Argo tunnel; the UUID, WebSocket path, and preferred endpoint will remain unchanged.")"
}

start_tunnel() {
  if tmux_session_exists \
      && ! tunnel_is_running; then
    die "$(T \
      "已存在同名 tmux 会话 ${TMUX_SESSION}，但不是本脚本创建的会话；为避免误伤，请先改名或删除该会话。" \
      "A tmux session named ${TMUX_SESSION} already exists but was not created by this script. Rename or remove it first to avoid affecting unrelated work.")"
  fi

  if tunnel_is_running; then
    local parsed_host=""

    parsed_host="$(extract_argo_host || true)"

    if [[ -n "$parsed_host" ]] \
        && valid_argo_host "$parsed_host"; then
      ARGO_HOST="$parsed_host"
      save_state
      generate_vmess_link

      info "$(T \
        "现有临时隧道运行正常，未重复创建。" \
        "The existing temporary tunnel is running normally; no duplicate tunnel was created.")"

      return 0
    fi

    warn "$(T \
      "检测到 tmux 会话，但尚未取得有效临时域名，继续等待……" \
      "A tmux session was detected, but no valid temporary hostname is available yet; waiting...")"

    if wait_for_argo_host; then
      generate_vmess_link
      return 0
    fi

    die "$(T \
      "现有临时隧道未返回域名，请查看日志。" \
      "The existing temporary tunnel did not return a hostname. Check the logs.")"
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

  info "$(T \
    "在后台 tmux 会话 ${TMUX_SESSION} 中创建临时 Argo……" \
    "Creating a temporary Argo tunnel in background tmux session ${TMUX_SESSION}...")"

  tmux new-session \
    -d \
    -s "$TMUX_SESSION" \
    "$CLOUDFLARED_RUNNER" \
    9>&- \
    || die "$(T \
      "无法创建 tmux 会话。" \
      "Unable to create the tmux session.")"

  if ! wait_for_argo_host; then
    warn "$(T \
      "90 秒内未取得 trycloudflare.com 域名，最近日志如下：" \
      "No trycloudflare.com hostname was obtained within 90 seconds. Recent logs:")"

    tail -n 60 "$LOG_FILE" >&2 || true

    stop_tunnel || true

    die "$(T \
      "临时隧道创建失败。" \
      "Failed to create the temporary tunnel.")"
  fi

  generate_vmess_link
}

prepare_deployment() {
  install_singbox_if_needed
  install_cloudflared_if_needed

  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"

  load_settings

  if [[ $ENDPOINT_CONFIGURED -ne 1 ]]; then
    PREFERRED_ENDPOINT="$DEFAULT_PREFERRED_ENDPOINT"
    save_settings

    info "$(T \
      "使用默认优选域名：${PREFERRED_ENDPOINT}" \
      "Using default preferred domain: ${PREFERRED_ENDPOINT}")"
  fi

  load_state

  if [[ -z "$UUID" || -z "$WSPATH" ]]; then
    generate_identity
  fi

  write_singbox_config
  write_singbox_service
  write_cloudflared_runner
  ensure_singbox_running
}

show_subscription() {
  load_settings
  load_state

  local running="$(T "否" "No")"
  local parsed_host=""

  if tunnel_is_running; then
    running="$(T "是" "Yes")"

    parsed_host="$(extract_argo_host || true)"

    if [[ -n "$parsed_host" ]] \
        && valid_argo_host "$parsed_host"; then
      if [[ "$ARGO_HOST" != "$parsed_host" ]]; then
        ARGO_HOST="$parsed_host"
        save_state
      fi
    fi

    if [[ -n "$ARGO_HOST" ]] \
        && valid_argo_host "$ARGO_HOST"; then
      generate_vmess_link
    fi
  fi

  printf '\n%s========== %s ==========%s\n' \
    "$C_GREEN" \
    "$(T "zdd-argo 当前节点" "Current zdd-argo node")" \
    "$C_RESET"

  printf '%-22s %s\n' \
    "$(T "节点名称：" "Node name:")" \
    "$NODE_NAME"

  printf '%-22s %s\n' \
    "$(T "优选域名/IP：" "Preferred domain/IP:")" \
    "${PREFERRED_ENDPOINT:-$(T "未设置" "not set")}"

  printf '%-22s %s\n' \
    "$(T "临时 Argo 域名：" "Temporary Argo host:")" \
    "${ARGO_HOST:-$(T "尚未生成" "not generated")}"

  printf '%-22s %s\n' \
    "UUID:" \
    "${UUID:-$(T "尚未生成" "not generated")}"

  printf '%-22s %s\n' \
    "$(T "WS 路径：" "WS path:")" \
    "${WSPATH:-$(T "尚未生成" "not generated")}"

  printf '%-22s 127.0.0.1:%s\n' \
    "$(T "本地监听：" "Local listener:")" \
    "$LOCAL_PORT"

  printf '%-22s %s\n' \
    "$(T "后台隧道运行：" "Background tunnel:")" \
    "$running"

  printf '%-22s %s\n' \
    "ECHConfigList:" \
    "$ECH_CONFIG"

  printf '%s========================================%s\n\n' \
    "$C_GREEN" \
    "$C_RESET"

  if [[ -f "$VMESS_LINK_FILE" ]]; then
    if ! tunnel_is_running; then
      warn "$(T \
        "后台隧道当前未运行；下面是保存的旧链接，目前不可用。" \
        "The background tunnel is not running. The saved link below is currently unusable.")"
    fi

    printf '%s%s%s\n' \
      "$C_CYAN" \
      "$(T \
        "VMess 分享链接（名称固定为 zdd-argo）：" \
        "VMess share link (name fixed to zdd-argo):")" \
      "$C_RESET"

    cat "$VMESS_LINK_FILE"

    printf '\n%s %s\n' \
      "$(T "保存位置：" "Saved at:")" \
      "$VMESS_LINK_FILE"

    printf '\n%s%s%s\n' \
      "$C_YELLOW" \
      "$(T \
        "ECH 兼容提示：" \
        "ECH compatibility note:")" \
      "$C_RESET"

    printf '%s\n' "$(T \
      "脚本已同时尝试写入 JSON 字段 ech 与 echConfigList。" \
      "The script writes both the ech and echConfigList JSON fields.")"

    printf '%s\n%s\n' \
      "$(T \
        "导入客户端后，请检查 EchConfigList 是否为：" \
        "After importing, verify that EchConfigList is:")" \
      "$ECH_CONFIG"

    printf '%s\n' "$(T \
      "若客户端忽略旧式 VMess JSON 的扩展字段，请手动粘贴这一行。" \
      "If the client ignores extension fields in legacy VMess JSON, paste this value manually.")"
  else
    warn "$(T \
      "尚未生成 VMess 分享链接，请先选择菜单 1。" \
      "No VMess share link has been generated. Choose menu item 1 first.")"
  fi
}

show_status() {
  load_settings

  if command -v jq >/dev/null 2>&1; then
    load_state
  else
    UUID=""
    WSPATH=""
    ARGO_HOST=""
    CREATED_AT=""
  fi

  resolve_singbox_bin
  resolve_cloudflared_bin

  printf '\n%s========== %s ==========%s\n' \
    "$C_CYAN" \
    "$(T "zdd-argo 运行状态" "zdd-argo status")" \
    "$C_RESET"

  printf '%-24s v %s\n' \
    "$(T "脚本版本：" "Script version:")" \
    "$SCRIPT_VERSION"

  printf '%-24s %s\n' \
    "$(T "优选域名/IP：" "Preferred domain/IP:")" \
    "${PREFERRED_ENDPOINT:-$(T "未设置" "not set")}"

  printf '%-24s ' "sing-box:"

  if [[ -n "$SINGBOX_BIN" ]]; then
    "$SINGBOX_BIN" version 2>/dev/null \
      | head -n 1 \
      || printf '%s\n' "$(T "已安装" "installed")"

    printf '%-24s %s' \
      "$(T "sing-box 路径：" "sing-box path:")" \
      "$SINGBOX_BIN"

    if [[ "$SINGBOX_BIN" == "$MANAGED_SINGBOX_BIN" ]]; then
      printf ' %s\n' "$(T \
        "（脚本专用，SHA-256 已校验）" \
        "(script-managed, SHA-256 verified)")"
    else
      printf ' %s\n' "$(T \
        "（外部安装）" \
        "(external installation)")"
    fi
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T "未安装" "not installed")" \
      "$C_RESET"
  fi

  printf '%-24s ' "cloudflared:"

  if [[ -n "$CLOUDFLARED_BIN" ]]; then
    "$CLOUDFLARED_BIN" --version 2>/dev/null \
      || printf '%s\n' "$(T "已安装" "installed")"

    printf '%-24s %s' \
      "$(T "cloudflared 路径：" "cloudflared path:")" \
      "$CLOUDFLARED_BIN"

    if [[ "$CLOUDFLARED_BIN" == "$MANAGED_CLOUDFLARED_BIN" ]]; then
      printf ' %s\n' "$(T \
        "（脚本专用，SHA-256 已校验）" \
        "(script-managed, SHA-256 verified)")"
    else
      printf ' %s\n' "$(T \
        "（外部安装）" \
        "(external installation)")"
    fi
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T "未安装" "not installed")" \
      "$C_RESET"
  fi

  printf '%-24s ' "$(T \
    "sing-box 服务：" \
    "sing-box service:")"

  if systemctl is-active --quiet "$SERVICE_NAME"; then
    printf '%s%s%s\n' \
      "$C_GREEN" \
      "$(T "运行中" "running")" \
      "$C_RESET"
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T "未运行" "stopped")" \
      "$C_RESET"
  fi

  printf '%-24s ' "$(T \
    "本地端口：" \
    "Local port:")"

  if listener_exact_loopback; then
    printf '%s127.0.0.1:%s %s%s\n' \
      "$C_GREEN" \
      "$LOCAL_PORT" \
      "$(T "正常" "ready")" \
      "$C_RESET"
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T \
        "未检测到正确监听" \
        "expected listener not detected")" \
      "$C_RESET"
  fi

  printf '%-24s ' "Argo / tmux:"

  if tunnel_is_running; then
    printf '%s%s%s (%s: %s)\n' \
      "$C_GREEN" \
      "$(T "运行中" "running")" \
      "$C_RESET" \
      "$(T "会话" "session")" \
      "$TMUX_SESSION"
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T "未运行" "stopped")" \
      "$C_RESET"
  fi

  printf '%-24s %s\n' \
    "$(T "临时域名：" "Temporary host:")" \
    "${ARGO_HOST:-$(T "尚未生成" "not generated")}"

  local resolved_zargo=""

  resolved_zargo="$(type -P zargo 2>/dev/null || true)"

  printf '%-24s ' "$(T \
    "管理命令：" \
    "Management command:")"

  if resolved_zdd_is_ours "$resolved_zargo"; then
    printf '%s%s%s (%s)\n' \
      "$C_GREEN" \
      "zargo" \
      "$C_RESET" \
      "$resolved_zargo"
  elif [[ -n "$resolved_zargo" ]]; then
    printf '%s%s%s (%s)\n' \
      "$C_RED" \
      "$(T \
        "被其他程序占用" \
        "resolved to another program")" \
      "$C_RESET" \
      "$resolved_zargo"
  else
    printf '%s%s%s\n' \
      "$C_RED" \
      "$(T "未找到" "not found")" \
      "$C_RESET"
  fi

  printf '%s========================================%s\n' \
    "$C_CYAN" \
    "$C_RESET"

  if [[ -f "$LOG_FILE" ]]; then
    printf '\n%s\n' "$(T \
      "最近 20 行 cloudflared 日志：" \
      "Last 20 lines of cloudflared logs:")"

    tail -n 20 "$LOG_FILE" || true
  fi
}

command_generate() {
  prepare_deployment

  if tunnel_is_running; then
    local choice=""

    printf '\n%s\n' "$(T \
      "检测到当前临时 Argo 已在运行：" \
      "A temporary Argo tunnel is already running:")"

    if [[ "$LANGUAGE" == "zh" ]]; then
      cat <<'EOF'
1. 保持当前域名，只校验并显示订阅
2. 重建临时域名（保留 UUID 与 WS 路径）
3. 全部重建（同时更换 UUID、WS 路径与临时域名）
0. 返回
EOF
    else
      cat <<'EOF'
1. Keep the current hostname; validate and display the subscription
2. Rebuild the temporary hostname (keep UUID and WebSocket path)
3. Rebuild everything (replace UUID, WebSocket path, and temporary hostname)
0. Back
EOF
    fi

    while true; do
      read_interactive choice \
        "$(T "请选择 [0-3]：" "Select [0-3]: ")" \
        "" \
        || choice=""

      case "$choice" in
        1)
          start_tunnel
          break
          ;;
        2)
          stop_tunnel
          start_tunnel
          break
          ;;
        3)
          stop_tunnel
          generate_identity
          write_singbox_config
          ensure_singbox_running
          start_tunnel
          break
          ;;
        0)
          info "$(T \
            "已返回，不做修改。" \
            "Returned without changes.")"
          return 0
          ;;
        *)
          warn "$(T \
            "请输入 0、1、2 或 3。" \
            "Please enter 0, 1, 2, or 3.")"
          ;;
      esac
    done
  else
    start_tunnel
  fi

  ok "$(T \
    "临时 Argo 已就绪；现在可以直接断开 SSH。" \
    "The temporary Argo tunnel is ready; you may now disconnect SSH.")"

  show_subscription
}

command_update_singbox() {
  install_or_update_singbox
}

command_update_cloudflared() {
  local had_deployment=0

  if [[ -f "$CLOUDFLARED_RUNNER" || -f "$STATE_JSON" ]]; then
    had_deployment=1
  fi

  install_or_update_cloudflared
  resolve_cloudflared_bin

  if [[ $had_deployment -eq 1 ]]; then
    write_cloudflared_runner

    ok "$(T \
      "脚本专用 cloudflared 已更新；当前正在运行的隧道不会中断，下次重建时使用新版本。" \
      "The script-managed cloudflared was updated. The running tunnel was not interrupted; the new version will be used on the next rebuild.")"
  else
    ok "$(T \
      "脚本专用 cloudflared 已安装或更新；当前未发现 zdd-argo 部署。" \
      "The script-managed cloudflared was installed or updated; no existing zdd-argo deployment was found.")"
  fi
}

command_update_components() {
  info "$(T \
    "开始更新 sing-box 和 cloudflared……" \
    "Updating sing-box and cloudflared...")"

  command_update_singbox
  command_update_cloudflared

  ok "$(T \
    "sing-box 和 cloudflared 已完成更新检查。" \
    "sing-box and cloudflared update checks are complete.")"
}

remove_zdd_components() {
  stop_tunnel || true

  systemctl disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true

  rm -f "$SINGBOX_UNIT"

  systemctl daemon-reload || true
  systemctl reset-failed "$SERVICE_NAME" >/dev/null 2>&1 || true

  rm -rf "$DATA_DIR"
  rm -f "$LOG_FILE"
}

confirm_yes() {
  local prompt="$1"
  local answer=""

  read_interactive answer "$prompt" "" \
    || die "$(T \
      "此操作必须在交互式终端中执行。" \
      "This operation must be run in an interactive terminal.")"

  answer="${answer#"${answer%%[![:space:]]*}"}"
  answer="${answer%"${answer##*[![:space:]]}"}"

  [[ "${answer,,}" == "yes" ]]
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

    if [[ "$path" == "$SHORTCUT_COMPAT_PATH" || "$path" == "$SHORTCUT_FALLBACK_PATH" ]] \
        && [[ -L "$path" ]] \
        && [[ "$(readlink "$path" 2>/dev/null || true)" == "$SHORTCUT_PATH" ]]; then
      rm -f "$path"
    elif path_is_replaceable_zdd_launcher "$path"; then
      rm -f "$path"
    elif [[ "$path" == "$LEGACY_SHORTCUT_PATH" || "$path" == "$LEGACY_SHORTCUT_BIN" ]]; then
      if grep -Fq 'zdd-argo' "$path" 2>/dev/null; then
        rm -f "$path"
      fi
    else
      warn "$(T \
        "快捷命令路径不是本项目创建的，未删除：${path}" \
        "Launcher path was not created by this project and was not removed: ${path}")"
    fi
  done
}

remove_managed_script() {
  if [[ -e "$MANAGED_SCRIPT_PATH" ]]; then
    if grep -q '^# zdd-argo' "$MANAGED_SCRIPT_PATH" 2>/dev/null; then
      rm -f \
        "$MANAGED_SCRIPT_PATH" \
        "${MANAGED_SCRIPT_PATH}.new."*
    else
      warn "$(T \
        "已安装脚本副本未通过项目标识校验，未删除：${MANAGED_SCRIPT_PATH}" \
        "The managed script copy failed the project identity check and was not removed: ${MANAGED_SCRIPT_PATH}")"
    fi
  fi
}

command_uninstall_zdd() {
  warn "$(T \
    "此操作会停止临时 Argo，并删除 zdd-argo 的专用服务、配置、日志、订阅、快捷命令和已安装脚本副本。" \
    "This will stop the temporary Argo tunnel and remove the zdd-argo service, configuration, logs, subscription, launcher, and managed script copy.")"

  warn "$(T \
    "sing-box、cloudflared、tmux 仍会保留；下载或 Git 克隆的源文件不会删除。" \
    "sing-box, cloudflared, and tmux will be preserved; downloaded or Git-cloned source files will not be deleted.")"

  if ! confirm_yes "$(T \
      "确认卸载请输入 yes：" \
      "Type yes to confirm: ")"; then
    info "$(T "已取消。" "Cancelled.")"
    return 0
  fi

  remove_zdd_components
  remove_shortcuts
  remove_managed_script
  cleanup_bin_dir

  ok "$(T \
    "zdd-argo 已卸载；脚本专用 sing-box 和 cloudflared 已保留。" \
    "zdd-argo was uninstalled; the script-managed sing-box and cloudflared were preserved.")"

  if [[ $MENU_MODE -eq 1 ]]; then
    return 10
  fi

  return 0
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

remove_cloudflared_program() {
  rm -f \
    "$MANAGED_CLOUDFLARED_BIN" \
    "$CLOUDFLARED_RELEASE_META" \
    "${MANAGED_CLOUDFLARED_BIN}.new."* \
    "${MANAGED_CLOUDFLARED_BIN}.backup."* \
    "${CLOUDFLARED_RELEASE_META}.backup."*

  hash -r
}

cleanup_bin_dir() {
  rmdir "$BIN_DIR" 2>/dev/null || true
}

show_full_uninstall_risks() {
  printf '\n%s%s%s\n' \
    "$C_RED" \
    "$(T "完整卸载影响：" "Full uninstall impact:")" \
    "$C_RESET"

  printf '%s\n' "$(T \
    "  - 删除 zdd-argo 专用部署、快捷命令和已安装脚本副本；" \
    "  - Removes the zdd-argo deployment, launcher, and managed script copy;")"

  printf '%s\n' "$(T \
    "  - 删除本脚本安装在 ${BIN_DIR} 的 sing-box 与 cloudflared；" \
    "  - Removes the script-managed sing-box and cloudflared from ${BIN_DIR};")"

  printf '%s\n' "$(T \
    "  - 不停止、不卸载 apt 或其他脚本维护的同名程序与服务；" \
    "  - Does not stop or uninstall same-named programs/services managed by apt or other scripts;")"

  printf '%s\n' "$(T \
    "  - 不删除下载或 Git 克隆的源文件，也不删除 /etc/sing-box、/etc/cloudflared 或 tmux。" \
    "  - Does not delete downloaded/Git-cloned source files, /etc/sing-box, /etc/cloudflared, or tmux.")"
}

command_purge_all() {
  show_full_uninstall_risks

  if ! confirm_yes "$(T \
      "确认完整卸载请输入 yes：" \
      "Type yes to confirm full uninstall: ")"; then
    info "$(T "已取消。" "Cancelled.")"
    return 0
  fi

  remove_zdd_components
  remove_singbox_program
  remove_cloudflared_program
  remove_shortcuts
  remove_managed_script
  cleanup_bin_dir

  systemctl daemon-reload || true

  ok "$(T \
    "zdd-argo 及脚本专用 sing-box、cloudflared 已卸载；源文件和系统中其他安装不受影响。" \
    "zdd-argo and its script-managed sing-box/cloudflared were removed; source files and other system installations were not affected.")"

  if [[ $MENU_MODE -eq 1 ]]; then
    return 10
  fi

  return 0
}

menu_header_status() {
  local sb="$(T "未安装" "not installed")"
  local argo="$(T "未运行" "stopped")"
  local host="—"

  load_settings
  resolve_singbox_bin

  if [[ -n "$SINGBOX_BIN" ]]; then
    sb="$(
      "$SINGBOX_BIN" version 2>/dev/null \
        | head -n 1 \
        | sed 's/^sing-box version /v/' \
        || true
    )"

    if [[ -z "$sb" ]]; then
      sb="$(T "已安装" "installed")"
    fi
  fi

  if tunnel_is_running; then
    argo="$(T "运行中" "running")"
  fi

  if [[ -f "$STATE_JSON" ]] \
      && command -v jq >/dev/null 2>&1; then
    host="$(
      jq -r '.argo_host // "—"' \
        "$STATE_JSON" \
        2>/dev/null \
        || printf '%s' "$(T "状态异常" "invalid state")"
    )"

    if [[ -z "$host" ]]; then
      host="—"
    fi
  fi

  printf '%s%s zdd-argo %s v %s%s\n' \
    "$C_BOLD" \
    "$C_CYAN" \
    "$(T "管理菜单" "Management Menu")" \
    "$SCRIPT_VERSION" \
    "$C_RESET"

  printf '%s %s    %s %s\n' \
    "sing-box:" \
    "$sb" \
    "Argo:" \
    "$argo"

  printf '%s %s\n' \
    "$(T "优选域名/IP：" "Preferred domain/IP:")" \
    "${PREFERRED_ENDPOINT:-$(T "未设置" "not set")}"

  printf '%s %s\n' \
    "$(T "当前域名：" "Current hostname:")" \
    "$host"

  printf '%s\n' \
    '────────────────────────────────────────'
}

run_menu_action() {
  local dependency_mode="$1"
  local fn="$2"
  local rc=0

  shift 2

  set +e

  (
    set -Eeuo pipefail

    if [[ "$dependency_mode" == "with-dependencies" ]]; then
      install_dependencies
    fi

    "$fn" "$@"
  )

  rc=$?

  set -e

  if [[ $rc -eq 10 ]]; then
    printf '\n'

    wait_for_zero "$(T \
      "卸载完成，输入 0 退出并清空屏幕：" \
      "Uninstall completed. Enter 0 to exit and clear the screen: ")"

    clear_screen
    exit 0
  fi

  if [[ $rc -ne 0 ]]; then
    error "$(T \
      "操作失败，退出码：${rc}" \
      "Operation failed with exit code: ${rc}")"
  fi

  pause_screen
}

interactive_menu() {
  MENU_MODE=1

  trap 'clear_screen; exit 130' INT TERM

  while true; do
    clear_screen
    menu_header_status

    if [[ "$LANGUAGE" == "zh" ]]; then
      cat <<'EOF'
1. 生成 / 重建临时 Argo
2. 查看当前订阅
3. 更新 sing-box 和 cloudflared
4. 查看运行状态与最近日志
5. 断开当前 Argo 并清理临时缓存
6. 卸载 zdd-argo（保留核心组件）
7. 完整卸载（含脚本专用核心组件）
0. 退出
EOF
    else
      cat <<'EOF'
1. Generate / Rebuild temporary Argo
2. View current subscription
3. Update sing-box and cloudflared
4. View status and recent logs
5. Disconnect current Argo and clear temporary cache
6. Uninstall zdd-argo (keep core components)
7. Full uninstall (including script-managed core components)
0. Exit
EOF
    fi

    printf '%s\n' '────────────────────────────────────────'

    local choice=""

    read_interactive choice \
      "$(T "请选择 [0-7]：" "Select [0-7]: ")" \
      "" \
      || choice=""

    clear_screen

    case "$choice" in
      1)
        run_menu_action \
          with-dependencies \
          run_with_lock \
          command_generate
        ;;
      2)
        run_menu_action \
          with-dependencies \
          run_with_lock \
          show_subscription
        ;;
      3)
        run_menu_action \
          with-dependencies \
          run_with_lock \
          command_update_components
        ;;
      4)
        run_menu_action \
          without-dependencies \
          show_status
        ;;
      5)
        run_menu_action \
          with-dependencies \
          run_with_lock \
          command_stop_clear_cache
        ;;
      6)
        run_menu_action \
          without-dependencies \
          run_with_lock \
          command_uninstall_zdd
        ;;
      7)
        run_menu_action \
          without-dependencies \
          run_with_lock \
          command_purge_all
        ;;
      0)
        clear_screen
        exit 0
        ;;
      *)
        warn "$(T \
          "请输入 0 到 7。" \
          "Please enter a number from 0 to 7.")"
        ;;
    esac
  done
}

bootstrap() {
  require_root
  check_os
  install_shortcut
}

automatic_install() {
  choose_language
  require_root
  check_os
  install_dependencies
  acquire_lock
  install_shortcut
  prepare_deployment
  start_tunnel

  ok "$(T \
    "临时 Argo 已安装并运行，可直接断开 SSH。" \
    "The temporary Argo tunnel is installed and running; you may disconnect SSH.")"

  show_subscription

  printf '\n%s%s%s\n' \
    "$C_YELLOW" \
    "$(T \
      "[提示] 可在客户端自行更换优选域名/IP；如 EchConfigList 为空，请手动填写：${ECH_CONFIG}" \
      "[NOTICE] You may replace the preferred domain/IP in the client. If EchConfigList is empty, enter: ${ECH_CONFIG}")" \
    "$C_RESET"

  printf '%s%s%s\n' \
    "$C_YELLOW" \
    "$(T \
      "[提示] 后续使用 zargo 打开管理菜单。" \
      "[NOTICE] Run zargo later to open the management menu.")" \
    "$C_RESET"
}

main() {
  resolve_script_path

  if [[ "$#" -ne 0 ]]; then
    LANGUAGE="zh"

    die "$(T \
      "本项目安装后只提供一个管理命令：zargo" \
      "After installation, this project provides only one management command: zargo")"
  fi

  choose_language
  bootstrap
  interactive_menu
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi