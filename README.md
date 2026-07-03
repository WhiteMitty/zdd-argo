# zdd-argo
### version 0.1.0 
### 2026-07-02

### 概览
- 在 VPS 上生成 Cloudflare 临时 Argo 隧道
- 支持 `VMess / WS / TLS` 与 `VLESS-ENC / WS / TLS`
- 临时隧道由 `tmux` 保持，断开 SSH 后仍可运行
- 默认优选域名：`saas.sin.fan`
- 默认 ECH：`cloudflare-ech.com+https://doh.pub/dns-query`
- Quick Tunnel 适合临时测试，不建议作为长期生产服务

### 要求

- root 权限
- Debian / Ubuntu / Alpine
- 默认端口：
  - VMess：`10000`
  - VLESS-ENC：`10001`

### 安装
```bash
curl -fsSL -o zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && bash zdd-argo.sh
```
或者：
```bash
wget -qO zdd-argo.sh https://raw.githubusercontent.com/WhiteMitty/zdd-argo/main/zdd-argo.sh \
  && bash zdd-argo.sh
```

### 卸载
运行：
```bash
zargo
```
选择完整卸载。
完整卸载会删除：
/etc/zdd-argo
/usr/local/lib/zdd-argo
zargo 快捷命令
zdd-argo 专用服务
zdd-argo 专用日志
zdd-argo 专用低权限账户
本脚本创建的 tmux 会话
不会删除：
apt / apk 安装的系统依赖
其他脚本安装的 sing-box / xray / cloudflared
手动安装的同名程序
非本脚本创建的 tmux 会话，除非你手动选择删除

### 其他
- 停止或重建隧道后，旧 trycloudflare.com 域名会失效
- Quick Tunnel 每次重建都可能获得新的临时域名
- ALPN 固定为 http/1.1
- 订阅已尝试写入 ECH 字段；若客户端导入后为空，请手动填写：
```bash
cloudflare-ech.com+https://doh.pub/dns-query
```

### License
MIT
