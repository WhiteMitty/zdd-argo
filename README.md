<p align="right">
  <a href="#zh-cn">
    <img src="https://img.shields.io/badge/简体中文-0969DA?style=flat-square" alt="简体中文">
  </a>
  <a href="#english">
    <img src="https://img.shields.io/badge/English-6E7781?style=flat-square" alt="English">
  </a>
</p>

<a id="zh-cn"></a>

# zdd-argo

在 Debian / Ubuntu VPS 上部署和管理 **Cloudflare Quick Tunnel + VMess/WS** 的双语交互脚本。

> 当前版本：**v 0.1.0**

`zdd-argo` 使用脚本专用的 `sing-box` 和 `cloudflared`，通过独立 `tmux` 会话维持临时 Argo 隧道，并生成 VMess 分享链接。关闭 SSH 后，已经启动的临时隧道仍会继续运行。

顶部的 **简体中文 / English** 控件都指向本 README 内部，不会打开另一个 Markdown 文件。

## 主要功能

- 启动时选择：
  - `1) 中文`
  - `2) English`
- 安装后只使用一个管理命令：

  ```bash
  zdd argo
  ```

- 自动安装和更新脚本专用的：
  - `sing-box`
  - `cloudflared`
- 从官方 GitHub Release 下载核心程序并校验 SHA-256 摘要
- `sing-box` 仅监听 `127.0.0.1:10000`
- Cloudflare Quick Tunnel 在后台 `tmux` 会话中运行
- 自动生成 UUID、WebSocket 路径和 VMess 分享链接
- VMess 节点名称固定为 `zdd-argo`
- 优选地址可使用域名、IPv4 或 IPv6
- 默认优选域名为 `saas.sin.fan`
- 可查看订阅、修改优选地址、更新两个核心组件、检查状态、清理缓存和卸载
- 不覆盖 apt 或其他项目维护的 `sing-box` / `cloudflared`
- 下载或 Git 克隆得到的源文件不会被卸载流程删除

## 系统要求

- Debian 或 Ubuntu
- systemd
- root 权限
- CPU 架构：`amd64` 或 `arm64`
- 能访问 GitHub 和 Cloudflare

## 安装

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

非 root 用户将最后一条命令改为：

```bash
sudo bash zdd-argo.sh
```

每次在交互式终端运行时，脚本都会先显示语言选择。在选择语言之前，不会执行 root 检查、依赖安装、快捷命令写入、设置写入或 Argo 部署。

首次运行会：

1. 选择界面语言；
2. 检查 root 权限、系统和依赖；
3. 将脚本副本安装到 `/usr/local/lib/zdd-argo/zdd-argo.sh`；
4. 安装 `zdd` 管理启动器；
5. 询问优选域名或优选 IP；
6. 进入管理菜单。

以后使用：

```bash
zdd argo
```

非 root 用户使用：

```bash
sudo zdd argo
```

下载目录里的 `zdd-argo.sh` 可以保留、移动或删除，不影响已安装的管理命令。

## 同页语言切换

GitHub README 不运行自定义 JavaScript，因此无法实现网页式动态标签页。本 README 使用同页锚点：

- 点击顶部 `简体中文`：回到中文部分；
- 点击顶部 `English`：跳到本页面下方的英文部分；
- 不会打开 `README_EN.md` 或其他文件。

## 优选域名 / 优选 IP

首次配置会显示默认值：

```text
saas.sin.fan
```

该默认域名主要面向**中国大陆电信线路**，并不保证适合其他运营商或地区。可以直接输入自己的：

```text
example.com
104.16.1.1
2606:4700:4700::1111
```

直接按 Enter 会使用当前值；首次配置时使用默认值。

脚本会：

- 将域名转为小写；
- 移除域名末尾的点；
- 接受带方括号的 IPv6 并保存为标准裸地址；
- 将带前导零的 IPv4 规范化，例如 `001.002.003.004` 会保存为 `1.2.3.4`；
- 拒绝协议前缀、端口、空格和非法地址。

