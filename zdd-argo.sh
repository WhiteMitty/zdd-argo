#!/usr/bin/env bash
# zdd-argo: Debian/Ubuntu 上的一键临时 Cloudflare Quick Tunnel + VMess/WS 节点生成器
# 用法：bash zdd-argo.sh [install|show|status|restart|reset|logs|attach|stop|remove|help]

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_VERSION="1.0.0"
NAME="zdd-argo"
LOCAL_PORT="10000"
PREFERRED_DOMAIN="saas.sin.fan"
TMUX_SESSION="zdd-argo"

DATA_DIR="/etc/zdd-argo"
STATE_FILE="${DATA_DIR}/state.env"
SINGBOX_CONFIG="${DATA_DIR}/sing-box.json"
SINGBOX_UNIT="/etc/systemd/system/zdd-argo-singbox.service"
CLOUDFLARED_RUNNER="${DATA_DIR}/run-cloudflared.sh"
CLOUDFLARED_HOME="${DATA_DIR}/cloudflared-home"
LOG_FILE="/var/log/zdd-argo-cloudflared.log"
VMESS_JSON_FILE="${DATA_DIR}/vmess.json"
VMESS_LINK_FILE="${DATA_DIR}/vmess.txt"

UUID=""
WSPATH=""
ARGO_HOST=""
SINGBOX_BIN=""
CLOUDFLARED_BIN=""

if [[ -t 1 ]]; then
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
  C_RESET=$'\033[0m'
else
  C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""; C_RESET=""
fi

info()  { printf '%s[信息]%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }
ok()    { printf '%s[完成]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s[注意]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
die()   { printf '%s[错误]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

on_error() {
  local exit_code=$?
  printf '%s[错误]%s 脚本在第 %s 行异常退出，退出码：%s\n' \
    "$C_RED" "$C_RESET" "${BASH_LINENO[0]:-未知}" "$exit_code" >&2
  exit "$exit_code"
}
trap on_error ERR

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "请使用 root 运行：sudo bash $0"
}

check_os() {
  [[ -r /etc/os-release ]] || die "无法识别操作系统，仅支持 Debian/Ubuntu。"
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    debian|ubuntu) ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*) ;;
        *) die "当前系统为 ${PRETTY_NAME:-未知}，此脚本仅支持 Debian/Ubuntu。" ;;
      esac
      ;;
  esac
}

install_dependencies() {
  local missing=0
  for cmd in curl jq openssl tmux ss base64; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing=1
      break
    fi
  done

  if [[ $missing -eq 1 ]]; then
    info "安装基础依赖……"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y curl jq openssl ca-certificates tmux iproute2 coreutils
  fi
}

install_singbox_if_needed() {
  if command -v sing-box >/dev/null 2>&1; then
    SINGBOX_BIN="$(command -v sing-box)"
    return
  fi

  info "安装 sing-box……"
  curl -fsSL --retry 3 https://sing-box.app/install.sh | sh
  command -v sing-box >/dev/null 2>&1 || die "sing-box 安装后仍未找到可执行文件。"
  SINGBOX_BIN="$(command -v sing-box)"
}

install_cloudflared_if_needed() {
  if command -v cloudflared >/dev/null 2>&1; then
    CLOUDFLARED_BIN="$(command -v cloudflared)"
    return
  fi

  local asset arch tmp_file
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) asset="cloudflared-linux-amd64" ;;
    aarch64|arm64) asset="cloudflared-linux-arm64" ;;
    *) die "暂不支持 CPU 架构：${arch}。本脚本支持 amd64 和 arm64。" ;;
  esac

  info "安装 cloudflared（${arch}）……"
  tmp_file="$(mktemp)"
  curl -fL --retry 3 --connect-timeout 15 \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/${asset}" \
    -o "$tmp_file"
  install -m 0755 "$tmp_file" /usr/local/bin/cloudflared
  rm -f "$tmp_file"
  CLOUDFLARED_BIN="/usr/local/bin/cloudflared"
}

load_state() {
  UUID=""
  WSPATH=""
  ARGO_HOST=""
  if [[ -f "$STATE_FILE" ]]; then
    # 文件由本脚本以 root 权限创建，仅包含三个受控变量。
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  fi
}

save_state() {
  umask 077
  cat > "$STATE_FILE" <<EOF
UUID='${UUID}'
WSPATH='${WSPATH}'
ARGO_HOST='${ARGO_HOST}'
EOF
  chmod 600 "$STATE_FILE"
}

