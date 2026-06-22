# zdd-argo

在 Debian / Ubuntu VPS 上管理 **Cloudflare Quick Tunnel + VMess/WS**。

- 管理命令：`zargo`
- 后端：`sing-box` + `cloudflared`
- 临时隧道由 `tmux` 保持，断开 SSH 后仍可继续运行
- 支持中文和 English

## 系统要求

- Debian / Ubuntu
- root 权限
- systemd
- amd64 / arm64

## 安装

```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

也可以使用：

```bash
wget -qO zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && chmod +x zdd-argo.sh \
  && bash zdd-argo.sh
```

安装后使用唤醒菜单：

```bash
zargo
```

## 管理菜单

```text
1. 生成 / 管理临时 Argo
2. 查看当前订阅
3. 更新 sing-box 和 cloudflared
4. 查看运行状态与最近日志
5. 断开当前 Argo 并清理临时缓存
6. 卸载 zdd-argo（保留核心组件）
7. 完整卸载（含脚本专用核心组件）
0. 退出
```

选择更新后，会直接依次更新 `sing-box` 和 `cloudflared`，没有二级菜单。

## 卸载

运行：

```bash
zargo
```

选择普通卸载或完整卸载后，输入 `yes` 确认；

普通卸载保留脚本专用的 `sing-box` 和 `cloudflared`；完整卸载会同时删除它们。

## 说明

- Quick Tunnel 每次重建都可能获得新的 `*.trycloudflare.com` 域名。
- 停止或重建隧道后，旧分享链接会失效。
- 本项目不会覆盖 apt 或其他项目维护的 `sing-box` / `cloudflared`。
- Alpn 默认 http/1.1 是为了更好配合 WS 传输。
- <span style="color:red; font-weight:bold">Ech须手动添加，以 v2rayN 为例，找到 EchConfigList 字段填写                                             cloudflare-ech.com+https://dns.jhb.ovh/joeyblog  即实现 Ech （取自 Joey 佬）。</span>

![Ech](Ech.jpg)

## License

MIT