修改优选地址不会重启当前 Argo；如果隧道正在运行，只会重新生成分享链接。

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

退出菜单不会停止当前隧道。

### 更新核心组件

```text
1. 更新 sing-box
2. 更新 cloudflared
3. 同时更新 sing-box 与 cloudflared
0. 返回
```

更新 `cloudflared` 不会中断已经运行的进程；新二进制在下次重建隧道时生效。

## 分享链接参数

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

写入磁盘前，脚本会解码并验证 VMess JSON，确认：

- 节点名称为 `zdd-argo`；
- 优选地址正确；
- Host、SNI、`vcn` 与临时域名一致；
- `pcs` 为空；
- `ech` 和 `echConfigList` 已写入。

## ECH 兼容说明

默认值：

```text
cloudflare-ech.com+https://dns.jhb.ovh/joeyblog
```

脚本会同时写入：

```text
ech
echConfigList
```

部分客户端会忽略旧式 VMess JSON 的扩展字段。导入后请检查 `EchConfigList`，缺失时手动粘贴默认值。

## 文件位置

| 路径 | 用途 |
|---|---|
| `/usr/local/lib/zdd-argo/zdd-argo.sh` | 已安装脚本副本 |
| `/usr/local/lib/zdd-argo/sing-box` | 脚本专用 sing-box |
| `/usr/local/lib/zdd-argo/cloudflared` | 脚本专用 cloudflared |
| `/usr/local/bin/zdd` | 主启动器 |
| `/usr/local/sbin/zdd` | 兼容软链接 |
| `/usr/bin/zdd` | 仅在当前 PATH 无法解析前两者时创建的兼容软链接 |
| `/etc/zdd-argo/settings.json` | 优选地址设置 |
| `/etc/zdd-argo/state.json` | UUID、WS 路径和临时域名 |
| `/etc/zdd-argo/vmess.json` | 当前 VMess JSON |
| `/etc/zdd-argo/vmess.txt` | 当前 VMess 分享链接 |
| `/var/log/zdd-argo-cloudflared.log` | cloudflared 日志 |
| `/etc/systemd/system/zdd-argo-singbox.service` | sing-box 服务 |

不要上传以下运行时文件：

```text
/etc/zdd-argo/settings.json
/etc/zdd-argo/state.json
/etc/zdd-argo/vmess.json
/etc/zdd-argo/vmess.txt
```

## 安全设计

- 不使用 `curl | sh` 安装核心程序
- 仅从官方 GitHub Release 获取二进制
- 验证 Release 下载地址和 GitHub 提供的 SHA-256 摘要
- 解压 sing-box 前检查绝对路径和 `..` 路径穿越
- 核心程序安装在独立目录，不覆盖系统已有程序
- sing-box 与 cloudflared 更新包含失败回滚
- Release 元数据采用临时文件和原子替换，并显式处理写入失败
- sing-box 只监听回环地址
- systemd 服务使用权限收缩
- 状态和设置使用 JSON 解析，不执行其内容
- 写操作使用互斥锁；后台 tmux 不继承锁
- 查看订阅时的状态刷新和链接写入也受锁保护
- 启动器原子替换，并验证当前 PATH 中的 `zdd` 确实属于本项目
- 不覆盖来源不明的同名命令
- 卸载不删除下载目录或 Git 仓库源文件
- VMess 分享链接生成后执行自检

## 更新脚本

重新下载并运行：

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

这会更新 `/usr/local/lib/zdd-argo/zdd-argo.sh`，不会主动停止当前 Argo。

## 卸载

运行：

```bash
zdd argo
```

选择：

```text
7. 卸载 zdd-argo（保留 sing-box、cloudflared）
```

或：

```text
8. 完整卸载（含脚本专用 sing-box、cloudflared）
```

普通卸载删除部署、配置、服务、启动器和已安装脚本副本，但保留脚本专用的核心二进制。完整卸载会一并删除脚本专用的 `sing-box` 和 `cloudflared`。

两种方式都不会删除：