generate_identity() {
  UUID="$(cat /proc/sys/kernel/random/uuid)"
  WSPATH="/$(openssl rand -hex 16)-vmws"
  ARGO_HOST=""
  save_state
}

write_singbox_config() {
  [[ -n "$UUID" && -n "$WSPATH" ]] || die "UUID 或 WS 路径为空。"

  umask 077
  cat > "$SINGBOX_CONFIG" <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-ws-in",
      "listen": "127.0.0.1",
      "listen_port": ${LOCAL_PORT},
      "users": [
        {
          "name": "zdd-argo",
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "transport": {
        "type": "ws",
        "path": "${WSPATH}"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "final": "direct"
  }
}
EOF
  chmod 600 "$SINGBOX_CONFIG"
  "$SINGBOX_BIN" check -c "$SINGBOX_CONFIG"
}

write_singbox_service() {
  cat > "$SINGBOX_UNIT" <<EOF
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

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "$SINGBOX_UNIT"
  systemctl daemon-reload
}

port_is_listening() {
  ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${LOCAL_PORT}$"
}

ensure_singbox_running() {
  if port_is_listening && ! systemctl is-active --quiet zdd-argo-singbox; then
    ss -ltnp 2>/dev/null | grep -E "(^|:)${LOCAL_PORT}[[:space:]]" || true
    die "本机端口 ${LOCAL_PORT} 已被其他程序占用，请先释放该端口。"
  fi

  systemctl enable zdd-argo-singbox >/dev/null
  systemctl restart zdd-argo-singbox
  sleep 1

  if ! systemctl is-active --quiet zdd-argo-singbox; then
    journalctl -u zdd-argo-singbox -n 50 --no-pager >&2 || true
    die "zdd-argo-singbox 启动失败。"
  fi

  if ! ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -qx "127.0.0.1:${LOCAL_PORT}"; then
    journalctl -u zdd-argo-singbox -n 50 --no-pager >&2 || true
    die "未检测到 127.0.0.1:${LOCAL_PORT} 监听。"
  fi
}

write_cloudflared_runner() {
  mkdir -p "$CLOUDFLARED_HOME"
  chmod 700 "$CLOUDFLARED_HOME"

  cat > "$CLOUDFLARED_RUNNER" <<EOF
#!/usr/bin/env bash
set -o pipefail
export HOME="${CLOUDFLARED_HOME}"
"${CLOUDFLARED_BIN}" tunnel --url "http://127.0.0.1:${LOCAL_PORT}" --protocol http2 2>&1 | tee -a "${LOG_FILE}"
exit \${PIPESTATUS[0]}
EOF
  chmod 700 "$CLOUDFLARED_RUNNER"
}

tunnel_is_running() {
  tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

extract_argo_host() {
  [[ -f "$LOG_FILE" ]] || return 1
  grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG_FILE" 2>/dev/null \
    | tail -n 1 \
    | sed 's#^https://##'
}

wait_for_argo_host() {
  local i host=""
  for ((i=1; i<=90; i++)); do
    host="$(extract_argo_host || true)"
    if [[ "$host" =~ ^[a-z0-9-]+\.trycloudflare\.com$ ]]; then
      ARGO_HOST="$host"
      save_state
      return 0
    fi

    if ! tunnel_is_running; then
      break
    fi
    sleep 1
  done
  return 1
}

generate_vmess_link() {
  [[ -n "$ARGO_HOST" ]] || die "临时 Argo 域名为空，无法生成 VMess 链接。"

  jq -c -n \
    --arg ps "$NAME" \
    --arg add "$PREFERRED_DOMAIN" \
    --arg id "$UUID" \
    --arg host "$ARGO_HOST" \
    --arg path "$WSPATH" \
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
      pcs: ""
    }' > "$VMESS_JSON_FILE"

  printf 'vmess://%s\n' "$(base64 -w 0 < "$VMESS_JSON_FILE")" > "$VMESS_LINK_FILE"
  chmod 600 "$VMESS_JSON_FILE" "$VMESS_LINK_FILE"
}

start_tunnel() {
  if tunnel_is_running; then
    info "tmux 会话 ${TMUX_SESSION} 已在运行，不重复创建。"
    local parsed_host
    parsed_host="$(extract_argo_host || true)"
    if [[ -n "$parsed_host" ]]; then
      ARGO_HOST="$parsed_host"
      save_state
      generate_vmess_link
      return 0
    fi
    info "等待现有隧道返回临时域名……"
    if wait_for_argo_host; then
      generate_vmess_link
      return 0
    fi
    die "现有隧道未返回临时域名，请运行：bash $0 logs"
  fi

  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  ARGO_HOST=""
  save_state

  info "在后台 tmux 会话 ${TMUX_SESSION} 中创建临时 Argo 隧道……"
  tmux new-session -d -s "$TMUX_SESSION" "$CLOUDFLARED_RUNNER"

  if ! wait_for_argo_host; then
    warn "未能在 90 秒内取得 trycloudflare.com 域名。最近日志如下："
    tail -n 50 "$LOG_FILE" >&2 || true
    die "临时隧道创建失败；可运行 bash $0 logs 继续排查。"
  fi

  generate_vmess_link
}

stop_tunnel() {
  if tunnel_is_running; then
    tmux kill-session -t "$TMUX_SESSION"
    ok "临时 Argo 隧道已停止，旧的 trycloudflare.com 域名将失效。"
  else
    info "没有发现正在运行的 ${TMUX_SESSION} 会话。"
  fi
}

show_info() {
  load_state
  local running="否"
  tunnel_is_running && running="是"

  if [[ -z "$ARGO_HOST" ]]; then
    ARGO_HOST="$(extract_argo_host || true)"
  fi

  printf '\n%s========== zdd-argo 节点信息 ==========%s\n' "$C_GREEN" "$C_RESET"
  printf '名称：          %s\n' "$NAME"
  printf '优选域名：      %s\n' "$PREFERRED_DOMAIN"
  printf '临时 Argo 域名：%s\n' "${ARGO_HOST:-尚未生成}"
  printf 'UUID：          %s\n' "${UUID:-尚未生成}"
  printf 'WS 路径：       %s\n' "${WSPATH:-尚未生成}"
  printf '本地监听：      127.0.0.1:%s\n' "$LOCAL_PORT"
  printf 'tmux 后台运行： %s\n' "$running"
  printf '%s========================================%s\n\n' "$C_GREEN" "$C_RESET"

  if [[ -f "$VMESS_LINK_FILE" ]]; then
    if [[ "$running" != "是" ]]; then
      warn "隧道当前未运行，下面保存的是旧链接，暂时不可用。"
    fi
    printf '%sVMess 分享链接：%s\n' "$C_CYAN" "$C_RESET"
    cat "$VMESS_LINK_FILE"
    printf '\n链接保存位置：%s\n' "$VMESS_LINK_FILE"
  else
    warn "尚未生成 VMess 链接。"
  fi
}

show_status() {
  load_state
  printf '脚本版本：%s\n' "$SCRIPT_VERSION"
  printf 'sing-box：  '
  if systemctl is-active --quiet zdd-argo-singbox; then
    printf '%s运行中%s\n' "$C_GREEN" "$C_RESET"
  else
    printf '%s未运行%s\n' "$C_RED" "$C_RESET"
  fi

  printf '本地端口：  '
  if ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -qx "127.0.0.1:${LOCAL_PORT}"; then
    printf '%s127.0.0.1:%s 正常%s\n' "$C_GREEN" "$LOCAL_PORT" "$C_RESET"
  else
    printf '%s未检测到监听%s\n' "$C_RED" "$C_RESET"
  fi

  printf 'Argo/tmux： '
  if tunnel_is_running; then
    printf '%s运行中%s（会话：%s）\n' "$C_GREEN" "$C_RESET" "$TMUX_SESSION"
  else
    printf '%s未运行%s\n' "$C_RED" "$C_RESET"
  fi

  printf '临时域名：  %s\n' "${ARGO_HOST:-尚未生成}"
  [[ -n "$SINGBOX_BIN" ]] && "$SINGBOX_BIN" version | head -n 1 || true
  [[ -n "$CLOUDFLARED_BIN" ]] && "$CLOUDFLARED_BIN" --version || true
}

show_logs() {
  [[ -f "$LOG_FILE" ]] || die "日志文件尚不存在：$LOG_FILE"
  tail -n 100 "$LOG_FILE"
  printf '\n持续查看日志：tail -f %s\n' "$LOG_FILE"
}

attach_tmux() {
  tunnel_is_running || die "tmux 会话 ${TMUX_SESSION} 未运行。"
  info "进入后只查看日志；离开但不停止：按 Ctrl+B，松开后按 D。"
  tmux attach-session -t "$TMUX_SESSION"
}

prepare_all() {
  require_root
  check_os
  install_dependencies
  install_singbox_if_needed
  install_cloudflared_if_needed
  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"
  load_state

  if [[ -z "$UUID" || -z "$WSPATH" ]]; then
    generate_identity
  fi

  write_singbox_config
  write_singbox_service
  write_cloudflared_runner
  ensure_singbox_running
}

command_install() {
  prepare_all
  start_tunnel
  ok "部署完成。关闭 SSH 后，tmux 中的临时隧道仍会继续运行。"
  show_info
}

command_restart() {
  prepare_all
  warn "重启临时隧道会生成新的 trycloudflare.com 域名，旧 VMess 链接会失效。"
  stop_tunnel
  start_tunnel
  ok "临时隧道已重建。"
  show_info
}

command_reset() {
  require_root
  check_os
  install_dependencies
  install_singbox_if_needed
  install_cloudflared_if_needed
  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"

  warn "reset 会同时更换 UUID、WS 路径和临时 Argo 域名，旧链接将全部失效。"
  generate_identity
  write_singbox_config
  write_singbox_service
  write_cloudflared_runner
  ensure_singbox_running
  stop_tunnel
  start_tunnel
  ok "全部身份参数已经重新生成。"
  show_info
}

command_remove() {
  require_root
  local answer=""
  warn "此操作会删除 zdd-argo 的专用服务、配置、日志和节点链接。"
  warn "不会卸载 sing-box、cloudflared、tmux，也不会修改其他 sing-box 配置。"

  if [[ -t 0 ]]; then
    read -r -p "确定删除？请输入 YES：" answer
    [[ "$answer" == "YES" ]] || die "已取消。"
  else
    die "remove 必须在交互式终端中执行。"
  fi

  stop_tunnel
  systemctl disable --now zdd-argo-singbox >/dev/null 2>&1 || true
  rm -f "$SINGBOX_UNIT"
  systemctl daemon-reload
  rm -rf "$DATA_DIR"
  rm -f "$LOG_FILE"
  ok "zdd-argo 已删除。"
}

show_help() {
  cat <<EOF
zdd-argo ${SCRIPT_VERSION}

用法：
  sudo bash $0                 首次部署；已经部署时检查并保持现有隧道
  sudo bash $0 install         与上面相同
  sudo bash $0 show            显示当前参数和 VMess 链接
  sudo bash $0 status          检查 sing-box、端口和 tmux 状态
  sudo bash $0 logs            查看最近 100 行 cloudflared 日志
  sudo bash $0 attach          进入 tmux 日志界面（离开：Ctrl+B，再按 D）
  sudo bash $0 restart         只重建临时 Argo 域名，UUID/WS 路径保持不变
  sudo bash $0 reset           重建 UUID、WS 路径和临时 Argo 域名
  sudo bash $0 stop            停止临时 Argo；专用 sing-box 服务仍保留
  sudo bash $0 remove          删除本脚本创建的专用服务和数据
  bash $0 help                 显示帮助

重要说明：
  1. 断开 SSH 不会停止 tmux 中的隧道。
  2. VPS 重启、tmux 被杀或 cloudflared 退出后，临时域名会失效。
  3. restart/reset 会产生新临时域名，必须重新导入输出的 VMess 链接。
EOF
}

main() {
  local command="${1:-install}"
  case "$command" in
    install|start)
      command_install
      ;;
    show)
      require_root
      load_state
      show_info
      ;;
    status)
      require_root
      install_dependencies
      SINGBOX_BIN="$(command -v sing-box || true)"
      CLOUDFLARED_BIN="$(command -v cloudflared || true)"
      show_status
      ;;
    restart)
      command_restart
      ;;
    reset)
      command_reset
      ;;
    logs)
      require_root
      show_logs
      ;;
    attach)
      require_root
      attach_tmux
      ;;
    stop)
      require_root
      stop_tunnel
      ;;
    remove)
      command_remove
      ;;
    help|-h|--help)
      show_help
      ;;
    *)
      show_help
      die "未知命令：$command"
      ;;
  esac
}

main "$@"
