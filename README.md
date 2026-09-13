# zdd-argo
### version 0.2.0 
### 2026-09-14

### 概览
- 默认优选域名：saas.sin.fan
- 临时隧道由 tmux 保持，断开 SSH 后仍可运行
- 在 VPS 上生成 Cloudflare 临时 Argo 隧道
- 支持 VMess / WS / TLS 与 VLESS-ENC / WS / TLS

### 要求
- root 权限
- Debian / Ubuntu / Alpine

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
```bash
zargo
```
选择完整卸载。

### 其他
- ALPN 固定为 http/1.1
- VPS 若重启，临时隧道会失效

### License
MIT