- 手动下载的脚本；
- Git 克隆目录；
- apt 或其他项目维护的同名程序。

## Quick Tunnel 说明

本项目使用 Cloudflare Quick Tunnel。每次重建都可能获得新的：

```text
*.trycloudflare.com
```

需要注意：

- 隧道停止或重建后，旧域名和旧分享链接会失效；
- VPS 重启或 cloudflared 退出后，需要重新生成；
- Quick Tunnel 适合测试和临时使用，不应视为带 SLA 的生产隧道。

## 从本地稳定版升级

本地稳定版曾在 `/usr/local/sbin/zdd` 写入不带新版标记的启动器。当前版本会先核对旧启动器是否同时包含 `zdd argo`、`exec /usr/bin/env bash` 和 `zdd-argo.sh` 特征；确认属于本项目后，才会安全替换为新版启动器。

因此，旧版启动器不会仅因缺少 `# zdd-argo launcher` 标记而被误判为外部程序。真正无关的同名 `zdd` 仍会被拒绝覆盖。

## `zdd argo` 无法找到

只更新 GitHub 仓库不会自动更新已部署的 VPS。请在 VPS 上重新运行安装命令，然后执行：

```bash
hash -r
type -P zdd
ls -l /usr/local/bin/zdd /usr/local/sbin/zdd /usr/bin/zdd 2>/dev/null
```

正常情况下，`type -P zdd` 应返回本项目的启动器。如果 PATH 中已经存在其他项目的 `zdd`，脚本会停止并显示实际路径，不会覆盖。

## 常见问题

### SSH 断开后隧道会停止吗？

不会。cloudflared 由独立 tmux 会话维持。

### 退出菜单会停止隧道吗？

不会。

### 为什么旧分享链接失效？

Quick Tunnel 的域名是临时的。停止、重建或 VPS 重启后，请重新生成链接。

### 为什么 ECH 字段没有自动导入？

客户端可能忽略 VMess JSON 扩展字段，请手动填写 README 中的默认值。

## 许可证

本项目使用 [MIT License](LICENSE)。

## 免责声明

本项目仅用于合法的网络测试、学习和个人管理。使用者应遵守所在地法律法规、Cloudflare 服务条款及相关服务商政策。作者不对滥用、配置错误、服务中断或由此造成的损失承担责任。

<p align="right"><a href="#english">English ↓</a></p>

---

<a id="english"></a>

<p align="right">
  <a href="#zh-cn"><kbd>简体中文</kbd></a>
  <a href="#english"><kbd><strong>English</strong></kbd></a>
</p>

# zdd-argo

A bilingual interactive script for deploying and managing **Cloudflare Quick Tunnel + VMess/WS** on Debian and Ubuntu VPS servers.

> Current version: **v 0.1.0**

`zdd-argo` uses script-managed copies of `sing-box` and `cloudflared`, keeps the temporary Argo tunnel running in a dedicated `tmux` session, and generates a VMess share link. Once started, the tunnel continues running after SSH is disconnected.

The **简体中文 / English** controls at the top link to sections inside this README and do not open another Markdown file.

## Features

- Select `1) 中文` or `2) English` at startup
- Use only one management command after installation:

  ```bash
  zdd argo
  ```

- Install and update script-managed `sing-box` and `cloudflared`
- Download core programs from official GitHub Releases and verify SHA-256 digests
- Make sing-box listen only on `127.0.0.1:10000`
- Run Cloudflare Quick Tunnel in a background tmux session
- Generate a UUID, WebSocket path, and VMess share link
- Fix the VMess node name to `zdd-argo`
- Accept a preferred domain, IPv4 address, or IPv6 address
- Use `saas.sin.fan` as the default preferred domain
- View the subscription, change the preferred endpoint, update both core programs, inspect status, clear temporary data, and uninstall
- Do not overwrite sing-box or cloudflared installations managed by apt or other projects
- Do not delete downloaded or Git-cloned source files during uninstallation

## Requirements

- Debian or Ubuntu
- systemd
- Root privileges
- `amd64` or `arm64`
- Network access to GitHub and Cloudflare

