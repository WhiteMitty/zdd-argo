<p align="right">
  <a href="./README.md"><kbd><strong>简体中文</strong></kbd></a>
  <a href="./README_EN.md"><kbd>English</kbd></a>
</p>

# zdd-argo

在 Debian / Ubuntu VPS 上部署和管理 **Cloudflare Quick Tunnel + VMess/WS** 的双语交互脚本。

> 当前版本：**v 0.1.0**

`zdd-argo` 会安装脚本专用的 `sing-box` 与 `cloudflared`，通过 `tmux` 在后台维持临时 Argo 隧道，并生成可导入客户端的 VMess 分享链接。SSH 断开后，临时隧道仍可继续运行。

## 主要功能

- 启动时选择界面语言：
  - `1) 中文`
  - `2) English`
- 安装完成后只需一个管理命令：

  ```bash
  zdd argo
  ```

- 自动安装和更新脚本专用的：
  - `sing-box`
  - `cloudflared`
- 从官方 GitHub Release 下载核心程序，并核验 SHA-256 摘要
- `sing-box` 仅监听 `127.0.0.1:10000`
- Cloudflare Quick Tunnel 在独立 `tmux` 会话中后台运行
- 自动生成 UUID、WebSocket 路径和 VMess 分享链接
- 分享链接名称固定为：

  ```text
  zdd-argo
  ```

- 优选地址支持：
  - 域名
  - IPv4
  - IPv6
- 默认优选域名：

  ```text
  saas.sin.fan
  ```

- 支持查看订阅、查看状态、更新核心组件、清理临时缓存和安全卸载
- 不覆盖系统中由 apt 或其他项目维护的 `sing-box` / `cloudflared`

## 系统要求

- Debian 或 Ubuntu
- systemd
- root 权限
- CPU 架构：
  - `amd64`
  - `arm64`
- VPS 能访问 GitHub 和 Cloudflare

## 安装

请使用 root 用户运行。非 root 用户可在最后一条命令前加 `sudo`。

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

第一次运行时，脚本会：

1. 让你选择中文或英文；
2. 检查系统与基础依赖；
3. 将受管理的脚本副本安装到：

   ```text
   /usr/local/lib/zdd-argo/zdd-argo.sh
   ```

4. 创建快捷命令：

   ```text
   /usr/local/bin/zdd
   ```

5. 询问优选域名或优选 IP；
6. 进入管理菜单。

以后只需执行：

```bash
zdd argo
```

下载目录中的 `zdd-argo.sh` 可以保留、移动或删除，不影响已安装的管理命令。

## 语言切换

每次运行：

```bash
zdd argo
```

脚本都会先显示：

```text
Select language / 选择语言
1) 中文
2) English
```

选择后，本次菜单、提示、状态信息和错误信息都会使用对应语言。

## 优选域名 / 优选 IP

首次运行时，脚本会提示：

```text
默认值：saas.sin.fan
```

该默认域名主要面向**中国大陆电信线路**，不保证在其他运营商或其他地区表现更好。其他用户建议输入适合自己线路的优选域名或优选 IP。

支持输入：

```text
example.com
104.16.1.1
2606:4700:4700::1111
```

直接按 Enter 会保留当前值；首次配置时则使用默认值。

也可以在主菜单中随时修改优选地址。修改优选地址不会重启正在运行的临时 Argo，只会重新生成分享链接。

## 管理菜单

```text
1. 生成 / 管理临时 Argo
2. 查看当前订阅
3. 设置优选域名 / 优选 IP
4. 更新核心组件
5. 查看运行状态与最近日志
6. 断开当前 Argo 并清理临时缓存
7. 卸载 zdd-argo（保留 sing-box、cloudflared）
8. 完整卸载（含脚本专用 sing-box、cloudflared）
0. 退出
```

退出菜单不会停止已经运行的临时 Argo。

### 更新核心组件

进入“更新核心组件”后，可以选择：

```text
1. 更新 sing-box
2. 更新 cloudflared
3. 同时更新 sing-box 与 cloudflared
0. 返回
```

更新 `cloudflared` 时，当前正在运行的隧道不会被中断；新版本会在下次重建临时 Argo 时生效。

## 分享链接参数

生成的 VMess 分享链接使用：

| 参数 | 值 |
|---|---|
| 节点名称 | `zdd-argo` |
| 地址 | 当前设置的优选域名或优选 IP |
| 端口 | `443` |
| 传输 | `WebSocket` |
| TLS | 启用 |
| Host | 当前 `trycloudflare.com` 临时域名 |
| SNI | 当前 `trycloudflare.com` 临时域名 |
| ALPN | `http/1.1` |
| 指纹 | `firefox` |
| 本地入口 | `127.0.0.1:10000` |

脚本在保存前会解码并检查 VMess JSON，确认：

- 名称为 `zdd-argo`
- 优选地址正确
- Host、SNI 与临时域名一致
- ECH 扩展字段已写入

## ECH 兼容说明

脚本会同时写入：

```text
ech
echConfigList
```

默认内容：

```text
cloudflare-ech.com+https://dns.jhb.ovh/joeyblog
```

