# zdd-argo

> 在 Debian / Ubuntu VPS 上快速部署和管理 Cloudflare Quick Tunnel + VMess/WS。

**当前版本：v 0.1.0**

`zdd-argo` 会自动安装并管理脚本专用的 `sing-box` 与 `cloudflared`，通过 `tmux` 保持临时 Argo 隧道在 SSH 断开后继续运行，并生成可导入客户端的 VMess 分享链接。

## 功能

- 自动安装脚本专用的 `sing-box` 与 `cloudflared`
- 从 GitHub Release 下载并校验 SHA-256 摘要
- `sing-box` 仅监听 `127.0.0.1:10000`
- 使用 Cloudflare Quick Tunnel 生成临时 `trycloudflare.com` 域名
- 使用 `tmux` 保持隧道在 SSH 断开后继续运行
- 自动生成 UUID、WebSocket 路径和 VMess 分享链接
- 固定节点名称为 `zdd-argo`
- 默认使用 `saas.sin.fan` 作为优选域名
- 支持查看订阅、更新 sing-box、查看状态、停止隧道和清理临时缓存
- 安装后可通过 `zdd argo` 调出中文菜单
- 不覆盖系统中由 apt 或其他项目维护的 sing-box / cloudflared

## 系统要求

- Debian 或 Ubuntu
- systemd
- root 权限
- CPU 架构：`amd64` 或 `arm64`
- VPS 能访问 GitHub 与 Cloudflare

## 常规安装

请使用 root 用户运行。非 root 用户可在命令前加 `sudo`。

### curl

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

### wget

```bash
wget -qO zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

脚本首次运行后会：

1. 检查系统和依赖；
2. 将受管理的脚本副本安装到 `/usr/local/lib/zdd-argo/zdd-argo.sh`；
3. 创建快捷命令 `/usr/local/sbin/zdd`；
4. 进入中文管理菜单。

此后直接运行：

```bash
zdd argo
```

下载目录中的 `zdd-argo.sh` 可以保留、移动或删除，不会影响已经安装的快捷命令。

## 管理菜单

```text
1. 生成 / 管理临时 Argo
2. 查看当前订阅
3. 更新 sing-box
4. 卸载 zdd-argo（保留 sing-box、cloudflared）
5. 完整卸载（含脚本专用 sing-box、cloudflared）
6. 查看运行状态与最近日志
7. 断开当前 Argo 并清理临时缓存
0. 退出
```

退出菜单不会停止已经运行的临时 Argo。

## 命令行用法

```bash
zdd argo
zdd argo generate
zdd argo show
zdd argo update
zdd argo status
zdd argo uninstall
zdd argo purge
```

| 命令 | 作用 |
|---|---|
| `zdd argo` | 打开中文菜单 |
| `zdd argo generate` | 生成或管理临时 Argo |
| `zdd argo show` | 查看当前订阅 |
| `zdd argo update` | 更新脚本专用 sing-box |
| `zdd argo status` | 查看运行状态和最近日志 |
| `zdd argo uninstall` | 卸载 zdd-argo，保留 sing-box 与 cloudflared |
| `zdd argo purge` | 完整卸载脚本专用组件 |

卸载操作不会删除你下载或 Git 克隆得到的仓库源文件。

## 默认参数

| 参数 | 默认值 |
|---|---|
| 节点名称 | `zdd-argo` |
| 本地监听 | `127.0.0.1:10000` |
| 优选域名 | `saas.sin.fan` |
| ECHConfigList | `cloudflare-ech.com+https://dns.jhb.ovh/joeyblog` |
| 传输 | VMess + WebSocket + TLS |
| ALPN | `http/1.1` |
| uTLS 指纹 | `firefox` |

### 临时覆盖默认值

可以通过环境变量临时覆盖优选域名或 ECH 配置：

```bash
ZDD_ARGO_DOMAIN=example.com bash zdd-argo.sh
```

```bash
ZDD_ARGO_ECH_CONFIG='cloudflare-ech.com+https://example.com/dns-query' bash zdd-argo.sh
```

使用快捷命令时也可以传入环境变量：

```bash
ZDD_ARGO_DOMAIN=example.com zdd argo
```

未设置环境变量时，始终使用上表中的默认值。

## 文件位置

| 路径 | 用途 |
|---|---|
| `/usr/local/lib/zdd-argo/zdd-argo.sh` | 已安装的脚本副本 |
| `/usr/local/lib/zdd-argo/sing-box` | 脚本专用 sing-box |
| `/usr/local/lib/zdd-argo/cloudflared` | 脚本专用 cloudflared |
| `/usr/local/sbin/zdd` | `zdd argo` 快捷入口 |
| `/etc/zdd-argo/` | 配置、状态与订阅 |
| `/var/log/zdd-argo-cloudflared.log` | cloudflared 日志 |
| `/etc/systemd/system/zdd-argo-singbox.service` | sing-box systemd 服务 |

敏感文件默认使用严格权限保存。不要把以下运行时文件上传到 GitHub：

```text
/etc/zdd-argo/state.json
/etc/zdd-argo/vmess.json
/etc/zdd-argo/vmess.txt
```

## 更新

下载仓库中的新版脚本并重新运行，即可更新受管理的脚本副本：

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

更新脚本本身不会主动停止当前 Argo。菜单中的“更新 sing-box”只更新脚本专用 sing-box。

## ECH 兼容说明

脚本会在 VMess JSON 中同时尝试写入：

```text
ech
echConfigList
```

默认内容：

```text
cloudflare-ech.com+https://dns.jhb.ovh/joeyblog
```

不同客户端对旧式 VMess JSON 扩展字段的处理可能不同。导入 v2rayN 后，请检查 `EchConfigList` 是否正确；若未保留，请手动粘贴上述内容。

## Quick Tunnel 说明

本项目使用 Cloudflare Quick Tunnel：

- 每次重新创建隧道都可能获得新的 `trycloudflare.com` 域名；
- 旧订阅会在域名变化后失效；
- VPS 重启或 cloudflared 退出后，需要重新生成临时 Argo；
- Quick Tunnel 更适合个人测试和临时使用，不应视为带 SLA 的生产隧道。

## 安全设计

- 不使用 `curl | sh` 安装 sing-box；
- sing-box 与 cloudflared 下载后校验 GitHub Release SHA-256 摘要；
- sing-box 压缩包解压前检查路径穿越；
- sing-box 只监听回环地址；
- systemd 服务启用权限收缩；
- 状态文件以 JSON 读取，不执行状态文件内容；
- 写操作使用互斥锁；
- 后台 tmux 不继承写操作锁；
- 更新 sing-box 失败时尝试回滚旧版本。

## 常见问题

### SSH 断开后隧道会停止吗？

不会。cloudflared 在 tmux 后台会话中运行。

### 退出 `zdd argo` 菜单会停止隧道吗？

不会。菜单退出和隧道生命周期相互独立。

### 为什么旧订阅突然不可用？

Quick Tunnel 的域名是临时的。隧道被停止、重建或 VPS 重启后，旧域名可能失效，请重新生成并导入订阅。

### 为什么客户端没有自动出现 ECH 配置？

部分客户端会忽略 VMess JSON 中的扩展字段。请手动填写 README 中给出的 `EchConfigList`。

## 许可证

本项目使用 [MIT License](LICENSE)。

## 免责声明

本项目仅用于合法的网络测试、学习与个人管理。使用者应遵守所在地法律法规、Cloudflare 服务条款及相关服务提供商政策。项目作者不对滥用、配置错误、服务中断或由此产生的损失承担责任。