## Installation

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

For a non-root user, change the last command to:

```bash
sudo bash zdd-argo.sh
```

On every interactive run, language selection is shown first. Before a language is selected, the script does not perform root checks, dependency installation, launcher writes, settings writes, or Argo deployment.

On first run, the script:

1. asks for the interface language;
2. checks root privileges, the system, and dependencies;
3. installs its managed copy at `/usr/local/lib/zdd-argo/zdd-argo.sh`;
4. installs the `zdd` launcher;
5. asks for a preferred domain or IP;
6. opens the management menu.

After installation, run:

```bash
zdd argo
```

As a non-root user:

```bash
sudo zdd argo
```

The downloaded `zdd-argo.sh` can be retained, moved, or removed without breaking the installed command.

## Same-page language controls

GitHub README files cannot run custom JavaScript, so true dynamic web tabs are not available. This README uses same-page anchors:

- click `简体中文` to return to the Chinese section;
- click `English` to jump to the English section below;
- no `README_EN.md` or other file is opened.

## Preferred domain / preferred IP

The first setup displays:

```text
saas.sin.fan
```

This default is intended mainly for China Telecom routes in mainland China and is not guaranteed to be optimal for other networks or regions. You may enter your own:

```text
example.com
104.16.1.1
2606:4700:4700::1111
```

Press Enter to keep the current value, or use the default during first setup.

The script:

- lowercases domain names;
- removes a trailing dot from domains;
- accepts bracketed IPv6 and stores the bare address;
- canonicalizes IPv4 addresses with leading zeroes, so `001.002.003.004` becomes `1.2.3.4`;
- rejects scheme prefixes, ports, spaces, and invalid addresses.

Changing the preferred endpoint does not restart the current Argo tunnel. If it is running, only the share link is regenerated.

## Management menu

```text
1. Generate / manage temporary Argo
2. View current subscription
3. Set preferred domain / preferred IP
4. Update core components
5. View status and recent logs
6. Disconnect current Argo and clear temporary cache
7. Uninstall zdd-argo (keep sing-box and cloudflared)
8. Full uninstall (including script-managed sing-box and cloudflared)
0. Exit
```

Exiting the menu does not stop the tunnel.

### Update core components

```text
1. Update sing-box
2. Update cloudflared
3. Update both sing-box and cloudflared
0. Back
```

Updating cloudflared does not interrupt the running process. The new binary is used on the next tunnel rebuild.

## Share-link parameters

| Field | Value |
|---|---|
| Node name | `zdd-argo` |
| Address | Current preferred domain or IP |
| Port | `443` |
| Transport | `WebSocket` |
| TLS | Enabled |
| Host | Current temporary `trycloudflare.com` hostname |
| SNI | Current temporary `trycloudflare.com` hostname |
| ALPN | `http/1.1` |
| Fingerprint | `firefox` |
| Local inbound | `127.0.0.1:10000` |

Before saving, the script decodes and validates the VMess JSON to confirm:

- the node name is `zdd-argo`;
- the preferred endpoint is correct;
- Host, SNI, and `vcn` match the temporary hostname;
- `pcs` is empty;
- `ech` and `echConfigList` are present.

## ECH compatibility

Default value:

```text
cloudflare-ech.com+https://dns.jhb.ovh/joeyblog
```

The script writes both:

```text
ech
echConfigList
```

Some clients ignore extension fields in legacy VMess JSON. Verify `EchConfigList` after import and paste the default value manually if necessary.

## File locations

| Path | Purpose |
|---|---|
| `/usr/local/lib/zdd-argo/zdd-argo.sh` | Managed script copy |
| `/usr/local/lib/zdd-argo/sing-box` | Script-managed sing-box |
| `/usr/local/lib/zdd-argo/cloudflared` | Script-managed cloudflared |
| `/usr/local/bin/zdd` | Primary launcher |
| `/usr/local/sbin/zdd` | Compatibility symlink |
| `/usr/bin/zdd` | Fallback symlink created only when PATH cannot resolve the first two |
| `/etc/zdd-argo/settings.json` | Preferred-endpoint settings |
| `/etc/zdd-argo/state.json` | UUID, WebSocket path, and temporary hostname |
| `/etc/zdd-argo/vmess.json` | Current VMess JSON |
| `/etc/zdd-argo/vmess.txt` | Current VMess share link |
| `/var/log/zdd-argo-cloudflared.log` | cloudflared log |
| `/etc/systemd/system/zdd-argo-singbox.service` | sing-box service |