不同客户端对旧式 VMess JSON 扩展字段的支持可能不同。导入客户端后，请检查 `EchConfigList`；如果未自动保留，请手动粘贴上述内容。

## 文件位置

| 路径 | 用途 |
|---|---|
| `/usr/local/lib/zdd-argo/zdd-argo.sh` | 已安装的脚本副本 |
| `/usr/local/lib/zdd-argo/sing-box` | 脚本专用 sing-box |
| `/usr/local/lib/zdd-argo/cloudflared` | 脚本专用 cloudflared |
| `/usr/local/bin/zdd` | `zdd argo` 主快捷入口 |
| `/usr/local/sbin/zdd` | 兼容快捷入口 |
| `/etc/zdd-argo/settings.json` | 优选地址设置 |
| `/etc/zdd-argo/state.json` | UUID、WS 路径和临时域名状态 |
| `/etc/zdd-argo/vmess.json` | 当前 VMess JSON |
| `/etc/zdd-argo/vmess.txt` | 当前 VMess 分享链接 |
| `/var/log/zdd-argo-cloudflared.log` | cloudflared 日志 |
| `/etc/systemd/system/zdd-argo-singbox.service` | sing-box systemd 服务 |

请勿把以下运行时文件上传到 GitHub：

```text
/etc/zdd-argo/settings.json
/etc/zdd-argo/state.json
/etc/zdd-argo/vmess.json
/etc/zdd-argo/vmess.txt
```

## 安全设计

本项目保留并加强了本地稳定版的安全措施：

- 不执行 `curl | sh` 安装 `sing-box`
- 从官方 GitHub Release 获取二进制
- 校验 GitHub 提供的 SHA-256 摘要
- 校验 Release 下载地址来源
- 解压 `sing-box` 前检查路径穿越
- 使用脚本专用安装目录，不覆盖系统已有程序
- 更新 `sing-box` 失败时自动回滚
- 更新 `cloudflared` 失败时自动回滚
- 回滚 `sing-box` 后再次检查服务是否恢复
- `sing-box` 只监听回环地址
- systemd 服务启用权限收缩
- 状态文件使用 JSON 解析，不执行状态文件内容
- 写操作使用互斥锁
- 后台 `tmux` 不继承写操作锁
- 不删除来源不明的同名快捷命令
- 卸载时不删除下载目录或 Git 仓库中的源文件
- 分享链接生成后执行自检

## 更新脚本

重新下载并运行仓库中的新版脚本：

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

脚本会更新：

```text
/usr/local/lib/zdd-argo/zdd-argo.sh
```

更新脚本本身不会主动停止当前临时 Argo。

## 卸载

运行：

```bash
zdd argo
```

然后选择：

```text
7. 卸载 zdd-argo（保留 sing-box、cloudflared）
```

或：

```text
8. 完整卸载（含脚本专用 sing-box、cloudflared）
```

普通卸载会保留脚本专用的 `sing-box` 和 `cloudflared`；完整卸载会一并删除它们。

两种卸载方式都不会删除：

- 你手动下载的 `zdd-argo.sh`
- Git 克隆得到的仓库文件
- apt 或其他项目维护的同名程序

## Quick Tunnel 说明

本项目使用 Cloudflare Quick Tunnel。它会生成随机的：

```text
*.trycloudflare.com
```

域名。

需要注意：

- 隧道被停止或重建后，旧域名会失效
- VPS 重启或 `cloudflared` 退出后，需要重新生成临时 Argo
- Quick Tunnel 定位为开发和测试用途
- Cloudflare 当前说明 Quick Tunnel 有并发请求限制，且不支持 SSE
- 不应将其视为带 SLA 的生产隧道

Cloudflare 官方说明：

- [Quick Tunnels](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
- [Set up Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/setup/)

## 常见问题

### 为什么输入 `zdd argo` 没有反应？

确认文件存在：

```bash
ls -l /usr/local/bin/zdd /usr/local/sbin/zdd
```

再检查：

```bash
command -v zdd
```

正常情况下应返回：

```text
/usr/local/bin/zdd
```

或：

```text
/usr/local/sbin/zdd
```

如果同名 `zdd` 命令已被其他程序占用，脚本会停止安装并明确提示，不会覆盖其他程序。

### 为什么只能使用 `zdd argo`？

这是有意设计。公开版不再暴露多组复杂子命令，所有操作统一从交互菜单完成。

### 为什么分享链接名称不是自定义名称？

本项目把名称固定为：

```text
zdd-argo
```

生成分享链接后还会执行自检，名称不正确时不会写入文件。

### 为什么旧订阅突然不可用？

Quick Tunnel 的域名是临时的。隧道停止、重建或 VPS 重启后，请重新生成并导入新的分享链接。

### SSH 断开后隧道会停止吗？

不会。`cloudflared` 在独立 `tmux` 会话中后台运行。

### 退出菜单会停止隧道吗？

不会。菜单进程和临时 Argo 隧道相互独立。

## 许可证

本项目使用 [MIT License](LICENSE)。

## 免责声明

本项目仅用于合法的网络测试、学习和个人管理。使用者应遵守所在地法律法规、Cloudflare 服务条款以及相关服务提供商政策。项目作者不对滥用、配置错误、服务中断或由此造成的损失承担责任。