Do not upload these runtime files:

```text
/etc/zdd-argo/settings.json
/etc/zdd-argo/state.json
/etc/zdd-argo/vmess.json
/etc/zdd-argo/vmess.txt
```

## Security design

- Does not use `curl | sh` to install core programs
- Downloads binaries only from official GitHub Releases
- Verifies Release URLs and GitHub-provided SHA-256 digests
- Checks sing-box archives for absolute paths and `..` traversal
- Installs core programs in a dedicated directory without overwriting system packages
- Rolls back failed sing-box and cloudflared updates
- Writes Release metadata atomically and handles write failures explicitly
- Makes sing-box listen only on loopback
- Applies systemd service hardening
- Parses state and settings as JSON instead of executing them
- Uses a write lock; background tmux does not inherit it
- Locks subscription refresh because it can update state and share-link files
- Replaces the launcher atomically and verifies that PATH resolves `zdd` to this project
- Refuses to overwrite unrelated commands
- Does not delete downloaded or Git repository source files during uninstall
- Self-validates generated VMess links

## Updating the script

Download and run the current repository version again:

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

This updates `/usr/local/lib/zdd-argo/zdd-argo.sh` without stopping the current Argo tunnel.

## Uninstallation

Run:

```bash
zdd argo
```

Choose item 7 to keep the script-managed core binaries, or item 8 to remove them as well.

Neither option removes:

- manually downloaded scripts;
- Git clone directories;
- same-named programs managed by apt or other projects.

## Quick Tunnel notes

Each rebuild may produce a new:

```text
*.trycloudflare.com
```

Remember:

- stopping or rebuilding invalidates the old hostname and share link;
- after a VPS reboot or cloudflared exit, generate a new tunnel;
- Quick Tunnel is intended for testing and temporary use, not as a production service with an SLA.

## Upgrading from the local stable edition

The local stable edition could write an unmarked launcher to `/usr/local/sbin/zdd`. This release verifies that a legacy launcher contains the expected `zdd argo`, `exec /usr/bin/env bash`, and `zdd-argo.sh` signatures before safely replacing it with the marked launcher.

A genuine legacy launcher is therefore not mistaken for an unrelated command merely because it lacks the newer `# zdd-argo launcher` marker. Truly unrelated `zdd` commands are still never overwritten.

## `zdd argo` is not found

Updating the GitHub repository alone does not update an already deployed VPS. Run the installation command again, then check:

```bash
hash -r
type -P zdd
ls -l /usr/local/bin/zdd /usr/local/sbin/zdd /usr/bin/zdd 2>/dev/null
```

Normally, `type -P zdd` resolves to this project's launcher. If another project already owns `zdd` in PATH, installation stops and reports its actual path instead of overwriting it.

## FAQ

### Does the tunnel stop after SSH disconnects?

No. cloudflared remains in a dedicated tmux session.

### Does exiting the menu stop the tunnel?

No.

### Why did the old share link stop working?

Quick Tunnel hostnames are temporary. Generate and import a new link after stopping, rebuilding, or rebooting the VPS.

### Why was ECH not imported automatically?

The client may ignore VMess JSON extension fields. Enter the README default manually.

## License

This project uses the [MIT License](LICENSE).

## Disclaimer

This project is intended only for lawful network testing, learning, and personal administration. Users must comply with local laws, Cloudflare terms, and relevant provider policies. The author is not responsible for misuse, configuration errors, service interruption, or resulting losses.

<p align="right"><a href="#zh-cn">↑ 简体中文</a></p>
